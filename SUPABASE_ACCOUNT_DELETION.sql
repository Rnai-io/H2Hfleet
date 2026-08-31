-- ==============================================================================
-- H2HFLEET — ACCOUNT DELETION (Google Play policy requirement)
-- Run in Supabase Dashboard -> SQL Editor -> New Query -> RUN
-- ==============================================================================
-- ให้ผู้ใช้ลบบัญชีของตัวเองได้จากในแอป ตามข้อบังคับ Google Play ปี 2024
-- ฟังก์ชันทั้งหมดเป็น SECURITY DEFINER และทำงานกับ auth.uid() ของผู้เรียกเท่านั้น
-- จึงไม่มีทางลบบัญชีคนอื่นได้แม้จะแก้ payload จากฝั่งแอป
-- ==============================================================================


-- ------------------------------------------------------------------------------
-- 1) PREVIEW — บอกผู้ใช้ว่ากำลังจะลบอะไรบ้าง ก่อนกดยืนยัน
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.account_deletion_preview()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid            UUID := auth.uid();
  v_company        UUID;
  v_role           TEXT;
  v_company_name   TEXT;
  v_other_users    INT  := 0;
  v_other_admins   INT  := 0;
  v_vehicles       INT  := 0;
  v_expenses       INT  := 0;
  v_maintenance    INT  := 0;
  v_gps            INT  := 0;
  v_trips          INT  := 0;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  SELECT u.company_id, u.role INTO v_company, v_role
  FROM public.users u WHERE u.id = v_uid;

  IF v_company IS NULL THEN
    RETURN jsonb_build_object(
      'has_profile', false, 'will_delete_company', false,
      'needs_transfer', false, 'vehicles', 0, 'expenses', 0,
      'maintenance', 0, 'gps_points', 0, 'trips', 0,
      'other_users', 0, 'role', COALESCE(v_role, 'unknown')
    );
  END IF;

  SELECT c.name INTO v_company_name FROM public.companies c WHERE c.id = v_company;

  SELECT COUNT(*) INTO v_other_users
  FROM public.users u WHERE u.company_id = v_company AND u.id <> v_uid;

  SELECT COUNT(*) INTO v_other_admins
  FROM public.users u
  WHERE u.company_id = v_company AND u.id <> v_uid
    AND u.role IN ('owner', 'admin');

  SELECT COUNT(*) INTO v_vehicles
  FROM public.vehicles v WHERE v.company_id = v_company;

  SELECT COUNT(*) INTO v_expenses
  FROM public.expenses e
  JOIN public.vehicles v ON v.id = e.vehicle_id
  WHERE v.company_id = v_company;

  SELECT COUNT(*) INTO v_maintenance
  FROM public.maintenance m
  JOIN public.vehicles v ON v.id = m.vehicle_id
  WHERE v.company_id = v_company;

  SELECT COUNT(*) INTO v_gps
  FROM public.gps_logs g
  JOIN public.vehicles v ON v.id = g.vehicle_id
  WHERE v.company_id = v_company;

  IF to_regclass('public.trips') IS NOT NULL THEN
    SELECT COUNT(*) INTO v_trips
    FROM public.trips t
    JOIN public.vehicles v ON v.id = t.vehicle_id
    WHERE v.company_id = v_company;
  END IF;

  RETURN jsonb_build_object(
    'has_profile',         true,
    'role',                COALESCE(v_role, 'owner'),
    'company_name',        COALESCE(v_company_name, ''),
    'other_users',         v_other_users,
    -- ไม่มีใครเหลือในบริษัท -> ลบบริษัททิ้งทั้งก้อน
    'will_delete_company', (v_other_users = 0),
    -- ยังมีคนอื่นอยู่ แต่เราเป็นแอดมินคนสุดท้าย -> ต้องโอนสิทธิ์ก่อน
    'needs_transfer',      (v_other_users > 0
                            AND COALESCE(v_role, 'owner') IN ('owner', 'admin')
                            AND v_other_admins = 0),
    'vehicles',            v_vehicles,
    'expenses',            v_expenses,
    'maintenance',         v_maintenance,
    'gps_points',          v_gps,
    'trips',               v_trips
  );
END;
$$;


-- ------------------------------------------------------------------------------
-- 2) รายชื่อผู้ใช้ที่โอนสิทธิ์ผู้ดูแลให้ได้ (ใช้ตอน needs_transfer = true)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.company_transfer_candidates()
RETURNS TABLE (id UUID, name TEXT, email TEXT, role TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid     UUID := auth.uid();
  v_company UUID;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  SELECT u.company_id INTO v_company FROM public.users u WHERE u.id = v_uid;
  IF v_company IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT u.id, u.name, u.email, u.role
  FROM public.users u
  WHERE u.company_id = v_company
    AND u.id <> v_uid
  ORDER BY
    CASE WHEN u.role IN ('owner', 'admin') THEN 0 ELSE 1 END,
    u.name;
END;
$$;


-- ------------------------------------------------------------------------------
-- 3) DELETE — ลบบัญชีของผู้เรียกอย่างถาวร
-- ------------------------------------------------------------------------------
-- p_transfer_to     : uuid ของผู้ใช้ที่จะรับสิทธิ์ owner ต่อ (จำเป็นเมื่อ needs_transfer)
-- p_delete_company  : ต้องส่ง true เมื่อ will_delete_company เพื่อยืนยันว่ารู้ตัว
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.delete_my_account(
  p_transfer_to    UUID    DEFAULT NULL,
  p_delete_company BOOLEAN DEFAULT FALSE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid           UUID := auth.uid();
  v_company       UUID;
  v_role          TEXT;
  v_other_users   INT := 0;
  v_other_admins  INT := 0;
  v_company_gone  BOOLEAN := FALSE;
  v_vehicle_ids   UUID[];
  v_photos_removed INT := 0;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  SELECT u.company_id, u.role INTO v_company, v_role
  FROM public.users u WHERE u.id = v_uid;

  -- ไม่มี profile ใน public.users (เช่นสมัครค้างไว้) -> ลบเฉพาะ auth user
  IF v_company IS NULL THEN
    DELETE FROM auth.users WHERE id = v_uid;
    RETURN jsonb_build_object('deleted', true, 'company_deleted', false, 'photos_removed', 0);
  END IF;

  SELECT COUNT(*) INTO v_other_users
  FROM public.users u WHERE u.company_id = v_company AND u.id <> v_uid;

  SELECT COUNT(*) INTO v_other_admins
  FROM public.users u
  WHERE u.company_id = v_company AND u.id <> v_uid
    AND u.role IN ('owner', 'admin');

  -- ── กรณี A: เป็นคนสุดท้ายของบริษัท -> ลบบริษัททั้งก้อน ───────────────────
  IF v_other_users = 0 THEN
    IF NOT p_delete_company THEN
      RAISE EXCEPTION 'confirm_company_delete'
        USING HINT = 'You are the last member. Call again with p_delete_company => true.';
    END IF;

    SELECT array_agg(v.id) INTO v_vehicle_ids
    FROM public.vehicles v WHERE v.company_id = v_company;

    -- ลบรูปใน storage (path ขึ้นต้นด้วย "<vehicle_id>/")
    IF v_vehicle_ids IS NOT NULL AND array_length(v_vehicle_ids, 1) > 0 THEN
      WITH removed AS (
        DELETE FROM storage.objects o
        WHERE o.bucket_id IN ('vehicle-photos', 'maintenance-photos', 'expense-receipts')
          AND split_part(o.name, '/', 1) = ANY (
                SELECT unnest(v_vehicle_ids)::text
              )
        RETURNING 1
      )
      SELECT COUNT(*) INTO v_photos_removed FROM removed;
    END IF;

    -- ตารางเสริมที่อาจมีหรือไม่มีในบางสภาพแวดล้อม
    IF to_regclass('public.vehicle_current_location') IS NOT NULL
       AND v_vehicle_ids IS NOT NULL THEN
      DELETE FROM public.vehicle_current_location
      WHERE vehicle_id = ANY (v_vehicle_ids);
    END IF;

    IF to_regclass('public.driver_locations') IS NOT NULL
       AND v_vehicle_ids IS NOT NULL THEN
      DELETE FROM public.driver_locations
      WHERE vehicle_id = ANY (v_vehicle_ids);
    END IF;

    -- companies -> ON DELETE CASCADE ไปยัง users / vehicles / expenses /
    -- maintenance / gps_logs / trips / ai_reports / line_settings
    DELETE FROM public.companies WHERE id = v_company;
    v_company_gone := TRUE;

  -- ── กรณี B: ยังมีคนอื่น แต่เราเป็นแอดมินคนสุดท้าย -> ต้องโอนสิทธิ์ ────────
  ELSIF COALESCE(v_role, 'owner') IN ('owner', 'admin') AND v_other_admins = 0 THEN
    IF p_transfer_to IS NULL THEN
      RAISE EXCEPTION 'transfer_required'
        USING HINT = 'Pass p_transfer_to with another user id in the same company.';
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = p_transfer_to AND u.company_id = v_company AND u.id <> v_uid
    ) THEN
      RAISE EXCEPTION 'invalid_transfer_target';
    END IF;

    UPDATE public.users SET role = 'owner', updated_at = NOW()
    WHERE id = p_transfer_to;
  END IF;

  -- ลบ profile ของตัวเอง (ถ้าบริษัทยังอยู่)
  IF NOT v_company_gone THEN
    DELETE FROM public.users WHERE id = v_uid;
  END IF;

  -- ลบบัญชี auth ทิ้งถาวร -> refresh token ทั้งหมดใช้ไม่ได้อีก
  DELETE FROM auth.users WHERE id = v_uid;

  RETURN jsonb_build_object(
    'deleted',         true,
    'company_deleted', v_company_gone,
    'transferred_to',  p_transfer_to,
    'photos_removed',  v_photos_removed
  );
END;
$$;


-- ------------------------------------------------------------------------------
-- 4) GRANTS — ให้เฉพาะผู้ใช้ที่ล็อกอินแล้วเรียกได้
-- ------------------------------------------------------------------------------
REVOKE ALL ON FUNCTION public.account_deletion_preview()          FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.company_transfer_candidates()       FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.delete_my_account(UUID, BOOLEAN)    FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.account_deletion_preview()       TO authenticated;
GRANT EXECUTE ON FUNCTION public.company_transfer_candidates()    TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_my_account(UUID, BOOLEAN) TO authenticated;


-- ------------------------------------------------------------------------------
-- 5) ตรวจสอบว่าติดตั้งสำเร็จ
-- ------------------------------------------------------------------------------
SELECT p.proname AS function_name,
       pg_get_function_identity_arguments(p.oid) AS arguments,
       p.prosecdef AS security_definer
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN ('account_deletion_preview', 'company_transfer_candidates', 'delete_my_account')
ORDER BY p.proname;
