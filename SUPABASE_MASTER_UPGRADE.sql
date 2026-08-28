-- ==============================================================================
-- H2HFLEET ENTERPRISE MASTER DATABASE UPGRADE & RLS MIGRATION SCRIPT
-- Version: 2026.08 - Enterprise Active Directory, Fleet Policies & Photo Storage
-- Run this script in Supabase Dashboard -> SQL Editor -> New Query -> RUN
-- ==============================================================================

-- 1. EXTENSIONS
-- ------------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. SCHEMA DEFINITIONS & AUTOMATIC COLUMN UPGRADES
-- ------------------------------------------------------------------------------

-- === 2.1 COMPANIES TABLE ===
CREATE TABLE IF NOT EXISTS public.companies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  plan TEXT DEFAULT 'free',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enterprise & Policy columns for companies
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS tax_id TEXT;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS branch_name TEXT DEFAULT 'สำนักงานใหญ่ (Headquarters)';
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS line_official_id TEXT DEFAULT '@655Jmtme';
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS max_speed_limit INTEGER DEFAULT 90;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS night_curfew_enabled BOOLEAN DEFAULT TRUE;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS gps_interval_sec INTEGER DEFAULT 5;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS require_pretrip_check BOOLEAN DEFAULT TRUE;

-- === 2.2 USERS & ACTIVE DIRECTORY RBAC TABLE ===
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  role TEXT DEFAULT 'owner',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Active Directory & RBAC columns for users
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS department TEXT DEFAULT 'Operations';
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS mfa_enabled BOOLEAN DEFAULT FALSE;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS last_login TEXT;

-- === 2.3 VEHICLES TABLE ===
CREATE TABLE IF NOT EXISTS public.vehicles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  plate_number TEXT NOT NULL,
  vehicle_type TEXT NOT NULL,
  brand TEXT,
  model TEXT,
  year INTEGER,
  fuel_type TEXT DEFAULT 'diesel',
  status TEXT DEFAULT 'active',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(company_id, plate_number)
);

-- Telematics & Photo columns for vehicles
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS nick_name TEXT;
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS remark TEXT;
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS gps_device_imei TEXT;
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS gps_device_type TEXT DEFAULT 'teltonika';
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS image_url TEXT;

-- === 2.4 EXPENSES TABLE ===
CREATE TABLE IF NOT EXISTS public.expenses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  note TEXT,
  expense_date DATE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Detailed Expense columns
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS fuel_liters DECIMAL(10, 2);
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS price_per_liter DECIMAL(10, 2);
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS odometer_km INTEGER;
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS gas_station TEXT;
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'cash';
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS receipt_photo_url TEXT;
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS invoice_no TEXT;
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS merchant_name TEXT;

-- === 2.5 MAINTENANCE TABLE ===
CREATE TABLE IF NOT EXISTS public.maintenance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  due_date DATE,
  due_km INTEGER,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- CAD & Detail columns for maintenance
ALTER TABLE public.maintenance ADD COLUMN IF NOT EXISTS part_category TEXT;
ALTER TABLE public.maintenance ADD COLUMN IF NOT EXISTS part_name TEXT;
ALTER TABLE public.maintenance ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.maintenance ADD COLUMN IF NOT EXISTS cost DECIMAL(10, 2) DEFAULT 0;
ALTER TABLE public.maintenance ADD COLUMN IF NOT EXISTS photo_url TEXT;
ALTER TABLE public.maintenance ADD COLUMN IF NOT EXISTS completed_date DATE;

-- === 2.6 GPS LOGS & TRIPS TABLE ===
CREATE TABLE IF NOT EXISTS public.gps_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
  lat DECIMAL(10, 8),
  lng DECIMAL(11, 8),
  speed DECIMAL(10, 2),
  engine_status TEXT,
  fuel_level DECIMAL(10, 2),
  recorded_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.trips (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE,
  distance_km DECIMAL(10, 2),
  idle_minutes INTEGER DEFAULT 0,
  fuel_used DECIMAL(10, 2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. HIGH-SPEED DATABASE INDEXES
-- ------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_users_company_id ON public.users(company_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_company_id ON public.vehicles(company_id);
CREATE INDEX IF NOT EXISTS idx_expenses_vehicle_id ON public.expenses(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_expenses_date ON public.expenses(expense_date);
CREATE INDEX IF NOT EXISTS idx_maintenance_vehicle_id ON public.maintenance(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_gps_logs_vehicle_id ON public.gps_logs(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_gps_logs_recorded ON public.gps_logs(recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_trips_vehicle_id ON public.trips(vehicle_id);

-- 4. STORAGE BUCKETS SETUP (Photos & Receipts)
-- ------------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('vehicle-photos', 'vehicle-photos', true),
  ('maintenance-photos', 'maintenance-photos', true),
  ('expense-receipts', 'expense-receipts', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 5. RECURSION-SAFE RLS HELPER FUNCTION (SECURITY DEFINER)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_my_company_id()
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT company_id FROM public.users WHERE id = auth.uid() LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_company_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_company_id() TO anon;

-- 6. ENABLE ROW LEVEL SECURITY (RLS) & CLEAN POLICIES
-- ------------------------------------------------------------------------------
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.maintenance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gps_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;

-- Drop obsolete policies to avoid collisions
DROP POLICY IF EXISTS "companies_select" ON public.companies;
DROP POLICY IF EXISTS "companies_insert" ON public.companies;
DROP POLICY IF EXISTS "companies_update" ON public.companies;
DROP POLICY IF EXISTS "users_select" ON public.users;
DROP POLICY IF EXISTS "users_insert" ON public.users;
DROP POLICY IF EXISTS "users_update" ON public.users;
DROP POLICY IF EXISTS "vehicles_select" ON public.vehicles;
DROP POLICY IF EXISTS "vehicles_insert" ON public.vehicles;
DROP POLICY IF EXISTS "vehicles_update" ON public.vehicles;
DROP POLICY IF EXISTS "vehicles_delete" ON public.vehicles;
DROP POLICY IF EXISTS "expenses_select" ON public.expenses;
DROP POLICY IF EXISTS "expenses_insert" ON public.expenses;
DROP POLICY IF EXISTS "expenses_update" ON public.expenses;
DROP POLICY IF EXISTS "expenses_delete" ON public.expenses;
DROP POLICY IF EXISTS "maintenance_select" ON public.maintenance;
DROP POLICY IF EXISTS "maintenance_insert" ON public.maintenance;
DROP POLICY IF EXISTS "maintenance_update" ON public.maintenance;
DROP POLICY IF EXISTS "maintenance_delete" ON public.maintenance;

-- === COMPANIES POLICIES ===
CREATE POLICY "companies_select" ON public.companies
  FOR SELECT USING (id = public.get_my_company_id());

CREATE POLICY "companies_insert" ON public.companies
  FOR INSERT WITH CHECK (true);

CREATE POLICY "companies_update" ON public.companies
  FOR UPDATE USING (id = public.get_my_company_id());

-- === USERS POLICIES ===
CREATE POLICY "users_select" ON public.users
  FOR SELECT USING (id = auth.uid() OR company_id = public.get_my_company_id());

CREATE POLICY "users_insert" ON public.users
  FOR INSERT WITH CHECK (id = auth.uid() OR company_id = public.get_my_company_id());

CREATE POLICY "users_update" ON public.users
  FOR UPDATE USING (id = auth.uid() OR company_id = public.get_my_company_id());

-- === VEHICLES POLICIES ===
CREATE POLICY "vehicles_select" ON public.vehicles
  FOR SELECT USING (company_id = public.get_my_company_id());

CREATE POLICY "vehicles_insert" ON public.vehicles
  FOR INSERT WITH CHECK (company_id = public.get_my_company_id());

CREATE POLICY "vehicles_update" ON public.vehicles
  FOR UPDATE USING (company_id = public.get_my_company_id());

CREATE POLICY "vehicles_delete" ON public.vehicles
  FOR DELETE USING (company_id = public.get_my_company_id());

-- === EXPENSES POLICIES ===
CREATE POLICY "expenses_select" ON public.expenses
  FOR SELECT USING (
    vehicle_id IN (SELECT id FROM public.vehicles WHERE company_id = public.get_my_company_id())
  );

CREATE POLICY "expenses_insert" ON public.expenses
  FOR INSERT WITH CHECK (
    vehicle_id IN (SELECT id FROM public.vehicles WHERE company_id = public.get_my_company_id())
  );

CREATE POLICY "expenses_update" ON public.expenses
  FOR UPDATE USING (
    vehicle_id IN (SELECT id FROM public.vehicles WHERE company_id = public.get_my_company_id())
  );

CREATE POLICY "expenses_delete" ON public.expenses
  FOR DELETE USING (
    vehicle_id IN (SELECT id FROM public.vehicles WHERE company_id = public.get_my_company_id())
  );

-- === MAINTENANCE POLICIES ===
CREATE POLICY "maintenance_select" ON public.maintenance
  FOR SELECT USING (
    vehicle_id IN (SELECT id FROM public.vehicles WHERE company_id = public.get_my_company_id())
  );

CREATE POLICY "maintenance_insert" ON public.maintenance
  FOR INSERT WITH CHECK (
    vehicle_id IN (SELECT id FROM public.vehicles WHERE company_id = public.get_my_company_id())
  );

CREATE POLICY "maintenance_update" ON public.maintenance
  FOR UPDATE USING (
    vehicle_id IN (SELECT id FROM public.vehicles WHERE company_id = public.get_my_company_id())
  );

CREATE POLICY "maintenance_delete" ON public.maintenance
  FOR DELETE USING (
    vehicle_id IN (SELECT id FROM public.vehicles WHERE company_id = public.get_my_company_id())
  );

-- === STORAGE POLICIES ===
DROP POLICY IF EXISTS "Public Read Access" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Upload Access" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Update Access" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Delete Access" ON storage.objects;

CREATE POLICY "Public Read Access" ON storage.objects
  FOR SELECT USING (bucket_id IN ('vehicle-photos', 'maintenance-photos', 'expense-receipts'));

CREATE POLICY "Authenticated Upload Access" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id IN ('vehicle-photos', 'maintenance-photos', 'expense-receipts')
  );

CREATE POLICY "Authenticated Update Access" ON storage.objects
  FOR UPDATE USING (
    bucket_id IN ('vehicle-photos', 'maintenance-photos', 'expense-receipts')
  );

CREATE POLICY "Authenticated Delete Access" ON storage.objects
  FOR DELETE USING (
    bucket_id IN ('vehicle-photos', 'maintenance-photos', 'expense-receipts')
  );

-- 7. GRANT SCHEMA PERMISSIONS
-- ------------------------------------------------------------------------------
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;

-- ==============================================================================
-- SUCCESS: Database Schema & RLS Policies are now 100% Up-To-Date!
-- ==============================================================================
