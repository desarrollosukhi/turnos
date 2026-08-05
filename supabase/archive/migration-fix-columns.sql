-- ============================================
-- FIX COMPLETO: Renombrar tablas + columnas
-- Ejecutar este SQL en Supabase SQL Editor
-- ============================================
-- Este SQL es idempotente: puede ejecutarse múltiples veces.

-- ============================================
-- 1. RENOMBRAR TABLAS (si existen con nombre viejo)
-- ============================================
DO $$ BEGIN ALTER TABLE IF EXISTS empresas RENAME TO companies; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE IF EXISTS teachers RENAME TO professionals; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE IF EXISTS classes RENAME TO services; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE IF EXISTS cancelled_class_sessions RENAME TO cancelled_service_sessions; EXCEPTION WHEN undefined_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE IF EXISTS cancelled_class_sessions RENAME TO cancelled_service_sessions; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE IF EXISTS feriados RENAME TO holidays; EXCEPTION WHEN undefined_table THEN NULL; END $$;

-- ============================================
-- 2. RENOMBRAR COLUMNAS (idempotente)
-- ============================================

-- companies
DO $$ BEGIN ALTER TABLE companies RENAME COLUMN nombre TO name; EXCEPTION WHEN undefined_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE companies RENAME COLUMN mostrar_alias TO show_alias; EXCEPTION WHEN undefined_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE companies RENAME COLUMN whatsapp_admin TO whatsapp; EXCEPTION WHEN undefined_column THEN NULL; END $$;

-- professionals
DO $$ BEGIN ALTER TABLE professionals RENAME COLUMN nombre TO name; EXCEPTION WHEN undefined_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE professionals RENAME COLUMN telefono TO phone; EXCEPTION WHEN undefined_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE professionals RENAME COLUMN activo TO active; EXCEPTION WHEN undefined_column THEN NULL; END $$;

-- services
DO $$ BEGIN ALTER TABLE services RENAME COLUMN teacher_id TO professional_id; EXCEPTION WHEN undefined_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE services RENAME COLUMN nombre TO name; EXCEPTION WHEN undefined_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE services RENAME COLUMN dia_semana TO day_of_week; EXCEPTION WHEN undefined_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE services RENAME COLUMN hora_inicio TO start_time; EXCEPTION WHEN undefined_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE services RENAME COLUMN hora_fin TO end_time; EXCEPTION WHEN undefined_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE services RENAME COLUMN permite_presencial TO allows_in_person; EXCEPTION WHEN undefined_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE services RENAME COLUMN permite_virtual TO allows_virtual; EXCEPTION WHEN undefined_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE services RENAME COLUMN cupos_presenciales TO in_person_capacity; EXCEPTION WHEN undefined_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE services RENAME COLUMN cupos_virtuales TO virtual_capacity; EXCEPTION WHEN undefined_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE services RENAME COLUMN activo TO active; EXCEPTION WHEN undefined_column THEN NULL; END $$;

-- users
DO $$ BEGIN ALTER TABLE users RENAME COLUMN nombre TO name; EXCEPTION WHEN undefined_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE users RENAME COLUMN telefono TO phone; EXCEPTION WHEN undefined_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE users RENAME COLUMN creditos TO credits; EXCEPTION WHEN undefined_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE users RENAME COLUMN activo TO active; EXCEPTION WHEN undefined_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE users RENAME COLUMN rol TO role; EXCEPTION WHEN undefined_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE users RENAME COLUMN empresa_id TO company_id; EXCEPTION WHEN undefined_column THEN NULL; END $$;

-- bookings
DO $$ BEGIN ALTER TABLE bookings RENAME COLUMN class_id TO service_id; EXCEPTION WHEN undefined_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE bookings RENAME COLUMN modalidad TO modality; EXCEPTION WHEN undefined_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE bookings RENAME COLUMN estado TO status; EXCEPTION WHEN undefined_column THEN NULL; END $$;

-- credit_movements
DO $$ BEGIN ALTER TABLE credit_movements RENAME COLUMN cantidad TO amount; EXCEPTION WHEN undefined_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE credit_movements RENAME COLUMN descripcion TO description; EXCEPTION WHEN undefined_column THEN NULL; END $$;

-- cancelled_service_sessions
DO $$ BEGIN ALTER TABLE cancelled_service_sessions RENAME COLUMN class_id TO service_id; EXCEPTION WHEN undefined_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE cancelled_service_sessions RENAME COLUMN empresa_id TO company_id; EXCEPTION WHEN undefined_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE cancelled_service_sessions RENAME COLUMN motivo TO reason; EXCEPTION WHEN undefined_column THEN NULL; END $$;

-- holidays
DO $$ BEGIN ALTER TABLE holidays RENAME COLUMN empresa_id TO company_id; EXCEPTION WHEN undefined_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE holidays RENAME COLUMN fecha TO date; EXCEPTION WHEN undefined_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE holidays RENAME COLUMN nombre TO name; EXCEPTION WHEN undefined_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE holidays RENAME COLUMN activo TO active; EXCEPTION WHEN undefined_column THEN NULL; END $$;

-- ============================================
-- 3. RENOMBRAR ENUMS
-- ============================================
DO $$ BEGIN ALTER TYPE modalidad_type RENAME TO modality_type; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN ALTER TYPE modality_type RENAME VALUE 'presencial' TO 'in_person'; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN ALTER TYPE booking_estado RENAME TO booking_status; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN ALTER TYPE booking_status RENAME VALUE 'reservada' TO 'pending'; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN ALTER TYPE booking_status RENAME VALUE 'cancelada' TO 'cancelled'; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN ALTER TYPE booking_status RENAME VALUE 'asistio' TO 'attended'; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN ALTER TYPE booking_status RENAME VALUE 'ausente' TO 'no_show'; EXCEPTION WHEN undefined_object THEN NULL; END $$;

-- ============================================
-- 4. NUEVAS TABLAS
-- ============================================
CREATE TABLE IF NOT EXISTS resources (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id UUID REFERENCES companies(id) NOT NULL,
  name TEXT NOT NULL,
  type TEXT,
  capacity INTEGER,
  active BOOLEAN DEFAULT true NOT NULL
);
ALTER TABLE resources ENABLE ROW LEVEL SECURITY;

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

CREATE TABLE IF NOT EXISTS plans (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  features JSONB DEFAULT '{}'::jsonb,
  active BOOLEAN DEFAULT true NOT NULL
);
ALTER TABLE plans ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id UUID REFERENCES companies(id) NOT NULL,
  plan_id UUID REFERENCES plans(id) NOT NULL,
  status TEXT DEFAULT 'active' NOT NULL CHECK (status IN ('active', 'cancelled', 'expired')),
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 5. NUEVAS COLUMNAS
-- ============================================
ALTER TABLE services ADD COLUMN IF NOT EXISTS duration_minutes INTEGER;
ALTER TABLE services ADD COLUMN IF NOT EXISTS resource_id UUID REFERENCES resources(id);
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS guest_name TEXT;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS guest_phone TEXT;

-- ============================================
-- 6. RLS POLICIES
-- ============================================

-- Limpiar policies viejas
DO $$ BEGIN DROP POLICY IF EXISTS "empresas_select_active" ON companies; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN DROP POLICY IF EXISTS "empresas_admin_all" ON companies; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN DROP POLICY IF EXISTS "users_select_own" ON users; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN DROP POLICY IF EXISTS "users_select_admin" ON users; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN DROP POLICY IF EXISTS "users_update_admin" ON users; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN DROP POLICY IF EXISTS "teachers_select_active" ON professionals; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN DROP POLICY IF EXISTS "teachers_admin_all" ON professionals; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN DROP POLICY IF EXISTS "teachers_select_own_empresa" ON professionals; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN DROP POLICY IF EXISTS "classes_select_active" ON services; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN DROP POLICY IF EXISTS "classes_admin_all" ON services; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN DROP POLICY IF EXISTS "classes_select_teacher" ON services; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN DROP POLICY IF EXISTS "bookings_select_own" ON bookings; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN DROP POLICY IF EXISTS "bookings_select_admin" ON bookings; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN DROP POLICY IF EXISTS "bookings_insert_own" ON bookings; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN DROP POLICY IF EXISTS "bookings_update_own_cancel" ON bookings; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN DROP POLICY IF EXISTS "bookings_update_admin" ON bookings; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN DROP POLICY IF EXISTS "bookings_select_teacher" ON bookings; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN DROP POLICY IF EXISTS "bookings_update_teacher" ON bookings; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN DROP POLICY IF EXISTS "credit_movements_select_own" ON credit_movements; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN DROP POLICY IF EXISTS "credit_movements_select_admin" ON credit_movements; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN DROP POLICY IF EXISTS "credit_movements_insert_admin" ON credit_movements; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN DROP POLICY IF EXISTS "cancelled_sessions_select" ON cancelled_service_sessions; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN DROP POLICY IF EXISTS "cancelled_sessions_admin_insert" ON cancelled_service_sessions; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN DROP POLICY IF EXISTS "cancelled_sessions_admin_delete" ON cancelled_service_sessions; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN DROP POLICY IF EXISTS "feriados_select" ON holidays; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN DROP POLICY IF EXISTS "feriados_admin_insert" ON holidays; EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN DROP POLICY IF EXISTS "feriados_admin_delete" ON holidays; EXCEPTION WHEN undefined_object THEN NULL; END $$;

-- Crear policies nuevas
DO $$ BEGIN CREATE POLICY "companies_select_active" ON companies FOR SELECT USING (active = true); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "companies_admin_all" ON companies FOR ALL USING (is_admin_of(id)); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "users_select_own" ON users FOR SELECT USING (auth.uid() = id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "users_select_admin" ON users FOR SELECT USING (is_admin_of(company_id)); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "users_update_admin" ON users FOR UPDATE USING (is_admin_of(company_id)); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "professionals_select_active" ON professionals FOR SELECT USING (active = true AND company_id IN (SELECT company_id FROM users WHERE id = auth.uid())); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "professionals_admin_all" ON professionals FOR ALL USING (is_admin_of(company_id)); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "services_select_active" ON services FOR SELECT USING (active = true AND company_id IN (SELECT company_id FROM users WHERE id = auth.uid())); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "services_admin_all" ON services FOR ALL USING (is_admin_of(company_id)); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "services_select_professional" ON services FOR SELECT USING (professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "bookings_select_own" ON bookings FOR SELECT USING (auth.uid() = user_id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "bookings_select_admin" ON bookings FOR SELECT USING (service_id IN (SELECT s.id FROM services s WHERE is_admin_of(s.company_id))); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "bookings_insert_own" ON bookings FOR INSERT WITH CHECK (auth.uid() = user_id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "bookings_update_own_cancel" ON bookings FOR UPDATE USING (auth.uid() = user_id AND status = 'pending'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "bookings_update_admin" ON bookings FOR UPDATE USING (service_id IN (SELECT s.id FROM services s WHERE is_admin_of(s.company_id))); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "bookings_select_professional" ON bookings FOR SELECT USING (service_id IN (SELECT s.id FROM services s JOIN professionals p ON p.id = s.professional_id WHERE p.user_id = auth.uid())); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "bookings_update_professional" ON bookings FOR UPDATE USING (service_id IN (SELECT s.id FROM services s JOIN professionals p ON p.id = s.professional_id WHERE p.user_id = auth.uid())); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "credit_movements_select_own" ON credit_movements FOR SELECT USING (auth.uid() = user_id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "credit_movements_select_admin" ON credit_movements FOR SELECT USING (is_admin_of((SELECT company_id FROM users WHERE id = user_id))); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "credit_movements_insert_admin" ON credit_movements FOR INSERT WITH CHECK (is_admin_of((SELECT company_id FROM users WHERE id = user_id))); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "cancelled_sessions_select" ON cancelled_service_sessions FOR SELECT USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid())); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "cancelled_sessions_admin_insert" ON cancelled_service_sessions FOR INSERT WITH CHECK (is_admin_of(company_id)); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "cancelled_sessions_admin_delete" ON cancelled_service_sessions FOR DELETE USING (is_admin_of(company_id)); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "holidays_select" ON holidays FOR SELECT USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid())); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "holidays_admin_insert" ON holidays FOR INSERT WITH CHECK (is_admin_of(company_id)); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "holidays_admin_delete" ON holidays FOR DELETE USING (is_admin_of(company_id)); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================
-- 7. FUNCTIONS
-- ============================================
DROP FUNCTION IF EXISTS get_teacher_display_name(UUID);
CREATE OR REPLACE FUNCTION get_professional_display_name(p_professional_id UUID)
RETURNS TEXT LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT COALESCE(
    (SELECT CASE WHEN cs.show_alias AND p.alias IS NOT NULL AND p.alias != '' THEN p.alias ELSE p.name END
     FROM professionals p JOIN company_settings cs ON cs.company_id = p.company_id WHERE p.id = p_professional_id),
    (SELECT name FROM professionals WHERE id = p_professional_id)
  );
$$;

DROP FUNCTION IF EXISTS is_class_session_cancelled(UUID, DATE);
CREATE OR REPLACE FUNCTION is_service_session_cancelled(p_service_id UUID, p_date DATE)
RETURNS BOOLEAN LANGUAGE plpgsql AS $$
BEGIN
  RETURN EXISTS (SELECT 1 FROM cancelled_service_sessions WHERE service_id = p_service_id AND date = p_date);
END;
$$;

-- ============================================
-- 8. TRIGGER
-- ============================================
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
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
  IF v_role IS NULL OR v_role IN ('customer', 'alumno') THEN
    SELECT COUNT(*) INTO v_user_count FROM public.users WHERE company_id = v_company_id;
    IF v_user_count = 0 THEN v_role := 'admin'; END IF;
  END IF;
  INSERT INTO public.users (id, company_id, name, email, role)
  VALUES (NEW.id, v_company_id, COALESCE(NEW.raw_user_meta_data->>'nombre', NEW.raw_user_meta_data->>'name', 'Sin nombre'), NEW.email, v_role)
  ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, email = EXCLUDED.email, role = EXCLUDED.role, company_id = EXCLUDED.company_id;
  RETURN NEW;
END;
$$;

-- ============================================
-- 9. company_settings DEFAULT
-- ============================================
INSERT INTO company_settings (company_id) VALUES ('00000000-0000-0000-0000-000000000001') ON CONFLICT (company_id) DO NOTHING;
