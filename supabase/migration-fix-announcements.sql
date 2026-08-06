-- ============================================
-- Migración: Fix get_active_announcements
-- Ahora muestra anuncios para reservas pending O cancelled
-- ============================================

DROP FUNCTION IF EXISTS get_active_announcements(uuid, uuid);

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
  reactivated_at TIMESTAMPTZ,
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
    a.reactivated_at,
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
            AND b.status IN ('pending', 'cancelled')
        )
      )
    )
  ORDER BY a.created_at DESC;
END;
$$;
