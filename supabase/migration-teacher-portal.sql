-- ============================================
-- MIGRACIÓN: Portal de Profesor + Alias
-- Ejecutar este SQL en Supabase SQL Editor
-- ============================================

-- 1. Extender roles
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_rol_check;
ALTER TABLE users ADD CONSTRAINT users_rol_check CHECK (rol IN ('admin', 'alumno', 'profesor'));

-- 2. Agregar campos a teachers
ALTER TABLE teachers ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);
ALTER TABLE teachers ADD COLUMN IF NOT EXISTS alias TEXT;

-- 3. Agregar configuración de alias a empresas
ALTER TABLE empresas ADD COLUMN IF NOT EXISTS mostrar_alias BOOLEAN DEFAULT false NOT NULL;

-- 4. Policies para profesores

-- Profesor ve sus propias clases
CREATE POLICY "classes_select_teacher" ON classes
  FOR SELECT USING (
    teacher_id IN (
      SELECT id FROM teachers WHERE user_id = auth.uid()
    )
  );

-- Profesor ve reservas de sus clases
CREATE POLICY "bookings_select_teacher" ON bookings
  FOR SELECT USING (
    class_id IN (
      SELECT c.id FROM classes c
      JOIN teachers t ON t.id = c.teacher_id
      WHERE t.user_id = auth.uid()
    )
  );

-- Profesor puede actualizar reservas de sus clases (marcar asistencia)
CREATE POLICY "bookings_update_teacher" ON bookings
  FOR UPDATE USING (
    class_id IN (
      SELECT c.id FROM classes c
      JOIN teachers t ON t.id = c.teacher_id
      WHERE t.user_id = auth.uid()
    )
  );

-- Profesor ve profesores de su empresa
CREATE POLICY "teachers_select_own_empresa" ON teachers
  FOR SELECT USING (
    empresa_id IN (
      SELECT empresa_id FROM users WHERE id = auth.uid()
    )
  );

-- 5. Función para obtener el display name del profesor
CREATE OR REPLACE FUNCTION get_teacher_display_name(p_teacher_id UUID)
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT COALESCE(
    (SELECT CASE
      WHEN e.mostrar_alias AND t.alias IS NOT NULL AND t.alias != '' THEN t.alias
      ELSE t.nombre
    END
    FROM teachers t
    JOIN empresas e ON e.id = t.empresa_id
    WHERE t.id = p_teacher_id),
    (SELECT nombre FROM teachers WHERE id = p_teacher_id)
  );
$$;
