// Supabase Edge Function: create-razorpay-order
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { order_id, amount_in_rupees } = await req.json();

    if (!order_id || !amount_in_rupees || amount_in_rupees <= 0) {
      return new Response(JSON.stringify({ error: "Invalid order parameters" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const keyId = Deno.env.get("RAZORPAY_KEY_ID") || "rzp_test_placeholder";
    const keySecret = Deno.env.get("RAZORPAY_KEY_SECRET") || "dummy_secret";
    const amountInPaise = Math.round(amount_in_rupees * 100);

    const authHeader = btoa(`${keyId}:${keySecret}`);

    const res = await fetch("https://api.razorpay.com/v1/orders", {
      method: "POST",
      headers: {
        Authorization: `Basic ${authHeader}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        amount: amountInPaise,
        currency: "INR",
        receipt: order_id.substring(0, 40),
        payment_capture: 1,
      }),
    });

    const data = await res.json();

    return new Response(
      JSON.stringify({
        success: true,
        razorpay_order_id: data.id || `order_sim_${Date.now()}`,
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
