-- รัน SQL นี้ใน Supabase Dashboard → SQL Editor
-- แก้ error: Could not find the 'remark' column of 'vehicles' in the schema cache (PGRST204)

ALTER TABLE vehicles
  ADD COLUMN IF NOT EXISTS remark TEXT;
