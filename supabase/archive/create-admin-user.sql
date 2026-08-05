-- Crear usuario admin directamente por SQL
-- Cambiar email y contraseña antes de ejecutar

-- 1. Generar un UUID para el usuario
DO $$
DECLARE
  v_user_id UUID := gen_random_uuid();
  v_empresa_id UUID := '00000000-0000-0000-0000-000000000001';
  v_email TEXT := 'desarrollosukhi@gmail.com';
  v_password TEXT := 'SUKHI2024';
  v_nombre TEXT := 'Sukhi Admin';
BEGIN
  -- Insertar en auth.users
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
    jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email')),
    jsonb_build_object('nombre', v_nombre, 'rol', 'admin', 'empresa_id', v_empresa_id::text),
    now(),
    now(),
    '',
    '',
    now()
  );

  -- Insertar en public.users (por si el trigger no firea)
  INSERT INTO public.users (id, empresa_id, nombre, email, rol)
  VALUES (v_user_id, v_empresa_id, v_nombre, v_email, 'admin')
  ON CONFLICT (id) DO NOTHING;

  RAISE NOTICE 'Usuario creado: % con ID %', v_email, v_user_id;
END;
$$;
