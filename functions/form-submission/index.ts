import { serve } from 'https://deno.land/std@0.131.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface FormSubmissionRequest {
  formId: string;
  formVersion: number;
  data: Record<string, any>;
  metadata?: Record<string, any>;
  organizationId?: string;
}

serve(async (req) => {
  // Create a Supabase client with the Auth context of the logged in user
  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    {
      global: {
        headers: { Authorization: req.headers.get('Authorization')! },
      },
    }
  )

  // Get the user from the Auth context
  const {
    data: { user },
  } = await supabaseClient.auth.getUser()

  if (!user) {
    return new Response(
      JSON.stringify({ error: 'Unauthorized' }),
      { status: 401, headers: { 'Content-Type': 'application/json' } }
    )
  }

  // Parse the request body
  let body: FormSubmissionRequest;
  try {
    body = await req.json();
  } catch (error) {
    return new Response(
      JSON.stringify({ error: 'Invalid request body' }),
      { status: 400, headers: { 'Content-Type': 'application/json' } }
    )
  }

  const { formId, formVersion, data, metadata = {}, organizationId } = body;

  if (!formId || !formVersion || !data) {
    return new Response(
      JSON.stringify({ error: 'Missing required fields' }),
      { status: 400, headers: { 'Content-Type': 'application/json' } }
    )
  }

  // Check if the form exists
  const { data: form, error: formError } = await supabaseClient
    .from('forms')
    .select('*')
    .eq('id', formId)
    .single();

  if (formError || !form) {
    return new Response(
      JSON.stringify({ error: 'Form not found' }),
      { status: 404, headers: { 'Content-Type': 'application/json' } }
    )
  }

  // Insert the form response
  const { data: response, error: responseError } = await supabaseClient
    .from('form_responses')
    .insert({
      form_id: formId,
      form_version: formVersion,
      data,
      metadata,
      status: 'submitted',
      submitted_by: user.id,
      organization_id: organizationId || form.organization_id,
    })
    .select()
    .single();

  if (responseError) {
    return new Response(
      JSON.stringify({ error: 'Failed to save form response', details: responseError }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }

  // Send notification (this would typically be implemented as a database trigger)
  // For simplicity, we're doing it here
  try {
    await supabaseClient
      .from('notifications')
      .insert({
        title: 'New Form Submission',
        message: `A new submission has been received for form: ${form.name}`,
        user_id: form.created_by,
        organization_id: organizationId || form.organization_id,
      });
  } catch (error) {
    console.error('Failed to send notification:', error);
    // Continue even if notification fails
  }

  return new Response(
    JSON.stringify({ success: true, data: response }),
    { status: 200, headers: { 'Content-Type': 'application/json' } }
  )
})