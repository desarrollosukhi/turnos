-- ============================================
-- MIGRACIÓN: Mejoras en clientes
-- Ejecutar este SQL en Supabase SQL Editor
-- ============================================

-- 1. Campo has_account para saber si tiene cuenta de acceso
ALTER TABLE users ADD COLUMN IF NOT EXISTS has_account BOOLEAN DEFAULT true NOT NULL;
