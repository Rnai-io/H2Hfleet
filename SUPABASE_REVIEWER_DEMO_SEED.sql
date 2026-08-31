-- ==============================================================================
-- H2HFLEET — บัญชีทดสอบสำหรับ Google Play reviewer
-- Run in Supabase Dashboard -> SQL Editor -> New Query -> RUN
-- ==============================================================================
-- ⚠️ ก่อนรันสคริปต์นี้ ต้องสร้าง auth user ก่อนด้วยมือ:
--    Supabase Dashboard -> Authentication -> Users -> Add user -> Create new user
--      Email:            playreview@h2hfleet.app
--      Password:         H2HPlay!Review2026
--      Auto Confirm User: ✅ ติ๊กให้เรียบร้อย (สำคัญ — reviewer ยืนยันอีเมลไม่ได้)
--    แล้วค่อยรันไฟล์นี้เพื่อเติมข้อมูลตัวอย่างให้บัญชีนั้น
--
-- สคริปต์นี้รันซ้ำได้ (idempotent) — รันใหม่จะล้างข้อมูลเดโมเดิมแล้วสร้างใหม่
-- ==============================================================================

DO $$
DECLARE
  v_email     TEXT := 'playreview@h2hfleet.app';
  v_uid       UUID;
  v_company   UUID;
  v_v1        UUID;
  v_v2        UUID;
  v_v3        UUID;
  v_v4        UUID;
  v_v5        UUID;
BEGIN
  -- 1) หา auth user ที่สร้างไว้
  SELECT id INTO v_uid FROM auth.users WHERE email = v_email;
  IF v_uid IS NULL THEN
    RAISE EXCEPTION
      'ยังไม่ได้สร้าง auth user "%" — ไปที่ Authentication -> Users -> Add user (ติ๊ก Auto Confirm) ก่อน', v_email;
  END IF;

  -- 2) ล้างข้อมูลเดโมเดิม (ถ้ามี) เพื่อให้รันซ้ำได้
  SELECT company_id INTO v_company FROM public.users WHERE id = v_uid;
  IF v_company IS NOT NULL THEN
    DELETE FROM public.companies WHERE id = v_company;  -- cascade ทุกตาราง
  END IF;

  -- 3) บริษัทตัวอย่าง
  INSERT INTO public.companies (name, plan, address, phone, email, tax_id, branch_name)
  VALUES ('H2H Demo Logistics (Play Review)', 'free',
          '99/9 ถนนสุขุมวิท เขตวัฒนา กรุงเทพฯ 10110',
          '02-000-0000', v_email, '0000000000000', 'สำนักงานใหญ่ (Demo)')
  RETURNING id INTO v_company;

  -- 4) ผู้ใช้ระดับ owner ผูกกับ auth user
  INSERT INTO public.users (id, company_id, email, name, role, department, is_active)
  VALUES (v_uid, v_company, v_email, 'Play Review Manager', 'owner', 'Operations', TRUE);

  -- 5) รถตัวอย่าง 5 คัน (ข้อมูลสมมติทั้งหมด ไม่ใช่ทะเบียนจริง)
  INSERT INTO public.vehicles (company_id, plate_number, vehicle_type, brand, model, year)
  VALUES (v_company, 'ดม-1001', 'truck',   'ISUZU',  'FTR 240',   2021) RETURNING id INTO v_v1;
  INSERT INTO public.vehicles (company_id, plate_number, vehicle_type, brand, model, year)
  VALUES (v_company, 'ดม-1002', 'truck',   'HINO',   '500 FC9J',  2020) RETURNING id INTO v_v2;
  INSERT INTO public.vehicles (company_id, plate_number, vehicle_type, brand, model, year)
  VALUES (v_company, 'ดม-1003', 'pickup',  'TOYOTA', 'Hilux Revo',2022) RETURNING id INTO v_v3;
  INSERT INTO public.vehicles (company_id, plate_number, vehicle_type, brand, model, year)
  VALUES (v_company, 'ดม-1004', 'pickup',  'ISUZU',  'D-Max',     2023) RETURNING id INTO v_v4;
  INSERT INTO public.vehicles (company_id, plate_number, vehicle_type, brand, model, year)
  VALUES (v_company, 'ดม-1005', 'van',     'TOYOTA', 'Commuter',  2019) RETURNING id INTO v_v5;

  -- 6) ค่าใช้จ่ายย้อนหลัง 60 วัน ให้แดชบอร์ดและกราฟมีข้อมูลแสดง
  INSERT INTO public.expenses (vehicle_id, type, amount, note, expense_date,
                               fuel_liters, price_per_liter, odometer_km, gas_station, payment_method)
  SELECT
    v.id,
    (ARRAY['fuel','fuel','fuel','toll','repair'])[1 + (g % 5)],
    ROUND((CASE WHEN g % 5 = 4 THEN 2500 + (g * 37 % 4000)
                WHEN g % 5 = 3 THEN 60 + (g * 7 % 180)
                ELSE 1800 + (g * 53 % 2200) END)::numeric, 2),
    'ข้อมูลตัวอย่างสำหรับการตรวจสอบแอป',
    CURRENT_DATE - (g % 60),
    CASE WHEN g % 5 < 3 THEN ROUND((45 + (g * 3 % 40))::numeric, 2) ELSE NULL END,
    CASE WHEN g % 5 < 3 THEN 34.50 ELSE NULL END,
    120000 + (g * 180),
    CASE WHEN g % 5 < 3 THEN (ARRAY['PTT','Bangchak','Shell'])[1 + (g % 3)] ELSE NULL END,
    'cash'
  FROM (VALUES (1),(2),(3),(4),(5)) AS t(n)
  CROSS JOIN generate_series(0, 23) AS g
  JOIN LATERAL (
    SELECT id FROM public.vehicles
    WHERE company_id = v_company ORDER BY plate_number OFFSET t.n - 1 LIMIT 1
  ) v ON TRUE;

  -- 7) งานซ่อมบำรุง — มีทั้งที่ครบกำหนดแล้วและที่กำลังจะถึง
  INSERT INTO public.maintenance (vehicle_id, type, part_category, part_name, description,
                                  due_date, due_km, status, cost)
  VALUES
    (v_v1, 'oil_change', 'engine', 'น้ำมันเครื่อง', 'เปลี่ยนถ่ายน้ำมันเครื่องตามรอบ',
     CURRENT_DATE + 7,   150000, 'pending',   3200),
    (v_v1, 'tire',       'wheel',  'ยางหน้า',      'สลับยางและตั้งศูนย์ล้อ',
     CURRENT_DATE + 30,  155000, 'pending',   8800),
    (v_v2, 'brake',      'brake',  'ผ้าเบรกหน้า',   'ผ้าเบรกเหลือน้อย ควรเปลี่ยน',
     CURRENT_DATE - 3,   142000, 'pending',   4500),
    (v_v3, 'insurance',  'legal',  'พ.ร.บ. + ประกันภัย', 'ต่ออายุประกันภัยชั้น 1',
     CURRENT_DATE + 21,  NULL,    'pending',  18500),
    (v_v4, 'tax',        'legal',  'ภาษีรถประจำปี', 'ต่อภาษีประจำปี',
     CURRENT_DATE + 45,  NULL,    'pending',   2400),
    (v_v5, 'oil_change', 'engine', 'น้ำมันเครื่อง', 'เปลี่ยนถ่ายเรียบร้อยแล้ว',
     CURRENT_DATE - 20,  138000, 'completed',  2900);

  -- 8) เส้นทาง GPS ตัวอย่าง (กรุงเทพฯ -> ชลบุรี) ให้แผนที่มีอะไรให้ดู
  INSERT INTO public.gps_logs (vehicle_id, lat, lng, speed, engine_status, recorded_at)
  SELECT v_v1,
         13.7563 + (g * 0.0125),
         100.5018 + (g * 0.0180),
         CASE WHEN g IN (0, 19) THEN 0 ELSE 55 + (g * 7 % 35) END,
         CASE WHEN g IN (0, 19) THEN 'off' ELSE 'on' END,
         NOW() - ((19 - g) * INTERVAL '6 minutes')
  FROM generate_series(0, 19) AS g;

  INSERT INTO public.gps_logs (vehicle_id, lat, lng, speed, engine_status, recorded_at)
  SELECT v_v3,
         13.7100 - (g * 0.0090),
         100.5300 + (g * 0.0060),
         40 + (g * 11 % 30), 'on',
         NOW() - ((14 - g) * INTERVAL '8 minutes')
  FROM generate_series(0, 14) AS g;

  -- 9) ตำแหน่งปัจจุบันของรถแต่ละคัน ให้แผนที่ขึ้นหมุดทันทีที่เปิดแอป
  IF to_regclass('public.vehicle_current_location') IS NOT NULL THEN
    INSERT INTO public.vehicle_current_location (vehicle_id, lat, lng, speed, heading)
    VALUES
      (v_v1, 13.9938, 100.8438, 0,  90),
      (v_v2, 13.7460, 100.5340, 42, 180),
      (v_v3, 13.5840, 100.6180, 58, 145),
      (v_v4, 13.8210, 100.5610, 0,  0),
      (v_v5, 13.6900, 100.7500, 33, 210)
    ON CONFLICT (vehicle_id) DO UPDATE
      SET lat = EXCLUDED.lat, lng = EXCLUDED.lng,
          speed = EXCLUDED.speed, heading = EXCLUDED.heading;
  END IF;

  -- 10) งานวิ่งย้อนหลัง
  IF to_regclass('public.trips') IS NOT NULL THEN
    INSERT INTO public.trips (vehicle_id, start_time, end_time, distance_km, idle_minutes, fuel_used)
    VALUES
      (v_v1, NOW() - INTERVAL '2 days',  NOW() - INTERVAL '2 days'  + INTERVAL '4 hours',  182.4, 25, 28.6),
      (v_v2, NOW() - INTERVAL '1 day',   NOW() - INTERVAL '1 day'   + INTERVAL '3 hours',  126.8, 14, 19.2),
      (v_v3, NOW() - INTERVAL '5 hours', NOW() - INTERVAL '1 hour',                         88.1,  9, 11.7);
  END IF;

  RAISE NOTICE 'สร้างข้อมูลเดโมเรียบร้อย — company_id = %, user_id = %', v_company, v_uid;
END $$;


-- ------------------------------------------------------------------------------
-- ตรวจสอบผลลัพธ์
-- ------------------------------------------------------------------------------
SELECT c.name AS company,
       (SELECT COUNT(*) FROM public.users     u WHERE u.company_id = c.id) AS users,
       (SELECT COUNT(*) FROM public.vehicles  v WHERE v.company_id = c.id) AS vehicles,
       (SELECT COUNT(*) FROM public.expenses  e
          JOIN public.vehicles v ON v.id = e.vehicle_id WHERE v.company_id = c.id) AS expenses,
       (SELECT COUNT(*) FROM public.maintenance m
          JOIN public.vehicles v ON v.id = m.vehicle_id WHERE v.company_id = c.id) AS maintenance,
       (SELECT COUNT(*) FROM public.gps_logs g
          JOIN public.vehicles v ON v.id = g.vehicle_id WHERE v.company_id = c.id) AS gps_points
FROM public.companies c
WHERE c.name = 'H2H Demo Logistics (Play Review)';
