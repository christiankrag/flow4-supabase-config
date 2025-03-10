-- Create organization relationships table for hierarchy
CREATE TABLE IF NOT EXISTS organization_relationships (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  parent_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  child_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  ownership_percentage NUMERIC(5,2) CHECK (ownership_percentage BETWEEN 0 AND 100),
  relationship_type TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT organization_relationships_parent_child_unique UNIQUE (parent_id, child_id),
  CONSTRAINT organization_relationships_different_orgs CHECK (parent_id != child_id)
);

-- Create departments table
CREATE TABLE IF NOT EXISTS departments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  parent_department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
  manager_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT departments_self_reference_check CHECK (id != parent_department_id)
);

-- Alter profiles table to add department and role fields
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS department_id UUID REFERENCES departments(id) ON DELETE SET NULL;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS role TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS reports_to UUID REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS bio TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS skills TEXT[];
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS location TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS last_active TIMESTAMPTZ;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS custom_fields JSONB;

-- Enable Row Level Security
ALTER TABLE organization_relationships ENABLE ROW LEVEL SECURITY;
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;

-- Create policies for organization relationships
CREATE POLICY organization_relationships_view_policy ON organization_relationships
  FOR SELECT
  USING (
    parent_id IN (
      SELECT organization_id FROM organization_members WHERE user_id = auth.uid()
    ) OR
    child_id IN (
      SELECT organization_id FROM organization_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY organization_relationships_insert_policy ON organization_relationships
  FOR INSERT
  WITH CHECK (
    parent_id IN (
      SELECT organization_id FROM organization_members 
      WHERE user_id = auth.uid() AND role IN ('admin', 'owner')
    ) AND
    child_id IN (
      SELECT organization_id FROM organization_members 
      WHERE user_id = auth.uid() AND role IN ('admin', 'owner')
    )
  );

CREATE POLICY organization_relationships_update_policy ON organization_relationships
  FOR UPDATE
  USING (
    parent_id IN (
      SELECT organization_id FROM organization_members 
      WHERE user_id = auth.uid() AND role IN ('admin', 'owner')
    ) AND
    child_id IN (
      SELECT organization_id FROM organization_members 
      WHERE user_id = auth.uid() AND role IN ('admin', 'owner')
    )
  );

CREATE POLICY organization_relationships_delete_policy ON organization_relationships
  FOR DELETE
  USING (
    parent_id IN (
      SELECT organization_id FROM organization_members 
      WHERE user_id = auth.uid() AND role IN ('admin', 'owner')
    ) AND
    child_id IN (
      SELECT organization_id FROM organization_members 
      WHERE user_id = auth.uid() AND role IN ('admin', 'owner')
    )
  );

-- Create policies for departments
CREATE POLICY departments_view_policy ON departments
  FOR SELECT
  USING (
    organization_id IN (
      SELECT organization_id FROM organization_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY departments_insert_policy ON departments
  FOR INSERT
  WITH CHECK (
    organization_id IN (
      SELECT organization_id FROM organization_members 
      WHERE user_id = auth.uid() AND role IN ('admin', 'owner')
    )
  );

CREATE POLICY departments_update_policy ON departments
  FOR UPDATE
  USING (
    organization_id IN (
      SELECT organization_id FROM organization_members 
      WHERE user_id = auth.uid() AND role IN ('admin', 'owner')
    )
  );

CREATE POLICY departments_delete_policy ON departments
  FOR DELETE
  USING (
    organization_id IN (
      SELECT organization_id FROM organization_members 
      WHERE user_id = auth.uid() AND role IN ('admin', 'owner')
    )
  );

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS organization_relationships_parent_id_idx ON organization_relationships(parent_id);
CREATE INDEX IF NOT EXISTS organization_relationships_child_id_idx ON organization_relationships(child_id);
CREATE INDEX IF NOT EXISTS departments_organization_id_idx ON departments(organization_id);
CREATE INDEX IF NOT EXISTS departments_parent_department_id_idx ON departments(parent_department_id);
CREATE INDEX IF NOT EXISTS departments_manager_id_idx ON departments(manager_id);
CREATE INDEX IF NOT EXISTS profiles_department_id_idx ON profiles(department_id);
CREATE INDEX IF NOT EXISTS profiles_reports_to_idx ON profiles(reports_to);

-- Create triggers for updated_at timestamp
CREATE TRIGGER update_organization_relationships_updated_at
BEFORE UPDATE ON organization_relationships
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_departments_updated_at
BEFORE UPDATE ON departments
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Create functions for department operations
-- Function to get all child departments recursively
CREATE OR REPLACE FUNCTION get_all_child_departments(root_department_id UUID)
RETURNS TABLE (department_id UUID) AS $$
WITH RECURSIVE department_tree AS (
  -- Base case: the root department
  SELECT id AS department_id FROM departments WHERE id = root_department_id
  
  UNION ALL
  
  -- Recursive case: all child departments
  SELECT d.id AS department_id
  FROM departments d
  JOIN department_tree dt ON d.parent_department_id = dt.department_id
)
SELECT department_id FROM department_tree;
$$ LANGUAGE SQL;

-- Function to check if a user is a manager of a department or any parent department
CREATE OR REPLACE FUNCTION is_department_manager_or_above(check_department_id UUID, check_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  current_dept_id UUID := check_department_id;
  is_manager BOOLEAN := FALSE;
BEGIN
  -- Check current department and all parent departments
  WHILE current_dept_id IS NOT NULL AND NOT is_manager LOOP
    -- Check if the user is the manager of the current department
    SELECT EXISTS (
      SELECT 1 FROM departments WHERE id = current_dept_id AND manager_id = check_user_id
    ) INTO is_manager;
    
    -- Move up to parent department if not manager
    IF NOT is_manager THEN
      SELECT parent_department_id INTO current_dept_id FROM departments WHERE id = current_dept_id;
    END IF;
  END LOOP;
  
  RETURN is_manager;
END;
$$ LANGUAGE plpgsql;