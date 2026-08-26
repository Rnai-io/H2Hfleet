-- ============================================================
-- H2HFleet - Supabase RLS Fix Script
-- คัดลอกคำสั่งทั้งหมดนี้ไปวางใน Supabase SQL Editor แล้วกด RUN
-- ============================================================

-- 1. COMPANIES Table
ALTER TABLE IF EXISTS companies ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Enable all for authenticated users on companies" ON companies;
CREATE POLICY "Enable all for authenticated users on companies" ON companies
  FOR ALL TO authenticated
  USING (true)
  WITH CHECK (true);

-- 2. USERS Table
ALTER TABLE IF EXISTS users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their company" ON users;
DROP POLICY IF EXISTS "Enable all for authenticated users on users" ON users;
CREATE POLICY "Enable all for authenticated users on users" ON users
  FOR ALL TO authenticated
  USING (true)
  WITH CHECK (true);

-- 3. VEHICLES Table
ALTER TABLE IF EXISTS vehicles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their company vehicles" ON vehicles;
DROP POLICY IF EXISTS "Enable all for authenticated users on vehicles" ON vehicles;
CREATE POLICY "Enable all for authenticated users on vehicles" ON vehicles
  FOR ALL TO authenticated
  USING (true)
  WITH CHECK (true);

-- 4. EXPENSES Table
ALTER TABLE IF EXISTS expenses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their company expenses" ON expenses;
DROP POLICY IF EXISTS "Enable all for authenticated users on expenses" ON expenses;
CREATE POLICY "Enable all for authenticated users on expenses" ON expenses
  FOR ALL TO authenticated
  USING (true)
  WITH CHECK (true);

-- 5. MAINTENANCE Table
ALTER TABLE IF EXISTS maintenance ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Enable all for authenticated users on maintenance" ON maintenance;
CREATE POLICY "Enable all for authenticated users on maintenance" ON maintenance
  FOR ALL TO authenticated
  USING (true)
  WITH CHECK (true);

-- 6. VEHICLE_CURRENT_LOCATION & GPS_LOGS
ALTER TABLE IF EXISTS vehicle_current_location ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Enable all for authenticated users on vehicle_current_location" ON vehicle_current_location;
CREATE POLICY "Enable all for authenticated users on vehicle_current_location" ON vehicle_current_location
  FOR ALL TO authenticated
  USING (true)
  WITH CHECK (true);

ALTER TABLE IF EXISTS gps_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Enable all for authenticated users on gps_logs" ON gps_logs;
CREATE POLICY "Enable all for authenticated users on gps_logs" ON gps_logs
  FOR ALL TO authenticated
  USING (true)
  WITH CHECK (true);

-- 7. TRIPS & AI_REPORTS & LINE_SETTINGS
ALTER TABLE IF EXISTS trips ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Enable all for authenticated users on trips" ON trips;
CREATE POLICY "Enable all for authenticated users on trips" ON trips
  FOR ALL TO authenticated
  USING (true)
  WITH CHECK (true);

ALTER TABLE IF EXISTS ai_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Enable all for authenticated users on ai_reports" ON ai_reports;
CREATE POLICY "Enable all for authenticated users on ai_reports" ON ai_reports
  FOR ALL TO authenticated
  USING (true)
  WITH CHECK (true);

ALTER TABLE IF EXISTS line_settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Enable all for authenticated users on line_settings" ON line_settings;
CREATE POLICY "Enable all for authenticated users on line_settings" ON line_settings
  FOR ALL TO authenticated
  USING (true)
  WITH CHECK (true);
