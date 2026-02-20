import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type",
};

interface UpdateOrderStatusRequest {
    order_id: string;
    new_status: string;
    notes?: string;
}

const VALID_STATUSES = [
    "pending",
    "confirmed",
    "preparing",
    "ready",
    "picked_up",
    "delivered",
    "cancelled",
];

const STATUS_FLOW = {
    pending: ["confirmed", "cancelled"],
    confirmed: ["preparing", "cancelled"],
    preparing: ["ready", "cancelled"],
    ready: ["picked_up", "cancelled"],
    picked_up: ["delivered", "cancelled"],
    delivered: [], // Final state
    cancelled: [], // Final state
};

Deno.serve(async (req: Request) => {
    // Handle CORS preflight
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
    }

    try {
        // Get JWT from Authorization header
        const authHeader = req.headers.get("Authorization");
        if (!authHeader) {
            return new Response(
                JSON.stringify({ error: "Missing authorization header" }),
                {
                    status: 401,
                    headers: { ...corsHeaders, "Content-Type": "application/json" },
                }
            );
        }

        // Create Supabase client with user's JWT
        const supabaseClient = createClient(
            Deno.env.get("SUPABASE_URL") ?? "",
            Deno.env.get("SUPABASE_ANON_KEY") ?? "",
            {
                global: {
                    headers: { Authorization: authHeader },
                },
            }
        );

        // Verify user is authenticated
        const {
            data: { user },
            error: userError,
        } = await supabaseClient.auth.getUser();

        if (userError || !user) {
            return new Response(
                JSON.stringify({ error: "Unauthorized" }),
                {
                    status: 401,
                    headers: { ...corsHeaders, "Content-Type": "application/json" },
                }
            );
        }

        // Check if user is admin
        const { data: adminUser, error: adminError } = await supabaseClient
            .from("admin_users")
            .select("id, is_super_admin, admin_permissions(can_edit_order_status)")
            .eq("auth_user_id", user.id)
            .single();

        if (adminError || !adminUser) {
            return new Response(
                JSON.stringify({ error: "Not an admin user" }),
                {
                    status: 403,
                    headers: { ...corsHeaders, "Content-Type": "application/json" },
                }
            );
        }

        // Check permission
        const hasPermission =
            adminUser.is_super_admin ||
            adminUser.admin_permissions?.can_edit_order_status;

        if (!hasPermission) {
            return new Response(
                JSON.stringify({ error: "Insufficient permissions" }),
                {
                    status: 403,
                    headers: { ...corsHeaders, "Content-Type": "application/json" },
                }
            );
        }

        // Parse request body
        const body: UpdateOrderStatusRequest = await req.json();
        const { order_id, new_status, notes } = body;

        // Validate inputs
        if (!order_id || !new_status) {
            return new Response(
                JSON.stringify({ error: "Missing required fields" }),
                {
                    status: 400,
                    headers: { ...corsHeaders, "Content-Type": "application/json" },
                }
            );
        }

        if (!VALID_STATUSES.includes(new_status)) {
            return new Response(
                JSON.stringify({ error: "Invalid status" }),
                {
                    status: 400,
                    headers: { ...corsHeaders, "Content-Type": "application/json" },
                }
            );
        }

        // Get current order
        const { data: order, error: orderError } = await supabaseClient
            .from("orders")
            .select("id, status, user_id")
            .eq("id", order_id)
            .single();

        if (orderError || !order) {
            return new Response(
                JSON.stringify({ error: "Order not found" }),
                {
                    status: 404,
                    headers: { ...corsHeaders, "Content-Type": "application/json" },
                }
            );
        }

        // Validate status transition
        const allowedTransitions = STATUS_FLOW[order.status as keyof typeof STATUS_FLOW] || [];
        if (!allowedTransitions.includes(new_status)) {
            return new Response(
                JSON.stringify({
                    error: `Cannot transition from ${order.status} to ${new_status}`,
                }),
                {
                    status: 400,
                    headers: { ...corsHeaders, "Content-Type": "application/json" },
                }
            );
        }

        // Update order status
        const updateData: any = {
            status: new_status,
            updated_at: new Date().toISOString(),
        };

        // Add timestamp for specific statuses (only for columns that exist in DB)
        // Note: Currently only picked_up_at and delivered_at exist in order_pilots table
        // Status timestamps are tracked by the status field and updated_at
        
        // Add cancellation notes if cancelled
        if (new_status === "cancelled" && notes) {
            updateData.cancellation_reason = notes;
            updateData.cancelled_by = user.id;
        }

        const { data: updatedOrder, error: updateError } = await supabaseClient
            .from("orders")
            .update(updateData)
            .eq("id", order_id)
            .select()
            .single();

        if (updateError) {
            return new Response(
                JSON.stringify({ error: updateError.message }),
                {
                    status: 500,
                    headers: { ...corsHeaders, "Content-Type": "application/json" },
                }
            );
        }

        return new Response(
            JSON.stringify({
                success: true,
                order: updatedOrder,
            }),
            {
                status: 200,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            }
        );
    } catch (error) {
        return new Response(
            JSON.stringify({ error: error.message }),
            {
                status: 500,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            }
        );
    }
});
