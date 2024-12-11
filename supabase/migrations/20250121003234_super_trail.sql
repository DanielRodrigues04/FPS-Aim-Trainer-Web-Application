/*
  # Fix user creation approach
  
  1. Changes
    - Remove direct auth.users insertion
    - Add initial settings for profiles
  
  2. Notes
    - Users should be created through Supabase Auth API instead
    - This migration only handles profile data
*/

-- Insert initial settings for profiles that will be created
INSERT INTO user_settings (
  profile_id,
  target_size,
  target_speed,
  game_time
) VALUES 
  (
    '00000000-0000-0000-0000-000000000001',
    40,
    1000,
    30
  ),
  (
    '00000000-0000-0000-0000-000000000002',
    40,
    1000,
    30
  ),
  (
    '00000000-0000-0000-0000-000000000003',
    40,
    1000,
    30
  )
ON CONFLICT (profile_id) DO NOTHING;