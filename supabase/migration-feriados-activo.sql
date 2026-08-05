-- ============================================
-- MIGRACIÓN: Agregar campo activo a feriados
-- Ejecutar este SQL en Supabase SQL Editor
-- ============================================

-- Agregar columna activo (default true para feriados existentes)
ALTER TABLE feriados ADD COLUMN IF NOT EXISTS activo BOOLEAN DEFAULT true NOT NULL;
