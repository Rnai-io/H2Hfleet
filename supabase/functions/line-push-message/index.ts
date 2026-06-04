import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

serve(async (req) => {
  if (req.method !== "POST") return new Response("Method Not Allowed", { status: 405 });

  try {
    const { userId, message, channelToken } = await req.json();

    if (!userId || !message || !channelToken) {
      return new Response(
        JSON.stringify({ error: "Missing parameters" }),
        { status: 400 }
      );
    }

    const res = await fetch("https://api.line.me/v2/bot/message/push", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${channelToken}`,
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
