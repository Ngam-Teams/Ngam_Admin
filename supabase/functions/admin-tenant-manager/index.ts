// =============================================================================
// Edge Function: admin-tenant-manager
// Purpose:  Handles all high-privilege tenant operations on behalf of the
//           Ngam Console Super Admin portal.
//           The service_role key never leaves this serverless environment.
// Deploy:   supabase functions deploy admin-tenant-manager
// =============================================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS pre-flight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // -------------------------------------------------------------------------
    // 1. Build a caller-scoped client (respects RLS, honours the user's JWT)
    // -------------------------------------------------------------------------
    const authHeader = req.headers.get('Authorization')!
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    // -------------------------------------------------------------------------
    // 2. Verify the caller's JWT has the super_admin role
    // -------------------------------------------------------------------------
    const { data: { user }, error: userError } = await supabase.auth.getUser()
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Invalid or missing authentication token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const { data: roleData, error: roleError } = await supabase
      .from('user_roles')
      .select('role')
      .eq('user_id', user.id)
      .single()

    if (roleError || roleData?.role !== 'super_admin') {
      return new Response(
        JSON.stringify({ error: 'Unauthorized Access – super_admin role required' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // -------------------------------------------------------------------------
    // 3. Execute privileged action using the service_role key (bypasses RLS)
    // -------------------------------------------------------------------------
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { action, businessId, tier } = await req.json()

    // --- Action: suspend_business -----------------------------------------------
    if (action === 'suspend_business') {
      const { error } = await supabaseAdmin
        .from('businesses')
        .update({ status: 'suspended' })
        .eq('id', businessId)

      if (error) throw error

      return new Response(
        JSON.stringify({ success: true, message: `Business ${businessId} suspended` }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // --- Action: upgrade_business -----------------------------------------------
    if (action === 'upgrade_business') {
      const { error } = await supabaseAdmin
        .from('businesses')
        .update({ business_subscription_tier: tier })
        .eq('id', businessId)

      if (error) throw error

      return new Response(
        JSON.stringify({ success: true, message: `Business ${businessId} upgraded to ${tier}` }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // --- Action: get_business_session -------------------------------------------
    // Returns the business row so the Flutter app can locally inherit the business session
    if (action === 'get_business_session') {
      const { data, error } = await supabaseAdmin
        .from('businesses')
        .select('*')
        .eq('id', businessId)
        .single()

      if (error) throw error

      return new Response(
        JSON.stringify({ success: true, business: data }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({ error: 'Invalid action' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (err) {
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
