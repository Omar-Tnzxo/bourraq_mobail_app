-- ============================================
-- Promo Codes Enhancement Migration
-- Run this in Supabase SQL Editor
-- ============================================

-- 1. Add missing columns to promo_codes table
ALTER TABLE public.promo_codes 
ADD COLUMN IF NOT EXISTS min_order_amount numeric DEFAULT 0,
ADD COLUMN IF NOT EXISTS max_discount numeric,
ADD COLUMN IF NOT EXISTS usage_limit integer,
ADD COLUMN IF NOT EXISTS usage_count integer DEFAULT 0,
ADD COLUMN IF NOT EXISTS per_user_limit integer DEFAULT 1,
ADD COLUMN IF NOT EXISTS start_date timestamp with time zone DEFAULT now();

-- 2. Create promo_code_usage table for tracking per-user usage
CREATE TABLE IF NOT EXISTS public.promo_code_usage (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  promo_code_id uuid NOT NULL,
  user_id uuid NOT NULL,
  order_id uuid,
  discount_amount numeric NOT NULL,
  used_at timestamp with time zone DEFAULT now(),
  CONSTRAINT promo_code_usage_pkey PRIMARY KEY (id),
  CONSTRAINT promo_code_usage_promo_code_id_fkey FOREIGN KEY (promo_code_id) REFERENCES public.promo_codes(id) ON DELETE CASCADE,
  CONSTRAINT promo_code_usage_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- 3. RLS for promo_code_usage
ALTER TABLE public.promo_code_usage ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own promo usage" 
  ON public.promo_code_usage FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own promo usage" 
  ON public.promo_code_usage FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- 4. Function to increment usage count
CREATE OR REPLACE FUNCTION public.increment_promo_usage(promo_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.promo_codes
  SET usage_count = COALESCE(usage_count, 0) + 1
  WHERE id = promo_id;
END;
$$;

-- 5. Update existing promo codes with default values
UPDATE public.promo_codes 
SET 
  min_order_amount = COALESCE(min_order_amount, 0),
  usage_count = COALESCE(usage_count, 0),
  per_user_limit = COALESCE(per_user_limit, 1),
  start_date = COALESCE(start_date, created_at)
WHERE min_order_amount IS NULL OR usage_count IS NULL;

-- 6. Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_promo_usage_user ON public.promo_code_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_promo_usage_code ON public.promo_code_usage(promo_code_id);
