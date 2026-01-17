-- Migration: Search Feature Tables
-- Created: 2026-01-15

-- =============================================
-- 1. Search History Table (Per user, last 20)
-- =============================================
CREATE TABLE IF NOT EXISTS public.search_history (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  query text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT search_history_pkey PRIMARY KEY (id),
  CONSTRAINT search_history_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_search_history_user_id ON public.search_history(user_id);
CREATE INDEX IF NOT EXISTS idx_search_history_created_at ON public.search_history(created_at DESC);

-- RLS Policies
ALTER TABLE public.search_history ENABLE ROW LEVEL SECURITY;

-- Users can only view their own search history
CREATE POLICY "Users can view own search history"
  ON public.search_history FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own search history
CREATE POLICY "Users can insert own search history"
  ON public.search_history FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own search history
CREATE POLICY "Users can delete own search history"
  ON public.search_history FOR DELETE
  USING (auth.uid() = user_id);

-- =============================================
-- 2. Popular Searches Table (Admin managed)
-- =============================================
CREATE TABLE IF NOT EXISTS public.popular_searches (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  keyword_ar text NOT NULL,
  keyword_en text NOT NULL,
  display_order integer DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT popular_searches_pkey PRIMARY KEY (id)
);

-- Index for ordering
CREATE INDEX IF NOT EXISTS idx_popular_searches_order ON public.popular_searches(display_order);

-- RLS Policies
ALTER TABLE public.popular_searches ENABLE ROW LEVEL SECURITY;

-- Everyone can read active popular searches
CREATE POLICY "Anyone can view active popular searches"
  ON public.popular_searches FOR SELECT
  USING (is_active = true);

-- =============================================
-- 3. Insert sample popular searches
-- =============================================
INSERT INTO public.popular_searches (keyword_ar, keyword_en, display_order) VALUES
  ('لبن', 'milk', 1),
  ('ارز', 'rice', 2),
  ('بيض', 'eggs', 3),
  ('water', 'water', 4),
  ('زيت', 'oil', 5),
  ('سكر', 'sugar', 6),
  ('مكرونة', 'pasta', 7),
  ('زبادي', 'yogurt', 8),
  ('جبنة', 'cheese', 9),
  ('خبز', 'bread', 10);
