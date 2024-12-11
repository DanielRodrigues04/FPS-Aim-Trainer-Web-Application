/*
  # FPS Aim Trainer Schema

  1. New Tables
    - `profiles`
      - `id` (uuid, primary key) - matches auth.users id
      - `username` (text) - display name
      - `created_at` (timestamp)
      - `updated_at` (timestamp)
    
    - `game_sessions`
      - `id` (uuid, primary key)
      - `profile_id` (uuid, foreign key)
      - `score` (integer)
      - `misses` (integer)
      - `accuracy` (float)
      - `target_size` (integer)
      - `target_speed` (integer)
      - `game_time` (integer)
      - `created_at` (timestamp)
    
    - `user_settings`
      - `profile_id` (uuid, primary key)
      - `target_size` (integer)
      - `target_speed` (integer)
      - `game_time` (integer)
      - `updated_at` (timestamp)

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users
*/

-- Create profiles table
CREATE TABLE profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id),
  username text UNIQUE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read all profiles"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can update own profile"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

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
  ON game_sessions
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Users can read own game sessions"
  ON game_sessions
  FOR SELECT
  TO authenticated
  USING (auth.uid() = profile_id);

-- Create user_settings table
CREATE TABLE user_settings (
  profile_id uuid PRIMARY KEY REFERENCES profiles(id),
  target_size integer NOT NULL DEFAULT 40,
  target_speed integer NOT NULL DEFAULT 1000,
  game_time integer NOT NULL DEFAULT 30,
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own settings"
  ON user_settings
  FOR SELECT
  TO authenticated
  USING (auth.uid() = profile_id);

CREATE POLICY "Users can update own settings"
  ON user_settings
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = profile_id);

-- Create function to handle profile creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO profiles (id)
  VALUES (new.id);

  INSERT INTO user_settings (profile_id)
  VALUES (new.id);

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user creation
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();