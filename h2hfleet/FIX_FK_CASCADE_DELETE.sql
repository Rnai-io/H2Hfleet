-- ============================================================
-- Fix: เพิ่ม ON DELETE CASCADE สำหรับ expenses → vehicles
-- รันใน Supabase Dashboard → SQL Editor
-- ทำให้ลบรถแล้ว expenses ลบตามอัตโนมัติที่ระดับ DB
-- ============================================================

-- 1) ดูชื่อ constraint เดิมก่อน
SELECT constraint_name
FROM information_schema.referential_constraints
WHERE unique_constraint_name IN (
  SELECT constraint_name
  FROM information_schema.table_constraints
  WHERE table_name = 'vehicles' AND constraint_type = 'PRIMARY KEY'
);

-- 2) ลบ FK constraint เดิมที่ไม่มี CASCADE
ALTER TABLE expenses
  DROP CONSTRAINT IF EXISTS expenses_vehicle_id_fkey;

-- 3) สร้างใหม่พร้อม ON DELETE CASCADE
ALTER TABLE expenses
  ADD CONSTRAINT expenses_vehicle_id_fkey
  FOREIGN KEY (vehicle_id)
  REFERENCES vehicles(id)
  ON DELETE CASCADE;

-- ✅ หลังรันแล้ว: ลบรถ → expenses ของรถนั้นลบอัตโนมัติทันที
