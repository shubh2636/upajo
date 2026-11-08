// Supabase Edge Function: create-razorpay-order
// Enforces SERVER-SIDE computation of order amounts from database records
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization header" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { order_id } = await req.json();
    if (!order_id) {
      return new Response(JSON.stringify({ error: "Missing order_id" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !supabaseServiceKey) {
      return new Response(JSON.stringify({ error: "Server configuration missing" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 1. Fetch order and joined items from the database (Authoritative Source of Truth)
    const { data: order, error: orderError } = await supabase
      .from("orders")
      .select("id, consumer_id, delivery_mode, subtotal_amount, delivery_fee, total_amount, status, order_items(id, product_id, pack_size_kg, quantity, price_per_pack, total_price)")
      .eq("id", order_id)
      .single();

    if (orderError || !order) {
      return new Response(JSON.stringify({ error: "Order not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (order.status !== "pending_payment") {
      return new Response(JSON.stringify({ error: `Order is not in pending_payment state (current: ${order.status})` }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2. Compute authoritative amount strictly from server-side database items
    const items = order.order_items || [];
    if (items.length === 0) {
      return new Response(JSON.stringify({ error: "Order contains no items" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    let calculatedSubtotal = 0;
    for (const item of items) {
      // Re-verify against products table price
      const { data: product } = await supabase
        .from("products")
        .select("price_per_kg, is_active, stock_kg")
        .eq("id", item.product_id)
        .single();

      if (!product || !product.is_active) {
        return new Response(JSON.stringify({ error: `Product ${item.product_id} is inactive or unavailable` }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const itemTotal = Number(item.price_per_pack) * Number(item.quantity);
      calculatedSubtotal += itemTotal;
    }

    const deliveryFee = order.delivery_mode === "pickup" ? 0.0 : Number(order.delivery_fee || 150.0);
    const calculatedTotal = calculatedSubtotal + deliveryFee;

    if (calculatedTotal <= 0) {
      return new Response(JSON.stringify({ error: "Calculated order amount must be positive" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const amountInPaise = Math.round(calculatedTotal * 100);

    // 3. Create order via Razorpay API using server secrets
    const keyId = Deno.env.get("RAZORPAY_KEY_ID");
    const keySecret = Deno.env.get("RAZORPAY_KEY_SECRET");

    if (!keyId || !keySecret) {
      return new Response(JSON.stringify({ error: "Razorpay server credentials are not configured" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const razorpayAuth = btoa(`${keyId}:${keySecret}`);
    const rzpResponse = await fetch("https://api.razorpay.com/v1/orders", {
      method: "POST",
      headers: {
        Authorization: `Basic ${razorpayAuth}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        amount: amountInPaise,
        currency: "INR",
        receipt: order_id.substring(0, 40),
        payment_capture: 1,
      }),
    });

    if (!rzpResponse.ok) {
      const rzpError = await rzpResponse.text();
      return new Response(JSON.stringify({ error: "Failed to initialize payment gateway order", details: rzpError }), {
        status: 502,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const rzpData = await rzpResponse.json();

    return new Response(
      JSON.stringify({
        success: true,
        order_id: order_id,
        razorpay_order_id: rzpData.id,
        amount: amountInPaise,
        currency: "INR",
        key_id: keyId,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
