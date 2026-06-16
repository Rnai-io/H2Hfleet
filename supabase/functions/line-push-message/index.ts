import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const CHANNEL_TOKEN =
  Deno.env.get("LINE_CHANNEL_TOKEN") ||
  "KlxTUlAtEC4NNmBbAcWvo83SCTzirO5zOHOiicwpiWlXKExRUf9SbfTtv8+tW9+cZc/uS5/mhUt/WZEzPRV+EgYoqlCnyv19BtEaqSULuCFkBzX0FBWLeg47H6UEKvD4h2xYzvKKKuaUnfwezepwLQdB04t89/1O/w1cDnyilFU=";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response("Method Not Allowed", {
      status: 405,
      headers: corsHeaders,
    });
  }

  try {
    const body = await req.json();
    const { userId, message } = body;

    if (!userId || !message) {
      return new Response(
        JSON.stringify({ error: "Missing userId or message", received: body }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log(`[LINE Push] Sending to userId=${userId}, tokenPrefix=${CHANNEL_TOKEN.slice(0, 20)}...`);

    const res = await fetch("https://api.line.me/v2/bot/message/push", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${CHANNEL_TOKEN}`,
      },
      body: JSON.stringify({
        to: userId,
        messages: [{ type: "text", text: message }],
      }),
    });

    // Parse LINE response as JSON (or text fallback)
    let lineBody: unknown;
    const contentType = res.headers.get("content-type") || "";
    if (contentType.includes("application/json")) {
      lineBody = await res.json();
    } else {
      lineBody = await res.text();
    }

    console.log(`[LINE Push] status=${res.status}`, JSON.stringify(lineBody));

    if (!res.ok) {
      return new Response(
        JSON.stringify({ error: lineBody, lineStatus: res.status }),
        {
          status: res.status,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    return new Response(JSON.stringify({ ok: true, data: lineBody }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("[LINE Push] Exception:", e);
    return new Response(
      JSON.stringify({ error: String(e) }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
