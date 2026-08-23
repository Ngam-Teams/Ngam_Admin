import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  // CORS Headers
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type' } })
  }

  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'Missing Authorization header' }), { status: 401, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } })
  }

  try {
    // 1. Initialize Supabase client using the user's JWT
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    // 2. Extract the user ID from the JWT to verify their role
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Invalid authentication token' }), { status: 401, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } })
    }

    // 3. Verify the caller has the 'super_admin' role in user_roles
    const { data: roleData, error: roleError } = await supabase
      .from('user_roles')
      .select('role')
      .eq('user_id', user.id)
      .single()

    if (roleError || roleData?.role !== 'super_admin') {
      return new Response(JSON.stringify({ error: 'Forbidden: Requires super_admin role' }), { status: 403, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } })
    }

    // 4. Authorized! Initialize the Service Role client to bypass RLS for destructive actions
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Parse request payload
    const { action, businessId, tier } = await req.json()
    if (!businessId) {
       return new Response(JSON.stringify({ error: 'businessId is required' }), { status: 400, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } })
    }

    // 5. Execute requested action
    switch (action) {
      case 'suspend_business': {
        const { error: suspendError } = await supabaseAdmin
          .from('businesses')
          .update({ status: 'suspended' })
          .eq('id', businessId)
        
        if (suspendError) throw suspendError
        return new Response(JSON.stringify({ success: true, message: 'Business suspended successfully' }), { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } })
      }

      case 'upgrade_business': {
        if (!tier) throw new Error('Tier is required for upgrade_business')
        const { error: upgradeError } = await supabaseAdmin
          .from('businesses')
          .update({ business_subscription_tier: tier })
          .eq('id', businessId)
        
        if (upgradeError) throw upgradeError
        return new Response(JSON.stringify({ success: true, message: `Business upgraded to ${tier}` }), { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } })
      }

      case 'get_business_session': {
        const { data: business, error: sessionError } = await supabaseAdmin
          .from('businesses')
          .select('*')
          .eq('id', businessId)
          .single()
          
        if (sessionError) throw sessionError
        return new Response(JSON.stringify({ success: true, business }), { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } })
      }

      default:
        return new Response(JSON.stringify({ error: `Invalid action: ${action}` }), { status: 400, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } })
    }

  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } })
  }
})
