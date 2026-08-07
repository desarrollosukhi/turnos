/**
 * Formatea una fecha (YYYY-MM-DD) al formato local es-AR.
 * Ej: "2026-08-11" -> "lun. 11 ago."
 */
export function formatDate(dateStr: string | null | undefined): string {
  if (!dateStr) return ''
  const date = new Date(dateStr + 'T12:00:00')
  return date.toLocaleDateString('es-AR', { weekday: 'short', day: 'numeric', month: 'short' })
}

/**
 * Formatea una fecha (YYYY-MM-DD) al formato local es-AR, versión larga.
 * Ej: "2026-08-11" -> "lunes, 11 de agosto de 2026"
 */
export function formatDateLong(dateStr: string | null | undefined): string {
  if (!dateStr) return ''
  const date = new Date(dateStr + 'T12:00:00')
  return date.toLocaleDateString('es-AR', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  })
}

/**
 * Quita los segundos de un horario "HH:mm:ss" -> "HH:mm".
 */
export function formatTime(time: string | null | undefined): string {
  if (!time) return ''
  return time.slice(0, 5)
}
