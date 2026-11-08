// Supabase Edge Function: send-push-notification (Firebase Cloud Messaging)
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

    const { user_id, title, body, data_payload } = await req.json();

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Verify caller session
    const token = authHeader.replace("Bearer ", "").trim();
    if (token !== supabaseKey) {
      const { data: { user } } = await supabase.auth.getUser(token);
      if (!user) {
        return new Response(JSON.stringify({ error: "Unauthorized session" }), {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
    }

    // Retrieve recipient's FCM token
    const { data: userProfile } = await supabase
      .from("profiles")
      .select("fcm_token")
      .eq("id", user_id)
      .maybeSingle();

    if (!userProfile?.fcm_token) {
      return new Response(JSON.stringify({ status: "skipped", reason: "No FCM token for user" }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Record notification in database
    await supabase.from("notifications").insert({
      user_id: user_id,
      title_hi: title,
      title_en: title,
      body_hi: body,
      body_en: body,
      type: "order_event",
      payload: data_payload || {},
    });

    return new Response(JSON.stringify({ success: true, message: "Push notification queued" }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

