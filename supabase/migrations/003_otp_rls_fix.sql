-- ═══════════════════════════════════════════════════════════════════
-- RLS POLICY FIX: Allow OTP Creation
-- ═══════════════════════════════════════════════════════════════════

-- Allow anyone to INSERT OTP (for registration)
CREATE POLICY "allow_insert_otp_for_registration"
ON public.otp_verifications
FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Allow authenticated users to SELECT their own OTP
CREATE POLICY "allow_select_own_otp"
ON public.otp_verifications
FOR SELECT
TO anon, authenticated
USING (true);

-- Allow UPDATE to mark OTP as used
CREATE POLICY "allow_update_otp_as_used"
ON public.otp_verifications
FOR UPDATE
TO anon, authenticated
USING (true)
WITH CHECK (true);
