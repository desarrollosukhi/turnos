-- ============================================
-- FIX: Cambiar todas las RLS de JWT a public.users
-- Ejecutar este SQL en Supabase SQL Editor
-- ============================================

-- ============================================
-- 0. FUNCIÓN HELPER (evita recursión en users)
-- ============================================

CREATE OR REPLACE FUNCTION public.is_admin_of(p_empresa_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid()
      AND rol = 'admin'
      AND empresa_id = p_empresa_id
  );
$$;

-- ============================================
-- 1. EMPRESAS
-- ============================================

DROP POLICY IF EXISTS "empresas_select_active" ON empresas;
DROP POLICY IF EXISTS "empresas_admin_all" ON empresas;

CREATE POLICY "empresas_select_active" ON empresas
  FOR SELECT USING (activo = true);

CREATE POLICY "empresas_admin_all" ON empresas
  FOR ALL USING ( is_admin_of(empresa_id) );

-- ============================================
-- 2. USERS
-- ============================================

DROP POLICY IF EXISTS "users_select_own" ON users;
DROP POLICY IF EXISTS "users_select_admin" ON users;
DROP POLICY IF EXISTS "users_update_admin" ON users;

CREATE POLICY "users_select_own" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "users_select_admin" ON users
  FOR SELECT USING ( is_admin_of(empresa_id) );

CREATE POLICY "users_update_admin" ON users
  FOR UPDATE USING ( is_admin_of(empresa_id) );

-- ============================================
-- 3. TEACHERS
-- ============================================

DROP POLICY IF EXISTS "teachers_select_active" ON teachers;
DROP POLICY IF EXISTS "teachers_admin_all" ON teachers;

CREATE POLICY "teachers_select_active" ON teachers
  FOR SELECT USING (
    activo = true
    and exists (
      select 1 from public.users u
      where u.id = auth.uid()
        and u.activo
        and u.empresa_id = teachers.empresa_id
    )
  );

CREATE POLICY "teachers_admin_all" ON teachers
  FOR ALL USING (
    exists (
      select 1 from public.users u
      where u.id = auth.uid()
        and u.rol = 'admin'
        and u.empresa_id = teachers.empresa_id
    )
  );

-- ============================================
-- 4. CLASSES
-- ============================================

DROP POLICY IF EXISTS "classes_select_active" ON classes;
DROP POLICY IF EXISTS "classes_admin_all" ON classes;

CREATE POLICY "classes_select_active" ON classes
  FOR SELECT USING (
    activo = true
    and exists (
      select 1 from public.users u
      where u.id = auth.uid()
        and u.activo
        and u.empresa_id = classes.empresa_id
    )
  );

CREATE POLICY "classes_admin_all" ON classes
  FOR ALL USING (
    exists (
      select 1 from public.users u
      where u.id = auth.uid()
        and u.rol = 'admin'
        and u.empresa_id = classes.empresa_id
    )
  );

-- ============================================
-- 5. BOOKINGS
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
    exists (
      select 1 from public.users u
      join classes c on c.empresa_id = u.empresa_id
      where u.id = auth.uid()
        and u.rol = 'admin'
        and c.id = bookings.class_id
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
    exists (
      select 1 from public.users u
      join classes c on c.empresa_id = u.empresa_id
      where u.id = auth.uid()
        and u.rol = 'admin'
        and c.id = bookings.class_id
    )
  );

-- ============================================
-- 6. CREDIT_MOVEMENTS
-- ============================================

DROP POLICY IF EXISTS "credit_movements_select_own" ON credit_movements;
DROP POLICY IF EXISTS "credit_movements_select_admin" ON credit_movements;
DROP POLICY IF EXISTS "credit_movements_insert_admin" ON credit_movements;

CREATE POLICY "credit_movements_select_own" ON credit_movements
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "credit_movements_select_admin" ON credit_movements
  FOR SELECT USING (
    exists (
      select 1 from public.users u
      where u.id = auth.uid()
        and u.rol = 'admin'
        and u.empresa_id = (
          select empresa_id from public.users where id = credit_movements.user_id
        )
    )
  );

CREATE POLICY "credit_movements_insert_admin" ON credit_movements
  FOR INSERT WITH CHECK (
    exists (
      select 1 from public.users u
      where u.id = auth.uid()
        and u.rol = 'admin'
        and u.empresa_id = (
          select empresa_id from public.users where id = credit_movements.user_id
        )
    )
  );

-- ============================================
-- 7. CANCELLED_CLASS_SESSIONS
-- ============================================

DROP POLICY IF EXISTS "cancelled_sessions_select" ON cancelled_class_sessions;
DROP POLICY IF EXISTS "cancelled_sessions_admin_insert" ON cancelled_class_sessions;
DROP POLICY IF EXISTS "cancelled_sessions_admin_delete" ON cancelled_class_sessions;

CREATE POLICY "cancelled_sessions_select" ON cancelled_class_sessions
  FOR SELECT USING (
    exists (
      select 1 from public.users u
      where u.id = auth.uid()
        and u.activo
        and u.empresa_id = cancelled_class_sessions.empresa_id
    )
  );

CREATE POLICY "cancelled_sessions_admin_insert" ON cancelled_class_sessions
  FOR INSERT WITH CHECK (
    exists (
      select 1 from public.users u
      where u.id = auth.uid()
        and u.rol = 'admin'
        and u.empresa_id = cancelled_class_sessions.empresa_id
    )
  );

CREATE POLICY "cancelled_sessions_admin_delete" ON cancelled_class_sessions
  FOR DELETE USING (
    exists (
      select 1 from public.users u
      where u.id = auth.uid()
        and u.rol = 'admin'
        and u.empresa_id = cancelled_class_sessions.empresa_id
    )
  );

-- ============================================
-- 8. FERIADOS
-- ============================================

DROP POLICY IF EXISTS "feriados_select" ON feriados;
DROP POLICY IF EXISTS "feriados_admin_insert" ON feriados;
DROP POLICY IF EXISTS "feriados_admin_delete" ON feriados;

CREATE POLICY "feriados_select" ON feriados
  FOR SELECT USING (
    exists (
      select 1 from public.users u
      where u.id = auth.uid()
        and u.activo
        and u.empresa_id = feriados.empresa_id
    )
  );

CREATE POLICY "feriados_admin_insert" ON feriados
  FOR INSERT WITH CHECK (
    exists (
      select 1 from public.users u
      where u.id = auth.uid()
        and u.rol = 'admin'
        and u.empresa_id = feriados.empresa_id
    )
  );

CREATE POLICY "feriados_admin_delete" ON feriados
  FOR DELETE USING (
    exists (
      select 1 from public.users u
      where u.id = auth.uid()
        and u.rol = 'admin'
        and u.empresa_id = feriados.empresa_id
    )
  );
