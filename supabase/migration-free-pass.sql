-- ============================================
-- MIGRACIÓN: Modo gimnasio + Tipo de acceso
-- Ejecutar este SQL en Supabase SQL Editor
-- ============================================

-- 1. Modo gimnasio en company_settings
ALTER TABLE company_settings ADD COLUMN IF NOT EXISTS gym_mode BOOLEAN DEFAULT false NOT NULL;

-- 2. Horario del gimnasio en companies
ALTER TABLE companies ADD COLUMN IF NOT EXISTS gym_schedule JSONB;

-- 3. Tipo de acceso en users
ALTER TABLE users ADD COLUMN IF NOT EXISTS access_type TEXT DEFAULT 'credits' CHECK (access_type IN ('credits', 'free_pass'));

-- 4. Tabla de pases
CREATE TABLE IF NOT EXISTS free_passes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  company_id UUID REFERENCES companies(id) NOT NULL,
  pass_type TEXT NOT NULL CHECK (pass_type IN ('monthly', 'credits')),
  credits_total INTEGER,
  credits_used INTEGER DEFAULT 0,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  active BOOLEAN DEFAULT true NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE free_passes ENABLE ROW LEVEL SECURITY;

-- Policies para free_passes
DO $$ BEGIN
  CREATE POLICY "free_passes_select_own" ON free_passes
    FOR SELECT USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "free_passes_select_admin" ON free_passes
    FOR SELECT USING (
      company_id IN (
        SELECT company_id FROM users WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "free_passes_insert_admin" ON free_passes
    FOR INSERT WITH CHECK (
      company_id IN (
        SELECT company_id FROM users WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "free_passes_update_admin" ON free_passes
    FOR UPDATE USING (
      company_id IN (
        SELECT company_id FROM users WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
