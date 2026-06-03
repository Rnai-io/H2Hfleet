-- ============================================
-- H2HFleet: Map Tracking SQL (Run in Supabase)
-- ============================================

-- 1. เพิ่ม GPS columns ใน vehicles table
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS gps_device_imei TEXT;
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS gps_device_type TEXT DEFAULT 'teltonika';

-- 2. สร้าง vehicle_current_location table
CREATE TABLE IF NOT EXISTS vehicle_current_location (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  lat DECIMAL(10, 8) NOT NULL,
  lng DECIMAL(11, 8) NOT NULL,
  speed DECIMAL(10, 2) DEFAULT 0,
  heading DECIMAL(5, 2) DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(vehicle_id)
);

CREATE INDEX IF NOT EXISTS idx_vehicle_current_location_vehicle_id
  ON vehicle_current_location(vehicle_id);

-- 3. Enable Realtime สำหรับ live map updates
ALTER PUBLICATION supabase_realtime ADD TABLE vehicle_current_location;

-- 4. RLS Policies
ALTER TABLE vehicle_current_location ENABLE ROW LEVEL SECURITY;

-- อ่านได้เฉพาะรถใน company เดียวกัน
CREATE POLICY "company_read_locations" ON vehicle_current_location
  FOR SELECT USING (
    vehicle_id IN (
      SELECT v.id FROM vehicles v
      JOIN users u ON u.company_id = v.company_id
      WHERE u.id = auth.uid()
    )
  );

-- upsert ได้ผ่าน service role เท่านั้น (Edge Function)
CREATE POLICY "service_upsert_locations" ON vehicle_current_location
  FOR ALL USING (auth.role() = 'service_role');

-- ============================================
-- Supabase Edge Function: handle_gps_data
-- Deploy ที่: Supabase Dashboard → Edge Functions
-- ============================================
-- สร้างไฟล์ supabase/functions/handle_gps_data/index.ts ด้วย code ด้านล่าง:

/*
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  try {
    const body = await req.json()
    const { imei, lat, lng, speed, heading } = body

    if (!imei || !lat || !lng) {
      return new Response('Missing required fields', { status: 400 })
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)

    // หา vehicle จาก IMEI
    const { data: vehicle, error: vErr } = await supabase
      .from('vehicles')
      .select('id')
      .eq('gps_device_imei', imei)
      .maybeSingle()

    if (vErr || !vehicle) {
      return new Response('Vehicle not found for IMEI: ' + imei, { status: 404 })
    }

    // บันทึก GPS log (ประวัติ)
    await supabase.from('gps_logs').insert({
      vehicle_id: vehicle.id,
      lat, lng, speed: speed ?? 0,
      recorded_at: new Date().toISOString()
    })

    // อัปเดต current location (live map)
    await supabase.from('vehicle_current_location').upsert({
      vehicle_id: vehicle.id,
      lat, lng,
      speed: speed ?? 0,
      heading: heading ?? 0,
      updated_at: new Date().toISOString()
    }, { onConflict: 'vehicle_id' })

    return new Response(JSON.stringify({ ok: true }), {
      headers: { 'Content-Type': 'application/json' }
    })
  } catch (e) {
    return new Response('Error: ' + e.message, { status: 500 })
  }
})
*/

-- ============================================
-- ทดสอบ: Simulate GPS location (ใช้ใน SQL Editor)
-- แทน 'YOUR_VEHICLE_ID' ด้วย id จาก vehicles table
-- ============================================
/*
INSERT INTO vehicle_current_location (vehicle_id, lat, lng, speed, heading)
VALUES ('YOUR_VEHICLE_ID', 13.7563, 100.5018, 60, 90)
ON CONFLICT (vehicle_id)
DO UPDATE SET
  lat = EXCLUDED.lat,
  lng = EXCLUDED.lng,
  speed = EXCLUDED.speed,
  heading = EXCLUDED.heading,
  updated_at = NOW();
*/
