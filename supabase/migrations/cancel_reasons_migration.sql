-- Cancel Reasons Migration
-- Run this in Supabase SQL Editor

-- 1. Create cancel_reasons table
CREATE TABLE IF NOT EXISTS public.cancel_reasons (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  text_ar VARCHAR(255) NOT NULL,
  text_en VARCHAR(255) NOT NULL,
  is_active BOOLEAN DEFAULT true,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.cancel_reasons ENABLE ROW LEVEL SECURITY;

-- Allow all users to read
CREATE POLICY "Allow read access to cancel_reasons" ON public.cancel_reasons
  FOR SELECT USING (true);

-- 2. Add cancel_reason_id to orders table
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS cancel_reason_id UUID REFERENCES public.cancel_reasons(id);

-- 3. Insert default cancel reasons
INSERT INTO public.cancel_reasons (text_ar, text_en, sort_order) VALUES
  ('غيرت رأيي، لم أعد أحتاج الطلب', 'I changed my mind. I don''t need the order anymore', 1),
  ('طلبت بالخطأ', 'I placed the order by mistake', 2),
  ('أريد تعديل المنتجات', 'I need to modify my ordered products', 3),
  ('أريد تغيير عنوان التوصيل', 'I need to change the delivery address', 4),
  ('أريد تغيير طريقة الدفع', 'I need to change the payment method', 5),
  ('الطلب يستغرق وقتاً طويلاً', 'The order is taking too long to arrive', 6),
  ('سبب آخر', 'Other', 7);
