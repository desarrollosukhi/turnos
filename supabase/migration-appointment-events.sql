-- ============================================
-- MIGRACIÓN: 3 modos de servicio
-- Semanal / Turno / Evento
-- Ejecutar este SQL en Supabase SQL Editor
-- ============================================

-- 1. Nuevo tipo de frecuencia
DO $$ BEGIN
  CREATE TYPE frequency_type AS ENUM ('weekly', 'appointment', 'one_time');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- 2. Agregar campos a services
ALTER TABLE services ADD COLUMN IF NOT EXISTS frequency TEXT DEFAULT 'weekly' CHECK (frequency IN ('weekly', 'appointment', 'one_time'));
ALTER TABLE services ADD COLUMN IF NOT EXISTS days_of_week dia_semana[];
ALTER TABLE services ADD COLUMN IF NOT EXISTS slot_interval_minutes INTEGER;
ALTER TABLE services ADD COLUMN IF NOT EXISTS appointment_start TIME;
ALTER TABLE services ADD COLUMN IF NOT EXISTS appointment_end TIME;
ALTER TABLE services ADD COLUMN IF NOT EXISTS event_date DATE;
ALTER TABLE services ADD COLUMN IF NOT EXISTS event_end_date DATE;

-- 3. Migrar datos existentes: day_of_week → days_of_week
UPDATE services SET days_of_week = ARRAY[day_of_week] WHERE day_of_week IS NOT NULL AND days_of_week IS NULL;

-- 4. Función para obtener slots disponibles (modo turno)
CREATE OR REPLACE FUNCTION get_appointment_slots(
  p_service_id UUID,
  p_date DATE
)
RETURNS TABLE(
  slot_time TIME,
  slot_available BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_service services%ROWTYPE;
  v_current_time TIME;
  v_slot_end TIME;
  v_booking_count BIGINT;
BEGIN
  SELECT * INTO v_service FROM services WHERE id = p_service_id;

  v_current_time := v_service.appointment_start;

  WHILE v_current_time < v_service.appointment_end LOOP
    v_slot_end := v_current_time + (v_service.slot_interval_minutes || ' minutes')::INTERVAL;

    -- Verificar si el slot ya está ocupado
    SELECT COUNT(*) INTO v_booking_count
    FROM bookings b
    WHERE b.service_id = p_service_id
      AND b.date = p_date
      AND b.status = 'pending'
      AND b.modality = 'in_person'
      AND b.guest_name IS NOT NULL;

    -- Para turnos, verificar si hay cupo
    slot_available := v_booking_count < COALESCE(v_service.in_person_capacity, 1);

    slot_time := v_current_time;
    RETURN NEXT;

    v_current_time := v_slot_end;
  END LOOP;
END;
$$;

-- 5. Función para obtener fechas de eventos
CREATE OR REPLACE FUNCTION get_event_dates(
  p_company_id UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE(
  service_id UUID,
  event_date DATE,
  service_name TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.id,
    s.event_date,
    s.name
  FROM services s
  WHERE s.company_id = p_company_id
    AND s.frequency = 'one_time'
    AND s.event_date >= p_start_date
    AND s.event_date <= p_end_date
    AND s.active = true;
END;
$$;
