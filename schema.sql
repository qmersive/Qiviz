-- Qiviz Supabase Schema (MVP)

-- 1. Profiles Table
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  name TEXT,
  nickname TEXT,
  country TEXT,
  university TEXT,
  city TEXT,
  interests TEXT[],
  relationship_goals TEXT[],
  languages TEXT[],
  bio TEXT,
  profile_photo_url TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  is_onboarded BOOLEAN DEFAULT false,
  qr_code_id TEXT UNIQUE
);

-- Row Level Security (RLS) for profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public profiles are viewable by everyone."
  ON profiles FOR SELECT
  USING ( true );

CREATE POLICY "Users can insert their own profile."
  ON profiles FOR INSERT
  WITH CHECK ( auth.uid() = id );

CREATE POLICY "Users can update own profile."
  ON profiles FOR UPDATE
  USING ( auth.uid() = id );

-- 2. Dares / Challenges Table
CREATE TABLE dares (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT now(),
  creator_id UUID REFERENCES profiles(id),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  entry_fee_inr INTEGER DEFAULT 0,
  end_time TIMESTAMPTZ NOT NULL,
  is_active BOOLEAN DEFAULT true
);

ALTER TABLE dares ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Dares are viewable by everyone."
  ON dares FOR SELECT
  USING ( true );

-- 3. Dare Entries
CREATE TABLE dare_entries (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT now(),
  dare_id UUID REFERENCES dares(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id),
  video_url TEXT,
  likes_count INTEGER DEFAULT 0
);

ALTER TABLE dare_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Dare entries are viewable by everyone."
  ON dare_entries FOR SELECT
  USING ( true );

CREATE POLICY "Users can insert their own dare entries."
  ON dare_entries FOR INSERT
  WITH CHECK ( auth.uid() = user_id );

-- 4. Events Table
CREATE TABLE events (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT now(),
  creator_id UUID REFERENCES profiles(id),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  event_date TIMESTAMPTZ NOT NULL,
  location_name TEXT NOT NULL,
  image_url TEXT,
  ticket_price_inr INTEGER DEFAULT 0
);

ALTER TABLE events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Events are viewable by everyone."
  ON events FOR SELECT
  USING ( true );

-- 5. Event Attendees
CREATE TABLE event_attendees (
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (event_id, user_id)
);

ALTER TABLE event_attendees ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Event attendees are viewable by everyone."
  ON event_attendees FOR SELECT
  USING ( true );

CREATE POLICY "Users can join events."
  ON event_attendees FOR INSERT
  WITH CHECK ( auth.uid() = user_id );

-- Function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, qr_code_id)
  VALUES (new.id, substr(md5(random()::text), 1, 10));
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to call the function when a user is created
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Enable Storage (Needs to be done via dashboard or API but we can define buckets later)
-- Example Bucket: profile_photos

-- ==========================================
-- SEED DATA: Demo User
-- ==========================================
-- This creates a test user you can login with.
-- Email: demo@qiviz.com
-- Password: password123

INSERT INTO auth.users (
  id,
  instance_id,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
) VALUES (
  'd2b45070-07a8-4229-8736-121dbde5f212',
  '00000000-0000-0000-0000-000000000000',
  'demo@qiviz.com',
  crypt('password123', gen_salt('bf')),
  now(),
  '{"provider": "email", "providers": ["email"]}',
  '{}',
  now(),
  now()
) ON CONFLICT (id) DO NOTHING;

-- Because of our trigger above, the profile is automatically created!
-- Let's update the profile with some dummy data for testing the app:
UPDATE public.profiles
SET 
  name = 'Demo Student',
  nickname = 'Demoy',
  country = 'Nigeria',
  university = 'Delhi University',
  city = 'New Delhi',
  bio = 'Just testing out the Qiviz app!',
  is_onboarded = true
WHERE id = 'd2b45070-07a8-4229-8736-121dbde5f212';
