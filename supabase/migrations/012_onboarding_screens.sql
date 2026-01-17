-- 012_onboarding_screens.sql
-- Create table for dynamic onboarding screens
-- Per PROJECT_TASKS.md: "Onboarding screens (max 4 screens, dynamic from database)"

create table if not exists public.onboarding_screens (
    id uuid default gen_random_uuid() primary key,
    image_url text not null,
    title_ar text not null,
    title_en text not null,
    description_ar text not null,
    description_en text not null,
    display_order integer not null default 0,
    is_active boolean default true,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.onboarding_screens enable row level security;

-- Policy: Viewable by everyone (including unauthenticated users)
drop policy if exists "Onboarding screens are viewable by everyone" on public.onboarding_screens;
create policy "Onboarding screens are viewable by everyone"
    on public.onboarding_screens for select
    using (true);

-- Insert default onboarding screens (matching current static content)
insert into public.onboarding_screens (image_url, title_ar, title_en, description_ar, description_en, display_order)
values
    (
        'assets/oneboarding/online_order.png',
        'تسوق بسهولة',
        'Shop Easily',
        'تصفح آلاف المنتجات من متاجر مختلفة في مكان واحد',
        'Browse thousands of products from different stores in one place',
        1
    ),
    (
        'assets/oneboarding/fast_delivery_motorcycle.png',
        'توصيل سريع',
        'Fast Delivery',
        'استلم طلباتك في أقل من 30 دقيقة',
        'Receive your orders in less than 30 minutes',
        2
    ),
    (
        'assets/oneboarding/order_tracking.png',
        'تتبع طلبك',
        'Track Your Order',
        'تابع طلبك لحظة بلحظة حتى يصل إليك',
        'Track your order live until it reaches you',
        3
    )
on conflict do nothing;
