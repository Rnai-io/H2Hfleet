-- รัน SQL นี้ใน Supabase Dashboard → SQL Editor
-- เพิ่มฟิลด์รายละเอียดให้ตาราง maintenance ที่มีอยู่แล้ว เพื่อรองรับฟีเจอร์ซ่อมบำรุงแบบครบวงจร

ALTER TABLE maintenance
  ADD COLUMN IF NOT EXISTS part_category TEXT DEFAULT 'other',
  ADD COLUMN IF NOT EXISTS part_name TEXT,
  ADD COLUMN IF NOT EXISTS description TEXT,
  ADD COLUMN IF NOT EXISTS cost NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS photo_url TEXT,
  ADD COLUMN IF NOT EXISTS completed_date DATE;

-- สร้าง Storage bucket สำหรับเก็บรูปซ่อมบำรุง (ทำครั้งเดียว)
-- ไปที่ Supabase Dashboard → Storage → New bucket
--   ชื่อ: maintenance-photos
--   Public bucket: เปิด (Yes)
--
-- หรือรัน SQL ด้านล่างนี้แทน:
INSERT INTO storage.buckets (id, name, public)
VALUES ('maintenance-photos', 'maintenance-photos', true)
ON CONFLICT (id) DO NOTHING;

-- Policy ให้ authenticated user อัปโหลด/อ่านรูปได้
DROP POLICY IF EXISTS "Allow authenticated uploads" ON storage.objects;
CREATE POLICY "Allow authenticated uploads"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'maintenance-photos');

DROP POLICY IF EXISTS "Allow public read" ON storage.objects;
CREATE POLICY "Allow public read"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'maintenance-photos');
