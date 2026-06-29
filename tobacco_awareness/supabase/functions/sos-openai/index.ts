import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Get the auth token from the request headers to verify the user
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing Authorization header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 2. Initialize Supabase client to verify user
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    const supabase = createClient(supabaseUrl, supabaseKey, {
      global: { headers: { Authorization: authHeader } },
    })

    const { data: { user }, error: userError } = await supabase.auth.getUser()
    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized user' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 3. Get request payload
    const { trigger_reason } = await req.json()
    if (!trigger_reason) {
      return new Response(JSON.stringify({ error: 'trigger_reason is required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 4. Call OpenAI API
    const openAiKey = Deno.env.get('OPENAI_API_KEY')
    if (!openAiKey) {
      throw new Error('OPENAI_API_KEY not configured')
    }

    const openAiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openAiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-3.5-turbo', // or gpt-4
        messages: [
          {
            role: 'system',
            content: 'You are an empathetic, concise AI assistant helping a high school student overcome a sudden tobacco craving. Provide a brief, actionable coping strategy instantly. Do not lecture, just give immediate practical advice.'
          },
          {
            role: 'user',
            content: `I am having a strong craving for tobacco right now because: ${trigger_reason}. What should I do right now?`
          }
        ],
        max_tokens: 150,
      }),
    })

    if (!openAiResponse.ok) {
      const errorData = await openAiResponse.json()
      throw new Error(`OpenAI API Error: ${errorData.error?.message || 'Unknown error'}`)
    }

    const aiData = await openAiResponse.json()
    const ai_response = aiData.choices[0].message.content.trim()

    // 5. Log the SOS interaction in the database (Row Level Security allows user to insert own logs)
    const { error: dbError } = await supabase
      .from('sos_logs')
      .insert({
        user_id: user.id,
        trigger_reason: trigger_reason,
        ai_response: ai_response
      })

    if (dbError) {
      console.error('Error logging SOS to DB:', dbError)
      // We don't fail the request if logging fails, we still want to return the advice
    }

    // 6. Return the response to the Flutter app
    return new Response(
      JSON.stringify({ advice: ai_response }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )

  } catch (error: any) {
    console.error('Edge Function Error:', error.message)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
