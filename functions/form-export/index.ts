import { serve } from 'https://deno.land/std@0.131.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface ExportRequest {
  formId: string;
  format: 'json' | 'csv' | 'pdf';
  dateRange?: {
    start: string;
    end: string;
  };
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
  let body: ExportRequest;
  try {
    body = await req.json();
  } catch (error) {
    return new Response(
      JSON.stringify({ error: 'Invalid request body' }),
      { status: 400, headers: { 'Content-Type': 'application/json' } }
    )
  }

  const { formId, format = 'json', dateRange } = body;

  if (!formId) {
    return new Response(
      JSON.stringify({ error: 'Missing form ID' }),
      { status: 400, headers: { 'Content-Type': 'application/json' } }
    )
  }

  // Check if the form exists and the user has access to it
  const { data: form, error: formError } = await supabaseClient
    .from('forms')
    .select('*')
    .eq('id', formId)
    .single();

  if (formError || !form) {
    return new Response(
      JSON.stringify({ error: 'Form not found or no access' }),
      { status: 404, headers: { 'Content-Type': 'application/json' } }
    )
  }

  // Build a query for form responses
  let query = supabaseClient
    .from('form_responses')
    .select('*')
    .eq('form_id', formId);

  // Add date range filter if provided
  if (dateRange) {
    query = query
      .gte('created_at', dateRange.start)
      .lte('created_at', dateRange.end);
  }

  // Execute the query
  const { data: responses, error: responsesError } = await query;

  if (responsesError) {
    return new Response(
      JSON.stringify({ error: 'Failed to fetch form responses', details: responsesError }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }

  // Process the responses based on the requested format
  if (format === 'json') {
    return new Response(
      JSON.stringify({ success: true, data: responses }),
      { 
        status: 200, 
        headers: { 
          'Content-Type': 'application/json',
          'Content-Disposition': `attachment; filename="form-${formId}-export.json"`
        } 
      }
    )
  } else if (format === 'csv') {
    // Simple CSV conversion for demonstration
    // In a real application, you'd want to use a proper CSV library
    if (!responses || responses.length === 0) {
      return new Response(
        'No data to export',
        { 
          status: 200, 
          headers: { 
            'Content-Type': 'text/csv',
            'Content-Disposition': `attachment; filename="form-${formId}-export.csv"`
          } 
        }
      )
    }

    // Get headers from the first response's data object
    const firstResponse = responses[0];
    const dataFields = Object.keys(firstResponse.data);
    const headers = ['id', 'created_at', 'submitted_by', ...dataFields];
    
    // Create CSV content
    let csvContent = headers.join(',') + '\n';
    
    for (const response of responses) {
      const values = [
        response.id,
        response.created_at,
        response.submitted_by,
        ...dataFields.map(field => {
          const value = response.data[field];
          // Handle different value types appropriately for CSV
          if (value === null || value === undefined) return '';
          if (typeof value === 'string') return `"${value.replace(/"/g, '""')}"`;
          return value;
        })
      ];
      csvContent += values.join(',') + '\n';
    }

    return new Response(
      csvContent,
      { 
        status: 200, 
        headers: { 
          'Content-Type': 'text/csv',
          'Content-Disposition': `attachment; filename="form-${formId}-export.csv"`
        } 
      }
    )
  } else {
    // PDF would be implemented with a PDF generation library
    return new Response(
      JSON.stringify({ error: 'PDF export not implemented in this example' }),
      { status: 501, headers: { 'Content-Type': 'application/json' } }
    )
  }
})