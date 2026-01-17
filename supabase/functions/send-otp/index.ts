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
        const { email, password, name, phone } = await req.json()

        // Validate input
        if (!email || !password || !name || !phone) {
            return new Response(
                JSON.stringify({ error: 'جميع الحقول مطلوبة' }),
                { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // Create Supabase client
        const supabaseAdmin = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

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
                JSON.stringify({ error: 'فشل في إنشاء رمز التحقق' }),
                { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // 🟡 DEVELOPMENT MODE: Print OTP to console instead of sending email
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
        console.log('📧 OTP GENERATED FOR:', email)
        console.log('🔐 OTP CODE:', otpCode)
        console.log('👤 NAME:', name)
        console.log('📱 PHONE:', phone)
        console.log('⏰ EXPIRES AT:', expiresAt)
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')

        // Try to send email (will fail for non-verified emails, but that's OK)
        const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')

        try {
            const resendResponse = await fetch('https://api.resend.com/emails', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${RESEND_API_KEY}`,
                },
                body: JSON.stringify({
                    from: 'Bourraq <onboarding@resend.dev>',
                    to: [email],
                    subject: 'رمز التحقق - بُراق',
                    html: `
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
          `,
                }),
            })

            if (resendResponse.ok) {
                console.log('✅ Email sent successfully!')
            } else {
                const error = await resendResponse.json()
                console.log('⚠️ Email failed (expected in dev):', error)
            }
        } catch (emailError) {
            console.log('⚠️ Email error (expected in dev):', emailError)
        }

        // Return success regardless of email status (OTP is in console)
        return new Response(
            JSON.stringify({
                message: 'تم إنشاء رمز التحقق بنجاح',
                email,
                // For development: include OTP in response
                dev_otp: otpCode,
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
