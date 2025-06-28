/*
  # Create score_details table

  1. New Tables
    - `score_details`
      - `id` (uuid, primary key)
      - `conversation_id` (text, foreign key to interview_sessions)
      - `clarity_score` (integer, score for clarity 0-100)
      - `clarity_reason` (text, explanation for clarity score)
      - `grammar_score` (integer, score for grammar 0-100)
      - `grammar_reason` (text, explanation for grammar score)
      - `substance_score` (integer, score for substance 0-100)
      - `substance_reason` (text, explanation for substance score)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on `score_details` table
    - Add policy for users to read their own session scores
    - Add policies for service role to insert/update scores

  3. Relationships
    - Foreign key to interview_sessions via conversation_id

  4. Indexes
    - conversation_id for fast lookups
    - created_at for sorting
    - score columns for analytics
*/

-- Create score_details table
CREATE TABLE IF NOT EXISTS score_details (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id text UNIQUE NOT NULL,
  clarity_score integer,
  clarity_reason text,
  grammar_score integer,
  grammar_reason text,
  substance_score integer,
  substance_reason text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE score_details ENABLE ROW LEVEL SECURITY;

-- Add constraints with existence checks
DO $$
BEGIN
  -- Add clarity_score constraint (0-100)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'score_details_clarity_score_check' 
    AND table_name = 'score_details'
  ) THEN
    ALTER TABLE score_details ADD CONSTRAINT score_details_clarity_score_check 
    CHECK (clarity_score >= 0 AND clarity_score <= 100);
  END IF;

  -- Add grammar_score constraint (0-100)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'score_details_grammar_score_check' 
    AND table_name = 'score_details'
  ) THEN
    ALTER TABLE score_details ADD CONSTRAINT score_details_grammar_score_check 
    CHECK (grammar_score >= 0 AND grammar_score <= 100);
  END IF;

  -- Add substance_score constraint (0-100)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'score_details_substance_score_check' 
    AND table_name = 'score_details'
  ) THEN
    ALTER TABLE score_details ADD CONSTRAINT score_details_substance_score_check 
    CHECK (substance_score >= 0 AND substance_score <= 100);
  END IF;
END $$;

-- Add indexes
CREATE INDEX IF NOT EXISTS score_details_conversation_id_idx 
ON score_details (conversation_id);

CREATE INDEX IF NOT EXISTS score_details_created_at_idx 
ON score_details (created_at DESC);

CREATE INDEX IF NOT EXISTS score_details_clarity_score_idx 
ON score_details (clarity_score DESC);

CREATE INDEX IF NOT EXISTS score_details_grammar_score_idx 
ON score_details (grammar_score DESC);

CREATE INDEX IF NOT EXISTS score_details_substance_score_idx 
ON score_details (substance_score DESC);

-- Add foreign key relationship with interview_sessions
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'score_details_conversation_id_fkey' 
    AND table_name = 'score_details'
  ) THEN
    ALTER TABLE score_details ADD CONSTRAINT score_details_conversation_id_fkey 
    FOREIGN KEY (conversation_id) REFERENCES interview_sessions(conversation_id) ON DELETE CASCADE;
  END IF;
END $$;

-- Create updated_at trigger (reuse existing function)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.triggers 
    WHERE trigger_name = 'score_details_updated_at' 
    AND event_object_table = 'score_details'
  ) THEN
    CREATE TRIGGER score_details_updated_at
      BEFORE UPDATE ON score_details
      FOR EACH ROW
      EXECUTE FUNCTION handle_updated_at();
  END IF;
END $$;

-- RLS Policies

-- Users can read score details of their own interview sessions
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE policyname = 'Users can read their own session score details' 
    AND tablename = 'score_details'
  ) THEN
    CREATE POLICY "Users can read their own session score details"
      ON score_details
      FOR SELECT
      TO authenticated
      USING (
        conversation_id IN (
          SELECT conversation_id 
          FROM interview_sessions 
          WHERE user_id = auth.uid() AND conversation_id IS NOT NULL
        )
      );
  END IF;
END $$;

-- Service role can insert score details (for AI scoring system)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE policyname = 'Service role can insert score details' 
    AND tablename = 'score_details'
  ) THEN
    CREATE POLICY "Service role can insert score details"
      ON score_details
      FOR INSERT
      TO service_role
      WITH CHECK (true);
  END IF;
END $$;

-- Service role can update score details (for AI scoring system)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE policyname = 'Service role can update score details' 
    AND tablename = 'score_details'
  ) THEN
    CREATE POLICY "Service role can update score details"
      ON score_details
      FOR UPDATE
      TO service_role
      USING (true);
  END IF;
END $$;

-- Add comments for documentation
COMMENT ON TABLE score_details IS 'Stores detailed scoring breakdown for interview sessions';
COMMENT ON COLUMN score_details.conversation_id IS 'Tavus conversation ID linking to interview_sessions';
COMMENT ON COLUMN score_details.clarity_score IS 'Score for clarity of communication (0-100)';
COMMENT ON COLUMN score_details.clarity_reason IS 'Explanation for the clarity score';
COMMENT ON COLUMN score_details.grammar_score IS 'Score for grammar and language usage (0-100)';
COMMENT ON COLUMN score_details.grammar_reason IS 'Explanation for the grammar score';
COMMENT ON COLUMN score_details.substance_score IS 'Score for content substance and depth (0-100)';
COMMENT ON COLUMN score_details.substance_reason IS 'Explanation for the substance score';