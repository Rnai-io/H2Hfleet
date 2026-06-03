-- ============================================================
-- H2HFleet: แก้ User ที่ login ได้แต่ไม่มีข้อมูลใน users table
-- รัน SQL นี้ใน Supabase → SQL Editor → New Query → Run
-- ============================================================

-- STEP 1: ดูว่า auth users มีคนไหนที่ยังไม่มี profile ใน users table
SELECT
  au.id,
  au.email,
  au.created_at,
  u.id as profile_id
FROM auth.users au
LEFT JOIN public.users u ON u.id = au.id
WHERE u.id IS NULL;

-- STEP 2: สร้าง company + user profile สำหรับทุก auth user ที่ยังไม่มี
-- (เปลี่ยน 'ชื่อบริษัทของคุณ' ให้เป็นชื่อจริง ถ้าต้องการ)
DO $$
DECLARE
  auth_user RECORD;
  new_company_id UUID;
BEGIN
  FOR auth_user IN
    SELECT au.id, au.email
    FROM auth.users au
    LEFT JOIN public.users u ON u.id = au.id
    WHERE u.id IS NULL
  LOOP
    -- สร้าง company
    INSERT INTO public.companies (name, plan)
    VALUES (split_part(auth_user.email, '@', 1) || ' Fleet', 'free')
    RETURNING id INTO new_company_id;

    -- สร้าง user profile
    INSERT INTO public.users (id, email, name, company_id, role)
    VALUES (
      auth_user.id,
      auth_user.email,
      split_part(auth_user.email, '@', 1),
      new_company_id,
      'owner'
    );

    RAISE NOTICE 'Created profile for: %', auth_user.email;
  END LOOP;
END $$;

-- STEP 3: ยืนยันว่าสร้างสำเร็จ
SELECT
  u.id,
  u.email,
  u.name,
  u.role,
  c.name as company_name
FROM public.users u
JOIN public.companies c ON c.id = u.company_id;
