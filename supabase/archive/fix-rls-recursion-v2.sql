-- ============================================
-- FIX v2: Corregir recursión en policies de users
-- Ejecutar este SQL en Supabase SQL Editor
-- ============================================

-- 1. Crear función SECURITY DEFINER que bypassea RLS
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

-- 2. Recrear las policies problemáticas de users
DROP POLICY IF EXISTS "users_select_admin" ON users;
CREATE POLICY "users_select_admin" ON users
  FOR SELECT USING ( is_admin_of(empresa_id) );

DROP POLICY IF EXISTS "users_update_admin" ON users;
CREATE POLICY "users_update_admin" ON users
  FOR UPDATE USING ( is_admin_of(empresa_id) );
