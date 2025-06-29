/*
  # Create app configuration table

  1. New Tables
    - `app_config`
      - `id` (uuid, primary key)
      - `key_name` (text, unique)
      - `key_value` (text)
      - `is_public` (boolean)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Security
    - Enable RLS on `app_config` table
    - Add policy for public configs to be readable by authenticated users
    - Add policy for service role to manage all configs

  3. Sample Data
    - Insert common public configuration values
*/

CREATE TABLE IF NOT EXISTS app_config (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key_name text UNIQUE NOT NULL,
  key_value text NOT NULL,
  is_public boolean DEFAULT false,
  description text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;

-- Policy for authenticated users to read public configs
CREATE POLICY "Authenticated users can read public configs"
  ON app_config
  FOR SELECT
  TO authenticated
  USING (is_public = true);

-- Policy for service role to manage all configs
CREATE POLICY "Service role can manage all configs"
  ON app_config
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Add updated_at trigger
CREATE TRIGGER app_config_updated_at
  BEFORE UPDATE ON app_config
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at();

-- Insert sample public configurations
INSERT INTO app_config (key_name, key_value, is_public, description) VALUES
('TAVUS_BASE_URL', 'https://tavusapi.com/v2', true, 'Base URL for Tavus API'),
('APP_VERSION', '1.0.0', true, 'Current app version'),
('SUPPORTED_LANGUAGES', 'english,spanish,french', true, 'Comma-separated list of supported languages'),
('MAX_SESSION_DURATION_MINUTES', '60', true, 'Maximum interview session duration in minutes'),
('MIN_SESSION_DURATION_MINUTES', '15', true, 'Minimum interview session duration in minutes'),
('ENABLE_ANALYTICS', 'false', true, 'Enable analytics tracking'),
('MAINTENANCE_MODE', 'false', true, 'Enable maintenance mode'),
('FEATURE_CV_UPLOAD', 'true', true, 'Enable CV upload feature'),
('FEATURE_AI_SCORING', 'true', true, 'Enable AI scoring feature'),
('MAX_CV_FILE_SIZE_MB', '10', true, 'Maximum CV file size in MB')
ON CONFLICT (key_name) DO NOTHING;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS app_config_key_name_idx ON app_config (key_name);
CREATE INDEX IF NOT EXISTS app_config_is_public_idx ON app_config (is_public);