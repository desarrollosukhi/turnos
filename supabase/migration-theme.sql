-- ============================================
-- MIGRACIÓN: Temas predefinidos por empresa
-- Ejecutar este SQL en Supabase SQL Editor
-- ============================================

-- Agregar columnas de theme a company_settings
ALTER TABLE company_settings ADD COLUMN IF NOT EXISTS theme_preset TEXT DEFAULT 'yoga';
ALTER TABLE company_settings ADD COLUMN IF NOT EXISTS primary_color TEXT DEFAULT '#2563eb';
ALTER TABLE company_settings ADD COLUMN IF NOT EXISTS primary_hover TEXT DEFAULT '#1d4ed8';
ALTER TABLE company_settings ADD COLUMN IF NOT EXISTS primary_subtle TEXT DEFAULT '#eff6ff';
ALTER TABLE company_settings ADD COLUMN IF NOT EXISTS background_color TEXT DEFAULT '#f9fafb';
ALTER TABLE company_settings ADD COLUMN IF NOT EXISTS surface_color TEXT DEFAULT '#ffffff';
ALTER TABLE company_settings ADD COLUMN IF NOT EXISTS text_color TEXT DEFAULT '#111827';
ALTER TABLE company_settings ADD COLUMN IF NOT EXISTS border_radius TEXT DEFAULT '0.5rem';
