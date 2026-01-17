-- Migration: 016_pilots_and_tracking.sql
-- Purpose: Add tables for pilots system and real-time tracking
-- Created: 2026-01-15
-- Note: Pilots manage their data via Dashboard (not the customer app)

-- ===========================================
-- 1. Pilots Table
-- Stores pilot/driver information
-- ===========================================
CREATE TABLE IF NOT EXISTS public.pilots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  name text NOT NULL,
  phone text NOT NULL,
  email text,
  -- Location & Area
  area_id uuid REFERENCES public.areas(id),
  -- Status
  is_active boolean DEFAULT true,
  is_available boolean DEFAULT false,  -- Online/Offline toggle
  is_verified boolean DEFAULT false,
  verification_level integer DEFAULT 0,
  -- Documents (URLs to Supabase Storage)
  id_document_url text,
  license_url text,
  vehicle_photo_url text,
  -- Vehicle info
  vehicle_type text DEFAULT 'motorcycle' CHECK (vehicle_type IN ('motorcycle', 'car', 'bicycle')),
  vehicle_plate text,
  -- Stats
  total_orders integer DEFAULT 0,
  rating_average numeric DEFAULT 0,
  rating_count integer DEFAULT 0,
  -- Timestamps
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  last_online timestamptz
);

CREATE INDEX IF NOT EXISTS idx_pilots_area ON public.pilots(area_id);
CREATE INDEX IF NOT EXISTS idx_pilots_available ON public.pilots(is_available, is_active);

-- ===========================================
-- 2. Pilot Locations Table
-- Real-time location for tracking
-- Updated frequently by pilot's device
-- ===========================================
CREATE TABLE IF NOT EXISTS public.pilot_locations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pilot_id uuid NOT NULL REFERENCES public.pilots(id) ON DELETE CASCADE,
  order_id uuid REFERENCES public.orders(id) ON DELETE SET NULL,  -- Current active order
  -- Location data
  latitude numeric NOT NULL,
  longitude numeric NOT NULL,
  heading numeric,        -- Direction in degrees
  speed numeric,          -- Speed in km/h
  accuracy numeric,       -- GPS accuracy in meters
  -- Timestamp
  updated_at timestamptz DEFAULT now(),
  -- Ensure one location per pilot
  CONSTRAINT pilot_locations_pilot_unique UNIQUE (pilot_id)
);

-- Enable real-time for this table
-- This allows customers to subscribe to location updates
ALTER PUBLICATION supabase_realtime ADD TABLE public.pilot_locations;

-- ===========================================
-- 3. Order Pilots Table (Junction Table)
-- Connects orders to assigned pilots
-- Supports multi-pilot orders
-- ===========================================
CREATE TABLE IF NOT EXISTS public.order_pilots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  pilot_id uuid NOT NULL REFERENCES public.pilots(id) ON DELETE CASCADE,
  -- Status
  status text DEFAULT 'assigned' CHECK (status IN ('assigned', 'accepted', 'rejected', 'picked_up', 'delivered')),
  -- Timestamps
  assigned_at timestamptz DEFAULT now(),
  accepted_at timestamptz,
  picked_up_at timestamptz,
  delivered_at timestamptz,
  -- Delivery proof
  delivery_photo_url text,  -- Photo at customer location
  -- Notes
  notes text,
  CONSTRAINT order_pilots_unique UNIQUE (order_id, pilot_id)
);

CREATE INDEX IF NOT EXISTS idx_order_pilots_order ON public.order_pilots(order_id);
CREATE INDEX IF NOT EXISTS idx_order_pilots_pilot ON public.order_pilots(pilot_id);
CREATE INDEX IF NOT EXISTS idx_order_pilots_status ON public.order_pilots(status);

-- ===========================================
-- 4. Pilot Earnings Table (for future)
-- Track earnings per pilot (currently salary-based)
-- ===========================================
CREATE TABLE IF NOT EXISTS public.pilot_earnings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pilot_id uuid NOT NULL REFERENCES public.pilots(id) ON DELETE CASCADE,
  order_id uuid REFERENCES public.orders(id) ON DELETE SET NULL,
  amount numeric NOT NULL DEFAULT 0,
  type text NOT NULL CHECK (type IN ('salary', 'bonus', 'penalty', 'tip')),
  description text,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_pilot_earnings_pilot ON public.pilot_earnings(pilot_id);

-- ===========================================
-- RLS Policies
-- ===========================================

-- Pilots: Read-only for customers (they don't need to see pilot details)
ALTER TABLE public.pilots ENABLE ROW LEVEL SECURITY;

-- Customers can only see basic pilot info for their orders
CREATE POLICY "Users can view pilot assigned to their orders"
  ON public.pilots FOR SELECT
  USING (
    id IN (
      SELECT op.pilot_id FROM public.order_pilots op
      JOIN public.orders o ON o.id = op.order_id
      WHERE o.user_id = (SELECT id FROM public.users WHERE auth_user_id = auth.uid())
    )
  );

-- Pilot Locations: Customers can see location for their active orders
ALTER TABLE public.pilot_locations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view pilot location for their orders"
  ON public.pilot_locations FOR SELECT
  USING (
    order_id IN (
      SELECT o.id FROM public.orders o
      WHERE o.user_id = (SELECT id FROM public.users WHERE auth_user_id = auth.uid())
      AND o.status IN ('confirmed', 'preparing', 'on_the_way')
    )
  );

-- Order Pilots: Customers can view their order assignments
ALTER TABLE public.order_pilots ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view pilots assigned to their orders"
  ON public.order_pilots FOR SELECT
  USING (
    order_id IN (
      SELECT o.id FROM public.orders o
      WHERE o.user_id = (SELECT id FROM public.users WHERE auth_user_id = auth.uid())
    )
  );

-- Pilot Earnings: Not accessible to customers
ALTER TABLE public.pilot_earnings ENABLE ROW LEVEL SECURITY;
-- No policies for customers (dashboard only)
