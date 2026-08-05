-- ============================================
-- Migración: Lista de espera
-- Tabla waitlist + funciones RPC
-- ============================================

-- Tabla waitlist
CREATE TABLE IF NOT EXISTS waitlist (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id UUID REFERENCES companies(id) NOT NULL,
  service_id UUID REFERENCES services(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  date DATE NOT NULL,
  modality modality_type NOT NULL,
  status TEXT DEFAULT 'waiting' NOT NULL CHECK (status IN ('waiting', 'notified', 'booked', 'cancelled')),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  CONSTRAINT waitlist_unique UNIQUE (service_id, date, user_id)
);

ALTER TABLE waitlist ENABLE ROW LEVEL SECURITY;

-- Policies
DO $$ BEGIN
  CREATE POLICY "waitlist_select_own" ON waitlist
    FOR SELECT USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "waitlist_select_admin" ON waitlist
    FOR SELECT USING (
      service_id IN (SELECT s.id FROM services s WHERE is_admin_of(s.company_id))
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "waitlist_insert_own" ON waitlist
    FOR INSERT WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "waitlist_update_admin" ON waitlist
    FOR UPDATE USING (
      service_id IN (SELECT s.id FROM services s WHERE is_admin_of(s.company_id))
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "waitlist_delete_own" ON waitlist
    FOR DELETE USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Unirse a la lista de espera
CREATE OR REPLACE FUNCTION join_waitlist(
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
  v_company_id UUID;
  v_exists BIGINT;
BEGIN
  SELECT company_id INTO v_company_id FROM services WHERE id = p_service_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Servicio no encontrado';
  END IF;

  -- Verificar que no tenga reserva ya activa
  SELECT COUNT(*) INTO v_exists FROM bookings
  WHERE user_id = v_user_id AND service_id = p_service_id AND date = p_date AND status = 'pending';
  IF v_exists > 0 THEN
    RAISE EXCEPTION 'Ya tenés una reserva para este servicio en esta fecha';
  END IF;

  -- Verificar que no esté ya en la waitlist
  SELECT COUNT(*) INTO v_exists FROM waitlist
  WHERE user_id = v_user_id AND service_id = p_service_id AND date = p_date AND status = 'waiting';
  IF v_exists > 0 THEN
    RAISE EXCEPTION 'Ya estás en la lista de espera para esta fecha';
  END IF;

  INSERT INTO waitlist (company_id, service_id, user_id, date, modality)
  VALUES (v_company_id, p_service_id, v_user_id, p_date, p_modality);

  RETURN 'Te agregaste a la lista de espera';
END;
$$;

-- Salir de la lista de espera
CREATE OR REPLACE FUNCTION leave_waitlist(
  p_waitlist_id UUID
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  DELETE FROM waitlist
  WHERE id = p_waitlist_id AND user_id = v_user_id AND status = 'waiting';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No se encontró en la lista de espera';
  END IF;

  RETURN 'Saliste de la lista de espera';
END;
$$;

-- Procesar waitlist cuando se cancela una reserva (llamada desde cancel_booking o cancel_service_session)
CREATE OR REPLACE FUNCTION process_waitlist_for_slot(
  p_service_id UUID,
  p_date DATE,
  p_modality modality_type
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_next_user RECORD;
BEGIN
  -- Buscar el primero en la waitlist para esa fecha y modalidad
  SELECT w.id, w.user_id INTO v_next_user
  FROM waitlist w
  WHERE w.service_id = p_service_id
    AND w.date = p_date
    AND w.modality = p_modality
    AND w.status = 'waiting'
  ORDER BY w.created_at ASC
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  -- Marcar como notificado
  UPDATE waitlist SET status = 'notified' WHERE id = v_next_user.id;

  RETURN v_next_user.user_id;
END;
$$;
