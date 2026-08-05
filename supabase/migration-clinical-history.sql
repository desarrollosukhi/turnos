-- ============================================
-- MIGRACIÓN: Historia Clínica
-- Ejecutar este SQL en Supabase SQL Editor
-- ============================================

-- 1. Habilitar historia clínica en company_settings
ALTER TABLE company_settings ADD COLUMN IF NOT EXISTS enable_clinical_history BOOLEAN DEFAULT false NOT NULL;

-- 2. Tabla de campos configurables
CREATE TABLE IF NOT EXISTS clinical_history_fields (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id UUID REFERENCES companies(id) NOT NULL,
  field_name TEXT NOT NULL,
  field_type TEXT NOT NULL DEFAULT 'text' CHECK (field_type IN ('text', 'select', 'date')),
  is_required BOOLEAN DEFAULT false NOT NULL,
  sort_order INTEGER DEFAULT 0 NOT NULL,
  active BOOLEAN DEFAULT true NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  CONSTRAINT clinical_history_fields_unique UNIQUE (company_id, field_name)
);

ALTER TABLE clinical_history_fields ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  CREATE POLICY "clinical_history_fields_select" ON clinical_history_fields
    FOR SELECT USING (
      company_id IN (
        SELECT company_id FROM users WHERE id = auth.uid()
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "clinical_history_fields_admin_all" ON clinical_history_fields
    FOR ALL USING (is_admin_of(company_id));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- 3. Tabla de registros de historia clínica
CREATE TABLE IF NOT EXISTS clinical_history_entries (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  company_id UUID REFERENCES companies(id) NOT NULL,
  professional_id UUID REFERENCES professionals(id) NOT NULL,
  booking_id UUID REFERENCES bookings(id),
  field_values JSONB DEFAULT '{}'::jsonb,
  free_text TEXT,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE clinical_history_entries ENABLE ROW LEVEL SECURITY;

-- Policies para clinical_history_entries
DO $$ BEGIN
  CREATE POLICY "clinical_history_entries_select_own" ON clinical_history_entries
    FOR SELECT USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "clinical_history_entries_select_admin" ON clinical_history_entries
    FOR SELECT USING (
      company_id IN (
        SELECT company_id FROM users WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "clinical_history_entries_select_professional" ON clinical_history_entries
    FOR SELECT USING (
      professional_id IN (
        SELECT id FROM professionals WHERE user_id = auth.uid()
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "clinical_history_entries_insert_professional" ON clinical_history_entries
    FOR INSERT WITH CHECK (
      professional_id IN (
        SELECT id FROM professionals WHERE user_id = auth.uid()
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "clinical_history_entries_update_professional" ON clinical_history_entries
    FOR UPDATE USING (
      professional_id IN (
        SELECT id FROM professionals WHERE user_id = auth.uid()
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "clinical_history_entries_admin_all" ON clinical_history_entries
    FOR ALL USING (
      company_id IN (
        SELECT company_id FROM users WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
