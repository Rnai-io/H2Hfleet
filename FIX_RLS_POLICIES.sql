-- ============================================================
-- H2HFleet: แก้ไข RLS Infinite Recursion
-- รัน SQL นี้ใน Supabase → SQL Editor → New Query → Run
-- ============================================================

-- STEP 1: ลบ policies เก่าที่มีปัญหาออกทั้งหมด
-- ============================================================
DROP POLICY IF EXISTS "Users can view their company"            ON users;
DROP POLICY IF EXISTS "Users can view their company vehicles"   ON vehicles;
DROP POLICY IF EXISTS "Users can view their company expenses"   ON expenses;

-- ลบ policies เก่าที่อาจมีอยู่
DROP POLICY IF EXISTS "users_select"       ON users;
DROP POLICY IF EXISTS "users_insert"       ON users;
DROP POLICY IF EXISTS "users_update"       ON users;
DROP POLICY IF EXISTS "companies_select"   ON companies;
DROP POLICY IF EXISTS "companies_insert"   ON companies;
DROP POLICY IF EXISTS "companies_update"   ON companies;
DROP POLICY IF EXISTS "vehicles_select"    ON vehicles;
DROP POLICY IF EXISTS "vehicles_insert"    ON vehicles;
DROP POLICY IF EXISTS "vehicles_update"    ON vehicles;
DROP POLICY IF EXISTS "vehicles_delete"    ON vehicles;
DROP POLICY IF EXISTS "expenses_select"    ON expenses;
DROP POLICY IF EXISTS "expenses_insert"    ON expenses;
DROP POLICY IF EXISTS "expenses_update"    ON expenses;
DROP POLICY IF EXISTS "expenses_delete"    ON expenses;

-- STEP 2: สร้าง helper function ที่ bypass RLS (SECURITY DEFINER)
-- ============================================================
-- Function นี้รันในฐานะ postgres owner จึงไม่ถูก RLS กั้น
-- ป้องกัน infinite recursion ได้ทั้งหมด

CREATE OR REPLACE FUNCTION public.get_my_company_id()
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT company_id FROM users WHERE id = auth.uid() LIMIT 1;
$$;

-- ให้ authenticated users เรียกใช้ function ได้
GRANT EXECUTE ON FUNCTION public.get_my_company_id() TO authenticated;

-- STEP 3: สร้าง RLS Policies ใหม่ที่ถูกต้อง
-- ============================================================

-- === COMPANIES ===
CREATE POLICY "companies_select" ON companies
  FOR SELECT USING (id = get_my_company_id());

-- ตอน register ยังไม่มี company → ต้องอนุญาต insert ก่อน
CREATE POLICY "companies_insert" ON companies
  FOR INSERT WITH CHECK (true);

CREATE POLICY "companies_update" ON companies
  FOR UPDATE USING (id = get_my_company_id());

-- === USERS ===
-- ใช้ id = auth.uid() โดยตรง ไม่ query users ข้างใน
CREATE POLICY "users_select" ON users
  FOR SELECT USING (
    id = auth.uid()
    OR company_id = get_my_company_id()
  );

CREATE POLICY "users_insert" ON users
  FOR INSERT WITH CHECK (id = auth.uid());

CREATE POLICY "users_update" ON users
  FOR UPDATE USING (id = auth.uid());

-- === VEHICLES ===
CREATE POLICY "vehicles_select" ON vehicles
  FOR SELECT USING (company_id = get_my_company_id());

CREATE POLICY "vehicles_insert" ON vehicles
  FOR INSERT WITH CHECK (company_id = get_my_company_id());

CREATE POLICY "vehicles_update" ON vehicles
  FOR UPDATE USING (company_id = get_my_company_id());

CREATE POLICY "vehicles_delete" ON vehicles
  FOR DELETE USING (company_id = get_my_company_id());

-- === EXPENSES ===
CREATE POLICY "expenses_select" ON expenses
  FOR SELECT USING (
    vehicle_id IN (
      SELECT id FROM vehicles WHERE company_id = get_my_company_id()
    )
  );

CREATE POLICY "expenses_insert" ON expenses
  FOR INSERT WITH CHECK (
    vehicle_id IN (
      SELECT id FROM vehicles WHERE company_id = get_my_company_id()
    )
  );

CREATE POLICY "expenses_update" ON expenses
  FOR UPDATE USING (
    vehicle_id IN (
      SELECT id FROM vehicles WHERE company_id = get_my_company_id()
    )
  );

CREATE POLICY "expenses_delete" ON expenses
  FOR DELETE USING (
    vehicle_id IN (
      SELECT id FROM vehicles WHERE company_id = get_my_company_id()
    )
  );

-- === MAINTENANCE ===
CREATE POLICY "maintenance_select" ON maintenance
  FOR SELECT USING (
    vehicle_id IN (
      SELECT id FROM vehicles WHERE company_id = get_my_company_id()
    )
  );

CREATE POLICY "maintenance_insert" ON maintenance
  FOR INSERT WITH CHECK (
    vehicle_id IN (
      SELECT id FROM vehicles WHERE company_id = get_my_company_id()
    )
  );

CREATE POLICY "maintenance_update" ON maintenance
  FOR UPDATE USING (
    vehicle_id IN (
      SELECT id FROM vehicles WHERE company_id = get_my_company_id()
    )
  );

-- === AI REPORTS ===
CREATE POLICY "ai_reports_select" ON ai_reports
  FOR SELECT USING (company_id = get_my_company_id());

CREATE POLICY "ai_reports_insert" ON ai_reports
  FOR INSERT WITH CHECK (company_id = get_my_company_id());

-- === LINE SETTINGS ===
CREATE POLICY "line_settings_select" ON line_settings
  FOR SELECT USING (company_id = get_my_company_id());

CREATE POLICY "line_settings_insert" ON line_settings
  FOR INSERT WITH CHECK (company_id = get_my_company_id());

CREATE POLICY "line_settings_update" ON line_settings
  FOR UPDATE USING (company_id = get_my_company_id());

-- STEP 4: ตรวจสอบว่า policies สร้างสำเร็จ
-- ============================================================
SELECT
  tablename,
  policyname,
  cmd
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
