-- ============================================
-- SCHEMA: Plataforma SaaS de Gestión de Reservas
-- Multi-tenant con tabla companies
-- RLS basado en public.users (no JWT)
-- Seguridad: SECURITY DEFINER + SET search_path + auth.uid()
-- ============================================

-- ENUMS
CREATE TYPE modality_type AS ENUM ('in_person', 'virtual');
CREATE TYPE booking_status AS ENUM ('pending', 'cancelled', 'attended', 'no_show');
CREATE TYPE dia_semana AS ENUM ('lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo');

-- ============================================
-- TABLA: companies
-- ============================================
CREATE TABLE companies (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  business_type TEXT DEFAULT 'YOGA' NOT NULL CHECK (business_type IN ('YOGA', 'GYM', 'PILATES', 'HAIRDRESSER', 'BARBER', 'MEDICAL', 'CUSTOM')),
  active BOOLEAN DEFAULT true NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- ============================================
-- TABLA: company_settings
-- ============================================
CREATE TABLE company_settings (
  company_id UUID REFERENCES companies(id) PRIMARY KEY,
  customer_mode TEXT DEFAULT 'MEMBER' NOT NULL CHECK (customer_mode IN ('MEMBER', 'GUEST')),
  booking_mode TEXT DEFAULT 'CLASS' NOT NULL CHECK (booking_mode IN ('CLASS', 'APPOINTMENT')),
  manage_credits BOOLEAN DEFAULT true NOT NULL,
  allow_virtual BOOLEAN DEFAULT true NOT NULL,
  allow_public_booking BOOLEAN DEFAULT false NOT NULL,
  require_login BOOLEAN DEFAULT true NOT NULL,
  show_alias BOOLEAN DEFAULT false NOT NULL,
  whatsapp TEXT,
  logo_url TEXT,
  minutos_ventana_reserva INTEGER DEFAULT 30 NOT NULL,
  minutos_ventana_cancelacion INTEGER DEFAULT 30 NOT NULL
);

-- ============================================
-- TABLA: users
-- ============================================
CREATE TABLE users (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  company_id UUID REFERENCES companies(id),
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  credits INTEGER DEFAULT 0 NOT NULL CHECK (credits >= 0),
  active BOOLEAN DEFAULT true NOT NULL,
  role TEXT DEFAULT 'customer' NOT NULL CHECK (role IN ('super_admin', 'admin', 'professional', 'customer')),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- ============================================
-- TABLA: professionals
-- ============================================
CREATE TABLE professionals (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id UUID REFERENCES companies(id) NOT NULL,
  user_id UUID REFERENCES auth.users(id),
  name TEXT NOT NULL,
  alias TEXT,
  email TEXT,
  phone TEXT,
  whatsapp TEXT,
  active BOOLEAN DEFAULT true NOT NULL
);

-- ============================================
-- TABLA: resources
-- ============================================
CREATE TABLE resources (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id UUID REFERENCES companies(id) NOT NULL,
  name TEXT NOT NULL,
  type TEXT,
  capacity INTEGER,
  active BOOLEAN DEFAULT true NOT NULL
);

-- ============================================
-- TABLA: services
-- ============================================
CREATE TABLE services (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id UUID REFERENCES companies(id) NOT NULL,
  professional_id UUID REFERENCES professionals(id) NOT NULL,
  resource_id UUID REFERENCES resources(id),
  name TEXT NOT NULL,
  day_of_week dia_semana,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  duration_minutes INTEGER,
  allows_in_person BOOLEAN DEFAULT false NOT NULL,
  allows_virtual BOOLEAN DEFAULT false NOT NULL,
  in_person_capacity INTEGER CHECK (in_person_capacity > 0),
  virtual_capacity INTEGER CHECK (virtual_capacity > 0),
  active BOOLEAN DEFAULT true NOT NULL,
  CONSTRAINT services_modalidad_presencial CHECK (
    allows_in_person = false OR in_person_capacity IS NOT NULL
  ),
  CONSTRAINT services_modalidad_virtual CHECK (
    allows_virtual = false OR virtual_capacity IS NOT NULL
  ),
  CONSTRAINT services_al_menos_una_modalidad CHECK (
    allows_in_person = true OR allows_virtual = true
  )
);

-- ============================================
-- TABLA: bookings
-- ============================================
CREATE TABLE bookings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  service_id UUID REFERENCES services(id) ON DELETE CASCADE NOT NULL,
  date DATE NOT NULL,
  modality modality_type,
  status booking_status DEFAULT 'pending' NOT NULL,
  guest_name TEXT,
  guest_phone TEXT,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- ============================================
-- TABLA: credit_movements
-- ============================================
CREATE TABLE credit_movements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  amount INTEGER NOT NULL,
  description TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- ============================================
-- TABLA: cancelled_service_sessions
-- ============================================
CREATE TABLE cancelled_service_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id UUID REFERENCES companies(id) NOT NULL,
  service_id UUID REFERENCES services(id) ON DELETE CASCADE NOT NULL,
  date DATE NOT NULL,
  reason TEXT,
  cancelled_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  CONSTRAINT cancelled_service_sessions_unique UNIQUE (service_id, date)
);

-- ============================================
-- TABLA: holidays
-- ============================================
CREATE TABLE holidays (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id UUID REFERENCES companies(id) NOT NULL,
  date DATE NOT NULL,
  name TEXT NOT NULL,
  active BOOLEAN DEFAULT true NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  CONSTRAINT holidays_unique UNIQUE (company_id, date)
);

-- ============================================
-- TABLA: plans (futuro)
-- ============================================
CREATE TABLE plans (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  features JSONB DEFAULT '{}'::jsonb,
  active BOOLEAN DEFAULT true NOT NULL
);

-- ============================================
-- TABLA: subscriptions (futuro)
-- ============================================
CREATE TABLE subscriptions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id UUID REFERENCES companies(id) NOT NULL,
  plan_id UUID REFERENCES plans(id) NOT NULL,
  status TEXT DEFAULT 'active' NOT NULL CHECK (status IN ('active', 'cancelled', 'expired')),
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE professionals ENABLE ROW LEVEL SECURITY;
ALTER TABLE resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE cancelled_service_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE holidays ENABLE ROW LEVEL SECURITY;
ALTER TABLE plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- ============================================
-- FUNCIÓN HELPER: is_admin_of
-- ============================================

CREATE OR REPLACE FUNCTION public.is_admin_of(p_company_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid()
      AND role IN ('admin', 'super_admin')
      AND company_id = p_company_id
  );
$$;

-- ============================================
-- POLICIES: companies
-- ============================================

CREATE POLICY "companies_select_active" ON companies
  FOR SELECT USING (active = true);

CREATE POLICY "companies_admin_all" ON companies
  FOR ALL USING (
    exists (
      select 1 from public.users u
      where u.id = auth.uid()
        and u.role IN ('admin', 'super_admin')
        and u.company_id = companies.id
    )
  );

-- ============================================
-- POLICIES: company_settings
-- ============================================

CREATE POLICY "company_settings_select" ON company_settings
  FOR SELECT USING (
    company_id IN (
      SELECT company_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "company_settings_admin_all" ON company_settings
  FOR ALL USING (is_admin_of(company_id));

-- ============================================
-- POLICIES: users
-- ============================================

CREATE POLICY "users_select_own" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "users_select_admin" ON users
  FOR SELECT USING ( is_admin_of(company_id) );

CREATE POLICY "users_update_admin" ON users
  FOR UPDATE USING ( is_admin_of(company_id) );

CREATE POLICY "users_update_own" ON users
  FOR UPDATE USING (auth.uid() = id);

-- ============================================
-- POLICIES: professionals
-- ============================================

CREATE POLICY "professionals_select_active" ON professionals
  FOR SELECT USING (
    active = true
    and company_id IN (
      SELECT company_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "professionals_admin_all" ON professionals
  FOR ALL USING (is_admin_of(company_id));

-- ============================================
-- POLICIES: resources
-- ============================================

CREATE POLICY "resources_select" ON resources
  FOR SELECT USING (
    active = true
    and company_id IN (
      SELECT company_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "resources_admin_all" ON resources
  FOR ALL USING (is_admin_of(company_id));

-- ============================================
-- POLICIES: services
-- ============================================

CREATE POLICY "services_select_active" ON services
  FOR SELECT USING (
    active = true
    and company_id IN (
      SELECT company_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "services_admin_all" ON services
  FOR ALL USING (is_admin_of(company_id));

CREATE POLICY "services_select_professional" ON services
  FOR SELECT USING (
    professional_id IN (
      SELECT id FROM professionals WHERE user_id = auth.uid()
    )
  );

-- ============================================
-- POLICIES: bookings
-- ============================================

CREATE POLICY "bookings_select_own" ON bookings
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "bookings_select_admin" ON bookings
  FOR SELECT USING (
    service_id IN (
      SELECT s.id FROM services s
      WHERE is_admin_of(s.company_id)
    )
  );

CREATE POLICY "bookings_insert_own" ON bookings
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "bookings_update_own_cancel" ON bookings
  FOR UPDATE USING (
    auth.uid() = user_id AND status = 'pending'
  );

CREATE POLICY "bookings_update_admin" ON bookings
  FOR UPDATE USING (
    service_id IN (
      SELECT s.id FROM services s
      WHERE is_admin_of(s.company_id)
    )
  );

CREATE POLICY "bookings_select_professional" ON bookings
  FOR SELECT USING (
    service_id IN (
      SELECT s.id FROM services s
      JOIN professionals p ON p.id = s.professional_id
      WHERE p.user_id = auth.uid()
    )
  );

CREATE POLICY "bookings_update_professional" ON bookings
  FOR UPDATE USING (
    service_id IN (
      SELECT s.id FROM services s
      JOIN professionals p ON p.id = s.professional_id
      WHERE p.user_id = auth.uid()
    )
  );

-- ============================================
-- POLICIES: credit_movements
-- ============================================

CREATE POLICY "credit_movements_select_own" ON credit_movements
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "credit_movements_select_admin" ON credit_movements
  FOR SELECT USING (
    is_admin_of((SELECT company_id FROM users WHERE id = user_id))
  );

CREATE POLICY "credit_movements_insert_admin" ON credit_movements
  FOR INSERT WITH CHECK (
    is_admin_of((SELECT company_id FROM users WHERE id = user_id))
  );

-- ============================================
-- POLICIES: cancelled_service_sessions
-- ============================================

CREATE POLICY "cancelled_sessions_select" ON cancelled_service_sessions
  FOR SELECT USING (
    company_id IN (
      SELECT company_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "cancelled_sessions_admin_insert" ON cancelled_service_sessions
  FOR INSERT WITH CHECK (is_admin_of(company_id));

CREATE POLICY "cancelled_sessions_admin_delete" ON cancelled_service_sessions
  FOR DELETE USING (is_admin_of(company_id));

-- ============================================
-- POLICIES: holidays
-- ============================================

CREATE POLICY "holidays_select" ON holidays
  FOR SELECT USING (
    company_id IN (
      SELECT company_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "holidays_admin_insert" ON holidays
  FOR INSERT WITH CHECK (is_admin_of(company_id));

CREATE POLICY "holidays_admin_delete" ON holidays
  FOR DELETE USING (is_admin_of(company_id));

CREATE POLICY "holidays_admin_update" ON holidays
  FOR UPDATE USING (is_admin_of(company_id));

-- ============================================
-- FUNCIONES
-- ============================================

-- handle_new_user: crea perfil en users al registrarse
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_company_id UUID;
  v_role TEXT;
BEGIN
  v_company_id := (NEW.raw_user_meta_data->>'company_id')::UUID;
  v_role := COALESCE(NEW.raw_user_meta_data->>'role', 'customer');

  INSERT INTO public.users (id, company_id, name, email, role)
  VALUES (
    NEW.id,
    v_company_id,
    COALESCE(NEW.raw_user_meta_data->>'name', 'Sin nombre'),
    NEW.email,
    v_role
  )
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    email = EXCLUDED.email,
    role = EXCLUDED.role,
    company_id = EXCLUDED.company_id;

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

REVOKE EXECUTE ON FUNCTION handle_new_user() FROM anon, authenticated;

-- create_company_for_user: crea empresa y vincula al admin
CREATE OR REPLACE FUNCTION create_company_for_user(
  p_name TEXT,
  p_business_type TEXT DEFAULT 'YOGA'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_role TEXT;
  v_company_count BIGINT;
  v_new_company companies%ROWTYPE;
BEGIN
  SELECT role INTO v_role FROM users WHERE id = v_user_id;
  IF v_role != 'admin' THEN
    RAISE EXCEPTION 'Solo los administradores pueden crear empresas';
  END IF;

  SELECT COUNT(*) INTO v_company_count
  FROM companies c
  WHERE c.id IN (SELECT company_id FROM users WHERE id = v_user_id);

  IF v_company_count >= 3 THEN
    RAISE EXCEPTION 'No se pueden crear más de 3 empresas';
  END IF;

  INSERT INTO companies (name, business_type)
  VALUES (p_name, p_business_type)
  RETURNING * INTO v_new_company;

  INSERT INTO company_settings (company_id)
  VALUES (v_new_company.id);

  UPDATE users SET company_id = v_new_company.id WHERE id = v_user_id;

  RETURN row_to_json(v_new_company);
END;
$$;

-- get_professional_display_name: obtiene nombre display del profesional
CREATE OR REPLACE FUNCTION get_professional_display_name(p_professional_id UUID)
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public, pg_temp
AS $$
  SELECT COALESCE(
    (SELECT CASE
      WHEN cs.show_alias AND p.alias IS NOT NULL AND p.alias != '' THEN p.alias
      ELSE p.name
    END
    FROM professionals p
    JOIN company_settings cs ON cs.company_id = p.company_id
    WHERE p.id = p_professional_id),
    (SELECT name FROM professionals WHERE id = p_professional_id)
  );
$$;

-- is_holiday: verifica si un día es feriado activo
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

-- is_service_session_cancelled: verifica si una sesión está cancelada
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

-- check_booking_window: verifica ventana de tiempo
CREATE OR REPLACE FUNCTION check_booking_window(
  p_service_id UUID,
  p_date DATE,
  p_company_id UUID
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
SET search_path = public, pg_temp
AS $$
DECLARE
  v_service services%ROWTYPE;
  v_settings company_settings%ROWTYPE;
  v_fecha_hora_clase TIMESTAMPTZ;
  v_minutos_para_clase INTEGER;
BEGIN
  SELECT * INTO v_service FROM services WHERE id = p_service_id;
  SELECT * INTO v_settings FROM company_settings WHERE company_id = p_company_id;

  v_fecha_hora_clase := (p_date + v_service.start_time)::TIMESTAMPTZ;
  v_minutos_para_clase := EXTRACT(EPOCH FROM (v_fecha_hora_clase - now()))::INTEGER / 60;

  RETURN QUERY SELECT
    v_minutos_para_clase > v_settings.minutos_ventana_reserva,
    v_minutos_para_clase > v_settings.minutos_ventana_cancelacion,
    v_minutos_para_clase,
    v_settings.minutos_ventana_reserva,
    v_settings.minutos_ventana_cancelacion,
    is_service_session_cancelled(p_service_id, p_date),
    is_holiday(p_company_id, p_date);
END;
$$;

-- get_class_availability: calcula cupos disponibles (SECURITY DEFINER para bypass RLS)
CREATE OR REPLACE FUNCTION get_class_availability(
  p_class_id UUID,
  p_date DATE
)
RETURNS TABLE(
  in_person_capacity_available BIGINT,
  virtual_capacity_available BIGINT,
  total_in_person_bookings BIGINT,
  total_virtual_bookings BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_service services%ROWTYPE;
BEGIN
  SELECT * INTO v_service FROM services WHERE id = p_class_id;

  RETURN QUERY
  SELECT
    COALESCE(v_service.in_person_capacity, 0)::BIGINT - COUNT(CASE WHEN b.modality = 'in_person' AND b.status = 'pending' THEN 1 END),
    COALESCE(v_service.virtual_capacity, 0)::BIGINT - COUNT(CASE WHEN b.modality = 'virtual' AND b.status = 'pending' THEN 1 END),
    COUNT(CASE WHEN b.modality = 'in_person' AND b.status = 'pending' THEN 1 END),
    COUNT(CASE WHEN b.modality = 'virtual' AND b.status = 'pending' THEN 1 END)
  FROM bookings b
  WHERE b.service_id = p_class_id
    AND b.date = p_date;
END;
$$;

-- book_service: reserva un servicio (usa auth.uid(), no acepta p_user_id)
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

-- cancel_booking: cancela una reserva (usa auth.uid())
CREATE OR REPLACE FUNCTION cancel_booking(
  p_booking_id UUID
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_booking bookings%ROWTYPE;
  v_service services%ROWTYPE;
  v_window RECORD;
BEGIN
  SELECT * INTO v_booking FROM bookings WHERE id = p_booking_id AND user_id = v_user_id AND status = 'pending';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Reserva no encontrada o ya cancelada';
  END IF;

  SELECT * INTO v_service FROM services WHERE id = v_booking.service_id;

  SELECT * INTO v_window FROM check_booking_window(v_booking.service_id, v_booking.date, v_service.company_id);

  IF v_window.puede_cancelar = false THEN
    RAISE EXCEPTION 'Fuera del tiempo permitido. Quedan % minutos. Contactá al profesional.', v_window.minutos_para_clase;
  END IF;

  UPDATE bookings SET status = 'cancelled' WHERE id = p_booking_id;
  UPDATE users SET credits = credits + 1 WHERE id = v_user_id;
  INSERT INTO credit_movements (user_id, amount, description)
  VALUES (v_user_id, 1, 'Cancelación de reserva');

  RETURN 'Reserva cancelada exitosamente';
END;
$$;

-- add_credits: agrega créditos (valida que caller sea admin)
CREATE OR REPLACE FUNCTION add_credits(
  p_user_id UUID,
  p_amount INTEGER,
  p_description TEXT
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_target_company UUID;
BEGIN
  SELECT company_id INTO v_target_company FROM users WHERE id = p_user_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Usuario no encontrado';
  END IF;

  IF NOT is_admin_of(v_target_company) THEN
    RAISE EXCEPTION 'No autorizado para modificar créditos de este usuario';
  END IF;

  UPDATE users SET credits = credits + p_amount WHERE id = p_user_id;

  INSERT INTO credit_movements (user_id, amount, description, expires_at)
  VALUES (p_user_id, p_amount, p_description,
    CASE WHEN p_amount > 0 THEN now() + interval '31 days' ELSE NULL END
  );

  RETURN 'Créditos actualizados exitosamente';
END;
$$;

-- mark_attendance: marca asistencia (valida rol + asignación del profesional)
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

-- admin_cancel_booking: permite al admin cancelar reservas de otros usuarios
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

-- cancel_service_session: cancela una sesión completa (valida admin)
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
BEGIN
  SELECT company_id INTO v_company_id FROM services WHERE id = p_service_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Servicio no encontrado';
  END IF;

  IF NOT is_admin_of(v_company_id) THEN
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
    'all',
    CURRENT_DATE,
    true
  );

  RETURN 'Sesión cancelada. ' || v_affected_count || ' reserva(s) afectada(s).';
END;
$$;
