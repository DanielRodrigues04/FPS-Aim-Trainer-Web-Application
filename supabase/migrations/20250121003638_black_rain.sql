/*
  # Fix database schema with proper auth setup
  
  1. Changes
    - Drop existing tables in correct order
    - Set up auth schema properly
    - Recreate tables with proper dependencies
    - Add proper auth policies
  
  2. Security
    - Enable RLS on all tables
    - Set up proper auth policies
    - Add necessary auth roles and permissions
*/

-- Enable UUID extension if not enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop existing tables in correct order
DROP TABLE IF EXISTS game_sessions CASCADE;
DROP TABLE IF EXISTS user_settings CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- Create auth roles
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    CREATE ROLE authenticated;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    CREATE ROLE anon;
  END IF;
END
$$;

-- Create profiles table first
CREATE TABLE profiles (
  id uuid PRIMARY KEY,
  username text UNIQUE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Grant necessary permissions
GRANT ALL ON profiles TO postgres;
GRANT ALL ON profiles TO authenticated;
GRANT SELECT ON profiles TO anon;

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

-- Grant necessary permissions
GRANT ALL ON user_settings TO postgres;
GRANT ALL ON user_settings TO authenticated;

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
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id uuid REFERENCES profiles(id) NOT NULL,
  score integer NOT NULL,
  misses integer NOT NULL,
  accuracy float NOT NULL,
  target_size integer NOT NULL,
  target_speed integer NOT NULL,
  game_time integer NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Grant necessary permissions
GRANT ALL ON game_sessions TO postgres;
GRANT ALL ON game_sessions TO authenticated;

ALTER TABLE game_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert own game sessions"
  ON game_sessions FOR INSERT
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Users can view own game sessions"
  ON game_sessions FOR SELECT
  USING (auth.uid() = profile_id);

-- Create function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Create profile
  INSERT INTO public.profiles (id)
  VALUES (new.id);
  
  -- Create default settings
  INSERT INTO public.user_settings (profile_id)
  VALUES (new.id);
  
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Grant usage on sequences
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO anon;

-- Grant execute on the handle_new_user function
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO postgres;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO authenticated;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO anon;