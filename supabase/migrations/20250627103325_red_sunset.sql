/*
  # Add conversation_id column to interview_sessions table

  1. Changes
    - Add `conversation_id` column to `interview_sessions` table
    - Column is optional (nullable) to support existing records
    - Add index for better query performance

  2. Security
    - No changes to existing RLS policies needed
    - Column inherits existing security model
*/

-- Add conversation_id column to interview_sessions table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'interview_sessions' AND column_name = 'conversation_id'
  ) THEN
    ALTER TABLE interview_sessions ADD COLUMN conversation_id text;
  END IF;
END $$;

-- Add index for conversation_id for better query performance
CREATE INDEX IF NOT EXISTS interview_sessions_conversation_id_idx 
ON interview_sessions (conversation_id);

-- Add comment to document the column
COMMENT ON COLUMN interview_sessions.conversation_id IS 'Tavus conversation ID for tracking the AI interview session';