-- ============================================
-- Promo Codes System Migration
-- Run this in Supabase SQL Editor
-- ============================================

-- Create promo_codes table
CREATE TABLE IF NOT EXISTS public.promo_codes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  discount_type text NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
  discount_value numeric NOT NULL CHECK (discount_value > 0),
  min_order_amount numeric DEFAULT 0,
  max_discount numeric, -- for percentage type, cap the max discount
  usage_limit integer, -- total uses allowed (null = unlimited)
  usage_count integer DEFAULT 0,
  per_user_limit integer DEFAULT 1, -- uses per user
  start_date timestamp with time zone DEFAULT now(),
  end_date timestamp with time zone,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT promo_codes_pkey PRIMARY KEY (id)
);

-- Create promo_code_usage table to track per-user usage
CREATE TABLE IF NOT EXISTS public.promo_code_usage (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  promo_code_id uuid NOT NULL,
  user_id uuid NOT NULL,
  order_id uuid,
  discount_amount numeric NOT NULL,
  used_at timestamp with time zone DEFAULT now(),
  CONSTRAINT promo_code_usage_pkey PRIMARY KEY (id),
  CONSTRAINT promo_code_usage_promo_code_id_fkey FOREIGN KEY (promo_code_id) REFERENCES public.promo_codes(id),
  CONSTRAINT promo_code_usage_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

-- RLS Policies for promo_codes (public read for active codes)
ALTER TABLE public.promo_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read active promo codes" 
  ON public.promo_codes FOR SELECT 
  USING (is_active = true AND (end_date IS NULL OR end_date > now()));

-- RLS for promo_code_usage (users can only see their own usage)
ALTER TABLE public.promo_code_usage ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own promo usage" 
  ON public.promo_code_usage FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own promo usage" 
  ON public.promo_code_usage FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- Insert sample promo codes
INSERT INTO public.promo_codes (code, discount_type, discount_value, min_order_amount, max_discount, usage_limit, is_active)
VALUES 
  ('BOURRAQ10', 'percentage', 10, 50, 100, NULL, true),
  ('WELCOME20', 'percentage', 20, 100, 200, 1000, true),
  ('SAVE50', 'fixed', 50, 200, NULL, 500, true);

-- Insert default delivery settings if not exists
INSERT INTO public.delivery_settings (area_id, free_delivery_threshold, free_delivery_enabled, delivery_fee, min_order_amount, is_active)
SELECT NULL, 300, true, 15.00, 50.00, true
WHERE NOT EXISTS (SELECT 1 FROM public.delivery_settings WHERE area_id IS NULL);
