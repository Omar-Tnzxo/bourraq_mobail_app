-- إنشاء جداول Orders و Order Items
-- يجب تنفيذ هذا في Supabase SQL Editor

-- جدول الطلبات
CREATE TABLE IF NOT EXISTS public.orders (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  address_id uuid NOT NULL,
  address_label character varying,
  address_text text,
  status character varying NOT NULL DEFAULT 'pending',
  payment_method character varying NOT NULL DEFAULT 'cash',
  subtotal numeric NOT NULL DEFAULT 0,
  delivery_fee numeric NOT NULL DEFAULT 0,
  discount numeric NOT NULL DEFAULT 0,
  total numeric NOT NULL DEFAULT 0,
  coupon_code character varying,
  notes text,
  is_scheduled boolean DEFAULT false,
  scheduled_time timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT orders_pkey PRIMARY KEY (id),
  CONSTRAINT orders_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);

-- جدول عناصر الطلب
CREATE TABLE IF NOT EXISTS public.order_items (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  order_id uuid NOT NULL,
  product_id character varying NOT NULL,
  product_name character varying NOT NULL,
  product_image text,
  price numeric NOT NULL DEFAULT 0,
  quantity integer NOT NULL DEFAULT 1,
  total_price numeric NOT NULL DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT order_items_pkey PRIMARY KEY (id),
  CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE
);

-- جدول تقييمات الطلبات
CREATE TABLE IF NOT EXISTS public.order_ratings (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  order_id uuid NOT NULL,
  user_id uuid NOT NULL,
  rating integer NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT order_ratings_pkey PRIMARY KEY (id),
  CONSTRAINT order_ratings_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id),
  CONSTRAINT order_ratings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);

-- تفعيل RLS
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_ratings ENABLE ROW LEVEL SECURITY;

-- RLS Policies للـ orders
CREATE POLICY "Users can view own orders" ON public.orders
    FOR SELECT
    USING (user_id IN (SELECT id FROM public.users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can create own orders" ON public.orders
    FOR INSERT
    WITH CHECK (user_id IN (SELECT id FROM public.users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can update own orders" ON public.orders
    FOR UPDATE
    USING (user_id IN (SELECT id FROM public.users WHERE auth_user_id = auth.uid()));

-- RLS Policies للـ order_items
CREATE POLICY "Users can view own order items" ON public.order_items
    FOR SELECT
    USING (order_id IN (SELECT id FROM public.orders WHERE user_id IN (SELECT id FROM public.users WHERE auth_user_id = auth.uid())));

CREATE POLICY "Users can create order items" ON public.order_items
    FOR INSERT
    WITH CHECK (order_id IN (SELECT id FROM public.orders WHERE user_id IN (SELECT id FROM public.users WHERE auth_user_id = auth.uid())));

-- RLS Policies للـ order_ratings
CREATE POLICY "Users can view own ratings" ON public.order_ratings
    FOR SELECT
    USING (user_id IN (SELECT id FROM public.users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can create ratings" ON public.order_ratings
    FOR INSERT
    WITH CHECK (user_id IN (SELECT id FROM public.users WHERE auth_user_id = auth.uid()));
