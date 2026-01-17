-- Create tables for Account Screen features: Promo Codes, FAQs, and Area Requests

-- 1. Promo Codes Table
create table if not exists public.promo_codes (
    id uuid default gen_random_uuid() primary key,
    code text not null unique,
    discount_type text not null check (discount_type in ('percentage', 'fixed')),
    discount_value numeric not null,
    description_ar text,
    description_en text,
    expiry_date timestamp with time zone not null,
    is_active boolean default true,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. FAQs Table
create table if not exists public.faqs (
    id uuid default gen_random_uuid() primary key,
    question_ar text not null,
    question_en text not null,
    answer_ar text not null,
    answer_en text not null,
    display_order integer default 0,
    is_active boolean default true,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. Area Requests Table
create table if not exists public.area_requests (
    id uuid default gen_random_uuid() primary key,
    user_id uuid references auth.users(id),
    area_name text not null,
    notes text,
    status text default 'pending' check (status in ('pending', 'reviewed', 'approved', 'rejected')),
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS (Safe to run multiple times)
alter table public.promo_codes enable row level security;
alter table public.faqs enable row level security;
alter table public.area_requests enable row level security;

-- Policies (Drop first to avoid exists error, or use specific naming to check)

-- Promo Codes
drop policy if exists "Promo codes are viewable by everyone" on public.promo_codes;
create policy "Promo codes are viewable by everyone"
    on public.promo_codes for select
    using (true);

-- FAQs
drop policy if exists "FAQs are viewable by everyone" on public.faqs;
create policy "FAQs are viewable by everyone"
    on public.faqs for select
    using (true);

-- Area Requests
drop policy if exists "Users can insert their own area requests" on public.area_requests;
create policy "Users can insert their own area requests"
    on public.area_requests for insert
    with check (auth.uid() = user_id);

drop policy if exists "Users can view their own area requests" on public.area_requests;
create policy "Users can view their own area requests"
    on public.area_requests for select
    using (auth.uid() = user_id);

-- Initial Mock Data (Using ON CONFLICT to avoid errors on duplicate runs)
insert into public.promo_codes (code, discount_type, discount_value, description_ar, description_en, expiry_date)
values
    ('WELCOME50', 'percentage', 50, 'خصم ترحيبي خاص للأعضاء الجدد', 'Special welcome discount for new members', now() + interval '1 year'),
    ('FREESHIP', 'fixed', 0, 'توصيل مجاني للطلبات فوق 200 جنيه', 'Free delivery for orders over 200 EGP', now() + interval '1 year')
on conflict (code) do nothing;

-- FAQs don't have a unique constraint other than ID, so we check existence or just delete and re-insert if standard mock data
-- For simplicity in dev, we can leave as is or add a check. Since it's mock data, let's keep it simple.
-- To prevent duplicating FAQs on re-runs during dev without unique keys, we can clear and re-insert or ignore.
-- Better strategy: truncate if it's just mock data tables during dev setup, OR just insert if empty.
-- Here we'll just insert if table is empty to avoid duplicates.
do $$
begin
    if not exists (select 1 from public.faqs) then
        insert into public.faqs (question_ar, question_en, answer_ar, answer_en, display_order)
        values
            ('كيف يمكنني تتبع طلبي؟', 'How can I track my order?', 'يمكنك تتبع طلبك من خلال الذهاب إلى قسم "طلباتي" واختيار الطلب النشط لـعرض تفاصيل التتبع المباشر.', 'You can track your order by going to "My Orders" section and selecting the active order to view live tracking details.', 1),
            ('ما هي طرق الدفع المتاحة؟', 'What payment methods are accepted?', 'نقبل الدفع نقداً عند الاستلام، وعن طريق البطاقات الائتمانية (Visa/Mastercard) من خلال التطبيق.', 'We accept Cash on Delivery (COD) and Credit/Debit Cards (Visa/Mastercard) via the app.', 2),
            ('هل يمكنني تعديل الطلب بعد تأكيده؟', 'Can I edit my order after confirmation?', 'للأسف لا يمكن تعديل الطلب بعد تأكيده، ولكن يمكنك إلغاؤه وإعادة الطلب إذا كان لا يزال في مرحلة "قيد المراجعة".', 'Unfortunately, orders cannot be edited once confirmed. However, you can cancel and reorder if it''s still in "Pending" status.', 3);
    end if;
end $$;
