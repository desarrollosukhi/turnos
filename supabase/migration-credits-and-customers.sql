-- ============================================
-- MIGRACIÓN: Créditos con vencimiento + Campos nuevos clientes
-- Ejecutar este SQL en Supabase SQL Editor
-- ============================================

-- 1. Agregar expires_at a credit_movements
ALTER TABLE credit_movements ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ;

-- 2. Migrar créditos existentes: asignar vencimiento 31 días desde hoy
UPDATE credit_movements SET expires_at = now() + interval '31 days' WHERE expires_at IS NULL AND amount > 0;

-- 3. Agregar campos nuevos a users
ALTER TABLE users ADD COLUMN IF NOT EXISTS birth_date DATE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS emergency_contact_name TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS emergency_contact_phone TEXT;

-- 4. Función para obtener balance no expirado
CREATE OR REPLACE FUNCTION get_effective_credits(p_user_id UUID)
RETURNS INTEGER
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT COALESCE(SUM(amount), 0)::INTEGER
  FROM credit_movements
  WHERE user_id = p_user_id
    AND (expires_at IS NULL OR expires_at > now());
$$;

-- 5. Función para obtener créditos por vencer (próximos 7 días)
CREATE OR REPLACE FUNCTION get_expiring_credits(p_user_id UUID)
RETURNS INTEGER
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT COALESCE(SUM(amount), 0)::INTEGER
  FROM credit_movements
  WHERE user_id = p_user_id
    AND amount > 0
    AND expires_at > now()
    AND expires_at <= now() + interval '7 days';
$$;
