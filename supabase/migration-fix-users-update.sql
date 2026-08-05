-- ============================================
-- Migración: Fix users update — permitir usuario actualizar su propio perfil
-- ============================================

DO $$ BEGIN
  CREATE POLICY "users_update_own" ON users
    FOR UPDATE USING (auth.uid() = id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
