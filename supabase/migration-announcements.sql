-- ============================================
-- Migración: Sistema de Anuncios (Announcements)
-- ============================================

-- Tabla announcements
CREATE TABLE IF NOT EXISTS announcements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id UUID REFERENCES companies(id) NOT NULL,
  professional_id UUID REFERENCES professionals(id),
  service_id UUID REFERENCES services(id),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  target TEXT DEFAULT 'all' NOT NULL CHECK (target IN ('all', 'service_bookings')),
  date_from DATE NOT NULL DEFAULT CURRENT_DATE,
  date_to DATE,
  active BOOLEAN DEFAULT true NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DO $$ BEGIN
  CREATE POLICY "announcements_select_company" ON announcements
    FOR SELECT USING (
      company_id IN (
        SELECT company_id FROM users WHERE id = auth.uid()
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "announcements_admin_all" ON announcements
    FOR ALL USING (is_admin_of(company_id));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "announcements_professional_manage" ON announcements
    FOR ALL USING (
      professional_id IN (
        SELECT p.id FROM professionals p WHERE p.user_id = auth.uid()
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Función para obtener anuncios activos
CREATE OR REPLACE FUNCTION get_active_announcements(
  p_company_id UUID,
  p_user_id UUID DEFAULT NULL
)
RETURNS TABLE(
  id UUID,
  title TEXT,
  content TEXT,
  professional_name TEXT,
  service_name TEXT,
  target TEXT,
  date_from DATE,
  date_to DATE,
  created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN QUERY
  SELECT
    a.id,
    a.title,
    a.content,
    COALESCE(p.name, 'Admin') AS professional_name,
    s.name AS service_name,
    a.target,
    a.date_from,
    a.date_to,
    a.created_at
  FROM announcements a
  LEFT JOIN professionals p ON p.id = a.professional_id
  LEFT JOIN services s ON s.id = a.service_id
  WHERE a.company_id = p_company_id
    AND a.active = true
    AND a.date_from <= CURRENT_DATE
    AND (a.date_to IS NULL OR a.date_to >= CURRENT_DATE)
    AND (
      a.target = 'all'
      OR (
        a.target = 'service_bookings'
        AND p_user_id IS NOT NULL
        AND EXISTS (
          SELECT 1 FROM bookings b
          WHERE b.user_id = p_user_id
            AND b.service_id = a.service_id
            AND b.status = 'pending'
        )
      )
    )
  ORDER BY a.created_at DESC;
END;
$$;
