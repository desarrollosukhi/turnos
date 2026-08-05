-- ============================================
-- Migración: Dashboard KPIs para admin (v2)
-- Función get_admin_dashboard_kpis simplificada
-- ============================================

CREATE OR REPLACE FUNCTION get_admin_dashboard_kpis(p_company_id UUID)
RETURNS TABLE(
  reservas_hoy BIGINT,
  reservas_semana BIGINT,
  clientes_activos BIGINT,
  creditos_total BIGINT,
  tasa_asistencia NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_today DATE := CURRENT_DATE;
  v_week_start DATE;
  v_week_end DATE;
  v_reservas_hoy BIGINT;
  v_reservas_semana BIGINT;
  v_clientes_activos BIGINT;
  v_creditos_total BIGINT;
  v_total_asistencia BIGINT;
  v_asistidos BIGINT;
BEGIN
  -- Calcular inicio de semana (lunes)
  v_week_start := v_today - (EXTRACT(DOW FROM v_today)::INTEGER - 1);
  v_week_end := v_week_start + 6;

  -- Reservas hoy
  SELECT COUNT(*)::BIGINT INTO v_reservas_hoy
  FROM bookings b
  JOIN services s ON s.id = b.service_id
  WHERE s.company_id = p_company_id
    AND b.date = v_today
    AND b.status = 'pending';

  -- Reservas esta semana
  SELECT COUNT(*)::BIGINT INTO v_reservas_semana
  FROM bookings b
  JOIN services s ON s.id = b.service_id
  WHERE s.company_id = p_company_id
    AND b.date >= v_week_start
    AND b.date <= v_week_end
    AND b.status = 'pending';

  -- Clientes activos
  SELECT COUNT(*)::BIGINT INTO v_clientes_activos
  FROM users
  WHERE company_id = p_company_id
    AND role = 'customer'
    AND active = true;

  -- Total créditos
  SELECT COALESCE(SUM(credits), 0)::BIGINT INTO v_creditos_total
  FROM users
  WHERE company_id = p_company_id
    AND role = 'customer'
    AND active = true;

  -- Tasa de asistencia (últimos 30 días)
  SELECT COUNT(*)::BIGINT, COUNT(CASE WHEN status = 'attended' THEN 1 END)::BIGINT
  INTO v_total_asistencia, v_asistidos
  FROM bookings b
  JOIN services s ON s.id = b.service_id
  WHERE s.company_id = p_company_id
    AND b.date >= v_today - INTERVAL '30 days'
    AND b.status IN ('attended', 'no_show');

  RETURN QUERY SELECT
    v_reservas_hoy,
    v_reservas_semana,
    v_clientes_activos,
    v_creditos_total,
    CASE
      WHEN v_total_asistencia = 0 THEN 0::NUMERIC
      ELSE ROUND(v_asistidos * 100.0 / v_total_asistencia, 1)
    END;
END;
$$;
