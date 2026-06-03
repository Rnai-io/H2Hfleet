import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // รับข้อมูลได้ทั้ง JSON และ query string (รองรับหลาย device format)
    let imei: string, lat: number, lng: number;
    let speed = 0, heading = 0;

    const contentType = req.headers.get("content-type") ?? "";

    if (contentType.includes("application/json")) {
      const body = await req.json();
      imei = body.imei ?? body.device_id ?? body.id;
      lat = Number(body.lat ?? body.latitude);
      lng = Number(body.lng ?? body.longitude);
      speed = Number(body.speed ?? 0);
      heading = Number(body.heading ?? body.course ?? 0);
    } else {
      // query string: ?imei=xxx&lat=xx&lng=xx&speed=xx
      const url = new URL(req.url);
      imei = url.searchParams.get("imei") ?? url.searchParams.get("id") ?? "";
      lat = Number(url.searchParams.get("lat") ?? url.searchParams.get("latitude") ?? 0);
      lng = Number(url.searchParams.get("lng") ?? url.searchParams.get("longitude") ?? 0);
      speed = Number(url.searchParams.get("speed") ?? 0);
      heading = Number(url.searchParams.get("heading") ?? url.searchParams.get("course") ?? 0);
    }

    if (!imei || !lat || !lng) {
      return new Response(
        JSON.stringify({ error: "Missing imei, lat, or lng" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(SUPABASE_URL, SERVICE_KEY);

    // หา vehicle จาก IMEI
    const { data: vehicle, error: vErr } = await supabase
      .from("vehicles")
      .select("id")
      .eq("gps_device_imei", imei)
      .maybeSingle();

    if (vErr || !vehicle) {
      return new Response(
        JSON.stringify({ error: `No vehicle found for IMEI: ${imei}` }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const now = new Date().toISOString();

    // บันทึก GPS log (ประวัติ)
    await supabase.from("gps_logs").insert({
      vehicle_id: vehicle.id,
      lat,
      lng,
      speed,
      recorded_at: now,
    });

    // อัปเดต current location (live map)
    await supabase.from("vehicle_current_location").upsert(
      { vehicle_id: vehicle.id, lat, lng, speed, heading, updated_at: now },
      { onConflict: "vehicle_id" }
    );

    return new Response(
      JSON.stringify({ ok: true, vehicle_id: vehicle.id }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
