-- ============================================
-- Migración: Fix add_credits — setear expires_at
-- Los créditos agregados por admin ahora vencen a los 31 días
-- ============================================

CREATE OR REPLACE FUNCTION add_credits(
  p_user_id UUID,
  p_amount INTEGER,
  p_description TEXT
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_target_company UUID;
BEGIN
  SELECT company_id INTO v_target_company FROM users WHERE id = p_user_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Usuario no encontrado';
  END IF;

  IF NOT is_admin_of(v_target_company) THEN
    RAISE EXCEPTION 'No autorizado para modificar créditos de este usuario';
  END IF;

  UPDATE users SET credits = credits + p_amount WHERE id = p_user_id;

  INSERT INTO credit_movements (user_id, amount, description, expires_at)
  VALUES (p_user_id, p_amount, p_description,
    CASE WHEN p_amount > 0 THEN now() + interval '31 days' ELSE NULL END
  );

  RETURN 'Créditos actualizados exitosamente';
END;
$$;
