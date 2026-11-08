// Supabase Edge Function: razorpay-webhook
// Cryptographically validates x-razorpay-signature, deduplicates events, and triggers atomic stock deduction
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    const signature = req.headers.get("x-razorpay-signature");
    if (!signature) {
      return new Response(JSON.stringify({ error: "Missing x-razorpay-signature header" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const webhookSecret = Deno.env.get("RAZORPAY_WEBHOOK_SECRET");
    if (!webhookSecret) {
      return new Response(JSON.stringify({ error: "RAZORPAY_WEBHOOK_SECRET is not configured" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Read raw body bytes to verify signature accurately
    const rawBody = await req.text();

    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
      "raw",
      encoder.encode(webhookSecret),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"]
    );

    const signatureBuffer = await crypto.subtle.sign("HMAC", key, encoder.encode(rawBody));
    const expectedSignature = Array.from(new Uint8Array(signatureBuffer))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");

    if (expectedSignature !== signature) {
      return new Response(JSON.stringify({ error: "Invalid webhook cryptographic signature" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const event = JSON.parse(rawBody);
    const eventType = event.event;

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    if (eventType === "payment.captured" || eventType === "order.paid") {
      const paymentEntity = event.payload?.payment?.entity;
      if (!paymentEntity) {
        return new Response(JSON.stringify({ error: "Invalid payment payload" }), { status: 400 });
      }

      const paymentId = paymentEntity.id;
      const rzpOrderId = paymentEntity.order_id;
      const amount = Number(paymentEntity.amount) / 100.0;
      // Receipt contains internal order_id
      const orderId = paymentEntity.notes?.order_id || paymentEntity.description;

      if (!orderId) {
        return new Response(JSON.stringify({ status: "skipped", message: "No internal order_id associated" }), {
          status: 200,
        });
      }

      // 1. Idempotency Check: check if payment ID was already processed
      const { data: existingPayment } = await supabase
        .from("payments")
        .select("id, order_id")
        .eq("razorpay_payment_id", paymentId)
        .maybeSingle();

      if (existingPayment) {
        return new Response(JSON.stringify({ status: "already_processed" }), { status: 200 });
      }

      // 2. Atomic Stock Deduction
      const { error: stockError } = await supabase.rpc("deduct_order_stock", {
        p_order_id: orderId,
      });

      if (stockError) {
        console.error(`Webhook stock deduction error for order ${orderId}: ${stockError.message}`);
      }

      // 3. Record payment
      await supabase.from("payments").insert({
        order_id: orderId,
        payment_method: "upi_razorpay",
        razorpay_order_id: rzpOrderId,
        razorpay_payment_id: paymentId,
        amount: amount,
        status: "captured",
        raw_payload: event,
      });

      // 4. Update order status to confirmed
      await supabase.from("orders").update({ status: "confirmed" }).eq("id", orderId);
    }

    return new Response(JSON.stringify({ status: "ok" }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
