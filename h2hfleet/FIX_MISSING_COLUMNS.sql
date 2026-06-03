-- ============================================================
-- FIX: เพิ่ม columns ที่ขาดใน vehicles table
-- รัน Supabase Dashboard → SQL Editor → วาง → Run
-- ============================================================

ALTER TABLE vehicles
  ADD COLUMN IF NOT EXISTS remark    TEXT,
  ADD COLUMN IF NOT EXISTS nick_name TEXT;

-- ตรวจสอบว่าเพิ่มแล้ว
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'vehicles'
ORDER BY ordinal_position;
