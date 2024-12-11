/*
  # Fix database schema and test data
  
  1. Changes
    - Drop existing tables in correct order
    - Recreate schema with proper dependencies
    - Add test users and data
  
  2. Security
    - Enable RLS on all tables
    - Set up proper policies
*/

-- Drop existing tables in correct order
DROP TABLE IF EXISTS game_sessions CASCADE;
DROP TABLE IF EXISTS user_settings CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- Create profiles table first
CREATE TABLE profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id),
  username text UNIQUE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public profiles are viewable by everyone"
  ON profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- Create user_settings table
CREATE TABLE user_settings (
  profile_id uuid PRIMARY KEY REFERENCES profiles(id),
  target_size integer NOT NULL DEFAULT 40,
  target_speed integer NOT NULL DEFAULT 1000,
  game_time integer NOT NULL DEFAULT 30,
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own settings"
  ON user_settings FOR SELECT
  USING (auth.uid() = profile_id);

CREATE POLICY "Users can update own settings"
  ON user_settings FOR UPDATE
  USING (auth.uid() = profile_id);

CREATE POLICY "Users can insert own settings"
  ON user_settings FOR INSERT
  WITH CHECK (auth.uid() = profile_id);

-- Create game_sessions table
CREATE TABLE game_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid REFERENCES profiles(id) NOT NULL,
  score integer NOT NULL,
  misses integer NOT NULL,
  accuracy float NOT NULL,
  target_size integer NOT NULL,
  target_speed integer NOT NULL,
  game_time integer NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE game_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert own game sessions"
  ON game_sessions FOR INSERT
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Users can view own game sessions"
  ON game_sessions FOR SELECT
  USING (auth.uid() = profile_id);

-- Create function to handle new user creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Create profile
  INSERT INTO profiles (id)
  VALUES (new.id);
  
  -- Create default settings
  INSERT INTO user_settings (profile_id)
  VALUES (new.id);
  
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Insert test users
DO $$
BEGIN
  -- Only insert if they don't exist
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'player1@example.com') THEN
    INSERT INTO auth.users (
      id,
      instance_id,
      email,
      encrypted_password,
      email_confirmed_at,
      created_at,
      updated_at,
      raw_app_meta_data,
      raw_user_meta_data,
      aud,
      role
    ) VALUES (
      '00000000-0000-0000-0000-000000000001',
      '00000000-0000-0000-0000-000000000000',
      'player1@example.com',
      crypt('player1password', gen_salt('bf')),
      now(),
      now(),
      now(),
      '{"provider":"email","providers":["email"]}',
      '{}',
      'authenticated',
      'authenticated'
    );
  END IF;
END $$;