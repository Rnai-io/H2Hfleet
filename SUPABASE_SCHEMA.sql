-- H2HFleet Database Schema
-- Run this in Supabase SQL Editor to create all tables

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Companies Table
CREATE TABLE companies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  plan TEXT DEFAULT 'free', -- free, starter, business
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Users Table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID NOT NULL REFERENCES companies(id),
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  role TEXT DEFAULT 'owner', -- owner, admin, driver
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Vehicles Table
CREATE TABLE vehicles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID NOT NULL REFERENCES companies(id),
  plate_number TEXT NOT NULL, -- ทะเบียนรถ (e.g., "1234-บบ")
  vehicle_type TEXT NOT NULL, -- รถปูน, รถตู้, รถบรรทุก
  brand TEXT, -- ยี่ห้อ (Isuzu, Hino, etc.)
  model TEXT, -- รุ่น
  year INTEGER,
  fuel_type TEXT DEFAULT 'diesel', -- diesel, petrol, gas
  status TEXT DEFAULT 'active', -- active, inactive, maintenance
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(company_id, plate_number)
);

-- Expenses Table (Core for MVP)
CREATE TABLE expenses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_id UUID NOT NULL REFERENCES vehicles(id),
  type TEXT NOT NULL, -- น้ำมัน, ซ่อม, ยาง, ค่าเที่ยว, maintenance
  amount DECIMAL(10, 2) NOT NULL,
  note TEXT,
  expense_date DATE NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Trips Table (For GPS/performance later)
CREATE TABLE trips (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_id UUID NOT NULL REFERENCES vehicles(id),
  start_time TIMESTAMP NOT NULL,
  end_time TIMESTAMP,
  distance_km DECIMAL(10, 2),
  idle_minutes INTEGER DEFAULT 0,
  fuel_used DECIMAL(10, 2),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- GPS Logs Table (For realtime tracking later)
CREATE TABLE gps_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_id UUID NOT NULL REFERENCES vehicles(id),
  lat DECIMAL(10, 8),
  lng DECIMAL(11, 8),
  speed DECIMAL(10, 2),
  engine_status TEXT,
  fuel_level DECIMAL(10, 2),
  recorded_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Maintenance Table
CREATE TABLE maintenance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_id UUID NOT NULL REFERENCES vehicles(id),
  type TEXT NOT NULL, -- เปลี่ยนน้ำมัน, ต่อประกัน, ภาษี, ยาง
  due_date DATE,
  due_km INTEGER,
  status TEXT DEFAULT 'pending', -- pending, completed, overdue
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- AI Reports Table
CREATE TABLE ai_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID NOT NULL REFERENCES companies(id),
  summary TEXT NOT NULL, -- AI generated summary in Thai
  risk_level TEXT DEFAULT 'normal', -- normal, warning, critical
  report_date DATE DEFAULT CURRENT_DATE,
  generated_at TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW()
);

-- LINE Settings Table (For notifications)
CREATE TABLE line_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID NOT NULL REFERENCES companies(id),
  line_notify_token TEXT NOT NULL,
  enabled BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(company_id)
);

-- Create indexes for common queries
CREATE INDEX idx_users_company_id ON users(company_id);
CREATE INDEX idx_vehicles_company_id ON vehicles(company_id);
CREATE INDEX idx_expenses_vehicle_id ON expenses(vehicle_id);
CREATE INDEX idx_expenses_date ON expenses(expense_date);
CREATE INDEX idx_trips_vehicle_id ON trips(vehicle_id);
CREATE INDEX idx_gps_logs_vehicle_id ON gps_logs(vehicle_id);
CREATE INDEX idx_ai_reports_company_date ON ai_reports(company_id, report_date);

-- Enable RLS (Row Level Security)
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE gps_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE line_settings ENABLE ROW LEVEL SECURITY;

-- RLS Policies (Users can only see their company's data)
CREATE POLICY "Users can view their company" ON users
  FOR SELECT USING (auth.uid()::uuid IN (
    SELECT id FROM users WHERE company_id = users.company_id
  ));

CREATE POLICY "Users can view their company vehicles" ON vehicles
  FOR SELECT USING (company_id IN (
    SELECT company_id FROM users WHERE id = auth.uid()::uuid
  ));

CREATE POLICY "Users can view their company expenses" ON expenses
  FOR SELECT USING (vehicle_id IN (
    SELECT id FROM vehicles WHERE company_id IN (
      SELECT company_id FROM users WHERE id = auth.uid()::uuid
    )
  ));

-- Grant permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO authenticated;
