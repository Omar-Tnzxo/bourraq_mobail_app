// @ts-ignore
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
// @ts-ignore
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// =====================================================
// SECURITY CONFIGURATION
// =====================================================
const RATE_LIMIT = 100; // requests per minute per order
const RATE_WINDOW = 60000; // 1 minute in ms
const requestCounts = new Map<string, { count: number; resetAt: number }>();

// =====================================================
// INTERFACES
// =====================================================
interface OrderRecord {
    id: string;
    user_id: string;
    status: string;
    order_number?: string;
    total?: number;
}

interface WebhookPayload {
    type: "UPDATE";
    table: "orders";
    record: OrderRecord;
    old_record: OrderRecord;
}

// =====================================================
// NOTIFICATION TEMPLATES
// =====================================================
const STATUS_NOTIFICATIONS: Record<string, { title_ar: string; body_ar: string; title_en: string; body_en: string }> = {
    confirmed: {
        title_ar: "تم تأكيد طلبك! ✅",
        body_ar: "طلبك #{order_number} تم تأكيده وجاري التحضير",
        title_en: "Order Confirmed! ✅",
        body_en: "Your order #{order_number} is confirmed and being prepared",
    },
    preparing: {
        title_ar: "جاري تحضير طلبك 🍳",
        body_ar: "طلبك #{order_number} يتم تحضيره الآن",
        title_en: "Preparing Your Order 🍳",
        body_en: "Your order #{order_number} is being prepared",
    },
    on_the_way: {
        title_ar: "الطيار في الطريق! 🚀",
        body_ar: "الطيار خرج لتوصيل طلبك #{order_number}",
        title_en: "Driver On The Way! 🚀",
        body_en: "The driver is on the way with your order #{order_number}",
    },
    delivered: {
        title_ar: "تم التوصيل! 🎉",
        body_ar: "طلبك #{order_number} وصل. قيّم تجربتك!",
        title_en: "Delivered! 🎉",
        body_en: "Your order #{order_number} has arrived. Rate your experience!",
    },
    cancelled: {
        title_ar: "تم إلغاء الطلب ❌",
        body_ar: "طلبك #{order_number} تم إلغاؤه",
        title_en: "Order Cancelled ❌",
        body_en: "Your order #{order_number} has been cancelled",
    },
};

// =====================================================
// SECURITY FUNCTIONS
// =====================================================

/**
 * Verify HMAC signature from webhook
 * Provides cryptographic verification that the request came from Supabase
 */
async function verifyHmacSignature(
    payload: string,
    signature: string | null,
    secret: string
): Promise<boolean> {
    if (!signature || !secret) return false;

    try {
        const encoder = new TextEncoder();
        const key = await crypto.subtle.importKey(
            "raw",
            encoder.encode(secret),
            { name: "HMAC", hash: "SHA-256" },
            false,
            ["sign"]
        );

        const signatureBuffer = await crypto.subtle.sign(
            "HMAC",
            key,
            encoder.encode(payload)
        );

        const expectedSignature = Array.from(new Uint8Array(signatureBuffer))
            .map((b) => b.toString(16).padStart(2, "0"))
            .join("");

        // Timing-safe comparison (prevent timing attacks)
        if (signature.length !== expectedSignature.length) return false;

        let result = 0;
        for (let i = 0; i < signature.length; i++) {
            result |= signature.charCodeAt(i) ^ expectedSignature.charCodeAt(i);
        }
        return result === 0;
    } catch (error) {
        console.error("HMAC verification error:", error);
        return false;
    }
}

/**
 * Rate limiting to prevent abuse
 * Limits requests per order ID
 */
function checkRateLimit(orderId: string): boolean {
    const now = Date.now();
    const record = requestCounts.get(orderId);

    if (!record || now > record.resetAt) {
        requestCounts.set(orderId, { count: 1, resetAt: now + RATE_WINDOW });
        return true;
    }

    if (record.count >= RATE_LIMIT) {
        console.warn(`Rate limit exceeded for order: ${orderId}`);
        return false;
    }

    record.count++;
    return true;
}

/**
 * Log webhook call for audit purposes
 */
async function logWebhookCall(
    supabase: any,
    webhookName: string,
    eventType: string,
    payload: any,
    signatureValid: boolean,
    responseStatus: number,
    responseBody: string
): Promise<void> {
    try {
        await supabase.from("webhook_logs").insert({
            webhook_name: webhookName,
            event_type: eventType,
            payload: payload,
            signature_valid: signatureValid,
            response_status: responseStatus,
            response_body: responseBody,
        });
    } catch (error) {
        console.error("Failed to log webhook call:", error);
    }
}

// =====================================================
// MAIN HANDLER
// =====================================================
serve(async (req) => {
    // Handle CORS preflight
    if (req.method === "OPTIONS") {
        return new Response("ok", {
            headers: {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "POST, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type, x-webhook-signature, Authorization",
            },
        });
    }

    // Only allow POST
    if (req.method !== "POST") {
        return new Response(JSON.stringify({ error: "Method not allowed" }), {
            status: 405,
            headers: { "Content-Type": "application/json" },
        });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    let rawBody = "";
    let payload: WebhookPayload;
    let signatureValid = false;

    try {
        // Get raw body
        rawBody = await req.text();
        const webhookSecret = Deno.env.get("WEBHOOK_SECRET");

        // Get token from URL query parameter
        const url = new URL(req.url);
        const urlToken = url.searchParams.get("token");

        // DEBUG: Log URL info
        console.log("🔍 DEBUG: Full URL:", req.url);
        console.log("🔍 DEBUG: Token present:", !!urlToken);

        // Verify token matches our secret
        if (webhookSecret && urlToken) {
            if (urlToken === webhookSecret) {
                signatureValid = true;
                console.log("🔒 Security: Token verified ✓");
            } else {
                console.error("🔒 Security: Invalid token");
                await logWebhookCall(supabase, "order-status-webhook", "SECURITY_FAILURE", null, false, 401, "Invalid token");
                return new Response(JSON.stringify({ error: "Invalid token" }), {
                    status: 401,
                    headers: { "Content-Type": "application/json" },
                });
            }
        } else if (webhookSecret && !urlToken) {
            console.warn("⚠️ Security: WEBHOOK_SECRET configured but no token - allowing request");
            signatureValid = true;
        } else {
            console.warn("⚠️ Security: WEBHOOK_SECRET not configured - verification skipped");
            signatureValid = true;
        }

        // Parse payload
        payload = JSON.parse(rawBody);

        // Rate limiting check
        if (payload.record?.id && !checkRateLimit(payload.record.id)) {
            await logWebhookCall(supabase, "order-status-webhook", "RATE_LIMITED", payload, signatureValid, 429, "Rate limit exceeded");
            return new Response(JSON.stringify({ error: "Rate limit exceeded" }), {
                status: 429,
                headers: { "Content-Type": "application/json" },
            });
        }

        console.log("📨 Received webhook:", JSON.stringify({
            type: payload.type,
            old_status: payload.old_record?.status,
            new_status: payload.record?.status,
            order_id: payload.record?.id?.slice(0, 8) + "...",
        }));

        // Only process status changes
        if (payload.record.status === payload.old_record.status) {
            return new Response(JSON.stringify({ message: "No status change" }), { status: 200 });
        }

        const newStatus = payload.record.status;
        const notification = STATUS_NOTIFICATIONS[newStatus];

        if (!notification) {
            return new Response(JSON.stringify({ message: `No notification for status: ${newStatus}` }), { status: 200 });
        }

        // Get auth_user_id from public.users
        const { data: userData, error: userError } = await supabase
            .from("users")
            .select("auth_user_id")
            .eq("id", payload.record.user_id)
            .single();

        if (userError || !userData?.auth_user_id) {
            console.error("❌ Failed to get auth_user_id:", userError);
            await logWebhookCall(supabase, "order-status-webhook", "USER_NOT_FOUND", payload, signatureValid, 404, "User not found");
            return new Response(JSON.stringify({ error: "User not found" }), { status: 404 });
        }

        const authUserId = userData.auth_user_id;

        // Check notification preferences
        const { data: prefs } = await supabase
            .from("notification_preferences")
            .select("order_updates")
            .eq("user_id", authUserId)
            .single();

        if (prefs && prefs.order_updates === false) {
            console.log("🔕 User disabled order notifications");
            return new Response(JSON.stringify({ message: "User disabled order notifications" }), { status: 200 });
        }

        // Prepare notification content
        const orderNumber = payload.record.order_number || payload.record.id.slice(0, 8);
        const title = notification.title_ar;
        const body = notification.body_ar.replace("{order_number}", orderNumber);

        // Call send-notification function
        const response = await fetch(`${supabaseUrl}/functions/v1/send-notification`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "Authorization": `Bearer ${supabaseKey}`,
            },
            body: JSON.stringify({
                user_id: authUserId,
                title,
                body,
                data: {
                    type: "order_update",
                    order_id: payload.record.id,
                    status: newStatus,
                },
            }),
        });

        const result = await response.json();
        console.log("📱 Notification result:", JSON.stringify(result));

        // Log to notifications table
        await supabase.from("notifications").insert({
            target_type: "user",
            target_user_id: authUserId,
            title_ar: notification.title_ar,
            title_en: notification.title_en,
            body_ar: notification.body_ar.replace("{order_number}", orderNumber),
            body_en: notification.body_en.replace("{order_number}", orderNumber),
            data: { order_id: payload.record.id, status: newStatus, type: "order_update" },
            status: result.success ? "sent" : "failed",
            sent_count: result.success ? 1 : 0,
            failed_count: result.success ? 0 : 1,
            sent_at: result.success ? new Date().toISOString() : null,
        });

        // Log successful webhook call
        await logWebhookCall(supabase, "order-status-webhook", "SUCCESS", payload, signatureValid, 200, JSON.stringify(result));

        return new Response(JSON.stringify(result), {
            status: 200,
            headers: { "Content-Type": "application/json" },
        });

    } catch (error) {
        console.error("❌ Error:", error);
        await logWebhookCall(supabase, "order-status-webhook", "ERROR", rawBody, signatureValid, 500, error.message);
        return new Response(JSON.stringify({ error: error.message }), {
            status: 500,
            headers: { "Content-Type": "application/json" },
        });
    }
});
