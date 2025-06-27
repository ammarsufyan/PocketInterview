import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
}

interface TavusWebhookPayload {
  properties: {
    transcript: Array<{
      role: "user" | "assistant"
      content: string
    }>
  }
  conversation_id: string
  webhook_url: string
  message_type: string
  event_type: string
  timestamp: string
}

interface TranscriptInsert {
  conversation_id: string
  transcript_data: any
  message_count: number
  user_message_count: number
  assistant_message_count: number
  webhook_timestamp: string
}

serve(async (req: Request) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    })
  }

  try {
    // Validate request method
    if (req.method !== "POST") {
      return new Response(
        JSON.stringify({ error: "Method not allowed" }),
        {
          status: 405,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      )
    }

    // Parse webhook payload
    const payload: TavusWebhookPayload = await req.json()
    
    console.log("📨 Received Tavus webhook:", {
      conversation_id: payload.conversation_id,
      event_type: payload.event_type,
      message_type: payload.message_type,
      transcript_length: payload.properties?.transcript?.length || 0
    })

    // Validate required fields
    if (!payload.conversation_id) {
      return new Response(
        JSON.stringify({ error: "Missing conversation_id" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      )
    }

    if (!payload.properties?.transcript || !Array.isArray(payload.properties.transcript)) {
      return new Response(
        JSON.stringify({ error: "Missing or invalid transcript data" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      )
    }

    // Validate event type
    if (payload.event_type !== "application.transcription_ready") {
      console.log(`⚠️ Ignoring webhook with event_type: ${payload.event_type}`)
      return new Response(
        JSON.stringify({ message: "Event type not handled", event_type: payload.event_type }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      )
    }

    // Initialize Supabase client with service role key
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Process transcript data
    const transcript = payload.properties.transcript
    const messageCount = transcript.length
    const userMessageCount = transcript.filter(msg => msg.role === "user").length
    const assistantMessageCount = transcript.filter(msg => msg.role === "assistant").length

    console.log("📊 Transcript analysis:", {
      total_messages: messageCount,
      user_messages: userMessageCount,
      assistant_messages: assistantMessageCount
    })

    // Prepare transcript data for insertion
    const transcriptInsert: TranscriptInsert = {
      conversation_id: payload.conversation_id,
      transcript_data: transcript,
      message_count: messageCount,
      user_message_count: userMessageCount,
      assistant_message_count: assistantMessageCount,
      webhook_timestamp: payload.timestamp
    }

    // Insert or update transcript in database
    const { data, error } = await supabase
      .from('interview_transcripts')
      .upsert(transcriptInsert, {
        onConflict: 'conversation_id',
        ignoreDuplicates: false
      })
      .select()

    if (error) {
      console.error("❌ Database error:", error)
      return new Response(
        JSON.stringify({ 
          error: "Database error", 
          details: error.message 
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      )
    }

    console.log("✅ Transcript saved successfully:", {
      conversation_id: payload.conversation_id,
      record_id: data?.[0]?.id
    })

    // Optionally update the interview session with transcript availability
    const { error: sessionUpdateError } = await supabase
      .from('interview_sessions')
      .update({ 
        questions_answered: userMessageCount,
        updated_at: new Date().toISOString()
      })
      .eq('conversation_id', payload.conversation_id)

    if (sessionUpdateError) {
      console.warn("⚠️ Failed to update session with transcript data:", sessionUpdateError)
      // Don't fail the webhook for this - transcript is still saved
    } else {
      console.log("✅ Updated session with transcript data")
    }

    // Return success response
    return new Response(
      JSON.stringify({ 
        success: true,
        message: "Transcript processed successfully",
        conversation_id: payload.conversation_id,
        message_count: messageCount,
        user_messages: userMessageCount,
        assistant_messages: assistantMessageCount
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    )

  } catch (error) {
    console.error("💥 Webhook processing error:", error)
    
    return new Response(
      JSON.stringify({ 
        error: "Internal server error",
        message: error.message 
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    )
  }
})