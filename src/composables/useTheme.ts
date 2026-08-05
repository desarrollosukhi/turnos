import { watch } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { getPresetById } from '@/utils/themePresets'

function hexToRgb(hex: string): { r: number; g: number; b: number } | null {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
  return result
    ? { r: parseInt(result[1]!, 16), g: parseInt(result[2]!, 16), b: parseInt(result[3]!, 16) }
    : null
}

function getContrastColor(hex: string): string {
  const rgb = hexToRgb(hex)
  if (!rgb) return '#6b7280'
  const luminance = (0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b) / 255
  return luminance > 0.5 ? '#6b7280' : '#94a3b8'
}

function getBorderColor(hex: string): string {
  const rgb = hexToRgb(hex)
  if (!rgb) return '#e5e7eb'
  const luminance = (0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b) / 255
  return luminance > 0.5 ? '#e5e7eb' : '#334155'
}

function applyColorsToRoot(
  primary: string,
  primaryHover: string,
  primarySubtle: string,
  background: string,
  surface: string,
  text: string,
) {
  const root = document.documentElement
  root.style.setProperty('--color-primary', primary)
  root.style.setProperty('--color-primary-hover', primaryHover)
  root.style.setProperty('--color-primary-subtle', primarySubtle)
  root.style.setProperty('--color-background', background)
  root.style.setProperty('--color-surface', surface)
  root.style.setProperty('--color-text', text)
  root.style.setProperty('--color-text-muted', getContrastColor(background))
  root.style.setProperty('--color-border', getBorderColor(background))
}

export function useTheme() {
  const authStore = useAuthStore()

  function applyTheme() {
    const settings = authStore.companySettings
    if (!settings) {
      applyPreset('clasico')
      return
    }

    applyColorsToRoot(
      settings.primary_color,
      settings.primary_hover,
      settings.primary_subtle,
      settings.background_color,
      settings.surface_color,
      settings.text_color,
    )
  }

  function applyPreset(presetId: string) {
    const preset = getPresetById(presetId)
    applyColorsToRoot(
      preset.primary_color,
      preset.primary_hover,
      preset.primary_subtle,
      preset.background_color,
      preset.surface_color,
      preset.text_color,
    )
  }

  // Watch for changes in companySettings
  watch(
    () => authStore.companySettings,
    () => applyTheme(),
    { immediate: true }
  )

  return { applyTheme, applyPreset }
}
