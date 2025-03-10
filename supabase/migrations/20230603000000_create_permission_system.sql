-- Create permission system with automated grants
-- This migration implements a comprehensive permission system to avoid manual intervention

-- Create application roles
CREATE ROLE IF NOT EXISTS app_admin;
CREATE ROLE IF NOT EXISTS app_editor;
CREATE ROLE IF NOT EXISTS app_viewer;
CREATE ROLE IF NOT EXISTS app_member;

-- Create a function to automatically grant permissions on tables
CREATE OR REPLACE FUNCTION grant_permissions_on_table()
RETURNS event_trigger AS $$
DECLARE
  obj record;
  schema_name text;
  table_name text;
BEGIN
  FOR obj IN SELECT * FROM pg_event_trigger_ddl_commands() WHERE command_tag IN ('CREATE TABLE', 'ALTER TABLE')
  LOOP
    -- Extract schema and table name
    schema_name := (regexp_matches(obj.object_identity, E'(\\w+)\\.(\\w+)'))[1];
    table_name := (regexp_matches(obj.object_identity, E'(\\w+)\\.(\\w+)'))[2];
    
    -- Skip if not in public schema
    IF schema_name != 'public' THEN
      CONTINUE;
    END IF;
    
    -- Grant permissions based on role
    EXECUTE format('GRANT SELECT ON %I.%I TO app_viewer, app_member, app_editor, app_admin', schema_name, table_name);
    EXECUTE format('GRANT INSERT, UPDATE ON %I.%I TO app_member, app_editor, app_admin', schema_name, table_name);
    EXECUTE format('GRANT DELETE ON %I.%I TO app_editor, app_admin', schema_name, table_name);
    EXECUTE format('GRANT ALL PRIVILEGES ON %I.%I TO app_admin', schema_name, table_name);
    
    RAISE NOTICE 'Granted permissions on %', obj.object_identity;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Create an event trigger to call our function
DROP EVENT TRIGGER IF EXISTS table_permission_trigger;
CREATE EVENT TRIGGER table_permission_trigger ON ddl_command_end
WHEN TAG IN ('CREATE TABLE', 'ALTER TABLE')
EXECUTE FUNCTION grant_permissions_on_table();

-- Create a function to manage organization roles
CREATE OR REPLACE FUNCTION manage_organization_role(
  p_user_id UUID,
  p_organization_id UUID,
  p_role TEXT
) RETURNS VOID AS $$
DECLARE
  v_db_role TEXT;
BEGIN
  -- Map application role to database role
  CASE p_role
    WHEN 'owner' THEN v_db_role := 'app_admin';
    WHEN 'admin' THEN v_db_role := 'app_admin';
    WHEN 'editor' THEN v_db_role := 'app_editor';
    WHEN 'member' THEN v_db_role := 'app_member';
    ELSE v_db_role := 'app_viewer';
  END CASE;
  
  -- Grant the database role to the user
  EXECUTE format('GRANT %I TO auth.uid()::text', v_db_role);
  
  -- Store the role in organization_members table
  INSERT INTO organization_members (user_id, organization_id, role)
  VALUES (p_user_id, p_organization_id, p_role)
  ON CONFLICT (user_id, organization_id) 
  DO UPDATE SET role = p_role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a secure function to assign department permissions
CREATE OR REPLACE FUNCTION assign_department_permission(
  p_user_id UUID,
  p_department_id UUID,
  p_permission TEXT
) RETURNS BOOLEAN AS $$
DECLARE
  v_organization_id UUID;
  v_user_role TEXT;
  v_user_in_org BOOLEAN;
BEGIN
  -- Check if department exists and get organization ID
  SELECT organization_id INTO v_organization_id
  FROM departments
  WHERE id = p_department_id;
  
  IF v_organization_id IS NULL THEN
    RETURN FALSE; -- Department not found
  END IF;
  
  -- Check if user is in the organization
  SELECT EXISTS (
    SELECT 1 FROM organization_members
    WHERE user_id = p_user_id AND organization_id = v_organization_id
  ) INTO v_user_in_org;
  
  IF NOT v_user_in_org THEN
    RETURN FALSE; -- User not in organization
  END IF;
  
  -- Check if user has sufficient privileges (admin or owner)
  SELECT role INTO v_user_role
  FROM organization_members
  WHERE user_id = auth.uid() AND organization_id = v_organization_id;
  
  IF v_user_role NOT IN ('admin', 'owner') THEN
    RETURN FALSE; -- Insufficient privileges
  END IF;
  
  -- Assign user to department with the specified permission
  UPDATE profiles
  SET department_id = p_department_id,
      role = p_permission
  WHERE id = p_user_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if a user has a specific permission on a resource
CREATE OR REPLACE FUNCTION has_permission(
  p_resource_type TEXT,
  p_resource_id UUID,
  p_action TEXT
) RETURNS BOOLEAN AS $$
DECLARE
  v_organization_id UUID;
  v_user_role TEXT;
  v_department_id UUID;
  v_user_department_id UUID;
  v_is_manager BOOLEAN;
BEGIN
  -- Default to no permission
  v_user_role := 'none';
  
  -- Handle different resource types
  CASE p_resource_type
    WHEN 'organization' THEN
      -- Get user's role in the organization
      SELECT role INTO v_user_role
      FROM organization_members
      WHERE user_id = auth.uid() AND organization_id = p_resource_id;
      
    WHEN 'department' THEN
      -- Get organization ID for the department
      SELECT organization_id, id INTO v_organization_id, v_department_id
      FROM departments
      WHERE id = p_resource_id;
      
      -- Get user's role in the organization
      SELECT role INTO v_user_role
      FROM organization_members
      WHERE user_id = auth.uid() AND organization_id = v_organization_id;
      
      -- Check if user is a manager of this department or parent department
      SELECT is_department_manager_or_above(p_resource_id, auth.uid()) INTO v_is_manager;
      
      -- If user is a manager, elevate their effective role for this operation
      IF v_is_manager AND v_user_role IN ('member', 'editor') THEN
        v_user_role := 'editor';
      END IF;
      
    WHEN 'workflow' THEN
      -- Get organization ID for the workflow
      SELECT organization_id INTO v_organization_id
      FROM workflows
      WHERE id = p_resource_id;
      
      -- Get user's role in the organization
      SELECT role INTO v_user_role
      FROM organization_members
      WHERE user_id = auth.uid() AND organization_id = v_organization_id;
      
    WHEN 'form' THEN
      -- Get organization ID for the form
      SELECT organization_id INTO v_organization_id
      FROM forms
      WHERE id = p_resource_id;
      
      -- Get user's role in the organization
      SELECT role INTO v_user_role
      FROM organization_members
      WHERE user_id = auth.uid() AND organization_id = v_organization_id;
      
    ELSE
      RETURN FALSE; -- Unknown resource type
  END CASE;
  
  -- Check permission based on role and action
  CASE p_action
    WHEN 'view' THEN
      RETURN v_user_role IN ('viewer', 'member', 'editor', 'admin', 'owner');
    WHEN 'edit' THEN
      RETURN v_user_role IN ('editor', 'admin', 'owner');
    WHEN 'delete' THEN
      RETURN v_user_role IN ('admin', 'owner');
    WHEN 'manage' THEN
      RETURN v_user_role IN ('admin', 'owner');
    ELSE
      RETURN FALSE; -- Unknown action
  END CASE;
END;
$$ LANGUAGE plpgsql;

-- Grant required permissions for existing tables
DO $$
DECLARE
  table_record RECORD;
BEGIN
  FOR table_record IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public')
  LOOP
    EXECUTE format('GRANT SELECT ON %I TO app_viewer, app_member, app_editor, app_admin', table_record.tablename);
    EXECUTE format('GRANT INSERT, UPDATE ON %I TO app_member, app_editor, app_admin', table_record.tablename);
    EXECUTE format('GRANT DELETE ON %I TO app_editor, app_admin', table_record.tablename);
    EXECUTE format('GRANT ALL PRIVILEGES ON %I TO app_admin', table_record.tablename);
  END LOOP;
END;
$$;

-- Create API for permission management
CREATE OR REPLACE FUNCTION add_user_to_organization(
  p_user_id UUID,
  p_organization_id UUID,
  p_role TEXT
) RETURNS BOOLEAN AS $$
BEGIN
  -- Check if caller has permission to manage the organization
  IF NOT has_permission('organization', p_organization_id, 'manage') THEN
    RETURN FALSE;
  END IF;
  
  -- Add user to organization with specified role
  PERFORM manage_organization_role(p_user_id, p_organization_id, p_role);
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION remove_user_from_organization(
  p_user_id UUID,
  p_organization_id UUID
) RETURNS BOOLEAN AS $$
BEGIN
  -- Check if caller has permission to manage the organization
  IF NOT has_permission('organization', p_organization_id, 'manage') THEN
    RETURN FALSE;
  END IF;
  
  -- Remove user from organization
  DELETE FROM organization_members
  WHERE user_id = p_user_id AND organization_id = p_organization_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to audit permission changes
CREATE OR REPLACE FUNCTION log_permission_change() RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO permission_audit_log (
    user_id,
    action,
    resource_type,
    resource_id,
    old_value,
    new_value,
    performed_by
  ) VALUES (
    CASE 
      WHEN TG_OP = 'INSERT' THEN NEW.user_id
      ELSE OLD.user_id
    END,
    TG_OP,
    TG_TABLE_NAME,
    CASE 
      WHEN TG_OP = 'INSERT' THEN NEW.organization_id
      ELSE OLD.organization_id
    END,
    CASE 
      WHEN TG_OP = 'DELETE' THEN OLD.role
      WHEN TG_OP = 'UPDATE' THEN OLD.role
      ELSE NULL
    END,
    CASE 
      WHEN TG_OP = 'INSERT' THEN NEW.role
      WHEN TG_OP = 'UPDATE' THEN NEW.role
      ELSE NULL
    END,
    auth.uid()
  );
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create audit log table
CREATE TABLE IF NOT EXISTS permission_audit_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  action TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id UUID NOT NULL,
  old_value TEXT,
  new_value TEXT,
  performed_by UUID NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create triggers on organization_members table
DROP TRIGGER IF EXISTS org_members_audit_insert ON organization_members;
CREATE TRIGGER org_members_audit_insert
AFTER INSERT ON organization_members
FOR EACH ROW
EXECUTE FUNCTION log_permission_change();

DROP TRIGGER IF EXISTS org_members_audit_update ON organization_members;
CREATE TRIGGER org_members_audit_update
AFTER UPDATE OF role ON organization_members
FOR EACH ROW
EXECUTE FUNCTION log_permission_change();

DROP TRIGGER IF EXISTS org_members_audit_delete ON organization_members;
CREATE TRIGGER org_members_audit_delete
AFTER DELETE ON organization_members
FOR EACH ROW
EXECUTE FUNCTION log_permission_change();

-- Function to get a user's effective permissions in an organization
CREATE OR REPLACE FUNCTION get_user_permissions(
  p_user_id UUID,
  p_organization_id UUID
) RETURNS TABLE (
  resource_type TEXT,
  permission TEXT
) AS $$
DECLARE
  v_role TEXT;
BEGIN
  -- Get user's role in the organization
  SELECT role INTO v_role
  FROM organization_members
  WHERE user_id = p_user_id AND organization_id = p_organization_id;
  
  IF v_role IS NULL THEN
    RETURN;
  END IF;
  
  -- Return permissions based on role
  CASE v_role
    WHEN 'owner' THEN
      resource_type := 'organization';
      permission := 'manage';
      RETURN NEXT;
      resource_type := 'department';
      permission := 'manage';
      RETURN NEXT;
      resource_type := 'form';
      permission := 'manage';
      RETURN NEXT;
      resource_type := 'workflow';
      permission := 'manage';
      RETURN NEXT;
      
    WHEN 'admin' THEN
      resource_type := 'organization';
      permission := 'manage';
      RETURN NEXT;
      resource_type := 'department';
      permission := 'manage';
      RETURN NEXT;
      resource_type := 'form';
      permission := 'manage';
      RETURN NEXT;
      resource_type := 'workflow';
      permission := 'manage';
      RETURN NEXT;
      
    WHEN 'editor' THEN
      resource_type := 'organization';
      permission := 'view';
      RETURN NEXT;
      resource_type := 'department';
      permission := 'view';
      RETURN NEXT;
      resource_type := 'form';
      permission := 'edit';
      RETURN NEXT;
      resource_type := 'workflow';
      permission := 'edit';
      RETURN NEXT;
      
    WHEN 'member' THEN
      resource_type := 'organization';
      permission := 'view';
      RETURN NEXT;
      resource_type := 'department';
      permission := 'view';
      RETURN NEXT;
      resource_type := 'form';
      permission := 'view';
      RETURN NEXT;
      resource_type := 'workflow';
      permission := 'view';
      RETURN NEXT;
      
    WHEN 'viewer' THEN
      resource_type := 'organization';
      permission := 'view';
      RETURN NEXT;
      resource_type := 'department';
      permission := 'view';
      RETURN NEXT;
      resource_type := 'form';
      permission := 'view';
      RETURN NEXT;
      resource_type := 'workflow';
      permission := 'view';
      RETURN NEXT;
  END CASE;
  
  -- Check if user is a department manager
  FOR resource_type, permission IN
    SELECT 'department', 'manage'
    FROM departments
    WHERE manager_id = p_user_id AND organization_id = p_organization_id
  LOOP
    RETURN NEXT;
  END LOOP;
END;
$$ LANGUAGE plpgsql;