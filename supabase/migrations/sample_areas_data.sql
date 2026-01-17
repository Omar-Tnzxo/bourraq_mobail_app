-- =============================================================================
-- Sample Areas Data for Geofencing
-- Run this script in Supabase SQL Editor to add sample supported areas
-- =============================================================================

-- Insert sample areas with lat/lng and radius
INSERT INTO public.areas (name_ar, name_en, city, governorate, latitude, longitude, radius_km, delivery_fee, is_active)
VALUES
  -- 6 October Areas
  ('حدائق أكتوبر', 'Hadayek October', '6 أكتوبر', 'الجيزة', 29.9602, 30.9271, 3.5, 25.0, true),
  ('ابني بيتك 2', 'Ebny Betak 2', '6 أكتوبر', 'الجيزة', 29.9501, 30.9112, 2.5, 25.0, true),
  ('ابني بيتك 3', 'Ebny Betak 3', '6 أكتوبر', 'الجيزة', 29.9450, 30.9050, 2.5, 25.0, true),
  ('ابني بيتك 4', 'Ebny Betak 4', '6 أكتوبر', 'الجيزة', 29.9400, 30.8980, 2.5, 25.0, true),
  ('دار مصر - القرنفل', 'Dar Misr - Qarnafil', '6 أكتوبر', 'الجيزة', 29.9380, 30.9320, 2.0, 30.0, true),
  ('الحي العاشر', '10th District', '6 أكتوبر', 'الجيزة', 29.9720, 30.9410, 2.0, 25.0, true),
  ('الحي الحادي عشر', '11th District', '6 أكتوبر', 'الجيزة', 29.9800, 30.9500, 2.0, 25.0, true)
ON CONFLICT (id) DO NOTHING;

-- Verify the data
SELECT id, name_ar, name_en, latitude, longitude, radius_km, delivery_fee, is_active 
FROM public.areas 
ORDER BY name_ar;

-- =============================================================================
-- How to Add More Areas:
-- 1. Get the center coordinates (latitude, longitude) from Google Maps
-- 2. Decide the radius in kilometers
-- 3. Set the delivery fee
-- 4. Set is_active to true
-- 
-- Example:
-- INSERT INTO public.areas (name_ar, name_en, city, governorate, latitude, longitude, radius_km, delivery_fee, is_active)
-- VALUES ('اسم المنطقة بالعربي', 'Area Name in English', 'City', 'Governorate', 29.1234, 30.5678, 3.0, 25.0, true);
-- =============================================================================
