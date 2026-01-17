-- تحديث RLS Policies لجدول user_addresses
-- يجب تنفيذ هذا في Supabase SQL Editor

-- أولاً: حذف الـ policies القديمة
DROP POLICY IF EXISTS "Users can view own addresses" ON public.user_addresses;
DROP POLICY IF EXISTS "Users can insert own addresses" ON public.user_addresses;
DROP POLICY IF EXISTS "Users can update own addresses" ON public.user_addresses;
DROP POLICY IF EXISTS "Users can delete own addresses" ON public.user_addresses;

-- ثانياً: إنشاء policies جديدة تستخدم subquery
-- (لأن user_id في user_addresses يشير لـ public.users.id وليس auth.users.id)

CREATE POLICY "Users can view own addresses" ON public.user_addresses
    FOR SELECT
    USING (user_id IN (SELECT id FROM public.users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can insert own addresses" ON public.user_addresses
    FOR INSERT
    WITH CHECK (user_id IN (SELECT id FROM public.users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can update own addresses" ON public.user_addresses
    FOR UPDATE
    USING (user_id IN (SELECT id FROM public.users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can delete own addresses" ON public.user_addresses
    FOR DELETE
    USING (user_id IN (SELECT id FROM public.users WHERE auth_user_id = auth.uid()));
