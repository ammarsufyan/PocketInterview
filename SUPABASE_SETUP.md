# Supabase Database Setup Instructions

## Step 1: Create the interview_sessions table

Go to your Supabase dashboard → SQL Editor and run this SQL:

```sql
-- Create interview_sessions table
CREATE TABLE IF NOT EXISTS interview_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category text NOT NULL CHECK (category IN ('Technical', 'Behavioral')),
  session_name text NOT NULL,
  score integer CHECK (score >= 0 AND score <= 100),
  duration_minutes integer NOT NULL CHECK (duration_minutes > 0),
  questions_answered integer NOT NULL DEFAULT 0 CHECK (questions_answered >= 0),
  session_data jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS interview_sessions_user_id_idx ON interview_sessions(user_id);
CREATE INDEX IF NOT EXISTS interview_sessions_category_idx ON interview_sessions(category);
CREATE INDEX IF NOT EXISTS interview_sessions_created_at_idx ON interview_sessions(created_at DESC);

-- Enable Row Level Security
ALTER TABLE interview_sessions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own sessions"
  ON interview_sessions
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own sessions"
  ON interview_sessions
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own sessions"
  ON interview_sessions
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own sessions"
  ON interview_sessions
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
CREATE TRIGGER interview_sessions_updated_at
  BEFORE UPDATE ON interview_sessions
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at();
```

## Step 2: Verify the setup

After running the SQL, verify that:
1. The `interview_sessions` table exists
2. RLS is enabled
3. Policies are created
4. Indexes are in place

You can check this by running:

```sql
-- Check if table exists
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name = 'interview_sessions';

-- Check RLS status
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'interview_sessions';

-- Check policies
SELECT policyname, cmd, roles 
FROM pg_policies 
WHERE tablename = 'interview_sessions';
```

## Step 3: Test with sample data (optional)

You can insert some test data to verify everything works:

```sql
-- Insert a test session (replace with your actual user ID)
INSERT INTO interview_sessions (
  user_id,
  category,
  session_name,
  score,
  duration_minutes,
  questions_answered,
  session_data
) VALUES (
  auth.uid(), -- This will use the current authenticated user
  'Technical',
  'Test iOS Development Session',
  85,
  30,
  10,
  '{"questions": ["What is SwiftUI?", "Explain MVVM"], "answers": ["UI framework", "Architecture pattern"]}'
);
```

## Troubleshooting

If you encounter any issues:

1. **Permission errors**: Make sure you're running the SQL as a database admin
2. **RLS errors**: Ensure you're authenticated when testing
3. **Foreign key errors**: Verify that the `auth.users` table exists (it should be created automatically by Supabase Auth)

## Next Steps

Once the database is set up:
1. The iOS app will automatically connect to this table
2. Users can create interview sessions that will be stored in Supabase
3. History will be loaded from the database when users open the History tab