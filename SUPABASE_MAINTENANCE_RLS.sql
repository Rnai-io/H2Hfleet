-- รัน SQL นี้ใน Supabase Dashboard → SQL Editor
-- แก้ error: new row violates row-level security policy for table "maintenance" (code 42501)
-- เพิ่ม RLS policy ให้ user เข้าถึงข้อมูล maintenance ของรถในบริษัทตัวเองได้

ALTER TABLE maintenance ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own company maintenance" ON maintenance;
CREATE POLICY "Users can view own company maintenance"
ON maintenance FOR SELECT
TO authenticated
USING (
  vehicle_id IN (
    SELECT v.id FROM vehicles v
    JOIN users u ON u.company_id = v.company_id
    WHERE u.id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Users can insert own company maintenance" ON maintenance;
CREATE POLICY "Users can insert own company maintenance"
ON maintenance FOR INSERT
TO authenticated
WITH CHECK (
  vehicle_id IN (
    SELECT v.id FROM vehicles v
    JOIN users u ON u.company_id = v.company_id
    WHERE u.id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Users can update own company maintenance" ON maintenance;
CREATE POLICY "Users can update own company maintenance"
ON maintenance FOR UPDATE
TO authenticated
USING (
  vehicle_id IN (
    SELECT v.id FROM vehicles v
    JOIN users u ON u.company_id = v.company_id
    WHERE u.id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Users can delete own company maintenance" ON maintenance;
CREATE POLICY "Users can delete own company maintenance"
ON maintenance FOR DELETE
TO authenticated
USING (
  vehicle_id IN (
    SELECT v.id FROM vehicles v
    JOIN users u ON u.company_id = v.company_id
    WHERE u.id = auth.uid()
  )
);
