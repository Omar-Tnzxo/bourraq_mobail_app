import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    // Use service role key to bypass RLS for assignment
    const supabaseClient = createClient(supabaseUrl, supabaseServiceRoleKey);

    const body = await req.json();
    const { order_id } = body;

    if (!order_id) {
      return new Response(JSON.stringify({ error: "Order ID is required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 1. Check if auto-assignment is enabled
    const { data: setting } = await supabaseClient
      .from('system_settings')
      .select('value')
      .eq('key', 'auto_assignment_enabled')
      .single();

    if (setting?.value !== true) {
      return new Response(JSON.stringify({ message: "Auto-assignment is disabled globally" }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2. Get order details (specifically the delivery area or lat/lng if available)
    const { data: order, error: orderError } = await supabaseClient
      .from('orders')
      .select('*, areas(latitude, longitude)')
      .eq('id', order_id)
      .single();

    if (orderError || !order) {
      return new Response(JSON.stringify({ error: "Order not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Use area coords as reference for "nearest"
    const refLat = order.areas?.latitude;
    const refLng = order.areas?.longitude;

    if (!refLat || !refLng) {
      return new Response(JSON.stringify({ error: "Order area location not defined" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 3. Find 5 nearest available pilots
    const { data: nearestPilots, error: rpcError } = await supabaseClient.rpc('get_nearest_available_pilots', {
      p_lat: refLat,
      p_lng: refLng,
      p_limit: 5,
      p_max_distance_km: 25 // Configurable
    });

    if (rpcError || !nearestPilots || nearestPilots.length === 0) {
      return new Response(JSON.stringify({ message: "No available pilots found within range" }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 4. Assign the first pilot (the nearest with least workload)
    const chosenPilot = nearestPilots[0];

    // Use the existing assign-pilot logic but internally
    const { error: assignError } = await supabaseClient
      .from("order_pilots")
      .upsert({
        order_id: order_id,
        pilot_id: chosenPilot.pilot_id,
        status: 'assigned',
        assigned_at: new Date().toISOString(),
        notes: 'Automatically assigned by system based on proximity'
      }, { onConflict: 'order_id' });

    if (assignError) {
      throw assignError;
    }

    // 5. Send notification to chosen pilot
    try {
      await supabaseClient.functions.invoke('send-notification', {
        body: {
          user_id: chosenPilot.pilot_id, // Note: notifications might need pilot's auth_user_id
          title: "طلب جديد تلقائي",
          body: `تم إسناد الطلب ${order_id.substring(0, 8)} إليك تلقائياً لتواجدك بالقرب من المنطقة.`,
          data: { order_id, type: 'new_assignment' }
        }
      });
    } catch (notiErr) {
      console.error("Notification failed but assignment succeeded", notiErr);
    }

    return new Response(JSON.stringify({
      success: true,
      pilot: chosenPilot.name,
      distance: chosenPilot.distance_km
    }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
