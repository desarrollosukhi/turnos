-- ============================================
-- FUNCIONES DE REPORTES
-- Ejecutar este SQL en Supabase SQL Editor
-- ============================================

-- Reporte 1: Reservas por profesional
CREATE OR REPLACE FUNCTION report_bookings_by_professional(
  p_company_id UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE(
  professional_name TEXT,
  total_reservations BIGINT,
  attended BIGINT,
  no_show BIGINT,
  cancelled BIGINT,
  attendance_rate NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.name,
    COUNT(b.id),
    COUNT(CASE WHEN b.status = 'attended' THEN 1 END),
    COUNT(CASE WHEN b.status = 'no_show' THEN 1 END),
    COUNT(CASE WHEN b.status = 'cancelled' THEN 1 END),
    CASE WHEN COUNT(b.id) > 0
      THEN ROUND(COUNT(CASE WHEN b.status = 'attended' THEN 1 END)::NUMERIC / COUNT(b.id) * 100, 1)
      ELSE 0
    END
  FROM bookings b
  JOIN services s ON s.id = b.service_id
  JOIN professionals p ON p.id = s.professional_id
  WHERE s.company_id = p_company_id
    AND b.date >= p_start_date
    AND b.date <= p_end_date
  GROUP BY p.id, p.name
  ORDER BY COUNT(b.id) DESC;
END;
$$;

-- Reporte 2: Ocupación de servicios
CREATE OR REPLACE FUNCTION report_occupancy(
  p_company_id UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE(
  service_name TEXT,
  professional_name TEXT,
  total_bookings BIGINT,
  total_capacity BIGINT,
  occupancy_rate NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.name,
    p.name,
    COUNT(b.id),
    COALESCE(s.in_person_capacity, 0) + COALESCE(s.virtual_capacity, 0),
    CASE WHEN (COALESCE(s.in_person_capacity, 0) + COALESCE(s.virtual_capacity, 0)) > 0
      THEN ROUND(COUNT(b.id)::NUMERIC / (COALESCE(s.in_person_capacity, 0) + COALESCE(s.virtual_capacity, 0)) * 100, 1)
      ELSE 0
    END
  FROM services s
  JOIN professionals p ON p.id = s.professional_id
  LEFT JOIN bookings b ON b.service_id = s.id AND b.status = 'pending' AND b.date >= p_start_date AND b.date <= p_end_date
  WHERE s.company_id = p_company_id
  GROUP BY s.id, s.name, p.name, s.in_person_capacity, s.virtual_capacity
  ORDER BY COUNT(b.id) DESC;
END;
$$;

-- Reporte 3: Consumo de créditos
CREATE OR REPLACE FUNCTION report_credit_consumption(
  p_company_id UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE(
  customer_name TEXT,
  credits_consumed BIGINT,
  credits_added BIGINT,
  net_balance BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.name,
    COALESCE(SUM(CASE WHEN cm.amount < 0 THEN ABS(cm.amount) END), 0),
    COALESCE(SUM(CASE WHEN cm.amount > 0 THEN cm.amount END), 0),
    COALESCE(SUM(cm.amount), 0)
  FROM credit_movements cm
  JOIN users u ON u.id = cm.user_id
  WHERE u.company_id = p_company_id
    AND cm.created_at >= p_start_date::TIMESTAMPTZ
    AND cm.created_at < (p_end_date + INTERVAL '1 day')::TIMESTAMPTZ
  GROUP BY u.id, u.name
  ORDER BY SUM(ABS(cm.amount)) DESC;
END;
$$;

-- Reporte 4: Tasa de asistencia
CREATE OR REPLACE FUNCTION report_attendance_rate(
  p_company_id UUID,
  p_start_date DATE,
  p_end_date DATE,
  p_professional_id UUID DEFAULT NULL
)
RETURNS TABLE(
  period TEXT,
  total_reservations BIGINT,
  attended BIGINT,
  no_show BIGINT,
  cancelled BIGINT,
  attendance_rate NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN QUERY
  SELECT
    TO_CHAR(b.date, 'YYYY-MM') as period,
    COUNT(b.id),
    COUNT(CASE WHEN b.status = 'attended' THEN 1 END),
    COUNT(CASE WHEN b.status = 'no_show' THEN 1 END),
    COUNT(CASE WHEN b.status = 'cancelled' THEN 1 END),
    CASE WHEN COUNT(b.id) > 0
      THEN ROUND(COUNT(CASE WHEN b.status = 'attended' THEN 1 END)::NUMERIC / COUNT(b.id) * 100, 1)
      ELSE 0
    END
  FROM bookings b
  JOIN services s ON s.id = b.service_id
  WHERE s.company_id = p_company_id
    AND b.date >= p_start_date
    AND b.date <= p_end_date
    AND (p_professional_id IS NULL OR s.professional_id = p_professional_id)
  GROUP BY TO_CHAR(b.date, 'YYYY-MM')
  ORDER BY period;
END;
$$;

-- Reporte 5: Clientes nuevos
CREATE OR REPLACE FUNCTION report_customer_growth(
  p_company_id UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE(
  month TEXT,
  new_customers BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN QUERY
  SELECT
    TO_CHAR(u.created_at, 'YYYY-MM') as month,
    COUNT(u.id)
  FROM users u
  WHERE u.company_id = p_company_id
    AND u.role = 'customer'
    AND u.created_at >= p_start_date::TIMESTAMPTZ
    AND u.created_at < (p_end_date + INTERVAL '1 day')::TIMESTAMPTZ
  GROUP BY TO_CHAR(u.created_at, 'YYYY-MM')
  ORDER BY month;
END;
$$;

-- Reporte 6: Servicios más demandados
CREATE OR REPLACE FUNCTION report_service_popularity(
  p_company_id UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE(
  service_name TEXT,
  professional_name TEXT,
  total_reservations BIGINT,
  percentage NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_total BIGINT;
BEGIN
  SELECT COUNT(*) INTO v_total
  FROM bookings b
  JOIN services s ON s.id = b.service_id
  WHERE s.company_id = p_company_id
    AND b.date >= p_start_date
    AND b.date <= p_end_date;

  RETURN QUERY
  SELECT
    s.name,
    p.name,
    COUNT(b.id),
    CASE WHEN v_total > 0
      THEN ROUND(COUNT(b.id)::NUMERIC / v_total * 100, 1)
      ELSE 0
    END
  FROM bookings b
  JOIN services s ON s.id = b.service_id
  JOIN professionals p ON p.id = s.professional_id
  WHERE s.company_id = p_company_id
    AND b.date >= p_start_date
    AND b.date <= p_end_date
  GROUP BY s.id, s.name, p.name
  ORDER BY COUNT(b.id) DESC;
END;
$$;

-- Reporte 7: Cancelaciones
CREATE OR REPLACE FUNCTION report_cancellations(
  p_company_id UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE(
  cancellation_date DATE,
  service_name TEXT,
  professional_name TEXT,
  reason TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN QUERY
  SELECT
    css.date,
    s.name,
    p.name,
    css.reason
  FROM cancelled_service_sessions css
  JOIN services s ON s.id = css.service_id
  JOIN professionals p ON p.id = s.professional_id
  WHERE css.company_id = p_company_id
    AND css.date >= p_start_date
    AND css.date <= p_end_date
  ORDER BY css.date DESC;
END;
$$;

-- Reporte 8: Reservas de un usuario (para nivel usuario)
CREATE OR REPLACE FUNCTION report_my_bookings(
  p_user_id UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE(
  service_name TEXT,
  professional_name TEXT,
  booking_date DATE,
  modality modality_type,
  status booking_status
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.name,
    p.name,
    b.date,
    b.modality,
    b.status
  FROM bookings b
  JOIN services s ON s.id = b.service_id
  JOIN professionals p ON p.id = s.professional_id
  WHERE b.user_id = p_user_id
    AND b.date >= p_start_date
    AND b.date <= p_end_date
  ORDER BY b.date DESC;
END;
$$;
