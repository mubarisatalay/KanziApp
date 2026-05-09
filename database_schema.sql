-- ============================================
-- Kanzi App - Supabase Database Schema
-- ============================================

-- Execute this in Supabase SQL Editor

-- ============================================
-- 1. PROFILES TABLE
-- ============================================
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 2. ROOMS TABLE
-- ============================================
CREATE TABLE public.rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  code TEXT UNIQUE NOT NULL,
  created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_rooms_code ON public.rooms(code);
CREATE INDEX idx_rooms_created_by ON public.rooms(created_by);

-- ============================================
-- 3. ROOM MEMBERS TABLE
-- ============================================
CREATE TABLE public.room_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('admin', 'member')),
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(room_id, user_id)
);

CREATE INDEX idx_room_members_room_id ON public.room_members(room_id);
CREATE INDEX idx_room_members_user_id ON public.room_members(user_id);

-- ============================================
-- 4. CHALLENGES TABLE
-- ============================================
CREATE TABLE public.challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
  challenge_text TEXT NOT NULL,
  challenge_type TEXT NOT NULL CHECK (challenge_type IN ('photo', 'text', 'photo_text')),
  challenge_date DATE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(room_id, challenge_date)
);

CREATE INDEX idx_challenges_room_date ON public.challenges(room_id, challenge_date);

-- ============================================
-- 5. SUBMISSIONS TABLE
-- ============================================
CREATE TABLE public.submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  room_id UUID NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
  image_url TEXT,
  text_content TEXT,
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(challenge_id, user_id)
);

CREATE INDEX idx_submissions_challenge_id ON public.submissions(challenge_id);
CREATE INDEX idx_submissions_user_id ON public.submissions(user_id);
CREATE INDEX idx_submissions_room_id ON public.submissions(room_id);

-- ============================================
-- 6. VOTES TABLE
-- ============================================
CREATE TABLE public.votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  submission_id UUID NOT NULL REFERENCES public.submissions(id) ON DELETE CASCADE,
  voter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  vote_value INTEGER NOT NULL DEFAULT 1 CHECK (vote_value >= 1 AND vote_value <= 5),
  voted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(submission_id, voter_id)
);

CREATE INDEX idx_votes_submission_id ON public.votes(submission_id);
CREATE INDEX idx_votes_voter_id ON public.votes(voter_id);

-- ============================================
-- 7. DATABASE FUNCTIONS
-- ============================================

-- Generate unique room code
CREATE OR REPLACE FUNCTION generate_room_code()
RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  result TEXT := '';
  i INTEGER;
BEGIN
  FOR i IN 1..6 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::INTEGER, 1);
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Get daily leaderboard for a room
CREATE OR REPLACE FUNCTION get_daily_leaderboard(p_room_id UUID, p_date DATE)
RETURNS TABLE (
  user_id UUID,
  username TEXT,
  display_name TEXT,
  avatar_url TEXT,
  total_votes BIGINT,
  submission_count BIGINT,
  rank BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id AS user_id,
    p.username,
    p.display_name,
    p.avatar_url,
    COALESCE(SUM(v.vote_value), 0)::BIGINT AS total_votes,
    COUNT(DISTINCT s.id)::BIGINT AS submission_count,
    RANK() OVER (ORDER BY COALESCE(SUM(v.vote_value), 0) DESC) AS rank
  FROM submissions s
  JOIN challenges c ON s.challenge_id = c.id
  JOIN profiles p ON s.user_id = p.id
  LEFT JOIN votes v ON s.id = v.submission_id
  WHERE s.room_id = p_room_id
    AND c.challenge_date = p_date
  GROUP BY p.id, p.username, p.display_name, p.avatar_url
  ORDER BY total_votes DESC;
END;
$$ LANGUAGE plpgsql;

-- Create daily challenges for all rooms
CREATE OR REPLACE FUNCTION create_daily_challenges()
RETURNS void AS $$
DECLARE
  room RECORD;
  challenge_pool TEXT[] := ARRAY[
    'Take the most cringe photo today.',
    'Take a photo with the youngest person you saw today.',
    'Share the most meaningful proverb you know.',
    'Capture the most beautiful sunset you see.',
    'Show us your weirdest possession.',
    'Take a photo of something that made you smile today.',
    'Share a childhood memory in one sentence.',
    'Take a photo of your view right now.',
    'What is your biggest fear? Explain in one sentence.',
    'Take a selfie with a stranger (with permission!).'
  ];
  challenge_types TEXT[] := ARRAY['photo', 'text', 'photo_text', 'photo', 'photo', 'photo', 'text', 'photo', 'text', 'photo'];
  random_index INTEGER;
  random_challenge TEXT;
  random_type TEXT;
BEGIN
  FOR room IN SELECT id FROM public.rooms LOOP
    random_index := floor(random() * array_length(challenge_pool, 1) + 1)::INTEGER;
    random_challenge := challenge_pool[random_index];
    random_type := challenge_types[random_index];
    
    INSERT INTO public.challenges (room_id, challenge_text, challenge_type, challenge_date)
    VALUES (room.id, random_challenge, random_type, CURRENT_DATE)
    ON CONFLICT (room_id, challenge_date) DO NOTHING;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 8. ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.room_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.votes ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 8.1 PROFILES POLICIES
-- ============================================

CREATE POLICY "Profiles are viewable by everyone"
  ON public.profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can insert their own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- ============================================
-- 8.2 ROOMS POLICIES
-- ============================================

CREATE POLICY "Users can view their rooms"
  ON public.rooms FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.room_members
      WHERE room_members.room_id = rooms.id
        AND room_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Authenticated users can create rooms"
  ON public.rooms FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Room admins can update their rooms"
  ON public.rooms FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.room_members
      WHERE room_members.room_id = rooms.id
        AND room_members.user_id = auth.uid()
        AND room_members.role = 'admin'
    )
  );

CREATE POLICY "Room admins can delete their rooms"
  ON public.rooms FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.room_members
      WHERE room_members.room_id = rooms.id
        AND room_members.user_id = auth.uid()
        AND room_members.role = 'admin'
    )
  );

-- ============================================
-- 8.3 ROOM MEMBERS POLICIES
-- ============================================

CREATE POLICY "Users can view members of their rooms"
  ON public.room_members FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.room_members rm
      WHERE rm.room_id = room_members.room_id
        AND rm.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can join rooms"
  ON public.room_members FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can update member roles"
  ON public.room_members FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.room_members rm
      WHERE rm.room_id = room_members.room_id
        AND rm.user_id = auth.uid()
        AND rm.role = 'admin'
    )
  );

CREATE POLICY "Users can leave or admins can remove members"
  ON public.room_members FOR DELETE
  USING (
    auth.uid() = user_id OR
    EXISTS (
      SELECT 1 FROM public.room_members rm
      WHERE rm.room_id = room_members.room_id
        AND rm.user_id = auth.uid()
        AND rm.role = 'admin'
    )
  );

-- ============================================
-- 8.4 CHALLENGES POLICIES
-- ============================================

CREATE POLICY "Users can view challenges in their rooms"
  ON public.challenges FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.room_members
      WHERE room_members.room_id = challenges.room_id
        AND room_members.user_id = auth.uid()
    )
  );

-- Room admins can create challenges
CREATE POLICY "Room admins can create challenges"
  ON public.challenges FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.room_members
      WHERE room_members.room_id = challenges.room_id
        AND room_members.user_id = auth.uid()
        AND room_members.role = 'admin'
    )
  );

-- ============================================
-- 8.5 SUBMISSIONS POLICIES
-- ============================================

CREATE POLICY "Users can view submissions in their rooms"
  ON public.submissions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.room_members
      WHERE room_members.room_id = submissions.room_id
        AND room_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create their own submissions"
  ON public.submissions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own submissions"
  ON public.submissions FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own submissions"
  ON public.submissions FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- 8.6 VOTES POLICIES
-- ============================================

CREATE POLICY "Users can view votes in their rooms"
  ON public.votes FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.submissions s
      JOIN public.room_members rm ON s.room_id = rm.room_id
      WHERE s.id = votes.submission_id
        AND rm.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can vote on submissions"
  ON public.votes FOR INSERT
  WITH CHECK (
    auth.uid() = voter_id AND
    NOT EXISTS (
      SELECT 1 FROM public.submissions
      WHERE submissions.id = votes.submission_id
        AND submissions.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update their own votes"
  ON public.votes FOR UPDATE
  USING (auth.uid() = voter_id);

CREATE POLICY "Users can delete their own votes"
  ON public.votes FOR DELETE
  USING (auth.uid() = voter_id);

-- ============================================
-- 9. TRIGGERS
-- ============================================

-- Update updated_at timestamp on profiles
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rooms_updated_at
  BEFORE UPDATE ON public.rooms
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Auto-create profile when a new user signs up
-- Uses SECURITY DEFINER to bypass RLS policies
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, display_name, created_at, updated_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substr(NEW.id::text, 1, 8)),
    COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substr(NEW.id::text, 1, 8)),
    NOW(),
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- RPC function for client-side profile creation (bypasses RLS)
-- Called by the app as a fallback when the trigger didn't create the profile
CREATE OR REPLACE FUNCTION public.ensure_profile_exists(
  user_id UUID,
  user_name TEXT
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO public.profiles (id, username, display_name, created_at, updated_at)
  VALUES (
    user_id,
    user_name,
    user_name,
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;
EXCEPTION
  WHEN unique_violation THEN
    -- Username already taken, use a fallback username
    INSERT INTO public.profiles (id, username, display_name, created_at, updated_at)
    VALUES (
      user_id,
      'user_' || substr(user_id::text, 1, 8),
      user_name,
      NOW(),
      NOW()
    )
    ON CONFLICT (id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 10. STORAGE SETUP
-- ============================================

-- Create storage bucket (run in Supabase Storage dashboard or via API)
-- Bucket name: challenge-images
-- Public: true
-- File size limit: 5MB
-- Allowed MIME types: image/jpeg, image/png, image/webp

-- Storage policy for uploads
INSERT INTO storage.buckets (id, name, public)
VALUES ('challenge-images', 'challenge-images', true)
ON CONFLICT (id) DO NOTHING;

-- Allow authenticated users to upload
CREATE POLICY "Authenticated users can upload images"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'challenge-images' AND
    auth.role() = 'authenticated'
  );

-- Allow authenticated users to update their own images
CREATE POLICY "Users can update their own images"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'challenge-images' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Allow authenticated users to delete their own images
CREATE POLICY "Users can delete their own images"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'challenge-images' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Allow public read access
CREATE POLICY "Public can view images"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'challenge-images');

-- ============================================
-- COMPLETION
-- ============================================

-- All tables, functions, and policies created successfully!
-- Next steps:
-- 1. Set up Edge Function for daily challenge generation
-- 2. Configure cron job to run create_daily_challenges() daily at midnight
-- 3. Test all policies with different user roles
