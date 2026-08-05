-- ============================================
-- FIX: Trigger + crear usuario admin limpio
-- ============================================

-- 1. Arreglar trigger (no puede UPDATE auth.users desde sí mismo)
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_empresa_id UUID;
  v_rol TEXT;
BEGIN
  v_empresa_id := COALESCE(
    (NEW.raw_user_meta_data->>'empresa_id')::UUID,
    '00000000-0000-0000-0000-000000000001'
  );

  v_rol := COALESCE(NEW.raw_user_meta_data->>'rol', 'alumno');

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

-- 2. Eliminar usuario anterior si existe (ignorar error si no existe)
DELETE FROM auth.users WHERE email = 'desarrollosukhi@gmail.com';
DELETE FROM public.users WHERE email = 'desarrollosukhi@gmail.com';

-- 3. Crear usuario admin limpio
DO $$
DECLARE
  v_user_id UUID := gen_random_uuid();
  v_empresa_id UUID := '00000000-0000-0000-0000-000000000001';
  v_email TEXT := 'desarrollosukhi@gmail.com';
  v_password TEXT := 'SUKHI2024';
  v_nombre TEXT := 'Sukhi Admin';
BEGIN
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    recovery_token,
    last_sign_in_at
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    v_user_id,
    'authenticated',
    'authenticated',
    v_email,
    crypt(v_password, gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    ('{"nombre":"'||v_nombre||'","rol":"admin","empresa_id":"'||v_empresa_id||'"}')::jsonb,
    now(),
    now(),
    '',
    '',
    now()
  );

  RAISE NOTICE 'Usuario creado: % con ID %', v_email, v_user_id;
END;
$$;
