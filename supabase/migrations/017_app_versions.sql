-- Migration: 017_app_versions.sql
-- Purpose: Add tables for force update system
-- Created: 2026-01-15

-- ===========================================
-- App Versions Table
-- Control app update popups
-- ===========================================
CREATE TABLE IF NOT EXISTS public.app_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  platform text NOT NULL CHECK (platform IN ('android', 'ios', 'all')),
  -- Version info
  version_number text NOT NULL,  -- e.g., "1.0.0"
  build_number integer NOT NULL,  -- e.g., 1
  -- Update control
  is_force_update boolean DEFAULT false,
  min_supported_version text,  -- Minimum version allowed
  -- Messages
  title_ar text NOT NULL DEFAULT 'تحديث متاح',
  title_en text NOT NULL DEFAULT 'Update Available',
  message_ar text NOT NULL DEFAULT 'يتوفر تحديث جديد للتطبيق',
  message_en text NOT NULL DEFAULT 'A new version of the app is available',
  -- Optional illustration
  illustration_url text,
  -- Store URLs
  android_store_url text DEFAULT 'https://play.google.com/store/apps/details?id=com.bourraq.app',
  ios_store_url text DEFAULT 'https://apps.apple.com/app/bourraq/id123456789',
  -- Status
  is_active boolean DEFAULT true,
  -- Timestamps
  created_at timestamptz DEFAULT now(),
  released_at timestamptz
);

-- Only one active version per platform
CREATE UNIQUE INDEX IF NOT EXISTS idx_app_versions_active
  ON public.app_versions(platform)
  WHERE is_active = true;

-- ===========================================
-- RLS Policies
-- ===========================================
ALTER TABLE public.app_versions ENABLE ROW LEVEL SECURITY;

-- Everyone can read app versions (needed for update check)
CREATE POLICY "Anyone can view app_versions"
  ON public.app_versions FOR SELECT
  USING (true);
