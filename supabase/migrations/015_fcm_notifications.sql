-- Migration: 015_fcm_notifications.sql
-- Purpose: Add tables for FCM push notifications system
-- Created: 2026-01-15

-- ===========================================
-- 1. FCM Tokens Table
-- Stores device tokens for push notifications
-- Supports both registered users and guests
-- ===========================================
CREATE TABLE IF NOT EXISTS public.fcm_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,  -- nullable for guests
  device_id text NOT NULL,
  token text NOT NULL,
  platform text NOT NULL CHECK (platform IN ('android', 'ios')),
  app_version text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT fcm_tokens_device_unique UNIQUE (device_id)
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user_id ON public.fcm_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_is_active ON public.fcm_tokens(is_active);

-- ===========================================
-- 2. Notifications Table
-- Stores all sent notifications with targeting info
-- ===========================================
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title_ar text NOT NULL,
  title_en text NOT NULL,
  body_ar text NOT NULL,
  body_en text NOT NULL,
  image_url text,
  data jsonb DEFAULT '{}',
  -- Targeting options
  target_type text NOT NULL CHECK (target_type IN ('all', 'registered', 'guests', 'area', 'user')),
  target_area_id uuid REFERENCES public.areas(id),
  target_user_id uuid REFERENCES auth.users(id),
  -- Status tracking
  sent_count integer DEFAULT 0,
  failed_count integer DEFAULT 0,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed')),
  -- Timestamps
  created_at timestamptz DEFAULT now(),
  scheduled_at timestamptz,
  sent_at timestamptz,
  -- Creator (admin/moderation)
  created_by uuid
);

-- Index for queries
CREATE INDEX IF NOT EXISTS idx_notifications_target_type ON public.notifications(target_type);
CREATE INDEX IF NOT EXISTS idx_notifications_status ON public.notifications(status);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);

-- ===========================================
-- 3. Notification Preferences Table
-- User preferences for notification types
-- ===========================================
CREATE TABLE IF NOT EXISTS public.notification_preferences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  -- Preference flags
  order_updates boolean DEFAULT true,
  promotions boolean DEFAULT true,
  stock_alerts boolean DEFAULT true,
  new_products boolean DEFAULT true,
  -- Timestamps
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT notification_preferences_user_unique UNIQUE (user_id)
);

-- ===========================================
-- 4. Stock Alerts Table
-- "Notify me when available" for products
-- ===========================================
CREATE TABLE IF NOT EXISTS public.stock_alerts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  is_notified boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  notified_at timestamptz,
  CONSTRAINT stock_alerts_unique UNIQUE (user_id, product_id)
);

CREATE INDEX IF NOT EXISTS idx_stock_alerts_product ON public.stock_alerts(product_id);

-- ===========================================
-- RLS Policies
-- ===========================================

-- FCM Tokens: Users can manage their own tokens
ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own fcm_tokens"
  ON public.fcm_tokens FOR SELECT
  USING (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Users can insert own fcm_tokens"
  ON public.fcm_tokens FOR INSERT
  WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Users can update own fcm_tokens"
  ON public.fcm_tokens FOR UPDATE
  USING (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Users can delete own fcm_tokens"
  ON public.fcm_tokens FOR DELETE
  USING (auth.uid() = user_id OR user_id IS NULL);

-- Notification Preferences: Users manage their own
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notification_preferences"
  ON public.notification_preferences FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own notification_preferences"
  ON public.notification_preferences FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own notification_preferences"
  ON public.notification_preferences FOR UPDATE
  USING (auth.uid() = user_id);

-- Stock Alerts: Users manage their own
ALTER TABLE public.stock_alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own stock_alerts"
  ON public.stock_alerts FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own stock_alerts"
  ON public.stock_alerts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own stock_alerts"
  ON public.stock_alerts FOR DELETE
  USING (auth.uid() = user_id);

-- Notifications: Read-only for users (admin creates via Dashboard)
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view notifications targeted to them"
  ON public.notifications FOR SELECT
  USING (
    target_type = 'all' OR
    (target_type = 'registered' AND auth.uid() IS NOT NULL) OR
    target_user_id = auth.uid()
  );
