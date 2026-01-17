-- Service Fee Configuration Migration
-- Run this in Supabase SQL Editor

-- 1. Add service_fee column to orders table
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS service_fee NUMERIC DEFAULT 0;

-- 2. Create app_settings table if not exists (for dynamic configuration)
CREATE TABLE IF NOT EXISTS public.app_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  key VARCHAR(100) NOT NULL UNIQUE,
  value TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

-- Allow all users to read settings
CREATE POLICY "Allow read access to app_settings" ON public.app_settings
  FOR SELECT USING (true);

-- 3. Insert default service fee and wallet_enabled
INSERT INTO public.app_settings (key, value, description) VALUES
  ('service_fee', '5.0', 'رسوم الخدمة الثابتة'),
  ('wallet_enabled', 'true', 'تفعيل/تعطيل استخدام المحفظة في الدفع')
ON CONFLICT (key) DO NOTHING;
