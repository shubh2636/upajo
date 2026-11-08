// Supabase Edge Function: verify-razorpay-payment
// Strictly verifies HMAC-SHA256 signature, deduplicates payment IDs, and executes atomic stock deduction
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

    const { order_id, razorpay_order_id, razorpay_payment_id, razorpay_signature } = await req.json();

    if (!order_id || !razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
      return new Response(JSON.stringify({ error: "Missing required verification parameters" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const secret = Deno.env.get("RAZORPAY_KEY_SECRET");
    if (!secret) {
      return new Response(JSON.stringify({ error: "RAZORPAY_KEY_SECRET server secret is not configured" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 1. Cryptographic HMAC SHA256 signature verification (No bypasses)
    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
      "raw",
      encoder.encode(secret),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"]
    );

    const payload = `${razorpay_order_id}|${razorpay_payment_id}`;
    const signatureBuffer = await crypto.subtle.sign("HMAC", key, encoder.encode(payload));
    const generatedSignature = Array.from(new Uint8Array(signatureBuffer))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");

    if (generatedSignature !== razorpay_signature) {
      return new Response(JSON.stringify({ success: false, error: "Invalid cryptographic payment signature" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2. Initialize Supabase Admin client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // 3. Idempotency & Replay Protection Check
    const { data: existingPayment } = await supabase
      .from("payments")
      .select("id, order_id, status")
      .eq("razorpay_payment_id", razorpay_payment_id)
      .maybeSingle();

    if (existingPayment) {
      if (existingPayment.order_id === order_id) {
        // Idempotent retry: payment already captured for this exact order
        return new Response(JSON.stringify({ success: true, message: "Payment already verified and processed" }), {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      } else {
        // Security alarm: Payment ID replayed against a different order!
        return new Response(JSON.stringify({ success: false, error: "Payment ID already utilized for another order" }), {
          status: 409,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
    }

    // 4. Fetch order details
    const { data: order, error: orderError } = await supabase
      .from("orders")
      .select("id, consumer_id, total_amount, status")
      .eq("id", order_id)
      .single();

    if (orderError || !order) {
      return new Response(JSON.stringify({ error: "Order not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Verify caller ownership (Prevent IDOR payment verification)
    const token = authHeader.replace("Bearer ", "").trim();
    const { data: { user } } = await supabase.auth.getUser(token);
    if (!user) {
      return new Response(JSON.stringify({ error: "Invalid user session" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (user.id !== order.consumer_id) {
      const { data: profile } = await supabase
        .from("profiles")
        .select("role")
        .eq("id", user.id)
        .maybeSingle();

      if (profile?.role !== "admin") {
        return new Response(JSON.stringify({ error: "Forbidden: You are not authorized to verify payment for this order" }), {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
    }

    // 5. Execute Atomic Stock Deduction via Database Stored Procedure (Row-level lock)
    const { error: stockError } = await supabase.rpc("deduct_order_stock", {
      p_order_id: order_id,
    });

    if (stockError) {
      return new Response(JSON.stringify({ error: "Failed to allocate inventory", details: stockError.message }), {
        status: 409,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 6. Record payment record
    const { error: paymentError } = await supabase.from("payments").insert({
      order_id: order_id,
      payment_method: "upi_razorpay",
      razorpay_order_id: razorpay_order_id,
      razorpay_payment_id: razorpay_payment_id,
      razorpay_signature: razorpay_signature,
      amount: order.total_amount,
      status: "captured",
    });

    if (paymentError) {
      return new Response(JSON.stringify({ error: "Failed to record payment", details: paymentError.message }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 7. Update order state from verified server event
    await supabase.from("orders").update({ status: "confirmed" }).eq("id", order_id);

    return new Response(
      JSON.stringify({
        success: true,
        message: "Payment cryptographically verified and inventory allocated successfully",
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
