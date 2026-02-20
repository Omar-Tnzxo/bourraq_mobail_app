import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type",
};

interface AssignPilotRequest {
    order_id: string;
    pilot_id: string;
}

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

        // Check if user is admin with assign permission
        const { data: adminUser, error: adminError } = await supabaseClient
            .from("admin_users")
            .select("id, is_super_admin, admin_permissions(can_assign_orders)")
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
            adminUser.admin_permissions?.can_assign_orders;

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
        const body: AssignPilotRequest = await req.json();
        const { order_id, pilot_id } = body;

        // Validate inputs
        if (!order_id || !pilot_id) {
            return new Response(
                JSON.stringify({ error: "Missing required fields" }),
                {
                    status: 400,
                    headers: { ...corsHeaders, "Content-Type": "application/json" },
                }
            );
        }

        // Verify pilot exists and is active
        const { data: pilot, error: pilotError } = await supabaseClient
            .from("pilots")
            .select("id, name, phone, is_active")
            .eq("id", pilot_id)
            .single();

        if (pilotError || !pilot) {
            return new Response(
                JSON.stringify({ error: "Pilot not found" }),
                {
                    status: 404,
                    headers: { ...corsHeaders, "Content-Type": "application/json" },
                }
            );
        }

        if (!pilot.is_active) {
            return new Response(
                JSON.stringify({ error: "Pilot is not active" }),
                {
                    status: 400,
                    headers: { ...corsHeaders, "Content-Type": "application/json" },
                }
            );
        }

        // Get order details
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

        // Check if order is in a valid state for pilot assignment
        const validStatuses = ["confirmed", "preparing", "ready"];
        if (!validStatuses.includes(order.status)) {
            return new Response(
                JSON.stringify({
                    error: `Cannot assign pilot to order with status: ${order.status}`,
                }),
                {
                    status: 400,
                    headers: { ...corsHeaders, "Content-Type": "application/json" },
                }
            );
        }

        // Check if pilot assignment already exists
        const { data: existingAssignment } = await supabaseClient
            .from("order_pilots")
            .select("id")
            .eq("order_id", order_id)
            .single();

        let pilotAssignment;

        if (existingAssignment) {
            // Update existing assignment
            const { data, error } = await supabaseClient
                .from("order_pilots")
                .update({
                    pilot_id: pilot_id,
                    assigned_at: new Date().toISOString(),
                    assigned_by: user.id,
                })
                .eq("order_id", order_id)
                .select()
                .single();

            if (error) {
                return new Response(
                    JSON.stringify({ error: error.message }),
                    {
                        status: 500,
                        headers: { ...corsHeaders, "Content-Type": "application/json" },
                    }
                );
            }
            pilotAssignment = data;
        } else {
            // Create new assignment
            const { data, error } = await supabaseClient
                .from("order_pilots")
                .insert({
                    order_id: order_id,
                    pilot_id: pilot_id,
                    assigned_at: new Date().toISOString(),
                    assigned_by: user.id,
                })
                .select()
                .single();

            if (error) {
                return new Response(
                    JSON.stringify({ error: error.message }),
                    {
                        status: 500,
                        headers: { ...corsHeaders, "Content-Type": "application/json" },
                    }
                );
            }
            pilotAssignment = data;
        }

        return new Response(
            JSON.stringify({
                success: true,
                assignment: pilotAssignment,
                pilot: pilot,
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
