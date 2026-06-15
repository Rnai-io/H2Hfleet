import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const CHANNEL_TOKEN = Deno.env.get("LINE_CHANNEL_TOKEN") || "KlxTUlAtEC4NNmBbAcWvo83SCTzirO5zOHOiicwpiWlXKExRUf9SbfTtv8+tW9+cZc/uS5/mhUt/WZEzPRV+EgYoqlCnyv19BtEaqSULuCFkBzX0FBWLeg47H6UEKvD4h2xYzvKKKuaUnfwezepwLQdB04t89/1O/w1cDnyilFU=";

serve(async (req) => {
  if (req.method !== "POST") return new Response("Method Not Allowed", { status: 405 });

  try {
    const { userId, message } = await req.json();

    if (!userId || !message) {
      return new Response(
        JSON.stringify({ error: "Missing userId or message" }),
        { status: 400 }
      );
    }

    const res = await fetch("https://api.line.me/v2/bot/message/push", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${CHANNEL_TOKEN}`,
      },
      body: JSON.stringify({
        to: userId,
        messages: [{ type: "text", text: message }],
      }),
    });

    if (!res.ok) {
      const error = await res.text();
      return new Response(
        JSON.stringify({ error, status: res.status }),
        { status: res.status }
      );
    }

    const data = await res.json();
    return new Response(JSON.stringify(data), { status: 200 });
  } catch (e) {
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500 }
    );
  }
});
