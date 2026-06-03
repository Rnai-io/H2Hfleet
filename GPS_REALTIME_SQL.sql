-- ============================================
-- GPS Realtime + Analytics SQL
-- Run ใน Supabase SQL Editor
-- ============================================

-- 1. RLS policy สำหรับ gps_logs
CREATE POLICY "allow_authenticated_read_gps" ON gps_logs
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "allow_service_write_gps" ON gps_logs
  FOR INSERT TO authenticated, service_role WITH CHECK (true);

-- 2. เพิ่ม index สำหรับ query ประวัติตามวันที่เร็วขึ้น
CREATE INDEX IF NOT EXISTS idx_gps_logs_vehicle_recorded
  ON gps_logs(vehicle_id, recorded_at DESC);

-- 3. Enable Realtime สำหรับ gps_logs
ALTER PUBLICATION supabase_realtime ADD TABLE gps_logs;

-- 4. ทดสอบ: insert GPS history สำหรับ กพ-5026 (สุรินทร์ → เส้นทางจำลอง)
-- แทน 'b45aeca8-9f44-4120-8ac8-0581066c57c6' ด้วย vehicle id จริง
INSERT INTO gps_logs (vehicle_id, lat, lng, speed, recorded_at) VALUES
  ('b45aeca8-9f44-4120-8ac8-0581066c57c6', 14.8820, 103.4930, 0,  NOW() - INTERVAL '2 hours'),
  ('b45aeca8-9f44-4120-8ac8-0581066c57c6', 14.8890, 103.5010, 55, NOW() - INTERVAL '90 minutes'),
  ('b45aeca8-9f44-4120-8ac8-0581066c57c6', 14.9020, 103.5120, 72, NOW() - INTERVAL '60 minutes'),
  ('b45aeca8-9f44-4120-8ac8-0581066c57c6', 14.9180, 103.5280, 68, NOW() - INTERVAL '45 minutes'),
  ('b45aeca8-9f44-4120-8ac8-0581066c57c6', 14.9350, 103.5450, 80, NOW() - INTERVAL '30 minutes'),
  ('b45aeca8-9f44-4120-8ac8-0581066c57c6', 14.9520, 103.5590, 45, NOW() - INTERVAL '15 minutes'),
  ('b45aeca8-9f44-4120-8ac8-0581066c57c6', 14.9650, 103.5700, 0,  NOW() - INTERVAL '5 minutes');

-- 5. อัปเดต current location เป็นตำแหน่งล่าสุด
UPDATE vehicle_current_location
SET lat = 14.9650, lng = 103.5700, speed = 0, updated_at = NOW() - INTERVAL '5 minutes'
WHERE vehicle_id = 'b45aeca8-9f44-4120-8ac8-0581066c57c6';
