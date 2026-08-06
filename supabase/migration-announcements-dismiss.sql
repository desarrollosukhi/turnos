-- ============================================
-- Migración: Anuncios con "Recordarme más tarde"
-- Agregar campo reactivated_at para control de visibilidad
-- ============================================

ALTER TABLE announcements ADD COLUMN IF NOT EXISTS reactivated_at TIMESTAMPTZ;
