-- ============================================
-- CORRECCIÓN: Infinite recursion en policies de users
-- Ejecutar este SQL en Supabase SQL Editor
-- ============================================

-- ============================================
-- 1. Eliminar policies recursivas de users
-- ============================================

DROP POLICY IF EXISTS "users_select_own" ON users;
DROP POLICY IF EXISTS "users_select_admin" ON users;
DROP POLICY IF EXISTS "users_update_admin" ON users;

-- ============================================
-- 2. Recrear policies sin recursión usando auth.jwt()
-- ============================================

-- Own: puede ver su propio perfil
CREATE POLICY "users_select_own" ON users
  FOR SELECT USING (auth.uid() = id);

-- Admin: puede ver usuarios de su empresa (usa JWT, no consulta la tabla)
CREATE POLICY "users_select_admin" ON users
  FOR SELECT USING (
    auth.jwt()->>'rol' = 'admin'
    AND empresa_id = (auth.jwt()->>'empresa_id')::UUID
  );

-- Admin: puede actualizar usuarios de su empresa
CREATE POLICY "users_update_admin" ON users
  FOR UPDATE USING (
    auth.jwt()->>'rol' = 'admin'
    AND empresa_id = (auth.jwt()->>'empresa_id')::UUID
  );

-- ============================================
-- 3. Actualizar policies de teachers
-- ============================================

DROP POLICY IF EXISTS "teachers_select_active" ON teachers;
DROP POLICY IF EXISTS "teachers_admin_all" ON teachers;

CREATE POLICY "teachers_select_active" ON teachers
  FOR SELECT USING (
    activo = true AND empresa_id = (auth.jwt()->>'empresa_id')::UUID
  );

CREATE POLICY "teachers_admin_all" ON teachers
  FOR ALL USING (
    auth.jwt()->>'rol' = 'admin'
    AND empresa_id = (auth.jwt()->>'empresa_id')::UUID
  );

-- ============================================
-- 4. Actualizar policies de classes
-- ============================================

DROP POLICY IF EXISTS "classes_select_active" ON classes;
DROP POLICY IF EXISTS "classes_admin_all" ON classes;

CREATE POLICY "classes_select_active" ON classes
  FOR SELECT USING (
    activo = true AND empresa_id = (auth.jwt()->>'empresa_id')::UUID
  );

CREATE POLICY "classes_admin_all" ON classes
  FOR ALL USING (
    auth.jwt()->>'rol' = 'admin'
    AND empresa_id = (auth.jwt()->>'empresa_id')::UUID
  );

-- ============================================
-- 5. Actualizar policies de bookings
-- ============================================

DROP POLICY IF EXISTS "bookings_select_own" ON bookings;
DROP POLICY IF EXISTS "bookings_select_admin" ON bookings;
DROP POLICY IF EXISTS "bookings_insert_own" ON bookings;
DROP POLICY IF EXISTS "bookings_update_own_cancel" ON bookings;
DROP POLICY IF EXISTS "bookings_update_admin" ON bookings;

CREATE POLICY "bookings_select_own" ON bookings
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "bookings_select_admin" ON bookings
  FOR SELECT USING (
    auth.jwt()->>'rol' = 'admin'
    AND class_id IN (
      SELECT id FROM classes WHERE empresa_id = (auth.jwt()->>'empresa_id')::UUID
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
    auth.jwt()->>'rol' = 'admin'
    AND class_id IN (
      SELECT id FROM classes WHERE empresa_id = (auth.jwt()->>'empresa_id')::UUID
    )
  );

-- ============================================
-- 6. Actualizar policies de credit_movements
-- ============================================

DROP POLICY IF EXISTS "credit_movements_select_own" ON credit_movements;
DROP POLICY IF EXISTS "credit_movements_select_admin" ON credit_movements;
DROP POLICY IF EXISTS "credit_movements_insert_admin" ON credit_movements;

CREATE POLICY "credit_movements_select_own" ON credit_movements
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "credit_movements_select_admin" ON credit_movements
  FOR SELECT USING (
    auth.jwt()->>'rol' = 'admin'
    AND user_id IN (
      SELECT id FROM users WHERE empresa_id = (auth.jwt()->>'empresa_id')::UUID
    )
  );

CREATE POLICY "credit_movements_insert_admin" ON credit_movements
  FOR INSERT WITH CHECK (
    auth.jwt()->>'rol' = 'admin'
    AND user_id IN (
      SELECT id FROM users WHERE empresa_id = (auth.jwt()->>'empresa_id')::UUID
    )
  );

-- ============================================
-- 7. Actualizar policies de cancelled_class_sessions
-- ============================================

DROP POLICY IF EXISTS "cancelled_sessions_select" ON cancelled_class_sessions;
DROP POLICY IF EXISTS "cancelled_sessions_admin_insert" ON cancelled_class_sessions;
DROP POLICY IF EXISTS "cancelled_sessions_admin_delete" ON cancelled_class_sessions;

CREATE POLICY "cancelled_sessions_select" ON cancelled_class_sessions
  FOR SELECT USING (
    empresa_id = (auth.jwt()->>'empresa_id')::UUID
  );

CREATE POLICY "cancelled_sessions_admin_insert" ON cancelled_class_sessions
  FOR INSERT WITH CHECK (
    auth.jwt()->>'rol' = 'admin'
    AND empresa_id = (auth.jwt()->>'empresa_id')::UUID
  );

CREATE POLICY "cancelled_sessions_admin_delete" ON cancelled_class_sessions
  FOR DELETE USING (
    auth.jwt()->>'rol' = 'admin'
    AND empresa_id = (auth.jwt()->>'empresa_id')::UUID
  );

-- ============================================
-- 8. Actualizar policies de feriados
-- ============================================

DROP POLICY IF EXISTS "feriados_select" ON feriados;
DROP POLICY IF EXISTS "feriados_admin_insert" ON feriados;
DROP POLICY IF EXISTS "feriados_admin_delete" ON feriados;

CREATE POLICY "feriados_select" ON feriados
  FOR SELECT USING (
    empresa_id = (auth.jwt()->>'empresa_id')::UUID
  );

CREATE POLICY "feriados_admin_insert" ON feriados
  FOR INSERT WITH CHECK (
    auth.jwt()->>'rol' = 'admin'
    AND empresa_id = (auth.jwt()->>'empresa_id')::UUID
  );

CREATE POLICY "feriados_admin_delete" ON feriados
  FOR DELETE USING (
    auth.jwt()->>'rol' = 'admin'
    AND empresa_id = (auth.jwt()->>'empresa_id')::UUID
  );

-- ============================================
-- 9. Actualizar policies de empresas
-- ============================================

DROP POLICY IF EXISTS "empresas_select_active" ON empresas;
DROP POLICY IF EXISTS "empresas_admin_all" ON empresas;

CREATE POLICY "empresas_select_active" ON empresas
  FOR SELECT USING (
    activo = true AND id = (auth.jwt()->>'empresa_id')::UUID
  );

CREATE POLICY "empresas_admin_all" ON empresas
  FOR ALL USING (
    auth.jwt()->>'rol' = 'admin'
    AND id = (auth.jwt()->>'empresa_id')::UUID
  );

-- ============================================
-- 10. Actualizar trigger handle_new_user
-- Guarda rol y empresa_id en JWT metadata
-- ============================================

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_empresa_id UUID;
  v_rol TEXT;
BEGIN
  -- Determinar empresa_id
  v_empresa_id := COALESCE(
    (NEW.raw_user_meta_data->>'empresa_id')::UUID,
    '00000000-0000-0000-0000-000000000001'
  );

  -- Determinar rol
  v_rol := COALESCE(NEW.raw_user_meta_data->>'rol', 'alumno');

  -- Insertar en tabla users
  INSERT INTO public.users (id, nombre, email, rol, empresa_id)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'nombre', 'Sin nombre'),
    NEW.email,
    v_rol,
    v_empresa_id
  );

  -- Actualizar JWT metadata para que las policies funcionen
  UPDATE auth.users
  SET raw_user_meta_data = raw_user_meta_data || jsonb_build_object(
    'rol', v_rol,
    'empresa_id', v_empresa_id::TEXT
  )
  WHERE id = NEW.id;

  RETURN NEW;
END;
$$;

-- ============================================
-- 11. Actualizar JWT del usuario admin existente
-- (Ejecutar solo si ya tenés un usuario admin)
-- ============================================

-- Descomentar y reemplazar con el UUID de tu usuario admin:
-- UPDATE auth.users
-- SET raw_user_meta_data = raw_user_meta_data || jsonb_build_object(
--   'rol', 'admin',
--   'empresa_id', '00000000-0000-0000-0000-000000000001'
-- )
-- WHERE id = 'TU_USER_UUID_AQUI';
