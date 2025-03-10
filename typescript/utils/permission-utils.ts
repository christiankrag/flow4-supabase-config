import { createClient } from '@supabase/supabase-js';
import {
  OrganizationRole,
  DepartmentRole,
  ResourceType,
  PermissionAction,
  Permission,
  PermissionCheckRequest,
  PermissionCheckResponse,
  UserPermission
} from '../permissions';
import { Profile } from '../database';

/**
 * Utility functions for working with permissions in the Flow4 app
 * 
 * These functions help with checking permissions, managing roles,
 * and providing consistent permission handling across the application.
 */

/**
 * Creates a Supabase client with the appropriate permissions
 */
export const createPermissionClient = () => {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
  const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;
  return createClient(supabaseUrl, supabaseKey);
};

/**
 * Check if a user has permission to perform an action on a resource
 * 
 * @param resourceType The type of resource (organization, department, workflow, form)
 * @param resourceId The ID of the specific resource
 * @param action The action to check (view, edit, delete, manage)
 * @returns Promise with the permission check result
 */
export const checkPermission = async (
  resourceType: ResourceType,
  resourceId: string,
  action: PermissionAction
): Promise<PermissionCheckResponse> => {
  const client = createPermissionClient();
  
  try {
    const { data, error } = await client.rpc('has_permission', {
      p_resource_type: resourceType,
      p_resource_id: resourceId,
      p_action: action
    });
    
    if (error) throw error;
    
    return {
      allowed: !!data,
      reason: data ? undefined : 'Insufficient permissions'
    };
  } catch (error: any) {
    console.error('Permission check failed:', error);
    return {
      allowed: false,
      reason: error.message || 'Permission check failed'
    };
  }
};

/**
 * Get all permissions for a user in an organization
 * 
 * @param userId The user ID to check permissions for
 * @param organizationId The organization context
 * @returns Promise with an array of permissions
 */
export const getUserPermissions = async (
  userId: string,
  organizationId: string
): Promise<Permission[]> => {
  const client = createPermissionClient();
  
  try {
    const { data, error } = await client.rpc('get_user_permissions', {
      p_user_id: userId,
      p_organization_id: organizationId
    });
    
    if (error) throw error;
    
    return (data || []).map((item: any) => ({
      resource: item.resource_type as ResourceType,
      action: item.permission as PermissionAction
    }));
  } catch (error: any) {
    console.error('Failed to get user permissions:', error);
    return [];
  }
};

/**
 * Add a user to an organization with a specific role
 * 
 * @param userId The user ID to add
 * @param organizationId The organization to add the user to
 * @param role The role to assign to the user
 * @returns Promise with the success status
 */
export const addUserToOrganization = async (
  userId: string,
  organizationId: string,
  role: OrganizationRole
): Promise<boolean> => {
  const client = createPermissionClient();
  
  try {
    const { data, error } = await client.rpc('add_user_to_organization', {
      p_user_id: userId,
      p_organization_id: organizationId,
      p_role: role
    });
    
    if (error) throw error;
    
    return !!data;
  } catch (error: any) {
    console.error('Failed to add user to organization:', error);
    return false;
  }
};

/**
 * Remove a user from an organization
 * 
 * @param userId The user ID to remove
 * @param organizationId The organization to remove the user from
 * @returns Promise with the success status
 */
export const removeUserFromOrganization = async (
  userId: string,
  organizationId: string
): Promise<boolean> => {
  const client = createPermissionClient();
  
  try {
    const { data, error } = await client.rpc('remove_user_from_organization', {
      p_user_id: userId,
      p_organization_id: organizationId
    });
    
    if (error) throw error;
    
    return !!data;
  } catch (error: any) {
    console.error('Failed to remove user from organization:', error);
    return false;
  }
};

/**
 * Assign a user to a department with a specific permission
 * 
 * @param userId The user ID to assign
 * @param departmentId The department to assign the user to
 * @param permission The permission level in the department
 * @returns Promise with the success status
 */
export const assignDepartmentPermission = async (
  userId: string,
  departmentId: string,
  permission: DepartmentRole
): Promise<boolean> => {
  const client = createPermissionClient();
  
  try {
    const { data, error } = await client.rpc('assign_department_permission', {
      p_user_id: userId,
      p_department_id: departmentId,
      p_permission: permission
    });
    
    if (error) throw error;
    
    return !!data;
  } catch (error: any) {
    console.error('Failed to assign department permission:', error);
    return false;
  }
};

/**
 * Get audit logs for permission changes
 * 
 * @param limit The maximum number of logs to retrieve
 * @param offset The offset for pagination
 * @returns Promise with the audit log entries
 */
export const getPermissionAuditLogs = async (
  limit: number = 20,
  offset: number = 0
) => {
  const client = createPermissionClient();
  
  try {
    const { data, error } = await client
      .from('permission_audit_log')
      .select('*')
      .order('timestamp', { ascending: false })
      .range(offset, offset + limit - 1);
    
    if (error) throw error;
    
    return data;
  } catch (error: any) {
    console.error('Failed to get permission audit logs:', error);
    return [];
  }
};

/**
 * Create React Hook friendly permission checking function
 * 
 * @param userPermissions The user's permissions
 * @returns Object with permission checking functions
 */
export const createPermissionChecker = (userPermissions: Permission[]) => {
  return {
    /**
     * Check if the user can view a resource type
     */
    canView: (resourceType: ResourceType): boolean => {
      return userPermissions.some(p => 
        p.resource === resourceType && 
        ['view', 'edit', 'manage'].includes(p.action)
      );
    },
    
    /**
     * Check if the user can edit a resource type
     */
    canEdit: (resourceType: ResourceType): boolean => {
      return userPermissions.some(p => 
        p.resource === resourceType && 
        ['edit', 'manage'].includes(p.action)
      );
    },
    
    /**
     * Check if the user can manage a resource type
     */
    canManage: (resourceType: ResourceType): boolean => {
      return userPermissions.some(p => 
        p.resource === resourceType && 
        p.action === 'manage'
      );
    }
  };
};