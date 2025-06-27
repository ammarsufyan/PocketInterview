/*
  # Create interview transcripts table

  1. New Tables
    - `interview_transcripts`
      - `id` (uuid, primary key)
      - `conversation_id` (text, unique, foreign key to interview_sessions)
      - `transcript_data` (jsonb, stores full conversation)
      - `message_count` (integer, total messages)
      - `user_message_count` (integer, user messages)
      - `assistant_message_count` (integer, AI messages)
      - `webhook_timestamp` (timestamptz, from Tavus webhook)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on `interview_transcripts` table
    - Add policy for users to read transcripts from their own sessions
    - Add policies for service role to insert/update transcripts (webhook)

  3. Changes to existing tables
    - Add unique constraint to `interview_sessions.conversation_id`
    - Add foreign key relationship between tables
*/

-- First, add unique constraint to interview_sessions.conversation_id if it doesn't exist
DO $$
BEGIN
  -- Check if unique constraint already exists
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'interview_sessions_conversation_id_unique'
  ) THEN
    -- Add unique constraint to conversation_id
    ALTER TABLE interview_sessions 
    ADD CONSTRAINT interview_sessions_conversation_id_unique 
    UNIQUE (conversation_id);
  END IF;
END $$;

-- Create interview_transcripts table
CREATE TABLE IF NOT EXISTS interview_transcripts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id text UNIQUE NOT NULL,
  transcript_data jsonb NOT NULL,
  message_count integer NOT NULL DEFAULT 0,
  user_message_count integer NOT NULL DEFAULT 0,
  assistant_message_count integer NOT NULL DEFAULT 0,
  webhook_timestamp timestamptz NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE interview_transcripts ENABLE ROW LEVEL SECURITY;

-- Add constraints
ALTER TABLE interview_transcripts ADD CONSTRAINT interview_transcripts_message_count_check 
CHECK (message_count >= 0);

ALTER TABLE interview_transcripts ADD CONSTRAINT interview_transcripts_user_message_count_check 
CHECK (user_message_count >= 0);

ALTER TABLE interview_transcripts ADD CONSTRAINT interview_transcripts_assistant_message_count_check 
CHECK (assistant_message_count >= 0);

-- Add indexes
CREATE INDEX IF NOT EXISTS interview_transcripts_conversation_id_idx 
ON interview_transcripts (conversation_id);

CREATE INDEX IF NOT EXISTS interview_transcripts_created_at_idx 
ON interview_transcripts (created_at DESC);

CREATE INDEX IF NOT EXISTS interview_transcripts_message_count_idx 
ON interview_transcripts (message_count DESC);

CREATE INDEX IF NOT EXISTS interview_transcripts_webhook_timestamp_idx 
ON interview_transcripts (webhook_timestamp DESC);

-- Add GIN index for transcript_data JSONB searching
CREATE INDEX IF NOT EXISTS interview_transcripts_transcript_data_gin_idx 
ON interview_transcripts USING GIN (transcript_data);

-- Add foreign key relationship with interview_sessions
-- This will now work because we added the unique constraint above
ALTER TABLE interview_transcripts ADD CONSTRAINT interview_transcripts_conversation_id_fkey 
FOREIGN KEY (conversation_id) REFERENCES interview_sessions(conversation_id) ON DELETE CASCADE;

-- Create updated_at trigger function if it doesn't exist
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
DROP TRIGGER IF EXISTS interview_transcripts_updated_at ON interview_transcripts;
CREATE TRIGGER interview_transcripts_updated_at
  BEFORE UPDATE ON interview_transcripts
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at();

-- RLS Policies

-- Users can read transcripts of their own interview sessions
CREATE POLICY "Users can read their own session transcripts"
  ON interview_transcripts
  FOR SELECT
  TO authenticated
  USING (
    conversation_id IN (
      SELECT conversation_id 
      FROM interview_sessions 
      WHERE user_id = auth.uid() AND conversation_id IS NOT NULL
    )
  );

-- Service role can insert transcripts (for webhook)
CREATE POLICY "Service role can insert transcripts"
  ON interview_transcripts
  FOR INSERT
  TO service_role
  WITH CHECK (true);

-- Service role can update transcripts (for webhook)
CREATE POLICY "Service role can update transcripts"
  ON interview_transcripts
  FOR UPDATE
  TO service_role
  USING (true);

-- Add comments for documentation
COMMENT ON TABLE interview_transcripts IS 'Stores interview transcripts received from Tavus webhooks';
COMMENT ON COLUMN interview_transcripts.conversation_id IS 'Tavus conversation ID linking to interview_sessions';
COMMENT ON COLUMN interview_transcripts.transcript_data IS 'Full transcript array from Tavus webhook';
COMMENT ON COLUMN interview_transcripts.message_count IS 'Total number of messages in the transcript';
COMMENT ON COLUMN interview_transcripts.user_message_count IS 'Number of user messages in the transcript';
COMMENT ON COLUMN interview_transcripts.assistant_message_count IS 'Number of assistant messages in the transcript';
COMMENT ON COLUMN interview_transcripts.webhook_timestamp IS 'Timestamp from the Tavus webhook payload';