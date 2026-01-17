-- ============================================================
-- HOME SECTIONS - Dynamic Home Page Configuration
-- ============================================================
-- Run this in Supabase SQL Editor

CREATE TABLE public.home_sections (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  section_type text NOT NULL CHECK (section_type IN ('banners', 'categories', 'products')),
  title_ar text,
  title_en text,
  display_order integer DEFAULT 0,
  is_active boolean DEFAULT true,
  config jsonb DEFAULT '{}',
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT home_sections_pkey PRIMARY KEY (id)
);

-- Enable RLS
ALTER TABLE public.home_sections ENABLE ROW LEVEL SECURITY;

-- Public read access (everyone can see home sections)
CREATE POLICY "Anyone can view home sections"
  ON public.home_sections
  FOR SELECT
  USING (true);

-- ============================================================
-- INSERT DEFAULT SECTIONS
-- ============================================================

INSERT INTO public.home_sections (section_type, title_ar, title_en, display_order, is_active, config) VALUES
(
  'banners',
  NULL,
  NULL,
  1,
  true,
  '{"auto_scroll": true, "scroll_interval_ms": 4000, "limit": 10}'::jsonb
),
(
  'categories',
  'التصنيفات',
  'Categories',
  2,
  true,
  '{"show_title": true, "limit": 8}'::jsonb
),
(
  'products',
  'الأكثر مبيعاً',
  'Best Sellers',
  3,
  true,
  '{"source": "best_sellers", "limit": 6, "show_see_all": true, "see_all_route": "/products?filter=best_sellers"}'::jsonb
);

-- ============================================================
-- OPTIONAL: Add more product sections
-- ============================================================

-- Uncomment to add "New Arrivals" section:
-- INSERT INTO public.home_sections (section_type, title_ar, title_en, display_order, is_active, config) VALUES
-- (
--   'products',
--   'وصل حديثاً',
--   'New Arrivals',
--   4,
--   true,
--   '{"source": "newest", "limit": 6, "show_see_all": true, "see_all_route": "/products?filter=newest"}'::jsonb
-- );

-- Uncomment to add "Offers" section:
-- INSERT INTO public.home_sections (section_type, title_ar, title_en, display_order, is_active, config) VALUES
-- (
--   'products',
--   'عروض اليوم',
--   'Today''s Offers',
--   5,
--   true,
--   '{"source": "offers", "limit": 6, "show_see_all": true, "see_all_route": "/products?filter=offers"}'::jsonb
-- );
