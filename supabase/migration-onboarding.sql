-- ============================================
-- MIGRACIÓN: Onboarding - Registro sin empresa
-- Ejecutar este SQL en Supabase SQL Editor
-- Idempotente: puede ejecutarse múltiples veces
-- ============================================

-- ============================================
-- 1. HACER company_id NULLABLE EN users
-- ============================================
DO $$ BEGIN
  ALTER TABLE users ALTER COLUMN company_id DROP NOT NULL;
EXCEPTION WHEN dependent_objects_still_exist THEN NULL; END $$;

-- ============================================
-- 2. ACTUALIZAR TRIGGER handle_new_user
-- ============================================
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_company_id UUID;
  v_role TEXT;
BEGIN
  v_company_id := (NEW.raw_user_meta_data->>'company_id')::UUID;
  v_role := COALESCE(NEW.raw_user_meta_data->>'role', 'customer');

  INSERT INTO public.users (id, company_id, name, email, role)
  VALUES (
    NEW.id,
    v_company_id,
    COALESCE(NEW.raw_user_meta_data->>'name', 'Sin nombre'),
    NEW.email,
    v_role
  )
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    email = EXCLUDED.email,
    role = EXCLUDED.role,
    company_id = EXCLUDED.company_id;

  RETURN NEW;
END;
$$;

-- ============================================
-- 3. CREAR FUNCIÓN create_company_for_user
-- ============================================
CREATE OR REPLACE FUNCTION create_company_for_user(
  p_name TEXT,
  p_business_type TEXT DEFAULT 'YOGA'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_role TEXT;
  v_company_count BIGINT;
  v_new_company companies%ROWTYPE;
BEGIN
  SELECT role INTO v_role FROM users WHERE id = v_user_id;
  IF v_role != 'admin' THEN
    RAISE EXCEPTION 'Solo los administradores pueden crear empresas';
  END IF;

  SELECT COUNT(*) INTO v_company_count
  FROM companies c
  WHERE c.id IN (SELECT company_id FROM users WHERE id = v_user_id);

  IF v_company_count >= 3 THEN
    RAISE EXCEPTION 'No se pueden crear más de 3 empresas';
  END IF;

  INSERT INTO companies (name, business_type)
  VALUES (p_name, p_business_type)
  RETURNING * INTO v_new_company;

  INSERT INTO company_settings (company_id)
  VALUES (v_new_company.id);

  UPDATE users SET company_id = v_new_company.id WHERE id = v_user_id;

  RETURN row_to_json(v_new_company);
END;
$$;
