-- ==============================================================================
-- MORE PLACES ENGINE: Database Schema & PostGIS Spatial Engine
-- Migration: 20260817000000_create_places_engine.sql
-- ==============================================================================

-- 1. Enable PostGIS Extension
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;

-- 2. Create Places Table
CREATE TABLE IF NOT EXISTS public.places (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    arabic_name TEXT,
    category TEXT NOT NULL DEFAULT 'other',
    sub_category TEXT,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    location extensions.GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (
        extensions.ST_SetSRID(extensions.ST_MakePoint(longitude, latitude), 4326)::extensions.geography
    ) STORED,
    address TEXT,
    city TEXT DEFAULT 'Cairo',
    country TEXT DEFAULT 'Egypt',
    phone TEXT,
    website TEXT,
    instagram TEXT,
    rating NUMERIC(3, 2) DEFAULT 4.5,
    reviews_count INTEGER DEFAULT 0,
    price_level TEXT DEFAULT '$$',
    featured_image TEXT,
    photos TEXT[] DEFAULT '{}',
    working_hours JSONB DEFAULT '{"monday": "08:00 - 23:00", "tuesday": "08:00 - 23:00", "wednesday": "08:00 - 23:00", "thursday": "08:00 - 00:00", "friday": "08:00 - 00:00", "saturday": "08:00 - 23:00", "sunday": "08:00 - 23:00"}'::jsonb,
    menu JSONB DEFAULT '[]'::jsonb,
    is_verified BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    open_now BOOLEAN DEFAULT true,
    people_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 3. Create High-Performance Spatial & Filtering Indexes
CREATE INDEX IF NOT EXISTS idx_places_location ON public.places USING GIST (location);
CREATE INDEX IF NOT EXISTS idx_places_category ON public.places (category);
CREATE INDEX IF NOT EXISTS idx_places_city ON public.places (city);
CREATE INDEX IF NOT EXISTS idx_places_rating ON public.places (rating DESC);
CREATE INDEX IF NOT EXISTS idx_places_is_active ON public.places (is_active);

-- 4. Create Spatial RPC Function for Lightning-Fast Nearby Search
CREATE OR REPLACE FUNCTION public.get_nearby_places(
    user_lat DOUBLE PRECISION,
    user_lng DOUBLE PRECISION,
    radius_meters DOUBLE PRECISION DEFAULT 10000,
    filter_category TEXT DEFAULT NULL,
    search_query TEXT DEFAULT NULL,
    limit_count INT DEFAULT 100
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    arabic_name TEXT,
    category TEXT,
    sub_category TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    address TEXT,
    city TEXT,
    country TEXT,
    phone TEXT,
    website TEXT,
    instagram TEXT,
    rating NUMERIC(3, 2),
    reviews_count INTEGER,
    price_level TEXT,
    featured_image TEXT,
    photos TEXT[],
    working_hours JSONB,
    menu JSONB,
    is_verified BOOLEAN,
    is_active BOOLEAN,
    open_now BOOLEAN,
    people_count INTEGER,
    distance_meters DOUBLE PRECISION
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.name,
        p.arabic_name,
        p.category,
        p.sub_category,
        p.latitude,
        p.longitude,
        p.address,
        p.city,
        p.country,
        p.phone,
        p.website,
        p.instagram,
        p.rating,
        p.reviews_count,
        p.price_level,
        p.featured_image,
        p.photos,
        p.working_hours,
        p.menu,
        p.is_verified,
        p.is_active,
        p.open_now,
        p.people_count,
        extensions.ST_Distance(
            p.location, 
            extensions.ST_SetSRID(extensions.ST_MakePoint(user_lng, user_lat), 4326)::extensions.geography
        ) AS distance_meters
    FROM public.places p
    WHERE p.is_active = true
      AND extensions.ST_DWithin(
          p.location, 
          extensions.ST_SetSRID(extensions.ST_MakePoint(user_lng, user_lat), 4326)::extensions.geography, 
          radius_meters
      )
      AND (filter_category IS NULL OR filter_category = '' OR LOWER(filter_category) = 'all' OR LOWER(p.category) = LOWER(filter_category))
      AND (
          search_query IS NULL OR search_query = '' 
          OR p.name ILIKE '%' || search_query || '%' 
          OR (p.arabic_name IS NOT NULL AND p.arabic_name ILIKE '%' || search_query || '%')
          OR (p.address IS NOT NULL AND p.address ILIKE '%' || search_query || '%')
      )
    ORDER BY distance_meters ASC
    LIMIT limit_count;
END;
$$;

-- 5. Row Level Security (RLS) Policies
ALTER TABLE public.places ENABLE ROW LEVEL SECURITY;

-- Allow public read access to all active places
DROP POLICY IF EXISTS "Allow public read access to active places" ON public.places;
CREATE POLICY "Allow public read access to active places"
ON public.places
FOR SELECT
TO anon, authenticated
USING (is_active = true);

-- Allow authenticated/anon insert for ingestion & contributions
DROP POLICY IF EXISTS "Allow public insert to places" ON public.places;
CREATE POLICY "Allow public insert to places"
ON public.places
FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Allow public update to places
DROP POLICY IF EXISTS "Allow public update to places" ON public.places;
CREATE POLICY "Allow public update to places"
ON public.places
FOR UPDATE
TO anon, authenticated
USING (true)
WITH CHECK (true);
