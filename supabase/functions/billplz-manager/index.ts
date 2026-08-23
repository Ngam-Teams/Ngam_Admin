import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const BILLPLZ_API_KEY = Deno.env.get('BILLPLZ_API_KEY') || ''
const BILLPLZ_COLLECTION_ID = Deno.env.get('BILLPLZ_COLLECTION_ID') || ''
const BILLPLZ_API_URL = 'https://www.billplz-sandbox.com/api/v3' // Use sandbox for testing

serve(async (req) => {
  const { url, method } = req
  const urlPattern = new URL(url)

  // 1. Webhook from Billplz when a payment succeeds
  if (urlPattern.pathname.endsWith('/webhook') && method === 'POST') {
    try {
      const formData = await req.formData()
      const billId = formData.get('id')
      const state = formData.get('state') // 'paid' or 'due'
      const paid = formData.get('paid') === 'true'

      if (paid && state === 'paid') {
        // Init Supabase admin client to bypass RLS
        const supabase = createClient(
          Deno.env.get('SUPABASE_URL') ?? '',
          Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

        // Find the invoice with this billId (assuming we save billId in billing_invoices.gateway_id)
        // For now, we update any invoice that matches the billId
        const { error } = await supabase
          .from('billing_invoices')
          .update({ status: 'paid' })
          .eq('gateway_id', billId)

        if (error) throw error

        return new Response(JSON.stringify({ message: 'Invoice marked as paid' }), {
          headers: { 'Content-Type': 'application/json' },
          status: 200,
        })
      }

      return new Response('Ignored', { status: 200 })
    } catch (err: any) {
      return new Response(JSON.stringify({ error: err.message }), { status: 400 })
    }
  }

  // 2. Generate a Payment Link for an invoice (Called by Frontend or Cron webhook)
  if (method === 'POST') {
    try {
      const body = await req.json()
      
      if (body.action === 'generate') {
        const { invoice_id, amount_due, business_email, business_name } = body

        // Call Billplz API to create a bill
        const response = await fetch(`${BILLPLZ_API_URL}/bills`, {
          method: 'POST',
          headers: {
            'Authorization': `Basic ${btoa(BILLPLZ_API_KEY + ':')}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            collection_id: BILLPLZ_COLLECTION_ID,
            description: `Ngam Console Platform Fee - Invoice ${invoice_id}`,
            email: business_email,
            name: business_name,
            amount: Math.round(amount_due * 100), // Billplz expects amount in cents (RM 1 = 100)
            callback_url: `${Deno.env.get('SUPABASE_URL')}/functions/v1/billplz-manager/webhook`,
            redirect_url: 'https://ngam-console.app/billing/success' // Where they go after paying
          })
        })

        if (!response.ok) {
          const err = await response.json()
          throw new Error(`Billplz Error: ${JSON.stringify(err)}`)
        }

        const billplzData = await response.json()

        // Save the billplzData.id to the invoice so the webhook can find it later
        const supabase = createClient(
          Deno.env.get('SUPABASE_URL') ?? '',
          Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )
        
        await supabase
          .from('billing_invoices')
          .update({ gateway_id: billplzData.id })
          .eq('id', invoice_id)

        return new Response(
          JSON.stringify({ payment_url: billplzData.url }),
          { headers: { 'Content-Type': 'application/json' } }
        )
      }
    } catch (err: any) {
      return new Response(JSON.stringify({ error: err.message }), { status: 400 })
    }
  }

  return new Response('Not Found', { status: 404 })
})
