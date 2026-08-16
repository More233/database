-- ==============================================================================
-- MORE COMPLETE SCHEMA: Profiles, Posts, Custom Venues, Saved Places, Reports, Notifications
-- ==============================================================================

-- 1. Profiles Table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    first_name TEXT,
    last_name TEXT,
    username TEXT UNIQUE,
    city TEXT,
    birthday TEXT,
    interests TEXT[],
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    phone TEXT,
    email TEXT,
    avatar_url TEXT,
    cover_url TEXT,
    fcm_token TEXT,
    foursquare_token TEXT,
    preferred_language TEXT DEFAULT 'ar',
    profile_visibility TEXT DEFAULT 'public',
    friend_requests_visibility TEXT DEFAULT 'everyone',
    check_in_visibility TEXT DEFAULT 'everyone',
    show_me_here_now BOOLEAN DEFAULT true,
    let_friends_check_in_with_me BOOLEAN DEFAULT true,
    show_stats_streaks BOOLEAN DEFAULT true,
    show_saved_places_profile BOOLEAN DEFAULT true,
    allow_tags_mentions BOOLEAN DEFAULT true,
    push_settings JSONB DEFAULT '{}'::jsonb,
    location_permission BOOLEAN DEFAULT true,
    precise_location BOOLEAN DEFAULT true,
    show_nearby_places BOOLEAN DEFAULT true,
    nearby_check_in_prompts BOOLEAN DEFAULT true,
    show_check_in_suggestions BOOLEAN DEFAULT true,
    suggest_places_when_nearby BOOLEAN DEFAULT true,
    suggest_from_recent_visits BOOLEAN DEFAULT true,
    use_photo_time_location BOOLEAN DEFAULT true
);

-- 2. Posts (Check-ins) Table
CREATE TABLE IF NOT EXISTS public.posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    title TEXT,
    category_name TEXT DEFAULT 'Other',
    location_address TEXT,
    description TEXT,
    image_url TEXT,
    is_private BOOLEAN DEFAULT false,
    sticker_index INT DEFAULT 0,
    tagged_friends JSONB DEFAULT '[]'::jsonb,
    likes_count INT DEFAULT 0,
    comments_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    is_bookmarked BOOLEAN DEFAULT false,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    place_id TEXT
);

-- 3. Custom Venues Table
CREATE TABLE IF NOT EXISTS public.custom_venues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    category_name TEXT DEFAULT 'Other',
    address TEXT,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    phone TEXT,
    website TEXT,
    hours TEXT,
    is_private BOOLEAN DEFAULT false,
    photos TEXT[] DEFAULT '{}',
    instagram TEXT,
    twitter TEXT,
    facebook TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 4. Saved Places Table
CREATE TABLE IF NOT EXISTS public.saved_places (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    place_id TEXT NOT NULL,
    name TEXT,
    category TEXT,
    address TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    UNIQUE(user_id, place_id)
);

-- 5. Reports Table
CREATE TABLE IF NOT EXISTS public.reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    reporter_name TEXT NOT NULL,
    reported_name TEXT NOT NULL,
    reported_type TEXT NOT NULL,
    reason TEXT NOT NULL,
    status TEXT DEFAULT 'pending' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 6. Notifications Table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    actor_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    title TEXT,
    body TEXT,
    data JSONB DEFAULT '{}'::jsonb,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 7. Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.custom_venues ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_places ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 8. Basic Policies
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile" ON public.profiles FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Public posts are viewable by everyone" ON public.posts;
CREATE POLICY "Public posts are viewable by everyone" ON public.posts FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert own posts" ON public.posts;
CREATE POLICY "Users can insert own posts" ON public.posts FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Users can update own posts" ON public.posts;
CREATE POLICY "Users can update own posts" ON public.posts FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Custom venues viewable by everyone" ON public.custom_venues;
CREATE POLICY "Custom venues viewable by everyone" ON public.custom_venues FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert custom venues" ON public.custom_venues;
CREATE POLICY "Users can insert custom venues" ON public.custom_venues FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Saved places viewable by owner" ON public.saved_places;
CREATE POLICY "Saved places viewable by owner" ON public.saved_places FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert saved places" ON public.saved_places;
CREATE POLICY "Users can insert saved places" ON public.saved_places FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Reports viewable and insertable" ON public.reports;
CREATE POLICY "Reports viewable and insertable" ON public.reports FOR ALL USING (true);

DROP POLICY IF EXISTS "Notifications viewable by owner" ON public.notifications;
CREATE POLICY "Notifications viewable by owner" ON public.notifications FOR ALL USING (true);
