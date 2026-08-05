import type { ThemePreset } from '@/types'

export const themePresets: ThemePreset[] = [
  {
    id: 'clasico',
    name: 'Clásico',
    primary_color: '#2563eb',
    primary_hover: '#1d4ed8',
    primary_subtle: '#eff6ff',
    background_color: '#f9fafb',
    surface_color: '#ffffff',
    text_color: '#111827',
    border_radius: '0.5rem',
  },
  {
    id: 'oscuro',
    name: 'Oscuro',
    primary_color: '#3b82f6',
    primary_hover: '#2563eb',
    primary_subtle: '#1e3a5f',
    background_color: '#0f172a',
    surface_color: '#1e293b',
    text_color: '#f1f5f9',
    border_radius: '0.5rem',
  },
  {
    id: 'naturaleza',
    name: 'Naturaleza',
    primary_color: '#059669',
    primary_hover: '#047857',
    primary_subtle: '#ecfdf5',
    background_color: '#f0fdf4',
    surface_color: '#ffffff',
    text_color: '#064e3b',
    border_radius: '0.75rem',
  },
  {
    id: 'elegante',
    name: 'Elegante',
    primary_color: '#7c3aed',
    primary_hover: '#6d28d9',
    primary_subtle: '#f5f3ff',
    background_color: '#faf5ff',
    surface_color: '#ffffff',
    text_color: '#1e1b4b',
    border_radius: '0.75rem',
  },
  {
    id: 'calido',
    name: 'Cálido',
    primary_color: '#ea580c',
    primary_hover: '#c2410c',
    primary_subtle: '#fff7ed',
    background_color: '#fffbf5',
    surface_color: '#ffffff',
    text_color: '#431407',
    border_radius: '0.5rem',
  },
  {
    id: 'minimalista',
    name: 'Minimalista',
    primary_color: '#18181b',
    primary_hover: '#27272a',
    primary_subtle: '#f4f4f5',
    background_color: '#ffffff',
    surface_color: '#ffffff',
    text_color: '#18181b',
    border_radius: '0.25rem',
  },
]

export function getPresetById(id: string): ThemePreset {
  const found = themePresets.find(p => p.id === id)
  return found ?? themePresets[0]!
}
