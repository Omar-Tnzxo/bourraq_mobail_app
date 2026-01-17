-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.app_settings (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  key character varying NOT NULL UNIQUE,
  value text NOT NULL,
  description text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT app_settings_pkey PRIMARY KEY (id)
);
CREATE TABLE public.app_versions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  platform text NOT NULL CHECK (platform = ANY (ARRAY['android'::text, 'ios'::text, 'all'::text])),
  version_number text NOT NULL,
  build_number integer NOT NULL,
  is_force_update boolean DEFAULT false,
  min_supported_version text,
  title_ar text NOT NULL DEFAULT 'تحديث متاح'::text,
  title_en text NOT NULL DEFAULT 'Update Available'::text,
  message_ar text NOT NULL DEFAULT 'يتوفر تحديث جديد للتطبيق'::text,
  message_en text NOT NULL DEFAULT 'A new version of the app is available'::text,
  illustration_url text,
  android_store_url text DEFAULT 'https://play.google.com/store/apps/details?id=com.bourraq.app'::text,
  ios_store_url text DEFAULT 'https://apps.apple.com/app/bourraq/id123456789'::text,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  released_at timestamp with time zone,
  CONSTRAINT app_versions_pkey PRIMARY KEY (id)
);
CREATE TABLE public.area_requests (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid,
  governorate character varying NOT NULL,
  city character varying NOT NULL,
  area_name character varying NOT NULL,
  additional_info text,
  status character varying DEFAULT 'pending'::character varying,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT area_requests_pkey PRIMARY KEY (id),
  CONSTRAINT area_requests_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.areas (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  name_ar character varying NOT NULL,
  name_en character varying NOT NULL,
  city character varying NOT NULL,
  governorate character varying NOT NULL,
  latitude numeric,
  longitude numeric,
  radius_km numeric,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  delivery_fee numeric DEFAULT 25.0,
  CONSTRAINT areas_pkey PRIMARY KEY (id)
);
CREATE TABLE public.banners (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  image_url_ar text NOT NULL,
  image_url_en text,
  action_url text,
  is_external boolean DEFAULT false,
  display_order integer DEFAULT 0,
  start_date timestamp with time zone,
  end_date timestamp with time zone,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT banners_pkey PRIMARY KEY (id)
);
CREATE TABLE public.cancel_reasons (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  text_ar character varying NOT NULL,
  text_en character varying NOT NULL,
  is_active boolean DEFAULT true,
  sort_order integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT cancel_reasons_pkey PRIMARY KEY (id)
);
CREATE TABLE public.cart_items (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  product_id uuid NOT NULL,
  quantity integer NOT NULL DEFAULT 1 CHECK (quantity > 0),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT cart_items_pkey PRIMARY KEY (id),
  CONSTRAINT cart_items_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT cart_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.categories (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name_ar text NOT NULL,
  name_en text NOT NULL,
  image_url text,
  image_url_en text,
  display_order integer DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT categories_pkey PRIMARY KEY (id)
);
CREATE TABLE public.deleted_users (
  id uuid NOT NULL,
  auth_user_id uuid,
  name character varying,
  email character varying,
  phone character varying,
  country character varying,
  city character varying,
  area_id uuid,
  is_banned boolean,
  deletion_reason text,
  deleted_at timestamp with time zone DEFAULT now(),
  original_created_at timestamp with time zone,
  CONSTRAINT deleted_users_pkey PRIMARY KEY (id)
);
CREATE TABLE public.delivery_settings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  area_id uuid,
  free_delivery_threshold numeric DEFAULT 0,
  free_delivery_enabled boolean DEFAULT false,
  delivery_fee numeric DEFAULT 15.00,
  min_order_amount numeric DEFAULT 50.00,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT delivery_settings_pkey PRIMARY KEY (id),
  CONSTRAINT delivery_settings_area_id_fkey FOREIGN KEY (area_id) REFERENCES public.areas(id)
);
CREATE TABLE public.faqs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  question_ar text NOT NULL,
  question_en text NOT NULL,
  answer_ar text NOT NULL,
  answer_en text NOT NULL,
  display_order integer DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT faqs_pkey PRIMARY KEY (id)
);
CREATE TABLE public.favorites (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  product_id uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT favorites_pkey PRIMARY KEY (id),
  CONSTRAINT favorites_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT favorites_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.fcm_tokens (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  device_id text NOT NULL UNIQUE,
  token text NOT NULL,
  platform text NOT NULL CHECK (platform = ANY (ARRAY['android'::text, 'ios'::text])),
  app_version text,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT fcm_tokens_pkey PRIMARY KEY (id),
  CONSTRAINT fcm_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.home_sections (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  section_type text NOT NULL CHECK (section_type = ANY (ARRAY['banners'::text, 'categories'::text, 'products'::text])),
  title_ar text,
  title_en text,
  display_order integer DEFAULT 0,
  is_active boolean DEFAULT true,
  config jsonb DEFAULT '{}'::jsonb,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT home_sections_pkey PRIMARY KEY (id)
);
CREATE TABLE public.notification_preferences (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE,
  order_updates boolean DEFAULT true,
  promotions boolean DEFAULT true,
  stock_alerts boolean DEFAULT true,
  new_products boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT notification_preferences_pkey PRIMARY KEY (id),
  CONSTRAINT notification_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title_ar text NOT NULL,
  title_en text NOT NULL,
  body_ar text NOT NULL,
  body_en text NOT NULL,
  image_url text,
  data jsonb DEFAULT '{}'::jsonb,
  target_type text NOT NULL CHECK (target_type = ANY (ARRAY['all'::text, 'registered'::text, 'guests'::text, 'area'::text, 'user'::text])),
  target_area_id uuid,
  target_user_id uuid,
  sent_count integer DEFAULT 0,
  failed_count integer DEFAULT 0,
  status text DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'sent'::text, 'failed'::text])),
  created_at timestamp with time zone DEFAULT now(),
  scheduled_at timestamp with time zone,
  sent_at timestamp with time zone,
  created_by uuid,
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_target_area_id_fkey FOREIGN KEY (target_area_id) REFERENCES public.areas(id),
  CONSTRAINT notifications_target_user_id_fkey FOREIGN KEY (target_user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.onboarding_screens (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  image_url text NOT NULL,
  title_ar text NOT NULL,
  title_en text NOT NULL,
  description_ar text NOT NULL,
  description_en text NOT NULL,
  display_order integer NOT NULL DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT onboarding_screens_pkey PRIMARY KEY (id)
);
CREATE TABLE public.order_items (
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
  CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id)
);
CREATE TABLE public.order_pilots (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL,
  pilot_id uuid NOT NULL,
  status text DEFAULT 'assigned'::text CHECK (status = ANY (ARRAY['assigned'::text, 'accepted'::text, 'rejected'::text, 'picked_up'::text, 'delivered'::text])),
  assigned_at timestamp with time zone DEFAULT now(),
  accepted_at timestamp with time zone,
  picked_up_at timestamp with time zone,
  delivered_at timestamp with time zone,
  delivery_photo_url text,
  notes text,
  CONSTRAINT order_pilots_pkey PRIMARY KEY (id),
  CONSTRAINT order_pilots_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id),
  CONSTRAINT order_pilots_pilot_id_fkey FOREIGN KEY (pilot_id) REFERENCES public.pilots(id)
);
CREATE TABLE public.order_ratings (
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
CREATE TABLE public.orders (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  address_id uuid NOT NULL,
  address_label character varying,
  address_text text,
  status character varying NOT NULL DEFAULT 'pending'::character varying,
  payment_method character varying NOT NULL DEFAULT 'cash'::character varying,
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
  cancel_reason_id uuid,
  service_fee numeric DEFAULT 0,
  CONSTRAINT orders_pkey PRIMARY KEY (id),
  CONSTRAINT orders_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT orders_cancel_reason_id_fkey FOREIGN KEY (cancel_reason_id) REFERENCES public.cancel_reasons(id)
);
CREATE TABLE public.otp_verifications (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  email character varying NOT NULL,
  otp_code character varying NOT NULL,
  purpose character varying NOT NULL,
  expires_at timestamp with time zone NOT NULL,
  is_used boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT otp_verifications_pkey PRIMARY KEY (id)
);
CREATE TABLE public.phone_number_tracking (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  phone character varying NOT NULL,
  user_id uuid NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT phone_number_tracking_pkey PRIMARY KEY (id),
  CONSTRAINT phone_number_tracking_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.pilot_earnings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  pilot_id uuid NOT NULL,
  order_id uuid,
  amount numeric NOT NULL DEFAULT 0,
  type text NOT NULL CHECK (type = ANY (ARRAY['salary'::text, 'bonus'::text, 'penalty'::text, 'tip'::text])),
  description text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT pilot_earnings_pkey PRIMARY KEY (id),
  CONSTRAINT pilot_earnings_pilot_id_fkey FOREIGN KEY (pilot_id) REFERENCES public.pilots(id),
  CONSTRAINT pilot_earnings_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id)
);
CREATE TABLE public.pilot_locations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  pilot_id uuid NOT NULL UNIQUE,
  order_id uuid,
  latitude numeric NOT NULL,
  longitude numeric NOT NULL,
  heading numeric,
  speed numeric,
  accuracy numeric,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT pilot_locations_pkey PRIMARY KEY (id),
  CONSTRAINT pilot_locations_pilot_id_fkey FOREIGN KEY (pilot_id) REFERENCES public.pilots(id),
  CONSTRAINT pilot_locations_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id)
);
CREATE TABLE public.pilots (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  auth_user_id uuid,
  name text NOT NULL,
  phone text NOT NULL,
  email text,
  area_id uuid,
  is_active boolean DEFAULT true,
  is_available boolean DEFAULT false,
  is_verified boolean DEFAULT false,
  verification_level integer DEFAULT 0,
  id_document_url text,
  license_url text,
  vehicle_photo_url text,
  vehicle_type text DEFAULT 'motorcycle'::text CHECK (vehicle_type = ANY (ARRAY['motorcycle'::text, 'car'::text, 'bicycle'::text])),
  vehicle_plate text,
  total_orders integer DEFAULT 0,
  rating_average numeric DEFAULT 0,
  rating_count integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  last_online timestamp with time zone,
  CONSTRAINT pilots_pkey PRIMARY KEY (id),
  CONSTRAINT pilots_auth_user_id_fkey FOREIGN KEY (auth_user_id) REFERENCES auth.users(id),
  CONSTRAINT pilots_area_id_fkey FOREIGN KEY (area_id) REFERENCES public.areas(id)
);
CREATE TABLE public.popular_searches (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  keyword_ar text NOT NULL,
  keyword_en text NOT NULL,
  display_order integer DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT popular_searches_pkey PRIMARY KEY (id)
);
CREATE TABLE public.products (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name_ar text NOT NULL,
  name_en text NOT NULL,
  description_ar text,
  description_en text,
  price numeric NOT NULL CHECK (price >= 0::numeric),
  old_price numeric,
  image_url text,
  category_id uuid,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  is_best_seller boolean DEFAULT false,
  weight_value numeric,
  weight_unit text DEFAULT 'piece'::text,
  stock_quantity integer DEFAULT 100,
  CONSTRAINT products_pkey PRIMARY KEY (id)
);
CREATE TABLE public.promo_code_usage (
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
CREATE TABLE public.promo_codes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  discount_type text NOT NULL CHECK (discount_type = ANY (ARRAY['percentage'::text, 'fixed'::text, 'free_shipping'::text])),
  discount_value numeric NOT NULL,
  description_ar text,
  description_en text,
  expiry_date timestamp with time zone NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  min_order_amount numeric DEFAULT 0,
  max_discount numeric,
  usage_limit integer,
  usage_count integer DEFAULT 0,
  per_user_limit integer DEFAULT 1,
  start_date timestamp with time zone DEFAULT now(),
  CONSTRAINT promo_codes_pkey PRIMARY KEY (id)
);
CREATE TABLE public.saved_cards (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  card_token text NOT NULL,
  last_four_digits character NOT NULL,
  card_brand character varying NOT NULL DEFAULT 'VISA'::character varying,
  card_label character varying,
  is_default boolean DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT saved_cards_pkey PRIMARY KEY (id),
  CONSTRAINT saved_cards_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.search_history (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  query text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT search_history_pkey PRIMARY KEY (id),
  CONSTRAINT search_history_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.stock_alerts (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  product_id uuid NOT NULL,
  is_notified boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  notified_at timestamp with time zone,
  CONSTRAINT stock_alerts_pkey PRIMARY KEY (id),
  CONSTRAINT stock_alerts_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT stock_alerts_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.user_addresses (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  address_type character varying NOT NULL,
  area_id uuid,
  latitude numeric,
  longitude numeric,
  building_name character varying,
  apartment_number character varying,
  floor_number character varying,
  street_name character varying,
  landmark character varying,
  address_label character varying,
  phone character varying,
  is_default boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT user_addresses_pkey PRIMARY KEY (id),
  CONSTRAINT user_addresses_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT user_addresses_area_id_fkey FOREIGN KEY (area_id) REFERENCES public.areas(id)
);
CREATE TABLE public.users (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  auth_user_id uuid NOT NULL UNIQUE,
  name character varying NOT NULL,
  email character varying NOT NULL UNIQUE,
  phone character varying NOT NULL,
  country character varying DEFAULT 'Egypt'::character varying,
  currency character varying DEFAULT 'EGP'::character varying,
  city character varying,
  area_id uuid,
  is_active boolean DEFAULT true,
  is_banned boolean DEFAULT false,
  is_email_verified boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  last_login timestamp with time zone,
  CONSTRAINT users_pkey PRIMARY KEY (id),
  CONSTRAINT users_auth_user_id_fkey FOREIGN KEY (auth_user_id) REFERENCES auth.users(id),
  CONSTRAINT users_area_id_fkey FOREIGN KEY (area_id) REFERENCES public.areas(id)
);
CREATE TABLE public.wallet_transactions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  wallet_id uuid NOT NULL,
  type USER-DEFINED NOT NULL,
  amount numeric NOT NULL CHECK (amount > 0::numeric),
  balance_after numeric NOT NULL,
  order_id uuid,
  description text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT wallet_transactions_pkey PRIMARY KEY (id),
  CONSTRAINT wallet_transactions_wallet_id_fkey FOREIGN KEY (wallet_id) REFERENCES public.wallets(id),
  CONSTRAINT wallet_transactions_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id)
);
CREATE TABLE public.wallets (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE,
  balance numeric NOT NULL DEFAULT 0.00 CHECK (balance >= 0::numeric),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT wallets_pkey PRIMARY KEY (id),
  CONSTRAINT wallets_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.weight_units (
  code text NOT NULL,
  name_ar text NOT NULL,
  name_en text NOT NULL,
  display_order integer DEFAULT 0,
  CONSTRAINT weight_units_pkey PRIMARY KEY (code)
);