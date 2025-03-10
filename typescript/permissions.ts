/**
 * TypeScript type definitions for the permission system
 * 
 * These types provide type safety when working with permissions and roles
 */

// Role types
export type OrganizationRole = 'owner' | 'admin' | 'editor' | 'member' | 'viewer';
export type DepartmentRole = 'manager' | 'member' | 'viewer';
export type ResourceType = 'organization' | 'department' | 'workflow' | 'form';
export type PermissionAction = 'view' | 'edit' | 'delete' | 'manage';

// Permission descriptor
export interface Permission {
  resource: ResourceType;
  action: PermissionAction;
}

// User permission in context
export interface UserPermission {
  userId: string;
  organizationId: string;
  role: OrganizationRole;
  departmentId?: string;
  departmentRole?: DepartmentRole;
  permissions: Permission[];
}

// Permission check request
export interface PermissionCheckRequest {
  resourceType: ResourceType;
  resourceId: string;
  action: PermissionAction;
}

// Permission check response
export interface PermissionCheckResponse {
  allowed: boolean;
  reason?: string;
}

// Permission audit log entry
export interface PermissionAuditLogEntry {
  id: string;
  userId: string;
  action: 'INSERT' | 'UPDATE' | 'DELETE';
  resourceType: string;
  resourceId: string;
  oldValue?: string;
  newValue?: string;
  performedBy: string;
  timestamp: string;
}

// Functions for permission management
export interface PermissionFunctions {
  addUserToOrganization: (userId: string, organizationId: string, role: OrganizationRole) => Promise<boolean>;
  removeUserFromOrganization: (userId: string, organizationId: string) => Promise<boolean>;
  assignDepartmentPermission: (userId: string, departmentId: string, permission: DepartmentRole) => Promise<boolean>;
  getUserPermissions: (userId: string, organizationId: string) => Promise<Permission[]>;
  hasPermission: (req: PermissionCheckRequest) => Promise<PermissionCheckResponse>;
}

// Helper functions for working with permissions in the client
export const canView = (permissions: Permission[], resourceType: ResourceType): boolean => {
  return permissions.some(p => 
    p.resource === resourceType && 
    ['view', 'edit', 'manage'].includes(p.action)
  );
};

export const canEdit = (permissions: Permission[], resourceType: ResourceType): boolean => {
  return permissions.some(p => 
    p.resource === resourceType && 
    ['edit', 'manage'].includes(p.action)
  );
};

export const canManage = (permissions: Permission[], resourceType: ResourceType): boolean => {
  return permissions.some(p => 
    p.resource === resourceType && 
    p.action === 'manage'
  );
};

// Map to display friendly names for roles
export const roleDisplayNames = {
  owner: 'Owner',
  admin: 'Administrator',
  editor: 'Editor',
  member: 'Member',
  viewer: 'Viewer',
  manager: 'Department Manager'
};

// Permission level descriptions
export const permissionDescriptions = {
  owner: 'Full control over the organization and all resources',
  admin: 'Manage users, departments, workflows, and forms',
  editor: 'Create and edit workflows and forms',
  member: 'View and use resources, submit forms',
  viewer: 'View-only access to resources',
  manager: 'Manage a specific department and its members'
};

// Default permissions by role
export const defaultPermissionsByRole: Record<OrganizationRole, Permission[]> = {
  owner: [
    { resource: 'organization', action: 'manage' },
    { resource: 'department', action: 'manage' },
    { resource: 'workflow', action: 'manage' },
    { resource: 'form', action: 'manage' }
  ],
  admin: [
    { resource: 'organization', action: 'manage' },
    { resource: 'department', action: 'manage' },
    { resource: 'workflow', action: 'manage' },
    { resource: 'form', action: 'manage' }
  ],
  editor: [
    { resource: 'organization', action: 'view' },
    { resource: 'department', action: 'view' },
    { resource: 'workflow', action: 'edit' },
    { resource: 'form', action: 'edit' }
  ],
  member: [
    { resource: 'organization', action: 'view' },
    { resource: 'department', action: 'view' },
    { resource: 'workflow', action: 'view' },
    { resource: 'form', action: 'view' }
  ],
  viewer: [
    { resource: 'organization', action: 'view' },
    { resource: 'department', action: 'view' },
    { resource: 'workflow', action: 'view' },
    { resource: 'form', action: 'view' }
  ]
};