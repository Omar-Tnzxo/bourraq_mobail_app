-- 009_favorites.sql
-- Create minimal Products table and Favorites table

-- 1. Minimal Products Table (for Favorites & Listings)
create table if not exists public.products (
    id uuid default gen_random_uuid() primary key,
    name_ar text not null,
    name_en text not null,
    description_ar text,
    description_en text,
    price numeric not null check (price >= 0),
    old_price numeric, -- Optional, for discounts
    image_url text,
    category_id uuid, -- Can be linked later when categories are fully implemented
    is_active boolean default true,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. Favorites Table
create table if not exists public.favorites (
    id uuid default gen_random_uuid() primary key,
    user_id uuid references auth.users(id) on delete cascade not null,
    product_id uuid references public.products(id) on delete cascade not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    unique(user_id, product_id) -- Prevent duplicate favorites
);

-- Enable RLS
alter table public.products enable row level security;
alter table public.favorites enable row level security;

-- Policies

-- Products: Viewable by everyone
drop policy if exists "Products are viewable by everyone" on public.products;
create policy "Products are viewable by everyone"
    on public.products for select
    using (true);

-- Favorites: Users can view/add/delete their own favorites
drop policy if exists "Users can view their own favorites" on public.favorites;
create policy "Users can view their own favorites"
    on public.favorites for select
    using (auth.uid() = user_id);

drop policy if exists "Users can add their own favorites" on public.favorites;
create policy "Users can add their own favorites"
    on public.favorites for insert
    with check (auth.uid() = user_id);

drop policy if exists "Users can remove their own favorites" on public.favorites;
create policy "Users can remove their own favorites"
    on public.favorites for delete
    using (auth.uid() = user_id);

-- Mock Data for Products (to test favorites)
insert into public.products (name_ar, name_en, price, old_price, image_url)
values
    ('طماطم طازجة (1 كجم)', 'Fresh Tomatoes (1kg)', 15.0, 20.0, 'https://placehold.co/400x400/png?text=Tomatoes'),
    ('خيار بلدي (1 كجم)', 'Baladi Cucumber (1kg)', 12.0, 15.0, 'https://placehold.co/400x400/png?text=Cucumber'),
    ('بطاطس تحمير (1 كجم)', 'Frying Potatoes (1kg)', 18.0, 22.0, 'https://placehold.co/400x400/png?text=Potatoes'),
    ('جزر (1 كجم)', 'Carrots (1kg)', 10.0, 12.0, 'https://placehold.co/400x400/png?text=Carrots'),
    ('فلفل ألوان (500 جم)', 'Colored Pepper (500g)', 25.0, 30.0, 'https://placehold.co/400x400/png?text=Pepper')
on conflict do nothing; -- No unique constraint on name, but just a safety pattern
