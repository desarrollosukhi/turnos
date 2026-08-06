-- ============================================
-- Migración: Agregar UPDATE policy para holidays
-- Permite a admins actualizar feriados (toggle active, editar nombre, etc.)
-- ============================================

DO $$ BEGIN
  CREATE POLICY "holidays_admin_update" ON holidays
    FOR UPDATE USING (is_admin_of(company_id));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
