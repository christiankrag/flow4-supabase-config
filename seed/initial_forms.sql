-- Seed data for initial forms (to be run after migrations)

-- Insert a sample form template
INSERT INTO public.forms (
  id,
  name,
  description,
  schema,
  metadata,
  version,
  status,
  created_at,
  updated_at,
  created_by,
  organization_id
)
VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  'Contact Form Template',
  'A simple contact form template with basic fields',
  '{
    "nodes": [
      {
        "id": "node-1",
        "type": "textInput",
        "position": { "x": 100, "y": 100 },
        "data": {
          "label": "Full Name",
          "description": "Enter your full name",
          "placeholder": "John Doe",
          "required": true,
          "fieldId": "full_name",
          "validation": [],
          "conditions": [],
          "settings": {}
        }
      },
      {
        "id": "node-2",
        "type": "textInput",
        "position": { "x": 100, "y": 200 },
        "data": {
          "label": "Email Address",
          "description": "Enter your email address",
          "placeholder": "john.doe@example.com",
          "required": true,
          "fieldId": "email",
          "validation": [
            { "type": "email", "message": "Please enter a valid email address" }
          ],
          "conditions": [],
          "settings": {}
        }
      },
      {
        "id": "node-3",
        "type": "textarea",
        "position": { "x": 100, "y": 300 },
        "data": {
          "label": "Message",
          "description": "Enter your message",
          "placeholder": "Type your message here...",
          "required": true,
          "fieldId": "message",
          "validation": [],
          "conditions": [],
          "settings": {}
        }
      }
    ],
    "edges": []
  }'::jsonb,
  '{
    "settings": {
      "theme": "default",
      "layout": "standard",
      "submitButtonText": "Submit",
      "showProgressBar": true,
      "enableAutosave": true
    },
    "created": "2023-01-01T00:00:00Z"
  }'::jsonb,
  1,
  'published',
  NOW(),
  NOW(),
  NULL, -- This would normally be a user ID
  NULL  -- This would normally be an organization ID
);

-- Insert an initial version for the template
INSERT INTO public.form_versions (
  id,
  form_id,
  version_number,
  name,
  description,
  schema,
  status,
  created_by,
  created_at,
  published_at,
  organization_id
)
VALUES (
  '00000000-0000-0000-0000-000000000002'::uuid,
  '00000000-0000-0000-0000-000000000001'::uuid,
  1,
  'Contact Form Template',
  'A simple contact form template with basic fields',
  '{
    "nodes": [
      {
        "id": "node-1",
        "type": "textInput",
        "position": { "x": 100, "y": 100 },
        "data": {
          "label": "Full Name",
          "description": "Enter your full name",
          "placeholder": "John Doe",
          "required": true,
          "fieldId": "full_name",
          "validation": [],
          "conditions": [],
          "settings": {}
        }
      },
      {
        "id": "node-2",
        "type": "textInput",
        "position": { "x": 100, "y": 200 },
        "data": {
          "label": "Email Address",
          "description": "Enter your email address",
          "placeholder": "john.doe@example.com",
          "required": true,
          "fieldId": "email",
          "validation": [
            { "type": "email", "message": "Please enter a valid email address" }
          ],
          "conditions": [],
          "settings": {}
        }
      },
      {
        "id": "node-3",
        "type": "textarea",
        "position": { "x": 100, "y": 300 },
        "data": {
          "label": "Message",
          "description": "Enter your message",
          "placeholder": "Type your message here...",
          "required": true,
          "fieldId": "message",
          "validation": [],
          "conditions": [],
          "settings": {}
        }
      }
    ],
    "edges": []
  }'::jsonb,
  'published',
  NULL, -- This would normally be a user ID
  NOW(),
  NOW(),
  NULL  -- This would normally be an organization ID
);