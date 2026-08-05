-- ============================================
-- Migración: Fix cancel_service_session
-- Ahora el profesional asignado también puede cancelar sesiones
-- ============================================

CREATE OR REPLACE FUNCTION cancel_service_session(
  p_service_id UUID,
  p_date DATE,
  p_reason TEXT DEFAULT NULL
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_company_id UUID;
  v_booking RECORD;
  v_affected_count INTEGER := 0;
  v_caller_role TEXT;
BEGIN
  SELECT company_id INTO v_company_id FROM services WHERE id = p_service_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Servicio no encontrado';
  END IF;

  SELECT role INTO v_caller_role FROM users WHERE id = auth.uid();

  -- Admin o super_admin: puede cancelar cualquier sesión
  IF v_caller_role IN ('admin', 'super_admin') THEN
    IF NOT is_admin_of(v_company_id) THEN
      RAISE EXCEPTION 'No autorizado para cancelar sesiones';
    END IF;
  -- Professional: solo puede cancelar sesiones de servicios asignados
  ELSIF v_caller_role = 'professional' THEN
    IF NOT EXISTS (
      SELECT 1 FROM services s
      JOIN professionals p ON p.id = s.professional_id
      WHERE s.id = p_service_id AND p.user_id = auth.uid()
    ) THEN
      RAISE EXCEPTION 'No estás asignado a este servicio';
    END IF;
  ELSE
    RAISE EXCEPTION 'No autorizado para cancelar sesiones';
  END IF;

  IF is_service_session_cancelled(p_service_id, p_date) THEN
    RAISE EXCEPTION 'Esta sesión ya está cancelada';
  END IF;

  INSERT INTO cancelled_service_sessions (company_id, service_id, date, reason, cancelled_by)
  VALUES (v_company_id, p_service_id, p_date, p_reason, auth.uid());

  FOR v_booking IN
    SELECT b.id, b.user_id
    FROM bookings b
    WHERE b.service_id = p_service_id
      AND b.date = p_date
      AND b.status = 'pending'
  LOOP
    UPDATE bookings SET status = 'cancelled' WHERE id = v_booking.id;
    IF v_booking.user_id IS NOT NULL THEN
      UPDATE users SET credits = credits + 1 WHERE id = v_booking.user_id;
      INSERT INTO credit_movements (user_id, amount, description)
      VALUES (v_booking.user_id, 1, 'Cancelación de sesión');
    END IF;
    v_affected_count := v_affected_count + 1;
  END LOOP;

  -- Crear anuncio automático
  INSERT INTO announcements (company_id, service_id, title, content, target, date_from, active)
  VALUES (
    v_company_id,
    p_service_id,
    'Sesión cancelada',
    'La sesión del ' || to_char(p_date, 'DD/MM/YYYY') || ' fue cancelada. Se devolvieron los créditos a los alumnos afectados.',
    'service_bookings',
    p_date,
    true
  );

  RETURN 'Sesión cancelada. ' || v_affected_count || ' reserva(s) afectada(s).';
END;
$$;
