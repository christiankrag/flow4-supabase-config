-- Create forms table
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

-- Create form_versions table
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

-- Create form_responses table
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

-- Create RLS policies for forms
ALTER TABLE public.forms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view forms in their organization" 
  ON public.forms FOR SELECT 
  USING (
    organization_id IN (
      SELECT organization_id FROM public.organization_members 
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create forms in their organization" 
  ON public.forms FOR INSERT 
  WITH CHECK (
    organization_id IN (
      SELECT organization_id FROM public.organization_members 
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update forms in their organization" 
  ON public.forms FOR UPDATE 
  USING (
    organization_id IN (
      SELECT organization_id FROM public.organization_members 
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete forms in their organization" 
  ON public.forms FOR DELETE 
  USING (
    organization_id IN (
      SELECT organization_id FROM public.organization_members 
      WHERE user_id = auth.uid()
    )
  );

-- Create RLS policies for form_versions
ALTER TABLE public.form_versions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view form versions in their organization" 
  ON public.form_versions FOR SELECT 
  USING (
    organization_id IN (
      SELECT organization_id FROM public.organization_members 
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create form versions in their organization" 
  ON public.form_versions FOR INSERT 
  WITH CHECK (
    organization_id IN (
      SELECT organization_id FROM public.organization_members 
      WHERE user_id = auth.uid()
    )
  );

-- Create RLS policies for form_responses
ALTER TABLE public.form_responses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view form responses in their organization" 
  ON public.form_responses FOR SELECT 
  USING (
    organization_id IN (
      SELECT organization_id FROM public.organization_members 
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create form responses in their organization" 
  ON public.form_responses FOR INSERT 
  WITH CHECK (
    organization_id IN (
      SELECT organization_id FROM public.organization_members 
      WHERE user_id = auth.uid()
    )
  );

-- Create functions for real-time updates
CREATE OR REPLACE FUNCTION public.handle_form_update()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_form_update
  BEFORE UPDATE ON public.forms
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_form_update();

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_forms_organization_id ON public.forms(organization_id);
CREATE INDEX IF NOT EXISTS idx_form_versions_form_id ON public.form_versions(form_id);
CREATE INDEX IF NOT EXISTS idx_form_responses_form_id ON public.form_responses(form_id);

-- Add realtime publication for forms
ALTER PUBLICATION supabase_realtime ADD TABLE public.forms;