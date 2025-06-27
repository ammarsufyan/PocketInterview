/*
  # Create interview transcripts table

  1. New Tables
    - `interview_transcripts`
      - `id` (uuid, primary key)
      - `conversation_id` (text, unique, foreign key reference)
      - `transcript_data` (jsonb, stores the full transcript array)
      - `message_count` (integer, number of messages in transcript)
      - `user_message_count` (integer, number of user messages)
      - `assistant_message_count` (integer, number of assistant messages)
      - `webhook_timestamp` (timestamptz, when webhook was received)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on `interview_transcripts` table
    - Add policy for users to read transcripts of their own sessions
    - Add policy for webhook to insert transcripts (service role)

  3. Indexes
    - Index on conversation_id for fast lookups
    - Index on created_at for sorting
    - Index on message_count for analytics
*/

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

-- Add foreign key relationship with interview_sessions
ALTER TABLE interview_transcripts ADD CONSTRAINT interview_transcripts_conversation_id_fkey 
FOREIGN KEY (conversation_id) REFERENCES interview_sessions(conversation_id) ON DELETE CASCADE;

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

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
      WHERE user_id = auth.uid()
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