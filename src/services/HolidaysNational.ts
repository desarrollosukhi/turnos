export interface HolidayNacional {
  date: string
  name: string
  type: 'inamovible' | 'trasladable' | 'feriado'
}

// Fallback local por si la API falla
const holidaysFallback: HolidayNacional[] = [
  { date: '2025-01-01', name: 'Año Nuevo', type: 'inamovible' },
  { date: '2025-02-17', name: 'Carnaval', type: 'feriado' },
  { date: '2025-02-18', name: 'Carnaval', type: 'feriado' },
  { date: '2025-03-24', name: 'Día de la Memoria', type: 'inamovible' },
  { date: '2025-04-02', name: 'Día del Veterano y de los Caídos en Malvinas', type: 'inamovible' },
  { date: '2025-04-17', name: 'Jueves Santo', type: 'feriado' },
  { date: '2025-04-18', name: 'Viernes Santo', type: 'feriado' },
  { date: '2025-05-01', name: 'Día del Trabajador', type: 'inamovible' },
  { date: '2025-05-25', name: 'Día de la Revolución de Mayo', type: 'inamovible' },
  { date: '2025-06-16', name: 'Paso a la Inmortalidad del General Martín Miguel de Güemes', type: 'trasladable' },
  { date: '2025-06-20', name: 'Día de la Bandera', type: 'inamovible' },
  { date: '2025-07-09', name: 'Día de la Independencia', type: 'inamovible' },
  { date: '2025-08-17', name: 'Paso a la Inmortalidad del General José de San Martín', type: 'trasladable' },
  { date: '2025-10-12', name: 'Día del Respeto a la Diversidad Cultural', type: 'trasladable' },
  { date: '2025-10-20', name: 'Día del Rosario', type: 'trasladable' },
  { date: '2025-11-20', name: 'Día de la Soberanía Nacional', type: 'trasladable' },
  { date: '2025-12-08', name: 'Inmaculada Concepción de María', type: 'inamovible' },
  { date: '2025-12-25', name: 'Navidad', type: 'inamovible' },
  { date: '2026-01-01', name: 'Año Nuevo', type: 'inamovible' },
  { date: '2026-02-02', name: 'Carnaval', type: 'feriado' },
  { date: '2026-02-03', name: 'Carnaval', type: 'feriado' },
  { date: '2026-03-24', name: 'Día de la Memoria', type: 'inamovible' },
  { date: '2026-04-02', name: 'Día del Veterano y de los Caídos en Malvinas', type: 'inamovible' },
  { date: '2026-04-02', name: 'Jueves Santo', type: 'feriado' },
  { date: '2026-04-03', name: 'Viernes Santo', type: 'feriado' },
  { date: '2026-05-01', name: 'Día del Trabajador', type: 'inamovible' },
  { date: '2026-05-25', name: 'Día de la Revolución de Mayo', type: 'inamovible' },
  { date: '2026-06-15', name: 'Paso a la Inmortalidad del General Martín Miguel de Güemes', type: 'trasladable' },
  { date: '2026-06-20', name: 'Día de la Bandera', type: 'inamovible' },
  { date: '2026-07-09', name: 'Día de la Independencia', type: 'inamovible' },
  { date: '2026-08-17', name: 'Paso a la Inmortalidad del General José de San Martín', type: 'trasladable' },
  { date: '2026-10-12', name: 'Día del Respeto a la Diversidad Cultural', type: 'trasladable' },
  { date: '2026-10-19', name: 'Día del Rosario', type: 'trasladable' },
  { date: '2026-11-20', name: 'Día de la Soberanía Nacional', type: 'trasladable' },
  { date: '2026-12-08', name: 'Inmaculada Concepción de María', type: 'inamovible' },
  { date: '2026-12-25', name: 'Navidad', type: 'inamovible' },
  { date: '2027-01-01', name: 'Año Nuevo', type: 'inamovible' },
  { date: '2027-02-15', name: 'Carnaval', type: 'feriado' },
  { date: '2027-02-16', name: 'Carnaval', type: 'feriado' },
  { date: '2027-03-24', name: 'Día de la Memoria', type: 'inamovible' },
  { date: '2027-04-02', name: 'Día del Veterano y de los Caídos en Malvinas', type: 'inamovible' },
  { date: '2027-04-22', name: 'Jueves Santo', type: 'feriado' },
  { date: '2027-04-23', name: 'Viernes Santo', type: 'feriado' },
  { date: '2027-05-01', name: 'Día del Trabajador', type: 'inamovible' },
  { date: '2027-05-25', name: 'Día de la Revolución de Mayo', type: 'inamovible' },
  { date: '2027-06-21', name: 'Paso a la Inmortalidad del General Martín Miguel de Güemes', type: 'trasladable' },
  { date: '2027-06-20', name: 'Día de la Bandera', type: 'inamovible' },
  { date: '2027-07-09', name: 'Día de la Independencia', type: 'inamovible' },
  { date: '2027-08-17', name: 'Paso a la Inmortalidad del General José de San Martín', type: 'trasladable' },
  { date: '2027-10-11', name: 'Día del Respeto a la Diversidad Cultural', type: 'trasladable' },
  { date: '2027-10-18', name: 'Día del Rosario', type: 'trasladable' },
  { date: '2027-11-22', name: 'Día de la Soberanía Nacional', type: 'trasladable' },
  { date: '2027-12-08', name: 'Inmaculada Concepción de María', type: 'inamovible' },
  { date: '2027-12-25', name: 'Navidad', type: 'inamovible' },
]

// Fetch feriados de un año desde API de ArgentinaDatos
async function fetchByYear(year: number): Promise<HolidayNacional[]> {
  try {
    const res = await fetch(`https://api.argentinadatos.com/v1/feriados/${year}`)
    if (!res.ok) return holidaysFallback.filter(f => f.date.startsWith(year.toString()))
    const data = await res.json()
    if (!Array.isArray(data) || data.length === 0) return holidaysFallback.filter(f => f.date.startsWith(year.toString()))
    return data.map((h: any) => ({
      date: h.fecha,
      name: h.nombre,
      type: h.tipo,
    }))
  } catch {
    return holidaysFallback.filter(f => f.date.startsWith(year.toString()))
  }
}

// Fetch feriados de múltiples años (para auto-sync)
export async function fetchHolidaysForYears(years: number[]): Promise<HolidayNacional[]> {
  const results = await Promise.all(years.map(y => fetchByYear(y)))
  return results.flat()
}

// Legacy: fetch de un solo año
export async function fetchHolidaysByYear(year: number): Promise<HolidayNacional[]> {
  return fetchByYear(year)
}

// Función sincrónica (fallback) para uso donde no se puede esperar
export function getHolidaysByYear(year: number): HolidayNacional[] {
  return holidaysFallback.filter(f => f.date.startsWith(year.toString()))
}

export function isHolidayNational(date: string): boolean {
  return holidaysFallback.some(f => f.date === date)
}
