-- ============================================
-- Migración: Fix bugs críticos
-- Fix #5: is_holiday — filtrar por active=true
-- Fix #6: is_service_session_cancelled — agregar SECURITY DEFINER
-- ============================================

-- Fix #5: is_holiday — solo feriados activos bloquean reservas
CREATE OR REPLACE FUNCTION is_holiday(
  p_company_id UUID,
  p_date DATE
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM holidays
    WHERE company_id = p_company_id AND date = p_date AND active = true
  );
END;
$$;

-- Fix #6: is_service_session_cancelled — SECURITY DEFINER para bypass RLS
CREATE OR REPLACE FUNCTION is_service_session_cancelled(
  p_service_id UUID,
  p_date DATE
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM cancelled_service_sessions
    WHERE service_id = p_service_id AND date = p_date
  );
END;
$$;
