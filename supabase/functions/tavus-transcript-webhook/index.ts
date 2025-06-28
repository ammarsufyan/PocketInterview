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
      role: "user" | "assistant" | "system"
      content: string
    }>
  }
  conversation_id: string
  webhook_url: string
  message_type: string
  event_type: string
  timestamp: string
}

interface TranscriptMessage {
  role: "user" | "assistant"
  content: string
}

interface TranscriptInsert {
  conversation_id: string
  transcript_data: TranscriptMessage[]
  message_count: number
  user_message_count: number
  assistant_message_count: number
  webhook_timestamp: string
}

interface LLMScoringResponse {
  clarity_score: number
  clarity_reason: string
  grammar_score: number
  grammar_reason: string
  substance_score: number
  substance_reason: string
}

interface ScoreDetailsInsert {
  conversation_id: string
  clarity_score: number
  clarity_reason: string
  grammar_score: number
  grammar_reason: string
  substance_score: number
  substance_reason: string
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

    // Filter out system messages and process transcript data
    const rawTranscript = payload.properties.transcript
    const filteredTranscript: TranscriptMessage[] = rawTranscript
      .filter(msg => msg.role !== "system") // Exclude system messages
      .map(msg => ({
        role: msg.role as "user" | "assistant",
        content: msg.content.trim()
      }))
      .filter(msg => msg.content.length > 0) // Remove empty messages

    const messageCount = filteredTranscript.length
    const userMessageCount = filteredTranscript.filter(msg => msg.role === "user").length
    const assistantMessageCount = filteredTranscript.filter(msg => msg.role === "assistant").length

    console.log("📊 Transcript analysis:", {
      raw_messages: rawTranscript.length,
      filtered_messages: messageCount,
      system_messages_excluded: rawTranscript.length - messageCount,
      user_messages: userMessageCount,
      assistant_messages: assistantMessageCount
    })

    // Skip if no meaningful content after filtering
    if (messageCount === 0) {
      console.log("⚠️ No meaningful transcript content after filtering system messages")
      return new Response(
        JSON.stringify({ 
          message: "No meaningful transcript content",
          conversation_id: payload.conversation_id 
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      )
    }

    // Prepare transcript data for insertion
    const transcriptInsert: TranscriptInsert = {
      conversation_id: payload.conversation_id,
      transcript_data: filteredTranscript,
      message_count: messageCount,
      user_message_count: userMessageCount,
      assistant_message_count: assistantMessageCount,
      webhook_timestamp: payload.timestamp
    }

    // Insert or update transcript in database
    const { data: transcriptData, error: transcriptError } = await supabase
      .from('interview_transcripts')
      .upsert(transcriptInsert, {
        onConflict: 'conversation_id',
        ignoreDuplicates: false
      })
      .select()

    if (transcriptError) {
      console.error("❌ Database error:", transcriptError)
      return new Response(
        JSON.stringify({ 
          error: "Database error", 
          details: transcriptError.message 
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      )
    }

    console.log("✅ Transcript saved successfully:", {
      conversation_id: payload.conversation_id,
      record_id: transcriptData?.[0]?.id,
      filtered_messages: messageCount
    })

    // 🔥 NEW: Generate AI scoring using OpenRouter LLM
    let scoringResult: LLMScoringResponse | null = null
    let overallScore: number | null = null
    
    try {
      console.log("🤖 Starting AI scoring with OpenRouter...")
      scoringResult = await generateAIScoring(filteredTranscript)
      
      if (scoringResult) {
        console.log("✅ AI scoring completed:", {
          clarity: scoringResult.clarity_score,
          grammar: scoringResult.grammar_score,
          substance: scoringResult.substance_score
        })

        // 🔥 UPDATED: Calculate weighted overall score using your formula
        // Formula: 0.5 * substance + 0.3 * clarity + 0.2 * grammar
        overallScore = Math.round(
          (0.5 * scoringResult.substance_score) + 
          (0.3 * scoringResult.clarity_score) + 
          (0.2 * scoringResult.grammar_score)
        )

        console.log("📊 Weighted score calculation:", {
          substance_weighted: 0.5 * scoringResult.substance_score,
          clarity_weighted: 0.3 * scoringResult.clarity_score,
          grammar_weighted: 0.2 * scoringResult.grammar_score,
          overall_score: overallScore
        })

        // Insert score details into database
        const scoreDetailsInsert: ScoreDetailsInsert = {
          conversation_id: payload.conversation_id,
          clarity_score: scoringResult.clarity_score,
          clarity_reason: scoringResult.clarity_reason,
          grammar_score: scoringResult.grammar_score,
          grammar_reason: scoringResult.grammar_reason,
          substance_score: scoringResult.substance_score,
          substance_reason: scoringResult.substance_reason
        }

        const { data: scoreData, error: scoreError } = await supabase
          .from('score_details')
          .upsert(scoreDetailsInsert, {
            onConflict: 'conversation_id',
            ignoreDuplicates: false
          })
          .select()

        if (scoreError) {
          console.error("❌ Score details database error:", scoreError)
        } else {
          console.log("✅ Score details saved successfully:", {
            conversation_id: payload.conversation_id,
            score_record_id: scoreData?.[0]?.id
          })

          // 🔥 UPDATED: Update the interview session with weighted overall score
          const { error: sessionScoreError } = await supabase
            .from('interview_sessions')
            .update({ 
              score: overallScore,
              updated_at: new Date().toISOString()
            })
            .eq('conversation_id', payload.conversation_id)

          if (sessionScoreError) {
            console.warn("⚠️ Failed to update session with overall score:", sessionScoreError)
          } else {
            console.log("✅ Updated session with weighted overall score:", overallScore)
          }
        }
      }
    } catch (scoringError) {
      console.error("❌ AI scoring failed:", scoringError)
      // Continue processing even if scoring fails
    }

    // Update the interview session with transcript availability and question count
    const { error: sessionUpdateError } = await supabase
      .from('interview_sessions')
      .update({ 
        questions_answered: userMessageCount,
        updated_at: new Date().toISOString()
      })
      .eq('conversation_id', payload.conversation_id)

    if (sessionUpdateError) {
      console.warn("⚠️ Failed to update session with transcript data:", sessionUpdateError)
    } else {
      console.log("✅ Updated session with transcript data")
    }

    // Return success response
    return new Response(
      JSON.stringify({ 
        success: true,
        message: "Transcript processed successfully",
        conversation_id: payload.conversation_id,
        total_messages: messageCount,
        user_messages: userMessageCount,
        assistant_messages: assistantMessageCount,
        system_messages_excluded: rawTranscript.length - messageCount,
        ai_scoring_completed: scoringResult !== null,
        overall_score: overallScore,
        scoring_breakdown: scoringResult ? {
          substance_score: scoringResult.substance_score,
          clarity_score: scoringResult.clarity_score,
          grammar_score: scoringResult.grammar_score,
          weighted_calculation: {
            substance_contribution: Math.round(0.5 * scoringResult.substance_score * 100) / 100,
            clarity_contribution: Math.round(0.3 * scoringResult.clarity_score * 100) / 100,
            grammar_contribution: Math.round(0.2 * scoringResult.grammar_score * 100) / 100
          }
        } : null
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

// 🔥 AI Scoring Function using OpenRouter
async function generateAIScoring(transcript: TranscriptMessage[]): Promise<LLMScoringResponse | null> {
  try {
    const OPENROUTER_API_KEY = "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"
    
    // Format transcript for LLM analysis
    const transcriptText = transcript
      .map(msg => `${msg.role}: ${msg.content}`)
      .join('\n\n')

    const prompt = `${transcriptText}

Let's say you're a technical interviewer, where role user is the candidate, and role assistant is the interviewer. Based on this conversation how would you rate from 0-100 how this person answer clarity, grammar, and substance

I want the answer to be in json format

{
"clarity_score" :
"clarity_reason" :
"grammar_score" :
"grammar_reason" :
"substance_score" :
"substance_reason" :
}`

    console.log("🤖 Sending request to OpenRouter...")

    const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${OPENROUTER_API_KEY}`,
      },
      body: JSON.stringify({
        model: "deepseek/deepseek-r1-0528:free",
        messages: [
          {
            role: "user",
            content: prompt
          }
        ]
      })
    })

    if (!response.ok) {
      const errorText = await response.text()
      console.error("❌ OpenRouter API error:", response.status, errorText)
      return null
    }

    const data = await response.json()
    
    if (!data.choices || !data.choices[0] || !data.choices[0].message) {
      console.error("❌ Invalid OpenRouter response structure:", data)
      return null
    }

    const content = data.choices[0].message.content
    console.log("🤖 Raw LLM response:", content)

    // Extract JSON from the response
    const jsonMatch = content.match(/\{[\s\S]*\}/)
    if (!jsonMatch) {
      console.error("❌ No JSON found in LLM response")
      return null
    }

    const jsonString = jsonMatch[0]
    const scoringResult = JSON.parse(jsonString)

    // Validate and sanitize the scoring result
    const validatedResult: LLMScoringResponse = {
      clarity_score: Math.max(0, Math.min(100, parseInt(scoringResult.clarity_score) || 0)),
      clarity_reason: (scoringResult.clarity_reason || "No reason provided").substring(0, 500),
      grammar_score: Math.max(0, Math.min(100, parseInt(scoringResult.grammar_score) || 0)),
      grammar_reason: (scoringResult.grammar_reason || "No reason provided").substring(0, 500),
      substance_score: Math.max(0, Math.min(100, parseInt(scoringResult.substance_score) || 0)),
      substance_reason: (scoringResult.substance_reason || "No reason provided").substring(0, 500)
    }

    console.log("✅ Validated scoring result:", validatedResult)
    return validatedResult

  } catch (error) {
    console.error("❌ AI scoring error:", error)
    return null
  }
}