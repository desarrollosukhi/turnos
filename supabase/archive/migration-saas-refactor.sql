-- ============================================
-- MIGRACIÓN: Renombrar a SaaS platform
-- Ejecutar este SQL en Supabase SQL Editor
-- ============================================

-- ============================================
-- 1. RENOMBRAR TABLAS
-- ============================================

-- empresas → companies
ALTER TABLE IF EXISTS empresas RENAME TO companies;

-- teachers → professionals
ALTER TABLE IF EXISTS teachers RENAME TO professionals;

-- classes → services
ALTER TABLE IF EXISTS classes RENAME TO services;

-- cancelled_class_sessions → cancelled_service_sessions
ALTER TABLE IF EXISTS cancelled_class_sessions RENAME TO cancelled_service_sessions;

-- feriados → holidays
ALTER TABLE IF EXISTS feriados RENAME TO holidays;

-- ============================================
-- 2. RENOMBRAR COLUMNAS
-- ============================================

-- companies (antes empresas)
ALTER TABLE IF EXISTS companies RENAME COLUMN nombre TO name;
-- logo_url ya se llama logo_url, no necesita renombrarse
ALTER TABLE IF EXISTS companies RENAME COLUMN mostrar_alias TO show_alias;
ALTER TABLE IF EXISTS companies RENAME COLUMN whatsapp_admin TO whatsapp;

-- professionals (antes teachers)
ALTER TABLE IF EXISTS professionals RENAME COLUMN nombre TO name;
-- alias, email ya se llaman igual, no necesitan renombrarse
ALTER TABLE IF EXISTS professionals RENAME COLUMN telefono TO phone;
ALTER TABLE IF EXISTS professionals RENAME COLUMN activo TO active;

-- services (antes classes)
ALTER TABLE IF EXISTS services RENAME COLUMN teacher_id TO professional_id;
ALTER TABLE IF EXISTS services RENAME COLUMN nombre TO name;
ALTER TABLE IF EXISTS services RENAME COLUMN dia_semana TO day_of_week;
ALTER TABLE IF EXISTS services RENAME COLUMN hora_inicio TO start_time;
ALTER TABLE IF EXISTS services RENAME COLUMN hora_fin TO end_time;
ALTER TABLE IF EXISTS services RENAME COLUMN permite_presencial TO allows_in_person;
ALTER TABLE IF EXISTS services RENAME COLUMN permite_virtual TO allows_virtual;
ALTER TABLE IF EXISTS services RENAME COLUMN cupos_presenciales TO in_person_capacity;
ALTER TABLE IF EXISTS services RENAME COLUMN cupos_virtuales TO virtual_capacity;
ALTER TABLE IF EXISTS services RENAME COLUMN activo TO active;

-- users
ALTER TABLE IF EXISTS users RENAME COLUMN nombre TO name;
ALTER TABLE IF EXISTS users RENAME COLUMN telefono TO phone;
ALTER TABLE IF EXISTS users RENAME COLUMN creditos TO credits;
ALTER TABLE IF EXISTS users RENAME COLUMN activo TO active;
ALTER TABLE IF EXISTS users RENAME COLUMN rol TO role;
ALTER TABLE IF EXISTS users RENAME COLUMN empresa_id TO company_id;

-- bookings
ALTER TABLE IF EXISTS bookings RENAME COLUMN class_id TO service_id;
ALTER TABLE IF EXISTS bookings RENAME COLUMN modalidad TO modality;
ALTER TABLE IF EXISTS bookings RENAME COLUMN estado TO status;

-- credit_movements
ALTER TABLE IF EXISTS credit_movements RENAME COLUMN cantidad TO amount;
ALTER TABLE IF EXISTS credit_movements RENAME COLUMN descripcion TO description;

-- cancelled_service_sessions
ALTER TABLE IF EXISTS cancelled_service_sessions RENAME COLUMN class_id TO service_id;
ALTER TABLE IF EXISTS cancelled_service_sessions RENAME COLUMN empresa_id TO company_id;
ALTER TABLE IF EXISTS cancelled_service_sessions RENAME COLUMN motivo TO reason;

-- holidays
ALTER TABLE IF EXISTS holidays RENAME COLUMN empresa_id TO company_id;
ALTER TABLE IF EXISTS holidays RENAME COLUMN fecha TO date;
ALTER TABLE IF EXISTS holidays RENAME COLUMN nombre TO name;
ALTER TABLE IF EXISTS holidays RENAME COLUMN activo TO active;

-- ============================================
-- 3. RENOMBRAR ENUMS
-- ============================================

-- modalidad_type → modality_type (cambiar valores)
ALTER TYPE modalidad_type RENAME TO modality_type;
ALTER TYPE modality_type RENAME VALUE 'presencial' TO 'in_person';

-- booking_estado → booking_status (cambiar valores)
ALTER TYPE booking_estado RENAME TO booking_status;
ALTER TYPE booking_status RENAME VALUE 'reservada' TO 'pending';
ALTER TYPE booking_status RENAME VALUE 'cancelada' TO 'cancelled';
ALTER TYPE booking_status RENAME VALUE 'asistio' TO 'attended';
ALTER TYPE booking_status RENAME VALUE 'ausente' TO 'no_show';

-- ============================================
-- 4. NUEVAS TABLAS
-- ============================================

-- Resources
CREATE TABLE IF NOT EXISTS resources (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id UUID REFERENCES companies(id) NOT NULL,
  name TEXT NOT NULL,
  type TEXT,
  capacity INTEGER,
  active BOOLEAN DEFAULT true NOT NULL
);

ALTER TABLE resources ENABLE ROW LEVEL SECURITY;

CREATE POLICY "resources_select" ON resources
  FOR SELECT USING (
    active = true
    AND company_id IN (
      SELECT company_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "resources_admin_all" ON resources
  FOR ALL USING (
    is_admin_of(company_id)
  );

-- Company Settings
CREATE TABLE IF NOT EXISTS company_settings (
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

ALTER TABLE company_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "company_settings_select" ON company_settings
  FOR SELECT USING (
    company_id IN (
      SELECT company_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "company_settings_admin_all" ON company_settings
  FOR ALL USING (
    is_admin_of(company_id)
  );

-- Plans (futuro)
CREATE TABLE IF NOT EXISTS plans (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  features JSONB DEFAULT '{}'::jsonb,
  active BOOLEAN DEFAULT true NOT NULL
);

-- Subscriptions (futuro)
CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id UUID REFERENCES companies(id) NOT NULL,
  plan_id UUID REFERENCES plans(id) NOT NULL,
  status TEXT DEFAULT 'active' NOT NULL CHECK (status IN ('active', 'cancelled', 'expired')),
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- ============================================
-- 5. AGREGAR CAMPOS FALTANTES A services
-- ============================================

-- duration_minutes para APPOINTMENT mode
ALTER TABLE services ADD COLUMN IF NOT EXISTS duration_minutes INTEGER;

-- resource_id para asociar recurso
ALTER TABLE services ADD COLUMN IF NOT EXISTS resource_id UUID REFERENCES resources(id);

-- ============================================
-- 6. AGREGAR CAMPOS FALTANTES A bookings
-- ============================================

-- guest_name y guest_phone para GUEST mode
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS guest_name TEXT;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS guest_phone TEXT;

-- ============================================
-- 7. ACTUALIZAR RLS POLICIES
-- ============================================

-- Renombrar policies de companies
DROP POLICY IF EXISTS "empresas_select_active" ON companies;
DROP POLICY IF EXISTS "empresas_admin_all" ON companies;

CREATE POLICY "companies_select_active" ON companies
  FOR SELECT USING (active = true);

CREATE POLICY "companies_admin_all" ON companies
  FOR ALL USING (is_admin_of(id));

-- Renombrar policies de users
DROP POLICY IF EXISTS "users_select_own" ON users;
DROP POLICY IF EXISTS "users_select_admin" ON users;
DROP POLICY IF EXISTS "users_update_admin" ON users;

CREATE POLICY "users_select_own" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "users_select_admin" ON users
  FOR SELECT USING (is_admin_of(company_id));

CREATE POLICY "users_update_admin" ON users
  FOR UPDATE USING (is_admin_of(company_id));

-- Renombrar policies de professionals
DROP POLICY IF EXISTS "teachers_select_active" ON professionals;
DROP POLICY IF EXISTS "teachers_admin_all" ON professionals;
DROP POLICY IF EXISTS "teachers_select_own_empresa" ON professionals;

CREATE POLICY "professionals_select_active" ON professionals
  FOR SELECT USING (
    active = true
    AND company_id IN (
      SELECT company_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "professionals_admin_all" ON professionals
  FOR ALL USING (is_admin_of(company_id));

-- Renombrar policies de services
DROP POLICY IF EXISTS "classes_select_active" ON services;
DROP POLICY IF EXISTS "classes_admin_all" ON services;
DROP POLICY IF EXISTS "classes_select_teacher" ON services;

CREATE POLICY "services_select_active" ON services
  FOR SELECT USING (
    active = true
    AND company_id IN (
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

-- Renombrar policies de bookings
DROP POLICY IF EXISTS "bookings_select_own" ON bookings;
DROP POLICY IF EXISTS "bookings_select_admin" ON bookings;
DROP POLICY IF EXISTS "bookings_insert_own" ON bookings;
DROP POLICY IF EXISTS "bookings_update_own_cancel" ON bookings;
DROP POLICY IF EXISTS "bookings_update_admin" ON bookings;
DROP POLICY IF EXISTS "bookings_select_teacher" ON bookings;
DROP POLICY IF EXISTS "bookings_update_teacher" ON bookings;

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

-- Renombrar policies de credit_movements
DROP POLICY IF EXISTS "credit_movements_select_own" ON credit_movements;
DROP POLICY IF EXISTS "credit_movements_select_admin" ON credit_movements;
DROP POLICY IF EXISTS "credit_movements_insert_admin" ON credit_movements;

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

-- Renombrar policies de cancelled_service_sessions
DROP POLICY IF EXISTS "cancelled_sessions_select" ON cancelled_service_sessions;
DROP POLICY IF EXISTS "cancelled_sessions_admin_insert" ON cancelled_service_sessions;
DROP POLICY IF EXISTS "cancelled_sessions_admin_delete" ON cancelled_service_sessions;

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

-- Renombrar policies de holidays
DROP POLICY IF EXISTS "feriados_select" ON holidays;
DROP POLICY IF EXISTS "feriados_admin_insert" ON holidays;
DROP POLICY IF EXISTS "feriados_admin_delete" ON holidays;

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

-- ============================================
-- 8. RENOMBRAR FUNCTIONS
-- ============================================

-- Renombrar get_teacher_display_name → get_professional_display_name
DROP FUNCTION IF EXISTS get_teacher_display_name(UUID);
CREATE OR REPLACE FUNCTION get_professional_display_name(p_professional_id UUID)
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
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

-- Renombrar is_holiday → is_holiday (mismo nombre, actualizar referencia)
-- La función ya existe y funciona

-- Renombrar is_class_session_cancelled → is_service_session_cancelled
DROP FUNCTION IF EXISTS is_class_session_cancelled(UUID, DATE);
CREATE OR REPLACE FUNCTION is_service_session_cancelled(p_service_id UUID, p_date DATE)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM cancelled_service_sessions
    WHERE service_id = p_service_id AND date = p_date
  );
END;
$$;

-- ============================================
-- 9. ACTUALIZAR TRIGGER
-- ============================================

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_company_id UUID;
  v_role TEXT;
  v_user_count BIGINT;
BEGIN
  v_company_id := COALESCE(
    (NEW.raw_user_meta_data->>'company_id')::UUID,
    (NEW.raw_user_meta_data->>'empresa_id')::UUID,
    '00000000-0000-0000-0000-000000000001'
  );

  v_role := COALESCE(NEW.raw_user_meta_data->>'role', NEW.raw_user_meta_data->>'rol', 'customer');

  -- Si no se especificó rol, el primer usuario de la empresa es admin
  IF v_role IS NULL OR v_role IN ('customer', 'alumno') THEN
    SELECT COUNT(*) INTO v_user_count FROM public.users WHERE company_id = v_company_id;
    IF v_user_count = 0 THEN
      v_role := 'admin';
    END IF;
  END IF;

  INSERT INTO public.users (id, company_id, name, email, role)
  VALUES (
    NEW.id,
    v_company_id,
    COALESCE(NEW.raw_user_meta_data->>'nombre', NEW.raw_user_meta_data->>'name', 'Sin nombre'),
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

-- ============================================
-- 10. CREAR company_settings POR DEFECTO
-- ============================================

INSERT INTO company_settings (company_id) VALUES ('00000000-0000-0000-0000-000000000001')
ON CONFLICT (company_id) DO NOTHING;
