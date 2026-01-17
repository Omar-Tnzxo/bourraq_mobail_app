-- Bourraq App - Row Level Security (RLS) Policies
-- Authentication & User Management

-- =====================================================
-- USERS TABLE RLS
-- =====================================================
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Users can read their own profile
CREATE POLICY "Users can view own profile"
    ON public.users
    FOR SELECT
    USING (auth.uid() = auth_user_id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
    ON public.users
    FOR UPDATE
    USING (auth.uid() = auth_user_id);

-- Only authenticated users can insert (via Edge Function)
CREATE POLICY "Authenticated users can insert"
    ON public.users
    FOR INSERT
    WITH CHECK (auth.uid() = auth_user_id);

-- Users can soft-delete their own account (moves to deleted_users)
CREATE POLICY "Users can delete own account"
    ON public.users
    FOR DELETE
    USING (auth.uid() = auth_user_id);

-- =====================================================
-- DELETED_USERS TABLE RLS
-- =====================================================
ALTER TABLE public.deleted_users ENABLE ROW LEVEL SECURITY;

-- No one can read deleted users (admin only via service_role)
CREATE POLICY "No public access to deleted users"
    ON public.deleted_users
    FOR ALL
    USING (FALSE);

-- =====================================================
-- OTP_VERIFICATIONS TABLE RLS
-- =====================================================
ALTER TABLE public.otp_verifications ENABLE ROW LEVEL SECURITY;

-- No direct access - only via Edge Functions
CREATE POLICY "No public access to OTP table"
    ON public.otp_verifications
    FOR ALL
    USING (FALSE);

-- =====================================================
-- AREAS TABLE RLS
-- =====================================================
ALTER TABLE public.areas ENABLE ROW LEVEL SECURITY;

-- Everyone can read areas (public data)
CREATE POLICY "Anyone can view areas"
    ON public.areas
    FOR SELECT
    USING (TRUE);

-- Only admins can modify (via service_role)
CREATE POLICY "Only admins can modify areas"
    ON public.areas
    FOR ALL
    USING (FALSE);

-- =====================================================
-- AREA_REQUESTS TABLE RLS
-- =====================================================
ALTER TABLE public.area_requests ENABLE ROW LEVEL SECURITY;

-- Users can create area requests
CREATE POLICY "Users can create area requests"
    ON public.area_requests
    FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- Users can view their own requests
CREATE POLICY "Users can view own area requests"
    ON public.area_requests
    FOR SELECT
    USING (user_id IN (
        SELECT id FROM public.users WHERE auth_user_id = auth.uid()
    ));

-- =====================================================
-- USER_ADDRESSES TABLE RLS
-- =====================================================
ALTER TABLE public.user_addresses ENABLE ROW LEVEL SECURITY;

-- Users can read their own addresses
CREATE POLICY "Users can view own addresses"
    ON public.user_addresses
    FOR SELECT
    USING (user_id IN (
        SELECT id FROM public.users WHERE auth_user_id = auth.uid()
    ));

-- Users can create their own addresses
CREATE POLICY "Users can create own addresses"
    ON public.user_addresses
    FOR INSERT
    WITH CHECK (user_id IN (
        SELECT id FROM public.users WHERE auth_user_id = auth.uid()
    ));

-- Users can update their own addresses
CREATE POLICY "Users can update own addresses"
    ON public.user_addresses
    FOR UPDATE
    USING (user_id IN (
        SELECT id FROM public.users WHERE auth_user_id = auth.uid()
    ));

-- Users can delete their own addresses
CREATE POLICY "Users can delete own addresses"
    ON public.user_addresses
    FOR DELETE
    USING (user_id IN (
        SELECT id FROM public.users WHERE auth_user_id = auth.uid()
    ));

-- =====================================================
-- PHONE_NUMBER_TRACKING TABLE RLS
-- =====================================================
ALTER TABLE public.phone_number_tracking ENABLE ROW LEVEL SECURITY;

-- No public access (managed via triggers)
CREATE POLICY "No public access to phone tracking"
    ON public.phone_number_tracking
    FOR ALL
    USING (FALSE);
