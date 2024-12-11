/*
  # Final fix for database schema with auth setup
  
  1. Changes
    - Set up auth schema first
    - Create proper roles and grants
    - Recreate tables with proper references
  
  2. Security
    - Set up proper auth roles and permissions
    - Enable RLS with proper policies
    - Set up proper schema permissions
*/

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Ensure auth schema exists
CREATE SCHEMA IF NOT EXISTS auth;

-- Drop existing objects in correct order
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();
DROP TABLE IF EXISTS game_sessions;
DROP TABLE IF EXISTS user_settings;
DROP TABLE IF EXISTS profiles;

-- Create roles if they don't exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'authenticated') THEN
    CREATE ROLE authenticated NOLOGIN NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'anon') THEN
    CREATE ROLE anon NOLOGIN NOINHERIT;
  END IF;
END
$$;

-- Grant schema usage
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA auth TO authenticated;
GRANT USAGE ON SCHEMA auth TO anon;

-- Create profiles table
CREATE TABLE profiles (
  id uuid PRIMARY KEY,
  username text UNIQUE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT fk_auth_user FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Grant permissions on profiles
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
  profile_id uuid PRIMARY KEY,
  target_size integer NOT NULL DEFAULT 40,
  target_speed integer NOT NULL DEFAULT 1000,
  game_time integer NOT NULL DEFAULT 30,
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT fk_profile FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE
);

-- Grant permissions on user_settings
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
  profile_id uuid NOT NULL,
  score integer NOT NULL,
  misses integer NOT NULL,
  accuracy float NOT NULL,
  target_size integer NOT NULL,
  target_speed integer NOT NULL,
  game_time integer NOT NULL,
  created_at timestamptz DEFAULT now(),
  CONSTRAINT fk_profile FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE
);

-- Grant permissions on game_sessions
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
RETURNS trigger
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.profiles (id)
  VALUES (new.id);
  
  INSERT INTO public.user_settings (profile_id)
  VALUES (new.id);
  
  RETURN new;
END;
$$;

-- Create trigger for new user creation
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Grant sequence usage
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO anon;

-- Grant function execution permissions
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO postgres;

-- Grant table permissions to supabase_auth_admin
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO postgres;