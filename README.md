# Flow4 Supabase Configuration

This repository contains the database schema, migrations, and TypeScript type definitions for the Flow4 Business Process Management Platform.

## Overview

Flow4 is a comprehensive business process management platform built with Next.js, React, and Supabase. It enables organizations to create custom forms, design workflows, and manage organizational structures efficiently.

This repository houses the Supabase configuration, including:
- Database schemas and migrations
- SQL functions and triggers
- Row Level Security policies
- TypeScript type definitions

## Structure

```
flow4-supabase-config/
├── supabase/
│   ├── migrations/           # Database migrations
│   │   ├── 20230601000000_create_workflow_tables.sql
│   │   ├── 20230602000000_create_organization_hierarchy_tables.sql
│   │   └── ...
│   ├── functions/            # PostgreSQL functions
│   └── seed/                 # Seed data
├── typescript/               # TypeScript type definitions
│   ├── database.ts           # Database schema types
│   └── ...
└── README.md
```

## Database Schema

The database schema includes the following key tables:

### Organization Management
- `organizations`: Core organization details
- `organization_relationships`: Parent-child relationships between organizations
- `departments`: Departmental structure within organizations
- `profiles`: User profiles with extended attributes for department assignment

### Form Builder
- `forms`: Form definitions with visual schema
- `form_responses`: Form submissions and data

### Workflow Designer
- `workflows`: Workflow definitions with visual schema
- `workflow_executions`: Instances of workflow runs
- `workflow_execution_steps`: Steps in a workflow execution
- `workflow_templates`: Reusable workflow templates

## Security

The database implements Row Level Security (RLS) to ensure data isolation between organizations. Each table has policies that restrict access based on organization membership and user roles.

## Migrations

Database migrations are stored in the `supabase/migrations` directory and are named with a timestamp prefix to ensure they are applied in the correct order.

To apply migrations to your local Supabase instance:

```bash
supabase db reset
```

To apply migrations to a remote Supabase instance:

```bash
supabase db push
```

## TypeScript Types

The `typescript` directory contains TypeScript type definitions that match the database schema. These types provide type safety when working with database records in your application code.

## Contributing

When contributing to this repository, please ensure that:

1. Migrations are idempotent (safe to run multiple times)
2. Row Level Security policies are properly defined for new tables
3. TypeScript type definitions are updated to match database schema changes
4. Migrations are named with a timestamp prefix in the format: `YYYYMMDDhhmmss_description.sql`

## Department Management Implementation

The current branch includes the implementation of department management features:

- Organization relationship tables for creating hierarchical structures
- Department tables for organizing users
- Extended profile fields for department assignment
- Helper functions for department hierarchy traversal
- TypeScript type definitions for the new schema

These changes provide a comprehensive way to organize users within organizations with:
- Hierarchical department structures
- Manager assignment
- Reporting relationships
- Role-based permissions

## License

[MIT License](LICENSE)