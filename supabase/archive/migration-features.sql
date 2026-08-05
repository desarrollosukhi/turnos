-- ============================================
-- MIGRACIÓN: Cancelación de clases + Ventana de tiempo + Feriados
-- Ejecutar este SQL en Supabase SQL Editor
-- ============================================

-- ============================================
-- 1. COLUMNAS NUEVAS EN empresas
-- ============================================

ALTER TABLE empresas ADD COLUMN minutos_ventana_reserva INTEGER DEFAULT 30;
ALTER TABLE empresas ADD COLUMN minutos_ventana_cancelacion INTEGER DEFAULT 30;
ALTER TABLE empresas ADD COLUMN whatsapp_admin TEXT;

-- ============================================
-- 2. TABLA: cancelled_class_sessions
-- ============================================

CREATE TABLE cancelled_class_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  empresa_id UUID REFERENCES empresas(id) NOT NULL,
  class_id UUID REFERENCES classes(id) ON DELETE CASCADE NOT NULL,
  fecha DATE NOT NULL,
  motivo TEXT,
  cancelled_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  CONSTRAINT cancelled_class_sessions_unique UNIQUE (class_id, fecha)
);

ALTER TABLE cancelled_class_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "cancelled_sessions_select" ON cancelled_class_sessions
  FOR SELECT USING (
    empresa_id IN (
      SELECT empresa_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "cancelled_sessions_admin_insert" ON cancelled_class_sessions
  FOR INSERT WITH CHECK (
    auth.uid() IN (
      SELECT id FROM users WHERE rol = 'admin' AND empresa_id = cancelled_class_sessions.empresa_id
    )
  );

CREATE POLICY "cancelled_sessions_admin_delete" ON cancelled_class_sessions
  FOR DELETE USING (
    auth.uid() IN (
      SELECT id FROM users WHERE rol = 'admin' AND empresa_id = cancelled_class_sessions.empresa_id
    )
  );

-- ============================================
-- 3. TABLA: feriados
-- ============================================

CREATE TABLE feriados (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  empresa_id UUID REFERENCES empresas(id) NOT NULL,
  fecha DATE NOT NULL,
  nombre TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  CONSTRAINT feriados_unique UNIQUE (empresa_id, fecha)
);

ALTER TABLE feriados ENABLE ROW LEVEL SECURITY;

CREATE POLICY "feriados_select" ON feriados
  FOR SELECT USING (
    empresa_id IN (
      SELECT empresa_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "feriados_admin_insert" ON feriados
  FOR INSERT WITH CHECK (
    auth.uid() IN (
      SELECT id FROM users WHERE rol = 'admin' AND empresa_id = feriados.empresa_id
    )
  );

CREATE POLICY "feriados_admin_delete" ON feriados
  FOR DELETE USING (
    auth.uid() IN (
      SELECT id FROM users WHERE rol = 'admin' AND empresa_id = feriados.empresa_id
    )
  );

-- ============================================
-- 4. FUNCIONES
-- ============================================

-- Verificar si una fecha es feriado
CREATE OR REPLACE FUNCTION is_holiday(
  p_empresa_id UUID,
  p_fecha DATE
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM feriados
    WHERE empresa_id = p_empresa_id AND fecha = p_fecha
  );
END;
$$;

-- Verificar si una sesión de clase está cancelada
CREATE OR REPLACE FUNCTION is_class_session_cancelled(
  p_class_id UUID,
  p_fecha DATE
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM cancelled_class_sessions
    WHERE class_id = p_class_id AND fecha = p_fecha
  );
END;
$$;

-- Verificar ventana de tiempo para reserva y cancelación
CREATE OR REPLACE FUNCTION check_booking_window(
  p_class_id UUID,
  p_fecha DATE,
  p_empresa_id UUID
)
RETURNS TABLE(
  puede_reservar BOOLEAN,
  puede_cancelar BOOLEAN,
  minutos_para_clase INTEGER,
  ventana_reserva INTEGER,
  ventana_cancelacion INTEGER,
  clase_cancelada BOOLEAN,
  es_feriado BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_class classes%ROWTYPE;
  v_empresa empresas%ROWTYPE;
  v_fecha_hora_clase TIMESTAMPTZ;
  v_minutos_para_clase INTEGER;
BEGIN
  SELECT * INTO v_class FROM classes WHERE id = p_class_id;
  SELECT * INTO v_empresa FROM empresas WHERE id = p_empresa_id;

  -- Combinar fecha + hora_inicio para obtener timestamp de la clase
  v_fecha_hora_clase := (p_fecha + v_class.hora_inicio)::TIMESTAMPTZ;

  -- Calcular minutos restantes
  v_minutos_para_clase := EXTRACT(EPOCH FROM (v_fecha_hora_clase - now()))::INTEGER / 60;

  RETURN QUERY SELECT
    v_minutos_para_clase > v_empresa.minutos_ventana_reserva,
    v_minutos_para_clase > v_empresa.minutos_ventana_cancelacion,
    v_minutos_para_clase,
    v_empresa.minutos_ventana_reserva,
    v_empresa.minutos_ventana_cancelacion,
    is_class_session_cancelled(p_class_id, p_fecha),
    is_holiday(p_empresa_id, p_fecha);
END;
$$;

-- Cancelar sesión de clase completa (devuelve créditos a todos)
CREATE OR REPLACE FUNCTION cancel_class_session(
  p_class_id UUID,
  p_fecha DATE,
  p_motivo TEXT DEFAULT NULL
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  v_empresa_id UUID;
  v_booking RECORD;
  v_affected_count INTEGER := 0;
BEGIN
  -- Obtener empresa_id de la clase
  SELECT empresa_id INTO v_empresa_id FROM classes WHERE id = p_class_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Clase no encontrada';
  END IF;

  -- Verificar que no esté ya cancelada
  IF is_class_session_cancelled(p_class_id, p_fecha) THEN
    RAISE EXCEPTION 'Esta sesión ya está cancelada';
  END IF;

  -- Crear registro de cancelación
  INSERT INTO cancelled_class_sessions (empresa_id, class_id, fecha, motivo, cancelled_by)
  VALUES (v_empresa_id, p_class_id, p_fecha, p_motivo, auth.uid());

  -- Cancelar todas las reservas activas y devolver créditos
  FOR v_booking IN
    SELECT b.id, b.user_id
    FROM bookings b
    WHERE b.class_id = p_class_id
      AND b.fecha = p_fecha
      AND b.estado = 'reservada'
  LOOP
    -- Cancelar reserva
    UPDATE bookings SET estado = 'cancelada' WHERE id = v_booking.id;

    -- Devolver crédito
    UPDATE users SET creditos = creditos + 1 WHERE id = v_booking.user_id;

    -- Registrar movimiento
    INSERT INTO credit_movements (user_id, cantidad, descripcion)
    VALUES (v_booking.user_id, 1, 'Cancelación de clase por el profe');

    v_affected_count := v_affected_count + 1;
  END LOOP;

  RETURN 'Clase cancelada. ' || v_affected_count || ' alumno(s) afectado(s).';
END;
$$;

-- ============================================
-- 5. MODIFICAR book_class CON VALIDACIONES
-- ============================================

CREATE OR REPLACE FUNCTION book_class(
  p_user_id UUID,
  p_class_id UUID,
  p_fecha DATE,
  p_modalidad modalidad_type
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  v_class classes%ROWTYPE;
  v_empresa_id UUID;
  v_window RECORD;
  v_cupos_disponibles BIGINT;
  v_creditos INTEGER;
  v_booking_exists BIGINT;
BEGIN
  -- Obtener clase y empresa
  SELECT * INTO v_class FROM classes WHERE id = p_class_id AND activo = true;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Clase no encontrada o inactiva';
  END IF;

  v_empresa_id := v_class.empresa_id;

  -- Verificar ventana de tiempo
  SELECT * INTO v_window FROM check_booking_window(p_class_id, p_fecha, v_empresa_id);

  IF v_window.es_feriado THEN
    RAISE EXCEPTION 'No se pueden reservar clases en días feriados';
  END IF;

  IF v_window.clase_cancelada THEN
    RAISE EXCEPTION 'Esta sesión de clase está cancelada';
  END IF;

  IF v_window.puede_reservar = false THEN
    RAISE EXCEPTION 'Estás fuera del tiempo permitido para reservar. Quedan % minutos para la clase. Contactá al profe si tenés una emergencia.', v_window.minutos_para_clase;
  END IF;

  -- Verificar modalidad
  IF p_modalidad = 'presencial' AND v_class.permite_presencial = false THEN
    RAISE EXCEPTION 'Esta clase no permite modalidad presencial';
  END IF;

  IF p_modalidad = 'virtual' AND v_class.permite_virtual = false THEN
    RAISE EXCEPTION 'Esta clase no permite modalidad virtual';
  END IF;

  -- Verificar duplicada
  SELECT COUNT(*) INTO v_booking_exists
  FROM bookings
  WHERE user_id = p_user_id AND class_id = p_class_id AND fecha = p_fecha AND estado = 'reservada';

  IF v_booking_exists > 0 THEN
    RAISE EXCEPTION 'Ya tienes una reserva para esta clase en esta fecha';
  END IF;

  -- Verificar cupos
  IF p_modalidad = 'presencial' THEN
    SELECT v_class.cupos_presenciales - COUNT(*) INTO v_cupos_disponibles
    FROM bookings
    WHERE class_id = p_class_id AND fecha = p_fecha AND modalidad = 'presencial' AND estado = 'reservada';

    IF v_cupos_disponibles <= 0 THEN
      RAISE EXCEPTION 'No hay cupos presenciales disponibles';
    END IF;
  ELSE
    SELECT v_class.cupos_virtuales - COUNT(*) INTO v_cupos_disponibles
    FROM bookings
    WHERE class_id = p_class_id AND fecha = p_fecha AND modalidad = 'virtual' AND estado = 'reservada';

    IF v_cupos_disponibles <= 0 THEN
      RAISE EXCEPTION 'No hay cupos virtuales disponibles';
    END IF;
  END IF;

  -- Verificar créditos
  SELECT creditos INTO v_creditos FROM users WHERE id = p_user_id;
  IF v_creditos <= 0 THEN
    RAISE EXCEPTION 'No tienes créditos disponibles';
  END IF;

  -- Crear reserva
  INSERT INTO bookings (user_id, class_id, fecha, modalidad, estado)
  VALUES (p_user_id, p_class_id, p_fecha, p_modalidad, 'reservada');

  -- Descontar crédito
  UPDATE users SET creditos = creditos - 1 WHERE id = p_user_id;

  -- Registrar movimiento
  INSERT INTO credit_movements (user_id, cantidad, descripcion)
  VALUES (p_user_id, -1, 'Reserva de clase');

  RETURN 'Reserva creada exitosamente';
END;
$$;

-- ============================================
-- 6. MODIFICAR cancel_booking CON VALIDACIONES
-- ============================================

CREATE OR REPLACE FUNCTION cancel_booking(
  p_booking_id UUID,
  p_user_id UUID
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  v_booking bookings%ROWTYPE;
  v_class classes%ROWTYPE;
  v_window RECORD;
BEGIN
  -- Obtener reserva
  SELECT * INTO v_booking FROM bookings WHERE id = p_booking_id AND user_id = p_user_id AND estado = 'reservada';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Reserva no encontrada o ya cancelada';
  END IF;

  -- Obtener clase
  SELECT * INTO v_class FROM classes WHERE id = v_booking.class_id;

  -- Verificar ventana de tiempo
  SELECT * INTO v_window FROM check_booking_window(v_booking.class_id, v_booking.fecha, v_class.empresa_id);

  IF v_window.puede_cancelar = false THEN
    RAISE EXCEPTION 'Estás fuera del tiempo permitido para cancelar. Quedan % minutos para la clase. Contactá al profe si tenés una emergencia.', v_window.minutos_para_clase;
  END IF;

  -- Cancelar reserva
  UPDATE bookings SET estado = 'cancelada' WHERE id = p_booking_id;

  -- Devolver crédito
  UPDATE users SET creditos = creditos + 1 WHERE id = p_user_id;

  -- Registrar movimiento
  INSERT INTO credit_movements (user_id, cantidad, descripcion)
  VALUES (p_user_id, 1, 'Cancelación de reserva');

  RETURN 'Reserva cancelada exitosamente';
END;
$$;
