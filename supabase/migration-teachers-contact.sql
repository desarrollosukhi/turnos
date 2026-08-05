-- ============================================
-- MIGRACIÓN: Agregar campos de contacto a teachers
-- Ejecutar este SQL en Supabase SQL Editor
-- ============================================

-- Agregar columnas de contacto
ALTER TABLE teachers ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE teachers ADD COLUMN IF NOT EXISTS telefono TEXT;
ALTER TABLE teachers ADD COLUMN IF NOT EXISTS whatsapp TEXT;
