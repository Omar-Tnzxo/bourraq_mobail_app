import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
    // Handle CORS preflight
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    let currentLang = 'ar';

    try {
        const bodyText = await req.text();
        console.log(`Received request body: ${bodyText}`);

        let body;
        try {
            body = JSON.parse(bodyText);
        } catch (e) {
            console.error('Failed to parse request body as JSON:', e);
            return new Response(
                JSON.stringify({ error: 'invalid json' }),
                { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        const { email, otp, password, name, phone, lang = 'ar' } = body
        currentLang = lang;

        console.log(`Verifying OTP for ${email}...`)

        // Validate input
        if (!email || !otp || !password || !name || !phone) {
            console.error('Missing fields:', { email: !!email, otp: !!otp, password: !!password, name: !!name, phone: !!phone });
            return new Response(
                JSON.stringify({ error: lang === 'ar' ? 'جميع الحقول مطلوبة' : 'All fields are required' }),
                { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // Create Supabase admin client
        const supabaseAdmin = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

        // Verify OTP
        const { data: otpData, error: otpError } = await supabaseAdmin
            .from('otp_verifications')
            .select('*')
            .eq('email', email)
            .eq('otp_code', otp)
            .eq('purpose', 'registration')
            .eq('is_used', false)
            .gt('expires_at', new Date().toISOString())
            .order('created_at', { ascending: false })
            .limit(1)
            .single()

        if (otpError || !otpData) {
            console.error('OTP verification failed or not found:', otpError);
            return new Response(
                JSON.stringify({ error: lang === 'ar' ? 'رمز التحقق غير صحيح أو منتهي الصلاحية' : 'Invalid or expired verification code' }),
                { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        console.log('OTP valid. Marking as used...');

        // Mark OTP as used
        const { error: updateError } = await supabaseAdmin
            .from('otp_verifications')
            .update({ is_used: true })
            .eq('id', otpData.id)

        if (updateError) {
            console.warn('Failed to mark OTP as used:', updateError);
        }

        // Create user in auth.users
        console.log(`Creating auth user for ${email}...`);
        const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
            email,
            password,
            email_confirm: true,
        })

        if (authError || !authData.user) {
            console.error('Auth creation error:', JSON.stringify(authError))

            const errorMessage = authError?.message || '';
            const isAlreadyRegistered = errorMessage.includes('already registered') ||
                errorMessage.includes('email_exists') ||
                (authError as any)?.status === 422;

            if (isAlreadyRegistered) {
                console.log(`Email ${email} is already registered.`);
                return new Response(
                    JSON.stringify({ error: lang === 'ar' ? 'البريد الإلكتروني مسجل بالفعل' : 'Email already registered' }),
                    { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
                )
            }

            return new Response(
                JSON.stringify({
                    error: lang === 'ar' ? 'فشل في إنشاء الحساب' : 'Failed to create account',
                    details: errorMessage,
                    code: (authError as any)?.code
                }),
                { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        console.log(`Auth user created: ${authData.user.id}. Creating profile...`)

        // Create user profile in public.users
        const { error: profileError } = await supabaseAdmin
            .from('users')
            .upsert({
                auth_user_id: authData.user.id,
                name,
                email,
                phone,
                is_email_verified: true,
            }, { onConflict: 'auth_user_id' })

        if (profileError) {
            console.error('Profile creation error:', profileError)
            // Rollback: delete auth user if we JUST created it and it's NOT a conflict
            await supabaseAdmin.auth.admin.deleteUser(authData.user.id)
            return new Response(
                JSON.stringify({ error: lang === 'ar' ? 'فشل في إنشاء الملف الشخصي' : 'Failed to create profile', details: profileError.message }),
                { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        console.log(`Profile processing finished. Attempting sign in...`)

        // Sign in the user to get session
        const { data: sessionData, error: sessionError } = await supabaseAdmin.auth.signInWithPassword({
            email,
            password,
        })

        if (sessionError || !sessionData.session) {
            console.error('Session creation error:', sessionError)
            return new Response(
                JSON.stringify({
                    error: lang === 'ar' ? 'فشل في تسجيل الدخول تلقائياً' : 'Auto-login failed',
                    user_id: authData.user.id
                }),
                { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        console.log(`Verification complete for ${email}. Returning session.`);

        return new Response(
            JSON.stringify({
                message: lang === 'ar' ? 'تم التحقق بنجاح' : 'Verified successfully',
                user: {
                    id: authData.user.id,
                    email: authData.user.email,
                    name,
                },
                session: sessionData.session
            }),
            { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    } catch (error: any) {
        console.error('Unexpected error in verify-otp:', error)
        return new Response(
            JSON.stringify({ error: currentLang === 'ar' ? 'حدث خطأ غير متوقع' : 'Unexpected error occurred', details: error.message }),
            { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }
})
