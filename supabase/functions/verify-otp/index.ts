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

    try {
        const { email, otp, password, name, phone } = await req.json()

        // Validate input
        if (!email || !otp || !password || !name || !phone) {
            return new Response(
                JSON.stringify({ error: 'جميع الحقول مطلوبة' }),
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
            return new Response(
                JSON.stringify({ error: 'رمز التحقق غير صحيح أو منتهي الصلاحية' }),
                { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // Mark OTP as used
        await supabaseAdmin
            .from('otp_verifications')
            .update({ is_used: true })
            .eq('id', otpData.id)

        // Create user in auth.users
        const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
            email,
            password,
            email_confirm: true,
        })

        if (authError || !authData.user) {
            console.error('Auth creation error:', authError)
            return new Response(
                JSON.stringify({ error: 'فشل في إنشاء الحساب' }),
                { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // Create user profile in public.users
        const { error: profileError } = await supabaseAdmin
            .from('users')
            .insert({
                auth_user_id: authData.user.id,
                name,
                email,
                phone,
                is_email_verified: true,
            })

        if (profileError) {
            console.error('Profile creation error:', profileError)
            // Rollback: delete auth user
            await supabaseAdmin.auth.admin.deleteUser(authData.user.id)
            return new Response(
                JSON.stringify({ error: 'فشل في إنشاء الملف الشخصي' }),
                { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // Sign in the user to get session
        const { data: sessionData, error: sessionError } = await supabaseAdmin.auth.signInWithPassword({
            email,
            password,
        })

        if (sessionError || !sessionData.session) {
            console.error('Session creation error:', sessionError)
            return new Response(
                JSON.stringify({ error: 'فشل في إنشاء الجلسة' }),
                { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        return new Response(
            JSON.stringify({
                message: 'تم التحقق بنجاح',
                user: {
                    id: authData.user.id,
                    email: authData.user.email,
                    name,
                },
                session: {
                    access_token: sessionData.session.access_token,
                    refresh_token: sessionData.session.refresh_token,
                },
            }),
            { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    } catch (error) {
        console.error('Error:', error)
        return new Response(
            JSON.stringify({ error: 'حدث خطأ غير متوقع' }),
            { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }
})
