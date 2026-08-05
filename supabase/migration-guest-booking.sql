-- ============================================
-- MIGRACIÓN: Reservas Guest + Link compartible
-- Ejecutar este SQL en Supabase SQL Editor
-- ============================================

-- 1. Función para reservas de guest (sin auth)
CREATE OR REPLACE FUNCTION book_service_guest(
  p_service_id UUID,
  p_date DATE,
  p_modality modality_type,
  p_guest_name TEXT,
  p_guest_phone TEXT,
  p_guest_email TEXT DEFAULT NULL
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_service services%ROWTYPE;
  v_company_id UUID;
  v_cupos_disponibles BIGINT;
BEGIN
  SELECT * INTO v_service FROM services WHERE id = p_service_id AND active = true;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Servicio no encontrado o inactivo';
  END IF;

  v_company_id := v_service.company_id;

  -- Verificar que la empresa permite bookings de guest
  IF NOT EXISTS (
    SELECT 1 FROM company_settings
    WHERE company_id = v_company_id
    AND customer_mode = 'GUEST'
  ) THEN
    RAISE EXCEPTION 'Esta empresa no permite reservas sin cuenta';
  END IF;

  -- Verificar modalidad
  IF p_modality = 'in_person' AND v_service.allows_in_person = false THEN
    RAISE EXCEPTION 'Este servicio no permite modalidad presencial';
  END IF;

  IF p_modality = 'virtual' AND v_service.allows_virtual = false THEN
    RAISE EXCEPTION 'Este servicio no permite modalidad virtual';
  END IF;

  -- Verificar cupos (capacity = 1 for appointments)
  IF p_modality = 'in_person' THEN
    SELECT v_service.in_person_capacity - COUNT(*) INTO v_cupos_disponibles
    FROM bookings
    WHERE service_id = p_service_id AND date = p_date AND modality = 'in_person' AND status = 'pending';
    IF v_cupos_disponibles <= 0 THEN
      RAISE EXCEPTION 'No hay cupos presenciales disponibles';
    END IF;
  ELSE
    SELECT v_service.virtual_capacity - COUNT(*) INTO v_cupos_disponibles
    FROM bookings
    WHERE service_id = p_service_id AND date = p_date AND modality = 'virtual' AND status = 'pending';
    IF v_cupos_disponibles <= 0 THEN
      RAISE EXCEPTION 'No hay cupos virtuales disponibles';
    END IF;
  END IF;

  -- Crear reserva (sin user_id para guest)
  INSERT INTO bookings (user_id, service_id, date, modality, status, guest_name, guest_phone)
  VALUES (NULL, p_service_id, p_date, p_modality, 'pending', p_guest_name, p_guest_phone);

  RETURN 'Reserva creada exitosamente';
END;
$$;

-- 2. Función para cancelar reservas de guest
CREATE OR REPLACE FUNCTION cancel_booking_guest(
  p_booking_id UUID
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_booking bookings%ROWTYPE;
BEGIN
  SELECT * INTO v_booking FROM bookings WHERE id = p_booking_id AND status = 'pending';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Reserva no encontrada o ya cancelada';
  END IF;

  IF v_booking.user_id IS NOT NULL THEN
    RAISE EXCEPTION 'Use cancel_booking para reservas con cuenta';
  END IF;

  UPDATE bookings SET status = 'cancelled' WHERE id = p_booking_id;
  RETURN 'Reserva cancelada exitosamente';
END;
$$;
