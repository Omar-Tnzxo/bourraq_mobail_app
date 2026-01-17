-- =====================================================
-- CART SYSTEM MIGRATION
-- Run this in Supabase SQL Editor
-- =====================================================

-- 1. ADD WEIGHT AND STOCK COLUMNS TO PRODUCTS
-- =====================================================
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS weight_value numeric,
ADD COLUMN IF NOT EXISTS weight_unit text DEFAULT 'piece',
ADD COLUMN IF NOT EXISTS stock_quantity integer DEFAULT 100;

-- Weight unit options: kg, g, mg, l, ml, piece, pack, box, dozen, etc.
COMMENT ON COLUMN public.products.weight_unit IS 
'Weight/size unit: kg, g, mg, l, ml, piece, pack, box, dozen, bundle, carton, bottle, can, bag';

-- 2. CREATE CART_ITEMS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.cart_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  quantity integer NOT NULL DEFAULT 1 CHECK (quantity > 0),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, product_id)
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_cart_items_user_id ON public.cart_items(user_id);

-- 3. CREATE DELIVERY_SETTINGS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.delivery_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  area_id uuid REFERENCES public.areas(id) ON DELETE CASCADE,
  free_delivery_threshold numeric DEFAULT 0,
  free_delivery_enabled boolean DEFAULT false,
  delivery_fee numeric DEFAULT 15.00,
  min_order_amount numeric DEFAULT 50.00,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- NULL area_id = default settings for all areas
COMMENT ON COLUMN public.delivery_settings.area_id IS 
'NULL = default for all areas, otherwise specific to this area';

-- 4. ROW LEVEL SECURITY
-- =====================================================

-- Cart Items RLS
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own cart" ON public.cart_items
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert to own cart" ON public.cart_items
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own cart" ON public.cart_items
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete from own cart" ON public.cart_items
  FOR DELETE USING (auth.uid() = user_id);

-- Delivery Settings RLS (public read)
ALTER TABLE public.delivery_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read delivery settings" ON public.delivery_settings
  FOR SELECT TO authenticated, anon USING (is_active = true);

-- 5. INSERT DEFAULT DELIVERY SETTINGS
-- =====================================================
INSERT INTO public.delivery_settings (area_id, free_delivery_threshold, free_delivery_enabled, delivery_fee, min_order_amount)
VALUES (NULL, 300.00, true, 15.00, 50.00)
ON CONFLICT DO NOTHING;

-- 6. CREATE WEIGHT UNITS REFERENCE TABLE (OPTIONAL)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.weight_units (
  code text PRIMARY KEY,
  name_ar text NOT NULL,
  name_en text NOT NULL,
  display_order integer DEFAULT 0
);

INSERT INTO public.weight_units (code, name_ar, name_en, display_order) VALUES
('kg', 'كيلو', 'Kilogram', 1),
('g', 'جرام', 'Gram', 2),
('mg', 'ملليجرام', 'Milligram', 3),
('l', 'لتر', 'Liter', 4),
('ml', 'ملي', 'Milliliter', 5),
('piece', 'حبة', 'Piece', 6),
('pack', 'عبوة', 'Pack', 7),
('box', 'علبة', 'Box', 8),
('dozen', 'درزن', 'Dozen', 9),
('bundle', 'ربطة', 'Bundle', 10),
('bottle', 'زجاجة', 'Bottle', 11),
('can', 'علبة معدنية', 'Can', 12),
('bag', 'كيس', 'Bag', 13),
('carton', 'كرتونة', 'Carton', 14)
ON CONFLICT (code) DO NOTHING;

-- =====================================================
-- DONE! Run this migration in Supabase SQL Editor
-- =====================================================
