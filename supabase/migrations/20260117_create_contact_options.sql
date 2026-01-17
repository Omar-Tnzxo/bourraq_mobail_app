-- =============================================
-- Migration: Create contact_options table
-- Date: 2026-01-17
-- Description: Stores dynamic contact options for the app
--              (All social media platforms) with visibility control
-- =============================================

-- Create contact_options table
CREATE TABLE IF NOT EXISTS public.contact_options (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  type text NOT NULL CHECK (type = ANY (ARRAY[
    -- Contact Types
    'phone'::text, 'whatsapp'::text, 'email'::text, 'website'::text,
    -- Social Media Platforms
    'facebook'::text, 'instagram'::text, 'twitter'::text, 'x'::text,
    'tiktok'::text, 'snapchat'::text, 'youtube'::text, 'linkedin'::text,
    'telegram'::text, 'pinterest'::text, 'threads'::text, 'discord'::text,
    'reddit'::text, 'twitch'::text, 'spotify'::text, 'soundcloud'::text,
    'github'::text, 'behance'::text, 'dribbble'::text, 'medium'::text,
    -- Generic
    'other'::text
  ])),
  title_ar text NOT NULL,
  title_en text NOT NULL,
  value text NOT NULL,
  icon_name text,
  display_order integer DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT contact_options_pkey PRIMARY KEY (id)
);

-- Enable Row Level Security
ALTER TABLE public.contact_options ENABLE ROW LEVEL SECURITY;

-- Create policy: Allow public read for active options only
CREATE POLICY "contact_options_read_active" ON public.contact_options
  FOR SELECT
  USING (is_active = true);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_contact_options_active_order 
  ON public.contact_options (is_active, display_order);

-- Insert default contact options (currently active: phone, whatsapp, facebook, website, email)
INSERT INTO public.contact_options (type, title_ar, title_en, value, display_order, is_active) VALUES
  -- Active options
  ('phone', 'الهاتف', 'Phone', '+201102450471', 1, true),
  ('whatsapp', 'واتساب', 'WhatsApp', '+201102450471', 2, true),
  ('facebook', 'فيسبوك', 'Facebook', 'https://www.facebook.com/Bourraq', 3, true),
  ('website', 'الموقع الإلكتروني', 'Website', 'https://www.bourraq.com', 4, true),
  ('email', 'البريد الإلكتروني', 'Email', 'bourraq.com@gmail.com', 5, true),
  -- Inactive options (enable from Supabase dashboard when ready)
  ('instagram', 'انستغرام', 'Instagram', 'https://www.instagram.com/bourraq', 6, false),
  ('twitter', 'تويتر / إكس', 'Twitter / X', 'https://twitter.com/bourraq', 7, false),
  ('tiktok', 'تيك توك', 'TikTok', 'https://www.tiktok.com/@bourraq', 8, false),
  ('snapchat', 'سناب شات', 'Snapchat', 'https://www.snapchat.com/add/bourraq', 9, false),
  ('youtube', 'يوتيوب', 'YouTube', 'https://www.youtube.com/@bourraq', 10, false),
  ('telegram', 'تيليجرام', 'Telegram', 'https://t.me/bourraq', 11, false),
  ('linkedin', 'لينكد إن', 'LinkedIn', 'https://www.linkedin.com/company/bourraq', 12, false),
  ('threads', 'ثريدز', 'Threads', 'https://www.threads.net/@bourraq', 13, false);
