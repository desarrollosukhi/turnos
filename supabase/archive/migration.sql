-- ============================================
-- MIGRACIÓN: Multi-tenant (empresas)
-- Ejecutar este SQL en Supabase SQL Editor
-- ============================================

-- 1. Crear tabla empresas
CREATE TABLE empresas (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre TEXT NOT NULL,
  activo BOOLEAN DEFAULT true NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE empresas ENABLE ROW LEVEL SECURITY;

-- Policies: empresas
CREATE POLICY "empresas_select_active" ON empresas
  FOR SELECT USING (activo = true);

CREATE POLICY "empresas_admin_all" ON empresas
  FOR ALL USING (
    auth.uid() IN (SELECT id FROM users WHERE rol = 'admin')
  );

-- 2. Insertar empresa por defecto (para datos existentes)
INSERT INTO empresas (id, nombre) VALUES ('00000000-0000-0000-0000-000000000001', 'Yoga Studio');

-- 3. Agregar empresa_id a users
ALTER TABLE users ADD COLUMN empresa_id UUID REFERENCES empresas(id) DEFAULT '00000000-0000-0000-0000-000000000001';

-- Asignar empresa por defecto a usuarios existentes
UPDATE users SET empresa_id = '00000000-0000-0000-0000-000000000001' WHERE empresa_id IS NULL;

ALTER TABLE users ALTER COLUMN empresa_id SET NOT NULL;

-- 4. Agregar empresa_id a teachers
ALTER TABLE teachers ADD COLUMN empresa_id UUID REFERENCES empresas(id) DEFAULT '00000000-0000-0000-0000-000000000001';

UPDATE teachers SET empresa_id = '00000000-0000-0000-0000-000000000001' WHERE empresa_id IS NULL;

ALTER TABLE teachers ALTER COLUMN empresa_id SET NOT NULL;

-- 5. Agregar empresa_id a classes
ALTER TABLE classes ADD COLUMN empresa_id UUID REFERENCES empresas(id) DEFAULT '00000000-0000-0000-0000-000000000001';

UPDATE classes SET empresa_id = '00000000-0000-0000-0000-000000000001' WHERE empresa_id IS NULL;

ALTER TABLE classes ALTER COLUMN empresa_id SET NOT NULL;

-- 6. Actualizar RLS policies con empresa_id

-- Drops policies existentes
DROP POLICY IF EXISTS "users_select_own" ON users;
DROP POLICY IF EXISTS "users_select_admin" ON users;
DROP POLICY IF EXISTS "users_update_admin" ON users;
DROP POLICY IF EXISTS "teachers_select_active" ON teachers;
DROP POLICY IF EXISTS "teachers_admin_all" ON teachers;
DROP POLICY IF EXISTS "classes_select_active" ON classes;
DROP POLICY IF EXISTS "classes_admin_all" ON classes;

-- Policies: users (con empresa_id)
CREATE POLICY "users_select_own" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "users_select_admin" ON users
  FOR SELECT USING (
    auth.uid() IN (SELECT id FROM users WHERE rol = 'admin' AND empresa_id = users.empresa_id)
  );

CREATE POLICY "users_update_admin" ON users
  FOR UPDATE USING (
    auth.uid() IN (SELECT id FROM users WHERE rol = 'admin' AND empresa_id = users.empresa_id)
  );

-- Policies: teachers (con empresa_id)
CREATE POLICY "teachers_select_active" ON teachers
  FOR SELECT USING (
    activo = true AND empresa_id IN (
      SELECT empresa_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "teachers_admin_all" ON teachers
  FOR ALL USING (
    auth.uid() IN (
      SELECT id FROM users WHERE rol = 'admin' AND empresa_id = teachers.empresa_id
    )
  );

-- Policies: classes (con empresa_id)
CREATE POLICY "classes_select_active" ON classes
  FOR SELECT USING (
    activo = true AND empresa_id IN (
      SELECT empresa_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "classes_admin_all" ON classes
  FOR ALL USING (
    auth.uid() IN (
      SELECT id FROM users WHERE rol = 'admin' AND empresa_id = classes.empresa_id
    )
  );

-- Policies: bookings (actualizar para usar empresa_id via classes)
DROP POLICY IF EXISTS "bookings_select_own" ON bookings;
DROP POLICY IF EXISTS "bookings_select_admin" ON bookings;
DROP POLICY IF EXISTS "bookings_insert_own" ON bookings;
DROP POLICY IF EXISTS "bookings_update_own_cancel" ON bookings;
DROP POLICY IF EXISTS "bookings_update_admin" ON bookings;

CREATE POLICY "bookings_select_own" ON bookings
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "bookings_select_admin" ON bookings
  FOR SELECT USING (
    auth.uid() IN (
      SELECT u.id FROM users u
      JOIN classes c ON c.empresa_id = u.empresa_id
      WHERE u.rol = 'admin' AND c.id = bookings.class_id
    )
  );

CREATE POLICY "bookings_insert_own" ON bookings
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "bookings_update_own_cancel" ON bookings
  FOR UPDATE USING (
    auth.uid() = user_id AND estado = 'reservada'
  );

CREATE POLICY "bookings_update_admin" ON bookings
  FOR UPDATE USING (
    auth.uid() IN (
      SELECT u.id FROM users u
      JOIN classes c ON c.empresa_id = u.empresa_id
      WHERE u.rol = 'admin' AND c.id = bookings.class_id
    )
  );

-- Policies: credit_movements (actualizar)
DROP POLICY IF EXISTS "credit_movements_select_own" ON credit_movements;
DROP POLICY IF EXISTS "credit_movements_select_admin" ON credit_movements;
DROP POLICY IF EXISTS "credit_movements_insert_admin" ON credit_movements;

CREATE POLICY "credit_movements_select_own" ON credit_movements
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "credit_movements_select_admin" ON credit_movements
  FOR SELECT USING (
    auth.uid() IN (
      SELECT id FROM users WHERE rol = 'admin' AND empresa_id = (
        SELECT empresa_id FROM users WHERE id = credit_movements.user_id
      )
    )
  );

CREATE POLICY "credit_movements_insert_admin" ON credit_movements
  FOR INSERT WITH CHECK (
    auth.uid() IN (
      SELECT id FROM users WHERE rol = 'admin' AND empresa_id = (
        SELECT empresa_id FROM users WHERE id = credit_movements.user_id
      )
    )
  );

-- 7. Actualizar trigger handle_new_user para incluir empresa_id
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.users (id, nombre, email, rol, empresa_id)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'nombre', 'Sin nombre'),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'rol', 'alumno'),
    COALESCE(
      (NEW.raw_user_meta_data->>'empresa_id')::UUID,
      '00000000-0000-0000-0000-000000000001'
    )
  );
  RETURN NEW;
END;
$$;
