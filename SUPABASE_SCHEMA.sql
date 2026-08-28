-- ==============================================================================
-- H2HFLEET COMPLETE PRODUCTION DATABASE SCHEMA
-- Version: 2026.08 Enterprise Control Panel, Active Directory & CAD Telematics
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Companies Table
CREATE TABLE IF NOT EXISTS public.companies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  plan TEXT DEFAULT 'free',
  tax_id TEXT,
  branch_name TEXT DEFAULT 'สำนักงานใหญ่ (Headquarters)',
  address TEXT,
  phone TEXT,
  email TEXT,
  line_official_id TEXT DEFAULT '@655Jmtme',
  max_speed_limit INTEGER DEFAULT 90,
  night_curfew_enabled BOOLEAN DEFAULT TRUE,
  gps_interval_sec INTEGER DEFAULT 5,
  require_pretrip_check BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Users & Active Directory RBAC Table
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  role TEXT DEFAULT 'owner',
  department TEXT DEFAULT 'Operations',
  mfa_enabled BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  last_login TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Vehicles Table
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
  nick_name TEXT,
  remark TEXT,
  gps_device_imei TEXT,
  gps_device_type TEXT DEFAULT 'teltonika',
  image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(company_id, plate_number)
);

-- Expenses Table
CREATE TABLE IF NOT EXISTS public.expenses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  note TEXT,
  expense_date DATE NOT NULL,
  fuel_liters DECIMAL(10, 2),
  price_per_liter DECIMAL(10, 2),
  odometer_km INTEGER,
  gas_station TEXT,
  payment_method TEXT DEFAULT 'cash',
  receipt_photo_url TEXT,
  invoice_no TEXT,
  merchant_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Maintenance Table
CREATE TABLE IF NOT EXISTS public.maintenance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  part_category TEXT,
  part_name TEXT,
  description TEXT,
  cost DECIMAL(10, 2) DEFAULT 0,
  photo_url TEXT,
  due_date DATE,
  due_km INTEGER,
  completed_date DATE,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Trips Table
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

-- GPS Logs Table
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

-- AI Reports Table
CREATE TABLE IF NOT EXISTS public.ai_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  summary TEXT NOT NULL,
  risk_level TEXT DEFAULT 'normal',
  report_date DATE DEFAULT CURRENT_DATE,
  generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- LINE Settings Table
CREATE TABLE IF NOT EXISTS public.line_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  line_notify_token TEXT NOT NULL,
  enabled BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(company_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_users_company_id ON public.users(company_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_company_id ON public.vehicles(company_id);
CREATE INDEX IF NOT EXISTS idx_expenses_vehicle_id ON public.expenses(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_expenses_date ON public.expenses(expense_date);
CREATE INDEX IF NOT EXISTS idx_maintenance_vehicle_id ON public.maintenance(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_gps_logs_vehicle_id ON public.gps_logs(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_gps_logs_recorded ON public.gps_logs(recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_trips_vehicle_id ON public.trips(vehicle_id);

-- Storage Buckets
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('vehicle-photos', 'vehicle-photos', true),
  ('maintenance-photos', 'maintenance-photos', true),
  ('expense-receipts', 'expense-receipts', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Helper Function (get_my_company_id)
CREATE OR REPLACE FUNCTION public.get_my_company_id()
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT company_id FROM public.users WHERE id = auth.uid() LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_company_id() TO authenticated, anon;

-- Row Level Security
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.maintenance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gps_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.line_settings ENABLE ROW LEVEL SECURITY;
