-- ============================================================
-- Migration: เพิ่ม nick_name column ใน vehicles table
-- รันใน Supabase Dashboard → SQL Editor
-- ============================================================

-- 1) เพิ่ม column (ถ้ายังไม่มี)
ALTER TABLE vehicles
  ADD COLUMN IF NOT EXISTS nick_name TEXT;

-- 2) ตรวจสอบว่า column ถูกเพิ่มแล้ว
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'vehicles'
  AND column_name = 'nick_name';
