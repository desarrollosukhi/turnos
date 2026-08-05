-- ============================================
-- MIGRACIÓN: Trigger admin automático + Auth para alumnos
-- Ejecutar este SQL en Supabase SQL Editor
-- ============================================

-- 1. Actualizar trigger para que el primer usuario sea admin
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_empresa_id UUID;
  v_rol TEXT;
  v_user_count BIGINT;
BEGIN
  v_empresa_id := COALESCE(
    (NEW.raw_user_meta_data->>'empresa_id')::UUID,
    '00000000-0000-0000-0000-000000000001'
  );

  v_rol := COALESCE(NEW.raw_user_meta_data->>'rol', 'alumno');

  -- Si no se especificó rol, el primer usuario de la empresa es admin
  IF v_rol IS NULL OR v_rol = 'alumno' THEN
    SELECT COUNT(*) INTO v_user_count FROM public.users WHERE empresa_id = v_empresa_id;
    IF v_user_count = 0 THEN
      v_rol := 'admin';
    END IF;
  END IF;

  INSERT INTO public.users (id, empresa_id, nombre, email, rol)
  VALUES (
    NEW.id,
    v_empresa_id,
    COALESCE(NEW.raw_user_meta_data->>'nombre', 'Sin nombre'),
    NEW.email,
    v_rol
  )
  ON CONFLICT (id) DO UPDATE SET
    nombre = EXCLUDED.nombre,
    email = EXCLUDED.email,
    rol = EXCLUDED.rol,
    empresa_id = EXCLUDED.empresa_id;

  RETURN NEW;
END;
$$;

-- 2. Actualizar usuario existente a admin si es el único de su empresa
UPDATE public.users
SET rol = 'admin'
WHERE id IN (
  SELECT u.id FROM public.users u
  WHERE u.empresa_id = '00000000-0000-0000-0000-000000000001'
    AND u.rol = 'alumno'
    AND NOT EXISTS (
      SELECT 1 FROM public.users u2
      WHERE u2.empresa_id = u.empresa_id
        AND u2.rol = 'admin'
        AND u2.id != u.id
    )
)
AND empresa_id = '00000000-0000-0000-0000-000000000001';

-- 3. Verificar resultado
SELECT id, email, nombre, rol FROM public.users WHERE empresa_id = '00000000-0000-0000-0000-000000000001';
