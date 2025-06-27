/*
  # Update interview_sessions table schema

  1. Schema Changes
    - Rename `duration_minutes` to `expected_duration_minutes`
    - Add `actual_duration_minutes` column
    - Add `completed_timestamp` column
    - Add `session_status` column
    - Add `end_reason` column
    - Remove `session_data` column

  2. Data Migration
    - Extract data from existing `session_data` JSON column
    - Populate new columns with extracted data
    - Handle existing records gracefully

  3. Indexes
    - Add indexes for new columns for better query performance
*/

-- Step 1: Add new columns
DO $$
BEGIN
  -- Add actual_duration_minutes column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'interview_sessions' AND column_name = 'actual_duration_minutes'
  ) THEN
    ALTER TABLE interview_sessions ADD COLUMN actual_duration_minutes integer;
  END IF;

  -- Add completed_timestamp column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'interview_sessions' AND column_name = 'completed_timestamp'
  ) THEN
    ALTER TABLE interview_sessions ADD COLUMN completed_timestamp timestamptz;
  END IF;

  -- Add session_status column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'interview_sessions' AND column_name = 'session_status'
  ) THEN
    ALTER TABLE interview_sessions ADD COLUMN session_status text DEFAULT 'created';
  END IF;

  -- Add end_reason column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'interview_sessions' AND column_name = 'end_reason'
  ) THEN
    ALTER TABLE interview_sessions ADD COLUMN end_reason text;
  END IF;
END $$;

-- Step 2: Migrate existing data from session_data JSON column
UPDATE interview_sessions 
SET 
  actual_duration_minutes = CASE 
    WHEN session_data ? 'actual_duration_minutes' THEN 
      (session_data->>'actual_duration_minutes')::integer
    ELSE duration_minutes
  END,
  completed_timestamp = CASE 
    WHEN session_data ? 'completed_timestamp' THEN 
      to_timestamp((session_data->>'completed_timestamp')::double precision)
    ELSE updated_at
  END,
  session_status = CASE 
    WHEN session_data ? 'session_status' THEN 
      session_data->>'session_status'
    ELSE 'completed'
  END,
  end_reason = CASE 
    WHEN session_data ? 'end_reason' THEN 
      session_data->>'end_reason'
    ELSE 'unknown'
  END
WHERE session_data IS NOT NULL;

-- Step 3: Rename duration_minutes to expected_duration_minutes
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'interview_sessions' AND column_name = 'duration_minutes'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'interview_sessions' AND column_name = 'expected_duration_minutes'
  ) THEN
    ALTER TABLE interview_sessions RENAME COLUMN duration_minutes TO expected_duration_minutes;
  END IF;
END $$;

-- Step 4: Update constraints for renamed column
DO $$
BEGIN
  -- Drop old constraint if it exists
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE table_name = 'interview_sessions' 
    AND constraint_name = 'interview_sessions_duration_minutes_check'
  ) THEN
    ALTER TABLE interview_sessions DROP CONSTRAINT interview_sessions_duration_minutes_check;
  END IF;

  -- Add new constraint for expected_duration_minutes
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE table_name = 'interview_sessions' 
    AND constraint_name = 'interview_sessions_expected_duration_minutes_check'
  ) THEN
    ALTER TABLE interview_sessions ADD CONSTRAINT interview_sessions_expected_duration_minutes_check 
    CHECK (expected_duration_minutes > 0);
  END IF;

  -- Add constraint for actual_duration_minutes
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE table_name = 'interview_sessions' 
    AND constraint_name = 'interview_sessions_actual_duration_minutes_check'
  ) THEN
    ALTER TABLE interview_sessions ADD CONSTRAINT interview_sessions_actual_duration_minutes_check 
    CHECK (actual_duration_minutes >= 0);
  END IF;

  -- Add constraint for session_status
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE table_name = 'interview_sessions' 
    AND constraint_name = 'interview_sessions_session_status_check'
  ) THEN
    ALTER TABLE interview_sessions ADD CONSTRAINT interview_sessions_session_status_check 
    CHECK (session_status IN ('created', 'active', 'completed', 'cancelled', 'error'));
  END IF;
END $$;

-- Step 5: Add indexes for new columns
CREATE INDEX IF NOT EXISTS interview_sessions_actual_duration_minutes_idx 
ON interview_sessions (actual_duration_minutes);

CREATE INDEX IF NOT EXISTS interview_sessions_completed_timestamp_idx 
ON interview_sessions (completed_timestamp DESC);

CREATE INDEX IF NOT EXISTS interview_sessions_session_status_idx 
ON interview_sessions (session_status);

CREATE INDEX IF NOT EXISTS interview_sessions_end_reason_idx 
ON interview_sessions (end_reason);

-- Step 6: Remove session_data column (after data migration)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'interview_sessions' AND column_name = 'session_data'
  ) THEN
    ALTER TABLE interview_sessions DROP COLUMN session_data;
  END IF;
END $$;

-- Step 7: Add comments for documentation
COMMENT ON COLUMN interview_sessions.expected_duration_minutes IS 'Planned duration of the interview session in minutes';
COMMENT ON COLUMN interview_sessions.actual_duration_minutes IS 'Actual duration of the interview session in minutes';
COMMENT ON COLUMN interview_sessions.completed_timestamp IS 'Timestamp when the interview session was completed';
COMMENT ON COLUMN interview_sessions.session_status IS 'Current status of the interview session (created, active, completed, cancelled, error)';
COMMENT ON COLUMN interview_sessions.end_reason IS 'Reason why the interview session ended (manual, timeout, error, etc.)';