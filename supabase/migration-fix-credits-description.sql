-- ============================================
-- Migración: Fix descripción de créditos — incluir nombre del servicio
-- ============================================

CREATE OR REPLACE FUNCTION book_service(
  p_service_id UUID,
  p_date DATE,
  p_modality modality_type
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_service services%ROWTYPE;
  v_company_id UUID;
  v_window RECORD;
  v_cupos_disponibles BIGINT;
  v_credits INTEGER;
  v_booking_exists BIGINT;
BEGIN
  SELECT * INTO v_service FROM services WHERE id = p_service_id AND active = true;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Servicio no encontrado o inactivo';
  END IF;

  v_company_id := v_service.company_id;

  SELECT * INTO v_window FROM check_booking_window(p_service_id, p_date, v_company_id);

  IF v_window.es_feriado THEN
    RAISE EXCEPTION 'No se pueden reservar en días feriados';
  END IF;

  IF v_window.clase_cancelada THEN
    RAISE EXCEPTION 'Esta sesión está cancelada';
  END IF;

  IF v_window.puede_reservar = false THEN
    RAISE EXCEPTION 'Fuera del tiempo permitido. Quedan % minutos. Contactá al profesional.', v_window.minutos_para_clase;
  END IF;

  IF p_modality = 'in_person' AND v_service.allows_in_person = false THEN
    RAISE EXCEPTION 'Este servicio no permite modalidad presencial';
  END IF;

  IF p_modality = 'virtual' AND v_service.allows_virtual = false THEN
    RAISE EXCEPTION 'Este servicio no permite modalidad virtual';
  END IF;

  SELECT COUNT(*) INTO v_booking_exists
  FROM bookings
  WHERE user_id = v_user_id AND service_id = p_service_id AND date = p_date AND status = 'pending';

  IF v_booking_exists > 0 THEN
    RAISE EXCEPTION 'Ya tenés una reserva para este servicio en esta fecha';
  END IF;

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

  SELECT credits INTO v_credits FROM users WHERE id = v_user_id;
  IF v_credits <= 0 THEN
    RAISE EXCEPTION 'No tenés créditos disponibles';
  END IF;

  INSERT INTO bookings (user_id, service_id, date, modality, status)
  VALUES (v_user_id, p_service_id, p_date, p_modality, 'pending');

  UPDATE users SET credits = credits - 1 WHERE id = v_user_id;

  INSERT INTO credit_movements (user_id, amount, description)
  VALUES (v_user_id, -1, 'Reserva: ' || v_service.name || ' (' || to_char(p_date, 'DD/MM/YYYY') || ')');

  RETURN 'Reserva creada exitosamente';
END;
$$;
