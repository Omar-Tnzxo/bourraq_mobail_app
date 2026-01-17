// @ts-ignore
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
// @ts-ignore
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

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

// Notification templates for each status
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

serve(async (req) => {
    try {
        const payload: WebhookPayload = await req.json();

        // Only process status changes
        if (payload.record.status === payload.old_record.status) {
            return new Response(JSON.stringify({ message: "No status change" }), { status: 200 });
        }

        const newStatus = payload.record.status;
        const notification = STATUS_NOTIFICATIONS[newStatus];

        if (!notification) {
            return new Response(JSON.stringify({ message: `No notification for status: ${newStatus}` }), { status: 200 });
        }

        // Get user's language preference
        const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
        const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
        const supabase = createClient(supabaseUrl, supabaseKey);

        // Get user's notification preferences
        const { data: prefs } = await supabase
            .from("notification_preferences")
            .select("order_updates, language")
            .eq("user_id", payload.record.user_id)
            .single();

        // Check if user wants order notifications
        if (prefs && prefs.order_updates === false) {
            return new Response(JSON.stringify({ message: "User disabled order notifications" }), { status: 200 });
        }

        // Default to Arabic
        const language = prefs?.language || "ar";
        const title = language === "ar" ? notification.title_ar : notification.title_en;
        const body = (language === "ar" ? notification.body_ar : notification.body_en)
            .replace("{order_number}", payload.record.order_number || payload.record.id.slice(0, 8));

        // Call the send-notification function
        const sendNotificationUrl = `${supabaseUrl}/functions/v1/send-notification`;

        const response = await fetch(sendNotificationUrl, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "Authorization": `Bearer ${supabaseKey}`,
            },
            body: JSON.stringify({
                user_id: payload.record.user_id,
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

        // Log notification to database
        await supabase.from("notifications").insert({
            user_id: payload.record.user_id,
            title,
            body,
            type: "order_update",
            data: { order_id: payload.record.id, status: newStatus },
            is_sent: result.success || false,
        });

        return new Response(JSON.stringify(result), {
            status: 200,
            headers: { "Content-Type": "application/json" },
        });
    } catch (error) {
        console.error("Error:", error);
        return new Response(
            JSON.stringify({ error: error.message }),
            { status: 500 }
        );
    }
});
