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

    let lang = 'ar'; // Default language

    try {
        const bodyText = await req.text();
        let body;
        try {
            body = JSON.parse(bodyText);
        } catch (e) {
            return new Response(JSON.stringify({ error: 'invalid json' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
        }

        lang = body.lang || 'ar'
        const { email, password, name, phone } = body

        // Validate input
        if (!email || !password || !name || !phone) {
            return new Response(
                JSON.stringify({ error: lang === 'ar' ? 'جميع الحقول مطلوبة' : 'All fields are required' }),
                { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // Create Supabase client
        const supabaseAdmin = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

        // 1. Check if user already exists in public.users (fully registered)
        const { data: existingProfile } = await supabaseAdmin
            .from('users')
            .select('id')
            .eq('email', email)
            .maybeSingle()

        if (existingProfile) {
            return new Response(
                JSON.stringify({ error: lang === 'ar' ? 'البريد الإلكتروني مسجل بالفعل' : 'Email already registered' }),
                { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // Generate 6-digit OTP
        const otpCode = Math.floor(100000 + Math.random() * 900000).toString()

        // Store OTP in database (expires in 5 minutes)
        const expiresAt = new Date(Date.now() + 5 * 60 * 1000).toISOString()

        const { error: otpError } = await supabaseAdmin
            .from('otp_verifications')
            .insert({
                email,
                otp_code: otpCode,
                purpose: 'registration',
                expires_at: expiresAt,
            })

        if (otpError) {
            console.error('OTP storage error:', otpError)
            return new Response(
                JSON.stringify({ error: lang === 'ar' ? 'فشل في إنشاء رمز التحقق' : 'Failed to generate verification code' }),
                { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // 🟡 Print OTP to Supabase logs for administrative tracking
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
        console.log('📧 OTP GENERATED FOR:', email, `[LANG: ${lang}]`)
        console.log('🔐 OTP CODE:', otpCode)
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')

        // Try to send email
        const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')
        let emailErrorOccurred = false;

        if (!RESEND_API_KEY) {
            console.error('❌ RESEND_API_KEY is missing in Supabase secrets!')
            emailErrorOccurred = true;
        } else {
            try {
                const isAr = lang === 'ar';
                const subject = isAr ? 'رمز التحقق - بُراق' : 'Verification Code - Bourraq';
                const fromName = isAr ? 'بُراق' : 'Bourraq';

                const resendResponse = await fetch('https://api.resend.com/emails', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${RESEND_API_KEY}`,
                    },
                    body: JSON.stringify({
                        from: `${fromName} <no-reply@bourraq.com>`,
                        to: [email],
                        subject: subject,
                        html: isAr ? `
                <div dir="rtl" style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                  <h2 style="color: #87BF54;">مرحباً بك في بُراق! 🚀</h2>
                  <p>شكراً لتسجيلك معنا ${name}!</p>
                  <p>رمز التحقق الخاص بك هو:</p>
                  <div style="background: #f5f5f5; padding: 20px; text-align: center; margin: 20px 0; border-radius: 8px;">
                    <h1 style="color: #87BF54; font-size: 36px; margin: 0; letter-spacing: 8px;">${otpCode}</h1>
                  </div>
                  <p style="color: #666;">هذا الرمز صالح لمدة <strong>5 دقائق</strong> فقط.</p>
                  <p style="color: #999; font-size: 12px;">إذا لم تطلب هذا الرمز، يرجى تجاهل هذه الرسالة.</p>
                </div>
              ` : `
                <div dir="ltr" style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; text-align: left;">
                  <h2 style="color: #87BF54;">Welcome to Bourraq! 🚀</h2>
                  <p>Thank you for registering with us, ${name}!</p>
                  <p>Your verification code is:</p>
                  <div style="background: #f5f5f5; padding: 20px; text-align: center; margin: 20px 0; border-radius: 8px;">
                    <h1 style="color: #87BF54; font-size: 36px; margin: 0; letter-spacing: 8px;">${otpCode}</h1>
                  </div>
                  <p style="color: #666;">This code is valid for <strong>5 minutes</strong> only.</p>
                  <p style="color: #999; font-size: 12px;">If you didn't request this code, please ignore this message.</p>
                </div>
              `,
                    }),
                })

                if (resendResponse.ok) {
                    console.log(`✅ Email sent successfully via no-reply@bourraq.com [${lang}]`)
                } else {
                    const resendError = await resendResponse.json()
                    console.error('⚠️ Resend API error:', resendError)
                    emailErrorOccurred = true;
                }
            } catch (err) {
                console.error('⚠️ Fetch error sending email:', err)
                emailErrorOccurred = true;
            }
        }

        // Return success response
        return new Response(
            JSON.stringify({
                message: lang === 'ar' ? 'تم إرسال رمز التحقق إلى بريدك الإلكتروني' : 'Verification code sent to your email',
                email
            }),
            { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    } catch (error: any) {
        console.error('Error:', error)
        return new Response(
            JSON.stringify({ error: lang === 'ar' ? 'حدث خطأ غير متوقع' : 'Unexpected error occurred', details: error.message }),
            { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }
})
