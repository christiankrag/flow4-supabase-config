import { useState, useEffect, useCallback, useMemo } from 'react';
import { Permission, ResourceType, PermissionAction } from '../permissions';
import { getUserPermissions, checkPermission } from '../utils/permission-utils';

/**
 * React hook for managing user permissions in the application
 * 
 * @param userId The ID of the user
 * @param organizationId The ID of the organization context
 * @returns Object with permission data and helper functions
 */
export const usePermissions = (userId: string, organizationId: string) => {
  const [permissions, setPermissions] = useState<Permission[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  // Fetch user permissions
  useEffect(() => {
    if (!userId || !organizationId) {
      setPermissions([]);
      setIsLoading(false);
      return;
    }

    const fetchPermissions = async () => {
      setIsLoading(true);
      setError(null);
      
      try {
        const userPermissions = await getUserPermissions(userId, organizationId);
        setPermissions(userPermissions);
      } catch (err: any) {
        console.error('Error fetching permissions:', err);
        setError(err.message || 'Failed to load permissions');
        setPermissions([]);
      } finally {
        setIsLoading(false);
      }
    };

    fetchPermissions();
  }, [userId, organizationId]);

  // Check specific permission
  const hasPermission = useCallback(async (
    resourceType: ResourceType,
    resourceId: string,
    action: PermissionAction
  ): Promise<boolean> => {
    if (!userId || !organizationId) return false;
    
    try {
      const result = await checkPermission(resourceType, resourceId, action);
      return result.allowed;
    } catch (err) {
      console.error('Permission check failed:', err);
      return false;
    }
  }, [userId, organizationId]);

  // Pre-computed permission checkers based on current permissions
  const permissionCheckers = useMemo(() => {
    return {
      // Check if user can view a resource type
      canView: (resourceType: ResourceType): boolean => {
        return permissions.some(p => 
          p.resource === resourceType && 
          ['view', 'edit', 'manage'].includes(p.action)
        );
      },
      
      // Check if user can edit a resource type
      canEdit: (resourceType: ResourceType): boolean => {
        return permissions.some(p => 
          p.resource === resourceType && 
          ['edit', 'manage'].includes(p.action)
        );
      },
      
      // Check if user can manage a resource type
      canManage: (resourceType: ResourceType): boolean => {
        return permissions.some(p => 
          p.resource === resourceType && 
          p.action === 'manage'
        );
      }
    };
  }, [permissions]);

  return {
    permissions,
    isLoading,
    error,
    hasPermission,
    ...permissionCheckers
  };
};

/**
 * Utility hook for checking permissions in organization context
 * 
 * @param userId The user ID
 * @param organizationId The organization ID
 * @param resourceType The type of resource
 * @param actions The actions to check
 * @returns Permission status and loading state
 */
export const useOrganizationPermissions = (
  userId: string, 
  organizationId: string,
  resourceType: ResourceType,
  actions: PermissionAction[] = ['view', 'edit', 'manage']
) => {
  const { 
    permissions, 
    isLoading, 
    error 
  } = usePermissions(userId, organizationId);

  const computedPermissions = useMemo(() => {
    const result: Record<string, boolean> = {};
    
    // Initialize all actions to false
    actions.forEach(action => {
      result[action] = false;
    });
    
    // Check each permission
    permissions.forEach(permission => {
      if (permission.resource === resourceType) {
        // If we have manage permission, we implicitly have edit and view
        if (permission.action === 'manage') {
          result['manage'] = true;
          result['edit'] = true;
          result['view'] = true;
        }
        // If we have edit permission, we implicitly have view
        else if (permission.action === 'edit') {
          result['edit'] = true;
          result['view'] = true;
        }
        // View permission
        else if (permission.action === 'view') {
          result['view'] = true;
        }
      }
    });
    
    return result;
  }, [permissions, resourceType, actions]);

  return {
    canView: computedPermissions['view'] || false,
    canEdit: computedPermissions['edit'] || false,
    canManage: computedPermissions['manage'] || false,
    isLoading,
    error
  };
};

/**
 * Utility hook for checking permissions on a specific resource
 * 
 * @param userId The user ID
 * @param resourceType The type of resource
 * @param resourceId The ID of the specific resource
 * @param action The action to check
 * @returns Permission status and loading state
 */
export const useResourcePermission = (
  userId: string,
  resourceType: ResourceType,
  resourceId: string,
  action: PermissionAction
) => {
  const [allowed, setAllowed] = useState<boolean>(false);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!userId || !resourceType || !resourceId) {
      setAllowed(false);
      setIsLoading(false);
      return;
    }

    const checkResourcePermission = async () => {
      setIsLoading(true);
      setError(null);
      
      try {
        const result = await checkPermission(resourceType, resourceId, action);
        setAllowed(result.allowed);
      } catch (err: any) {
        console.error('Permission check failed:', err);
        setError(err.message || 'Permission check failed');
        setAllowed(false);
      } finally {
        setIsLoading(false);
      }
    };

    checkResourcePermission();
  }, [userId, resourceType, resourceId, action]);

  return { allowed, isLoading, error };
};