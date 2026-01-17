-- 011_home_tables.sql
-- Create tables for Home Screen: Banners and Categories
-- Per requirements_qa.md #88, #131, #26, #64

-- 1. Categories Table
create table if not exists public.categories (
    id uuid default gen_random_uuid() primary key,
    name_ar text not null,
    name_en text not null,
    image_url text,
    image_url_en text, -- Optional separate English image
    display_order integer default 0,
    is_active boolean default true,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. Banners Table (per requirements_qa.md #131)
create table if not exists public.banners (
    id uuid default gen_random_uuid() primary key,
    image_url_ar text not null,
    image_url_en text, -- Optional, falls back to AR if null
    action_url text, -- Internal or external link
    is_external boolean default false,
    display_order integer default 0,
    start_date timestamp with time zone,
    end_date timestamp with time zone,
    is_active boolean default true,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. Update Products Table to link to Categories
alter table public.products
add column if not exists category_id uuid references public.categories(id) on delete set null;

-- Add is_best_seller column to products
alter table public.products
add column if not exists is_best_seller boolean default false;

-- Enable RLS
alter table public.categories enable row level security;
alter table public.banners enable row level security;

-- Policies

-- Categories: Viewable by everyone
drop policy if exists "Categories are viewable by everyone" on public.categories;
create policy "Categories are viewable by everyone"
    on public.categories for select
    using (true);

-- Banners: Viewable by everyone
drop policy if exists "Banners are viewable by everyone" on public.banners;
create policy "Banners are viewable by everyone"
    on public.banners for select
    using (true);

-- Mock Data for Categories
insert into public.categories (name_ar, name_en, display_order, image_url)
values
    ('خضروات وفواكه', 'Fruits & Vegetables', 1, 'https://placehold.co/200x200/87BF54/white?text=🥬'),
    ('ألبان وبيض', 'Dairy & Eggs', 2, 'https://placehold.co/200x200/F5F5DC/333?text=🥛'),
    ('مشروبات', 'Beverages', 3, 'https://placehold.co/200x200/4169E1/white?text=🥤'),
    ('وجبات خفيفة', 'Snacks', 4, 'https://placehold.co/200x200/FFD700/333?text=🍿'),
    ('مخبوزات وحلويات', 'Bakeries & Desserts', 5, 'https://placehold.co/200x200/D2691E/white?text=🥐'),
    ('لحوم ودواجن', 'Meat & Poultry', 6, 'https://placehold.co/200x200/8B0000/white?text=🍖')
on conflict do nothing;

-- Mock Data for Banners
insert into public.banners (image_url_ar, action_url, display_order, is_active)
values
    ('https://placehold.co/800x300/113511/white?text=عروض+خاصة', '/products?filter=offers', 1, true),
    ('https://placehold.co/800x300/87BF54/white?text=منتجات+جديدة', '/products?filter=new', 2, true),
    ('https://placehold.co/800x300/226923/white?text=التوصيل+المجاني', '/info/free-delivery', 3, true)
on conflict do nothing;

-- Update existing products with category and best_seller flag
update public.products 
set category_id = (select id from public.categories where name_en = 'Fruits & Vegetables' limit 1),
    is_best_seller = true
where name_en like '%Tomatoes%' or name_en like '%Cucumber%' or name_en like '%Potatoes%';

update public.products 
set category_id = (select id from public.categories where name_en = 'Fruits & Vegetables' limit 1),
    is_best_seller = false
where name_en like '%Carrots%' or name_en like '%Pepper%';
