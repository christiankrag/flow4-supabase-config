# Flow4 Supabase Configuration

This repository contains the necessary configuration files for setting up the Supabase backend for the Flow4 form builder.

## Overview

The Flow4 form builder is a feature-rich, drag-and-drop interface for creating and managing forms. It leverages Supabase for:

- Database storage for forms, form versions, and form responses
- Row-level security (RLS) policies for secure access control
- Edge functions for form submission and export
- Real-time updates for collaborative editing
- Database triggers for notifications and analytics

## Structure

- `/migrations/` - SQL migration files for database schema
- `/seed/` - Seed data for initial setup
- `/functions/` - Edge functions for form operations
- `/types/` - TypeScript type definitions

## Setup Instructions

### Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli) installed
- Supabase project already created

### Step 1: Link to Your Supabase Project

```bash
supabase login
supabase link --project-ref <your-project-ref>
```

### Step 2: Apply Migrations

```bash
# Apply the form builder tables migration
supabase db push migrations/form_builder_tables.sql

# Apply the form triggers migration
supabase db push migrations/form_triggers.sql
```

### Step 3: Load Seed Data (Optional)

```bash
supabase db execute < seed/initial_forms.sql
```

### Step 4: Deploy Edge Functions

```bash
# Deploy form submission function
supabase functions deploy form-submission

# Deploy form export function
supabase functions deploy form-export
```

### Step 5: Set Up Storage

```bash
# Create a bucket for form attachments
supabase storage create form-attachments
```

### Step 6: Update Environment Variables in Your Frontend Application

Add the following environment variables to your frontend application:

```
NEXT_PUBLIC_SUPABASE_URL=<your-supabase-url>
NEXT_PUBLIC_SUPABASE_ANON_KEY=<your-supabase-anon-key>
SUPABASE_SERVICE_ROLE_KEY=<your-supabase-service-role-key>
```

## Database Schema

### Forms Table

Stores the main form metadata and the current version information.

```sql
CREATE TABLE IF NOT EXISTS public.forms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  schema JSONB NOT NULL DEFAULT '{}'::jsonb,
  metadata JSONB DEFAULT '{}'::jsonb,
  version INTEGER NOT NULL DEFAULT 1,
  status TEXT NOT NULL DEFAULT 'draft',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  created_by UUID REFERENCES auth.users(id),
  organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE
);
```

### Form Versions Table

Tracks the history of form changes over time.

```sql
CREATE TABLE IF NOT EXISTS public.form_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  form_id UUID REFERENCES public.forms(id) ON DELETE CASCADE,
  version_number INTEGER NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  schema JSONB NOT NULL DEFAULT '{}'::jsonb,
  status TEXT NOT NULL DEFAULT 'draft',
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  published_at TIMESTAMPTZ,
  organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
  UNIQUE(form_id, version_number)
);
```

### Form Responses Table

Stores user submissions for forms.

```sql
CREATE TABLE IF NOT EXISTS public.form_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  form_id UUID REFERENCES public.forms(id) ON DELETE CASCADE,
  form_version INTEGER NOT NULL,
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  metadata JSONB DEFAULT '{}'::jsonb,
  status TEXT NOT NULL DEFAULT 'submitted',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  submitted_by UUID REFERENCES auth.users(id),
  organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE
);
```

## Edge Functions

### Form Submission

Handles form submissions, validates the data, and stores it in the database.

**Endpoint**: `/form-submission`

**Method**: POST

**Request Body**:
```json
{
  "formId": "uuid",
  "formVersion": 1,
  "data": {
    "field1": "value1",
    "field2": "value2"
  },
  "metadata": {
    "browser": "Chrome",
    "device": "Desktop"
  },
  "organizationId": "uuid"
}
```

### Form Export

Exports form responses in various formats (JSON, CSV, PDF).

**Endpoint**: `/form-export`

**Method**: POST

**Request Body**:
```json
{
  "formId": "uuid",
  "format": "json",
  "dateRange": {
    "start": "2023-01-01",
    "end": "2023-12-31"
  }
}
```

## Security

Row-level security (RLS) policies ensure that users can only access forms and submissions within their organization.

## Extending the Configuration

### Adding New Fields

To add new field types to the form builder:

1. Update the form builder front-end components
2. No changes to the database schema are required as field types are stored in the JSONB schema field

### Adding Analytics

1. Create a new table for analytics data
2. Create triggers to update analytics on form submission
3. Create an edge function to retrieve analytics data