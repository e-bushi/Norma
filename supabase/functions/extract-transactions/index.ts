// supabase/functions/extract-transactions/index.ts
// Main request handler for transaction extraction from screenshots

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { detectMediaType } from "./utils.ts"
import { callClaudeWithCascade } from "./claude.ts"

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

serve(async (req) => {
  // CORS headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  }

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get auth token from header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "You need to be logged in to use this feature." }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" }
        }
      )
    }

    // Extract token and verify user
    const token = authHeader.replace('Bearer ', '')
    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!)

    const { data: { user }, error: authError } = await supabase.auth.getUser(token)

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Your session has expired. Please log in again." }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" }
        }
      )
    }

    const { image_base64, device_token, apns_environment } = await req.json()

    if (!image_base64) {
      return new Response(
        JSON.stringify({ error: "I couldn't process that image. Please try taking a screenshot again." }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" }
        }
      )
    }

    // Auto-detect media type from base64 data
    const media_type = detectMediaType(image_base64)
    console.log(`Detected media type: ${media_type}`)

    // Call Claude with model cascade
    const { data: claudeData, model: usedModel } = await callClaudeWithCascade(image_base64, media_type)

    // Extract tool use result
    const toolUse = claudeData.content?.find((block: any) => block.type === "tool_use")

    if (!toolUse || !toolUse.input?.transactions) {
      return new Response(
        JSON.stringify({ error: "I couldn't find any transactions in that image. Make sure the screenshot shows transaction details like amounts and merchant names." }),
        {
          status: 422,
          headers: { ...corsHeaders, "Content-Type": "application/json" }
        }
      )
    }

    const transactions = toolUse.input.transactions

    console.log(`Extracted ${transactions.length} transactions from Claude:`, JSON.stringify(transactions, null, 2))

    // Insert into Supabase using authenticated user's ID
    const rows = transactions.map((t: any) => ({
      user_id: user.id,
      amount: t.amount,
      currency: t.currency,
      merchant: t.merchant,
      transaction_date: t.transaction_date || null,
      raw_text: JSON.stringify(t)
    }))

    console.log(`Attempting to insert ${rows.length} rows:`, JSON.stringify(rows, null, 2))

    const { data, error } = await supabase
      .from("pending_transactions")
      .insert(rows)
      .select()

    if (error) {
      console.error("Database insert error:", JSON.stringify(error, null, 2))
      return new Response(
        JSON.stringify({ error: "I found the transactions but couldn't save them. Please try again in a moment.", details: error }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" }
        }
      )
    }

    console.log(`Successfully inserted ${data.length} transactions`)

    // Fire notification request to separate edge function (don't await - fire and forget)
    if (device_token) {
      const notificationMessage = "I received your transactions. Make sure you confirm them in the app.."
      const environment = apns_environment || 'development'

      console.log(`Triggering notification function for ${environment} environment`)

      fetch(`${SUPABASE_URL}/functions/v1/send-notification`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`
        },
        body: JSON.stringify({
          device_token,
          message: notificationMessage,
          count: data.length,
          environment
        })
      }).catch(err => {
        console.error("Failed to trigger notification function:", err)
      })
    } else {
      console.warn("No device token provided, skipping push notification")
    }

    // Return immediately - don't wait for notification
    return new Response(
      JSON.stringify({
        success: true,
        message: "Got it! I'll process your transactions and notify you when they're ready."
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )

  } catch (err) {
    console.error("Unexpected error:", err)
    return new Response(
      JSON.stringify({ error: "Something went wrong while processing your transactions. Please try again.", details: err.message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      }
    )
  }
})
