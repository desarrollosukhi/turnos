-- ============================================
-- Migración: Admin cancela reservas + Fix mark_attendance
-- ============================================

-- 1. Función admin_cancel_booking: permite al admin cancelar reservas de otros usuarios
CREATE OR REPLACE FUNCTION admin_cancel_booking(p_booking_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_booking bookings%ROWTYPE;
  v_service services%ROWTYPE;
BEGIN
  SELECT * INTO v_booking FROM bookings WHERE id = p_booking_id AND status = 'pending';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Reserva no encontrada o ya cancelada';
  END IF;

  SELECT * INTO v_service FROM services WHERE id = v_booking.service_id;

  IF NOT is_admin_of(v_service.company_id) THEN
    RAISE EXCEPTION 'No autorizado para cancelar esta reserva';
  END IF;

  UPDATE bookings SET status = 'cancelled' WHERE id = p_booking_id;

  IF v_booking.user_id IS NOT NULL THEN
    UPDATE users SET credits = credits + 1 WHERE id = v_booking.user_id;
    INSERT INTO credit_movements (user_id, amount, description)
    VALUES (v_booking.user_id, 1, 'Cancelación de reserva por admin');
  END IF;

  RETURN 'Reserva cancelada exitosamente';
END;
$$;

-- 2. Fix mark_attendance: validar que el profesional esté asignado al servicio
CREATE OR REPLACE FUNCTION mark_attendance(
  p_booking_id UUID,
  p_estado booking_status
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_caller_role TEXT;
  v_service_company UUID;
  v_service_id UUID;
BEGIN
  SELECT role INTO v_caller_role FROM users WHERE id = v_caller_id;

  IF v_caller_role NOT IN ('admin', 'professional', 'super_admin') THEN
    RAISE EXCEPTION 'No autorizado para marcar asistencia';
  END IF;

  SELECT s.company_id, s.id INTO v_service_company, v_service_id
  FROM bookings b
  JOIN services s ON s.id = b.service_id
  WHERE b.id = p_booking_id;

  IF v_caller_role = 'professional' THEN
    IF NOT EXISTS (
      SELECT 1 FROM services s
      JOIN professionals p ON p.id = s.professional_id
      WHERE s.id = v_service_id AND p.user_id = v_caller_id
    ) THEN
      RAISE EXCEPTION 'No estás asignado a este servicio';
    END IF;
  ELSIF NOT is_admin_of(v_service_company) THEN
    RAISE EXCEPTION 'No autorizado para esta reserva';
  END IF;

  UPDATE bookings SET status = p_estado WHERE id = p_booking_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Reserva no encontrada';
  END IF;
  RETURN 'Asistencia actualizada';
END;
$$;
