-- Create function to log form response submissions
CREATE OR REPLACE FUNCTION public.handle_form_response_submitted()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert activity record
  INSERT INTO public.activities (
    action,
    resource_type,
    resource_id,
    user_id,
    organization_id,
    details
  ) VALUES (
    'form_response_submitted',
    'form',
    NEW.form_id,
    NEW.submitted_by,
    NEW.organization_id,
    jsonb_build_object(
      'form_response_id', NEW.id,
      'form_version', NEW.form_version
    )
  );
  
  -- Update form submission statistics (assuming there's a form_stats table)
  -- This would be implemented in a real application
  -- Example:
  -- UPDATE public.form_stats
  -- SET total_submissions = total_submissions + 1,
  --     last_submission_at = NOW()
  -- WHERE form_id = NEW.form_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for form response submissions
CREATE TRIGGER on_form_response_submitted
  AFTER INSERT ON public.form_responses
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_form_response_submitted();

-- Create function to notify form owners of new submissions
CREATE OR REPLACE FUNCTION public.notify_form_owner_of_submission()
RETURNS TRIGGER AS $$
DECLARE
  form_record RECORD;
BEGIN
  -- Get the form details
  SELECT created_by, name INTO form_record
  FROM public.forms
  WHERE id = NEW.form_id;
  
  -- Insert notification for form owner
  IF form_record.created_by IS NOT NULL THEN
    INSERT INTO public.notifications (
      title,
      message,
      user_id,
      organization_id,
      read
    ) VALUES (
      'New Form Submission',
      'You have received a new submission for form: ' || form_record.name,
      form_record.created_by,
      NEW.organization_id,
      false
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for form submission notifications
CREATE TRIGGER on_form_response_notification
  AFTER INSERT ON public.form_responses
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_form_owner_of_submission();

-- Create function to track form version changes
CREATE OR REPLACE FUNCTION public.handle_form_version_created()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert activity record
  INSERT INTO public.activities (
    action,
    resource_type,
    resource_id,
    user_id,
    organization_id,
    details
  ) VALUES (
    'form_version_created',
    'form',
    NEW.form_id,
    NEW.created_by,
    NEW.organization_id,
    jsonb_build_object(
      'form_version_id', NEW.id,
      'version_number', NEW.version_number,
      'status', NEW.status
    )
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for form version creation
CREATE TRIGGER on_form_version_created
  AFTER INSERT ON public.form_versions
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_form_version_created();