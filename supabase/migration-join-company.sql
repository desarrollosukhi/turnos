-- ============================================
-- Migración: join_company — permite a customers unirse a una empresa
-- ============================================

CREATE OR REPLACE FUNCTION join_company(p_company_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_role TEXT;
  v_current_company UUID;
BEGIN
  SELECT role, company_id INTO v_role, v_current_company
  FROM users WHERE id = v_user_id;

  IF v_role NOT IN ('customer', 'professional') THEN
    RAISE EXCEPTION 'Solo clientes y profesionales pueden unirse a una empresa';
  END IF;

  IF v_current_company IS NOT NULL THEN
    RAISE EXCEPTION 'Ya pertenecés a una empresa';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM companies WHERE id = p_company_id AND active = true) THEN
    RAISE EXCEPTION 'Empresa no encontrada o inactiva';
  END IF;

  UPDATE users SET company_id = p_company_id WHERE id = v_user_id;
  RETURN 'Te uniste a la empresa exitosamente';
END;
$$;
