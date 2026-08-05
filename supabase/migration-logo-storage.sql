-- ============================================
-- MIGRACIÓN: Storage bucket para logos
-- Ejecutar este SQL en Supabase SQL Editor
-- ============================================

-- Crear bucket para logos de empresas
INSERT INTO storage.buckets (id, name, public)
VALUES ('company-logos', 'company-logos', true)
ON CONFLICT (id) DO NOTHING;

-- Policy: lectura pública (cualquiera puede ver logos)
DO $$ BEGIN
  CREATE POLICY "company_logos_public" ON storage.objects
    FOR SELECT USING (bucket_id = 'company-logos');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Policy: upload solo por admin de la empresa
DO $$ BEGIN
  CREATE POLICY "company_logos_admin_upload" ON storage.objects
    FOR INSERT WITH CHECK (
      bucket_id = 'company-logos'
      AND (storage.foldername(name))[1] IN (
        SELECT company_id::text FROM users WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Policy: delete solo por admin de la empresa
DO $$ BEGIN
  CREATE POLICY "company_logos_admin_delete" ON storage.objects
    FOR DELETE USING (
      bucket_id = 'company-logos'
      AND (storage.foldername(name))[1] IN (
        SELECT company_id::text FROM users WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
