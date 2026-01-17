-- Add delivery_fee column to areas table
ALTER TABLE public.areas 
ADD COLUMN IF NOT EXISTS delivery_fee NUMERIC DEFAULT 25.0;

-- Update existing areas with different delivery fees for demonstration
UPDATE public.areas SET delivery_fee = 20.0 WHERE name_en IN ('Ebny Beitak 2', 'Ebny Beitak 3', 'Ebny Beitak 4', 'Ebny Beitak 5', 'Ebny Beitak 7');
UPDATE public.areas SET delivery_fee = 30.0 WHERE name_en = 'Hadayek October';
UPDATE public.areas SET delivery_fee = 35.0 WHERE name_en IN ('Dahshur', 'Militia');
UPDATE public.areas SET delivery_fee = 25.0 WHERE name_en IN ('Horus Compound', 'Dar Misr Compound', 'Stan Misr Compound');
UPDATE public.areas SET delivery_fee = 40.0 WHERE name_en = '390 Feddan Project';
