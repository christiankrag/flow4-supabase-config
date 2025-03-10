/**
 * TypeScript type definitions for database tables
 * 
 * These types provide type safety when working with database records
 * and should be kept in sync with the actual database schema.
 */

// Organizations
export interface Organization {
  id: string;
  name: string;
  description: string | null;
  logo: string | null;
  website: string | null;
  owner_id: string;
  created_at: string | null;
  updated_at: string | null;
  parent_ids: string[] | null;
  child_ids: string[] | null;
  settings: any | null;
}

export interface OrganizationInsert extends Omit<Organization, 'id' | 'created_at' | 'updated_at'> {
  id?: string;
  created_at?: string | null;
  updated_at?: string | null;
}

export interface OrganizationUpdate extends Partial<OrganizationInsert> {}

// Organization Relationships
export interface OrganizationRelationship {
  id: string;
  parent_id: string;
  child_id: string;
  ownership_percentage: number | null;
  relationship_type: string;
  created_at: string | null;
  updated_at: string | null;
}

export interface OrganizationRelationshipInsert extends Omit<OrganizationRelationship, 'id' | 'created_at' | 'updated_at'> {
  id?: string;
  created_at?: string | null;
  updated_at?: string | null;
}

export interface OrganizationRelationshipUpdate extends Partial<OrganizationRelationshipInsert> {}

// Departments
export interface Department {
  id: string;
  name: string;
  description: string | null;
  organization_id: string;
  parent_department_id: string | null;
  manager_id: string | null;
  created_at: string | null;
  updated_at: string | null;
}

export interface DepartmentInsert extends Omit<Department, 'id' | 'created_at' | 'updated_at'> {
  id?: string;
  created_at?: string | null;
  updated_at?: string | null;
}

export interface DepartmentUpdate extends Partial<DepartmentInsert> {}

// Profiles
export interface Profile {
  id: string;
  email: string | null;
  full_name: string | null;
  avatar_url: string | null;
  website: string | null;
  username: string | null;
  default_organization_id: string | null;
  connections: string[] | null;
  bio: string | null;
  status: string | null;
  created_at: string | null;
  updated_at: string | null;
  department_id: string | null;
  role: string | null;
  reports_to: string | null;
  title: string | null;
  skills: string[] | null;
  phone: string | null;
  location: string | null;
  last_active: string | null;
  custom_fields: any | null;
}

export interface ProfileInsert extends Omit<Profile, 'created_at' | 'updated_at'> {
  created_at?: string | null;
  updated_at?: string | null;
}

export interface ProfileUpdate extends Partial<ProfileInsert> {}

// Forms
export interface Form {
  id: string;
  name: string;
  description: string | null;
  schema: FormSchema;
  version: number;
  status: string;
  organization_id: string;
  settings: any | null;
  tags: string[] | null;
  created_at: string | null;
  updated_at: string | null;
  created_by: string;
}

export interface FormInsert extends Omit<Form, 'id' | 'created_at' | 'updated_at'> {
  id?: string;
  created_at?: string | null;
  updated_at?: string | null;
}

export interface FormUpdate extends Partial<FormInsert> {}

// Form Responses (Submissions)
export interface FormSubmission {
  id: string;
  form_id: string;
  data: any;
  status: string;
  submitted_by: string | null;
  organization_id: string;
  created_at: string | null;
  updated_at: string | null;
}

export interface FormSubmissionInsert extends Omit<FormSubmission, 'id' | 'created_at' | 'updated_at'> {
  id?: string;
  created_at?: string | null;
  updated_at?: string | null;
}

export interface FormSubmissionUpdate extends Partial<FormSubmissionInsert> {}

// Workflows
export interface Workflow {
  id: string;
  name: string;
  description: string | null;
  schema: WorkflowSchema;
  version: number;
  status: string;
  organization_id: string;
  settings: any | null;
  tags: string[] | null;
  created_at: string | null;
  updated_at: string | null;
  created_by: string;
}

export interface WorkflowInsert extends Omit<Workflow, 'id' | 'created_at' | 'updated_at'> {
  id?: string;
  created_at?: string | null;
  updated_at?: string | null;
}

export interface WorkflowUpdate extends Partial<WorkflowInsert> {}

// Workflow Executions
export interface WorkflowExecution {
  id: string;
  workflow_id: string;
  status: string;
  started_at: string | null;
  completed_at: string | null;
  input_data: any | null;
  output_data: any | null;
  error_message: string | null;
  triggered_by: string | null;
  organization_id: string;
  created_at: string | null;
  updated_at: string | null;
}

export interface WorkflowExecutionInsert extends Omit<WorkflowExecution, 'id' | 'created_at' | 'updated_at'> {
  id?: string;
  created_at?: string | null;
  updated_at?: string | null;
}

export interface WorkflowExecutionUpdate extends Partial<WorkflowExecutionInsert> {}

// Workflow Execution Steps
export interface WorkflowExecutionStep {
  id: string;
  execution_id: string;
  step_id: string;
  status: string;
  started_at: string | null;
  completed_at: string | null;
  input_data: any | null;
  output_data: any | null;
  error_message: string | null;
  created_at: string | null;
  updated_at: string | null;
}

export interface WorkflowExecutionStepInsert extends Omit<WorkflowExecutionStep, 'id' | 'created_at' | 'updated_at'> {
  id?: string;
  created_at?: string | null;
  updated_at?: string | null;
}

export interface WorkflowExecutionStepUpdate extends Partial<WorkflowExecutionStepInsert> {}

// Workflow Templates
export interface WorkflowTemplate {
  id: string;
  name: string;
  description: string | null;
  schema: WorkflowSchema;
  category: string | null;
  tags: string[] | null;
  organization_id: string;
  is_public: boolean;
  created_at: string | null;
  updated_at: string | null;
  created_by: string;
}

export interface WorkflowTemplateInsert extends Omit<WorkflowTemplate, 'id' | 'created_at' | 'updated_at'> {
  id?: string;
  created_at?: string | null;
  updated_at?: string | null;
}

export interface WorkflowTemplateUpdate extends Partial<WorkflowTemplateInsert> {}

// Schema definitions
export interface FormSchema {
  nodes: any[];
  edges: any[];
}

export interface WorkflowSchema {
  nodes: any[];
  edges: any[];
}

// Extended types with relations
export interface ProfileWithRelations extends Profile {
  department?: Department;
  manager?: Profile;
  directReports?: Profile[];
}

export interface DepartmentWithRelations extends Department {
  manager?: Profile;
  parentDepartment?: Department;
  childDepartments?: Department[];
  members?: Profile[];
}

export interface OrganizationWithRelations extends Organization {
  parentOrganizations?: OrganizationRelationship[];
  childOrganizations?: OrganizationRelationship[];
  departments?: Department[];
  members?: Profile[];
}