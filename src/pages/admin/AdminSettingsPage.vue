<script setup lang="ts">
import { useAuthStore } from '@/stores/auth'
import { CompanyService } from '@/services/CompanyService'
import { HolidayService } from '@/services/HolidayService'
import { fetchHolidaysByYear, getHolidaysByYear } from '@/services/HolidaysNational'
import type { HolidayNacional } from '@/services/HolidaysNational'
import { themePresets } from '@/utils/themePresets'
import { useTheme } from '@/composables/useTheme'
import ToastMessage from '@/components/ToastMessage.vue'
import ConfirmModal from '@/components/ConfirmModal.vue'
import ImageCropper from '@/components/ImageCropper.vue'
import { ref, computed, onMounted, watch } from 'vue'
import type { Holiday, Company, CompanySettings } from '@/types'

const authStore = useAuthStore()
const { applyPreset } = useTheme()

const companyData = ref<Company | null>(null)
const settingsData = ref<CompanySettings | null>(null)
const holidays = ref<Holiday[]>([])
const loading = ref(true)
const saving = ref(false)
const showAddHoliday = ref(false)
const showImportHoliday = ref(false)
const importYear = ref(new Date().getFullYear())
const importing = ref(false)
const holidayForm = ref({ date: '', name: '' })
const showToast = ref(false)
const toastMessage = ref('')
const toastType = ref<'success' | 'error' | 'info'>('success')
const uploading = ref(false)
const uploadError = ref('')
const selectedFile = ref<File | null>(null)
const previewUrl = ref('')
const isDragging = ref(false)
const showDeleteConfirm = ref(false)
const showCropper = ref(false)
const croppedBlob = ref<Blob | null>(null)

// Gym schedule
type GymDay = { active: boolean; start: string; end: string }
const defaultDay: GymDay = { active: false, start: '09:00', end: '18:00' }
const gymSchedule = ref<Record<GymDayName, GymDay>>({
  lunes: { active: true, start: '09:00', end: '18:00' },
  martes: { active: true, start: '09:00', end: '18:00' },
  miercoles: { active: true, start: '09:00', end: '18:00' },
  jueves: { active: true, start: '09:00', end: '18:00' },
  viernes: { active: true, start: '09:00', end: '18:00' },
  sabado: { active: true, start: '10:00', end: '14:00' },
  domingo: { active: false, start: '09:00', end: '18:00' },
})

const holidaysNational = ref<HolidayNacional[]>([])
const loadingHolidays = ref(false)

async function loadNationalHolidays() {
  loadingHolidays.value = true
  holidaysNational.value = await fetchHolidaysByYear(importYear.value)
  loadingHolidays.value = false
}

watch(importYear, () => loadNationalHolidays())

const gymDays = ['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo'] as const
type GymDayName = typeof gymDays[number]
const holidaysAvailable = computed(() => {
  const dates = new Set(holidays.value.map(h => h.date))
  return holidaysNational.value.filter(h => !dates.has(h.date))
})

onMounted(async () => {
  if (!authStore.companyId) return
  try {
    companyData.value = await CompanyService.getById(authStore.companyId)
    settingsData.value = await CompanyService.getSettings(authStore.companyId)
    holidays.value = await HolidayService.getAll(authStore.companyId)
    await loadNationalHolidays()
    // Load gym schedule
    if (companyData.value?.gym_schedule) {
      const raw = companyData.value.gym_schedule
      for (const day of gymDays) {
        if (raw[day]) {
          gymSchedule.value[day] = raw[day] as GymDay
        }
      }
    }
  } catch (e: any) {
    toastMessage.value = e.message || 'Error al cargar configuración'
    toastType.value = 'error'
    showToast.value = true
  }
  finally { loading.value = false }
})

async function handleSaveName() {
  if (!authStore.companyId || !companyData.value?.name?.trim()) return
  saving.value = true
  try {
    await CompanyService.update(authStore.companyId, { name: companyData.value.name.trim() })
    toastMessage.value = 'Nombre guardado'
    toastType.value = 'success'
    showToast.value = true
  } catch (e: any) {
    toastMessage.value = e.message || 'Error al guardar nombre'
    toastType.value = 'error'
    showToast.value = true
  }
  finally { saving.value = false }
}

async function handleSaveSettings() {
  if (!authStore.companyId || !settingsData.value) return
  saving.value = true
  try {
    await CompanyService.updateSettings(authStore.companyId, settingsData.value)
    // Save gym schedule to company
    if (companyData.value) {
      await CompanyService.update(authStore.companyId, { gym_schedule: gymSchedule.value })
    }
    toastMessage.value = 'Configuración guardada'
    toastType.value = 'success'
    showToast.value = true
  } catch (e: any) {
    toastMessage.value = e.message || 'Error al guardar configuración'
    toastType.value = 'error'
    showToast.value = true
  }
  finally { saving.value = false }
}

function handleFileSelect(file: File) {
  uploadError.value = ''

  if (file.size > 2 * 1024 * 1024) {
    uploadError.value = 'El archivo no puede superar 2MB'
    return
  }

  const allowedTypes = ['image/png', 'image/jpeg', 'image/svg+xml']
  if (!allowedTypes.includes(file.type)) {
    uploadError.value = 'Formato no permitido. Usá PNG, JPG o SVG'
    return
  }

  selectedFile.value = file

  // SVG se sube directo, imágenes pasan por el editor
  if (file.type === 'image/svg+xml') {
    previewUrl.value = URL.createObjectURL(file)
    croppedBlob.value = null
  } else {
    previewUrl.value = URL.createObjectURL(file)
    showCropper.value = true
  }
}

function handleFileInput(event: Event) {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  if (file) handleFileSelect(file)
}

function handleDrop(event: DragEvent) {
  isDragging.value = false
  const file = event.dataTransfer?.files?.[0]
  if (file) handleFileSelect(file)
}

function clearSelection() {
  selectedFile.value = null
  if (previewUrl.value) URL.revokeObjectURL(previewUrl.value)
  previewUrl.value = ''
  croppedBlob.value = null
  uploadError.value = ''
}

function handleEditExistingLogo() {
  if (!settingsData.value?.logo_url) return
  previewUrl.value = settingsData.value.logo_url
  selectedFile.value = null
  croppedBlob.value = null
  showCropper.value = true
}

function handleCropperApply(blob: Blob) {
  croppedBlob.value = blob
  showCropper.value = false
  // Crear preview del resultado
  if (previewUrl.value) URL.revokeObjectURL(previewUrl.value)
  previewUrl.value = URL.createObjectURL(blob)
}

function handleCropperCancel() {
  showCropper.value = false
  if (!croppedBlob.value) {
    clearSelection()
  }
}

async function handleUploadLogo() {
  const blobToUpload = croppedBlob.value || selectedFile.value
  if (!blobToUpload || !authStore.companyId) return

  uploading.value = true
  uploadError.value = ''
  try {
    let fileToUpload: File
    if (croppedBlob.value) {
      fileToUpload = new File([croppedBlob.value], 'logo.png', { type: 'image/png' })
    } else {
      fileToUpload = selectedFile.value!
    }
    const url = await CompanyService.uploadLogo(authStore.companyId, fileToUpload)
    settingsData.value = { ...settingsData.value!, logo_url: url }
    clearSelection()
    toastMessage.value = 'Logo subido correctamente'
    toastType.value = 'success'
    showToast.value = true
  } catch (e: any) {
    uploadError.value = e.message || 'Error al subir logo'
  } finally {
    uploading.value = false
  }
}

async function confirmDeleteLogo() {
  showDeleteConfirm.value = true
}

async function handleDeleteLogo() {
  showDeleteConfirm.value = false
  if (!authStore.companyId) return

  try {
    await CompanyService.deleteLogo(authStore.companyId)
    settingsData.value = { ...settingsData.value!, logo_url: null }
    toastMessage.value = 'Logo eliminado'
    toastType.value = 'success'
    showToast.value = true
  } catch (e: any) {
    uploadError.value = e.message || 'Error al eliminar logo'
  }
}

async function handleAddHoliday() {
  if (!authStore.companyId || !holidayForm.value.date || !holidayForm.value.name.trim()) return
  try {
    await HolidayService.create({ company_id: authStore.companyId, date: holidayForm.value.date, name: holidayForm.value.name.trim() })
    holidays.value = await HolidayService.getAll(authStore.companyId)
    holidayForm.value = { date: '', name: '' }
    showAddHoliday.value = false
  } catch (e: any) {
    toastMessage.value = e.message || 'Error al crear feriado'
    toastType.value = 'error'
    showToast.value = true
  }
}

async function handleImportHolidays() {
  if (!authStore.companyId || holidaysAvailable.value.length === 0) return
  importing.value = true
  try {
    for (const h of holidaysAvailable.value) {
      await HolidayService.create({ company_id: authStore.companyId, date: h.date, name: h.name })
    }
    holidays.value = await HolidayService.getAll(authStore.companyId)
    showImportHoliday.value = false
  } catch (e: any) {
    toastMessage.value = e.message || 'Error al importar feriados'
    toastType.value = 'error'
    showToast.value = true
  }
  finally { importing.value = false }
}

async function handleDeleteHoliday(id: string) {
  if (!confirm('¿Eliminar?')) return
  try { await HolidayService.delete(id); holidays.value = holidays.value.filter(h => h.id !== id) }
  catch (e: any) {
    toastMessage.value = e.message || 'Error al eliminar feriado'
    toastType.value = 'error'
    showToast.value = true
  }
}

async function handleToggleHoliday(h: Holiday) {
  try { await HolidayService.toggleActive(h.id, !h.active); holidays.value = holidays.value.map(x => x.id === h.id ? { ...x, active: !x.active } : x) }
  catch (e: any) {
    toastMessage.value = e.message || 'Error al actualizar feriado'
    toastType.value = 'error'
    showToast.value = true
  }
}

async function handleSelectPreset(presetId: string) {
  if (!authStore.companyId || !settingsData.value) return
  const preset = themePresets.find(p => p.id === presetId)
  if (!preset) return
  settingsData.value.theme_preset = presetId
  settingsData.value.primary_color = preset.primary_color
  settingsData.value.primary_hover = preset.primary_hover
  settingsData.value.primary_subtle = preset.primary_subtle
  settingsData.value.background_color = preset.background_color
  settingsData.value.surface_color = preset.surface_color
  settingsData.value.text_color = preset.text_color
  settingsData.value.border_radius = preset.border_radius
  applyPreset(presetId)
  await handleSaveSettings()
  toastMessage.value = `Tema "${preset.name}" aplicado`
  toastType.value = 'success'
  showToast.value = true
}
</script>

<template>
  <div>
    <ToastMessage :show="showToast" :message="toastMessage" :type="toastType" @close="showToast = false" />

    <h1 class="text-2xl font-bold mb-6" style="color: var(--color-text)">Configuración</h1>

    <div v-if="loading" class="text-center py-8"><div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div></div>

    <div v-else class="space-y-6">

      <!-- Logo -->
      <div class="rounded-lg shadow p-6" style="background-color: var(--color-surface)">
        <h2 class="text-lg font-semibold mb-4" style="color: var(--color-text)">Logo de la empresa</h2>

        <!-- Logo actual (sin preview pendiente) -->
        <div v-if="settingsData?.logo_url && !previewUrl" class="mb-4">
          <div class="group relative inline-block cursor-pointer">
            <img :src="settingsData.logo_url" alt="Logo actual" class="h-32 w-auto object-contain border rounded-lg p-2 transition-opacity" :style="{ borderColor: 'var(--color-border)' }" />
            <button @click="handleEditExistingLogo" class="absolute top-1/2 -translate-y-1/2 -left-3 rounded-full w-7 h-7 flex items-center justify-center text-xs cursor-pointer md:opacity-0 md:group-hover:opacity-100 transition-opacity" style="background-color: var(--color-primary); color: white" title="Editar logo">✏️</button>
            <button @click="confirmDeleteLogo" class="absolute top-1/2 -translate-y-1/2 -right-3 rounded-full w-7 h-7 flex items-center justify-center text-xs cursor-pointer md:opacity-0 md:group-hover:opacity-100 transition-opacity" style="background-color: #dc2626; color: white" title="Eliminar logo">×</button>
          </div>
          <p class="text-xs mt-2" style="color: var(--color-text-muted)">Logo actual — pasá el mouse para editar o eliminar</p>
        </div>

        <!-- Preview del archivo seleccionado -->
        <div v-if="previewUrl" class="mb-4">
          <p class="text-sm font-medium mb-2" style="color: var(--color-text)">Vista previa:</p>
          <div class="relative inline-block">
            <img :src="previewUrl" alt="Preview" class="h-32 w-auto object-contain border rounded-lg p-2" :style="{ borderColor: 'var(--color-primary)' }" />
            <button v-if="selectedFile?.type !== 'image/svg+xml'" @click="showCropper = true" class="absolute -top-2 -left-2 rounded-full w-6 h-6 flex items-center justify-center text-xs cursor-pointer hover:opacity-80" style="background-color: var(--color-primary); color: white" title="Editar imagen">✏️</button>
            <button @click="clearSelection" class="absolute -top-2 -right-2 rounded-full w-6 h-6 flex items-center justify-center text-xs cursor-pointer hover:opacity-80" style="background-color: #dc2626; color: white" title="Descartar">×</button>
          </div>
          <p v-if="selectedFile" class="text-xs mt-1" style="color: var(--color-text-muted)">{{ selectedFile.name }} ({{ (selectedFile.size / 1024).toFixed(0) }} KB)</p>
        </div>

        <!-- Drag & drop zone (solo si no hay logo ni preview) -->
        <div v-if="!settingsData?.logo_url && !previewUrl"
          @dragover.prevent="isDragging = true"
          @dragleave="isDragging = false"
          @drop.prevent="handleDrop"
          class="border-2 border-dashed rounded-lg p-8 text-center cursor-pointer transition-colors"
          :style="{
            borderColor: isDragging ? 'var(--color-primary)' : 'var(--color-border)',
            backgroundColor: isDragging ? 'var(--color-primary-subtle)' : 'transparent'
          }"
        >
          <div class="text-4xl mb-2">📁</div>
          <p class="text-sm mb-2" style="color: var(--color-text-muted)">
            Arrastrá tu logo aquí o
          </p>
          <label class="inline-block cursor-pointer">
            <span class="px-4 py-2 rounded-lg text-white cursor-pointer hover:opacity-90" :style="{ backgroundColor: 'var(--color-primary)' }">Elegir archivo</span>
            <input type="file" accept=".png,.jpg,.jpeg,.svg" @change="handleFileInput" class="hidden" />
          </label>
          <p class="text-xs mt-3" style="color: var(--color-text-muted)">PNG, JPG o SVG. Máximo 2MB.</p>
        </div>

        <!-- Barra de progreso / Botones -->
        <div v-if="selectedFile" class="mt-4">
          <div v-if="uploading" class="w-full h-2 rounded-full overflow-hidden" style="background-color: var(--color-primary-subtle)">
            <div class="h-full rounded-full animate-pulse" style="background-color: var(--color-primary); width: 60%"></div>
          </div>
          <div v-if="uploading" class="text-sm mt-1" style="color: var(--color-primary)">Subiendo logo...</div>
          <div v-if="!uploading" class="flex space-x-3 mt-2">
            <button @click="handleUploadLogo" class="px-4 py-2 rounded-lg text-white cursor-pointer hover:opacity-90" :style="{ backgroundColor: 'var(--color-primary)' }">Subir logo</button>
            <button @click="clearSelection" class="px-4 py-2 rounded-lg cursor-pointer" :style="{ backgroundColor: 'var(--color-primary-subtle)', color: 'var(--color-text)' }">Cancelar</button>
          </div>
        </div>

        <p v-if="uploadError" class="text-sm mt-2" style="color: #dc2626">{{ uploadError }}</p>
      </div>

      <!-- Confirm modal para eliminar logo -->
      <ConfirmModal
        :show="showDeleteConfirm"
        title="Eliminar logo"
        message="¿Estás seguro de que querés eliminar el logo de tu empresa?"
        icon="🗑️"
        confirm-text="Eliminar"
        confirm-color="#dc2626"
        @confirm="handleDeleteLogo"
        @cancel="showDeleteConfirm = false"
      />

      <!-- Editor de imagen -->
      <ImageCropper
        :show="showCropper"
        :image-src="previewUrl"
        @apply="handleCropperApply"
        @cancel="handleCropperCancel"
      />

      <!-- Nombre de la empresa -->
      <div v-if="companyData" class="rounded-lg shadow p-6" style="background-color: var(--color-surface)">
        <h2 class="text-lg font-semibold mb-4" style="color: var(--color-text)">Nombre de la empresa</h2>
        <div class="flex items-center space-x-4">
          <input v-model="companyData.name" type="text" class="flex-1 px-3 py-2 border rounded-lg" :style="{ borderColor: 'var(--color-border)' }" />
          <button @click="handleSaveName" :disabled="saving || !companyData?.name?.trim()" class="px-4 py-2 rounded-lg text-white disabled:opacity-50" :style="{ backgroundColor: 'var(--color-primary)' }">{{ saving ? 'Guardando...' : 'Guardar' }}</button>
        </div>
      </div>

      <!-- Ventana de tiempo -->
      <div v-if="settingsData" class="rounded-lg shadow p-6" style="background-color: var(--color-surface)">
        <h2 class="text-lg font-semibold mb-4" style="color: var(--color-text)">Ventana de tiempo</h2>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
          <div>
            <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Minutos para reserva</label>
            <input v-model.number="settingsData.minutos_ventana_reserva" type="number" min="0" class="w-full px-3 py-2 border rounded-lg" :style="{ borderColor: 'var(--color-border)' }" />
          </div>
          <div>
            <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Minutos para cancelación</label>
            <input v-model.number="settingsData.minutos_ventana_cancelacion" type="number" min="0" class="w-full px-3 py-2 border rounded-lg" :style="{ borderColor: 'var(--color-border)' }" />
          </div>
        </div>
        <div class="mb-4">
          <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">WhatsApp del profe</label>
          <input v-model="settingsData.whatsapp" type="text" placeholder="Ej: 5491155551234" class="w-full px-3 py-2 border rounded-lg" :style="{ borderColor: 'var(--color-border)' }" />
        </div>
        <div class="mb-4 flex items-center space-x-3">
          <button @click="settingsData.show_alias = !settingsData.show_alias" :class="[settingsData.show_alias ? 'bg-blue-600' : 'bg-gray-300', 'relative inline-flex h-6 w-11 items-center rounded-full transition-colors']">
            <span :class="[settingsData.show_alias ? 'translate-x-6' : 'translate-x-1', 'inline-block h-4 w-4 transform rounded-full bg-white transition-transform']" />
          </button>
          <div><p class="text-sm font-medium" style="color: var(--color-text)">Mostrar alias</p></div>
        </div>
        <button @click="handleSaveSettings" :disabled="saving" class="px-4 py-2 rounded-lg text-white disabled:opacity-50" :style="{ backgroundColor: 'var(--color-primary)' }">{{ saving ? 'Guardando...' : 'Guardar' }}</button>
      </div>

      <!-- Tema / Apariencia -->
      <div class="rounded-lg shadow p-6" style="background-color: var(--color-surface)">
        <h2 class="text-lg font-semibold mb-4" style="color: var(--color-text)">Apariencia</h2>
        <p class="text-sm mb-4" style="color: var(--color-text-muted)">Elegí un tema predefinido para personalizar la apariencia de tu negocio.</p>
        <div class="grid grid-cols-2 md:grid-cols-3 gap-3">
          <button
            v-for="preset in themePresets"
            :key="preset.id"
            @click="handleSelectPreset(preset.id)"
            :class="[
              'p-3 rounded-lg border-2 text-left transition-all hover:shadow-md',
              settingsData?.theme_preset === preset.id ? 'border-blue-500 shadow-md' : 'border-gray-200'
            ]"
          >
            <div class="flex items-center space-x-2 mb-2">
              <div class="w-6 h-6 rounded-full" :style="{ backgroundColor: preset.primary_color }"></div>
              <div class="w-6 h-6 rounded-full" :style="{ backgroundColor: preset.background_color, border: '1px solid #e5e7eb' }"></div>
            </div>
            <p class="text-sm font-medium" :style="{ color: preset.text_color }">{{ preset.name }}</p>
          </button>
        </div>
      </div>

      <!-- Modo Gimnasio -->
      <div v-if="settingsData" class="rounded-lg shadow p-6" style="background-color: var(--color-surface)">
        <h2 class="text-lg font-semibold mb-4" style="color: var(--color-text)">Modo Gimnasio</h2>
        <div class="mb-4 flex items-center space-x-3">
          <button @click="settingsData.gym_mode = !settingsData.gym_mode" :class="[settingsData.gym_mode ? 'bg-blue-600' : 'bg-gray-300', 'relative inline-flex h-6 w-11 items-center rounded-full transition-colors']">
            <span :class="[settingsData.gym_mode ? 'translate-x-6' : 'translate-x-1', 'inline-block h-4 w-4 transform rounded-full bg-white transition-transform']" />
          </button>
          <div>
            <p class="text-sm font-medium" style="color: var(--color-text)">Modo Gimnasio</p>
            <p class="text-xs" style="color: var(--color-text-muted)">Activa Free Pass y horario del gimnasio</p>
          </div>
        </div>

        <!-- Horario del gimnasio -->
        <div v-if="settingsData.gym_mode" class="mt-4">
          <p class="text-sm font-medium mb-2" style="color: var(--color-text)">Horario del gimnasio</p>
          <div class="space-y-2">
            <div v-for="day in gymDays" :key="day" class="flex items-center space-x-3">
              <input type="checkbox" v-model="gymSchedule[day].active" class="rounded" />
              <span class="w-20 text-sm capitalize" style="color: var(--color-text)">{{ day }}</span>
              <input v-if="gymSchedule[day].active" v-model="gymSchedule[day].start" type="time" class="px-2 py-1 border rounded text-sm" :style="{ borderColor: 'var(--color-border)' }" />
              <span v-if="gymSchedule[day].active" style="color: var(--color-text-muted)">a</span>
              <input v-if="gymSchedule[day].active" v-model="gymSchedule[day].end" type="time" class="px-2 py-1 border rounded text-sm" :style="{ borderColor: 'var(--color-border)' }" />
            </div>
          </div>
          <p class="text-xs mt-2" style="color: var(--color-text-muted)">Los clientes con Free Pass pueden asistir en estos horarios</p>
        </div>

        <button @click="handleSaveSettings" :disabled="saving" class="mt-4 px-4 py-2 rounded-lg text-white disabled:opacity-50" :style="{ backgroundColor: 'var(--color-primary)' }">{{ saving ? 'Guardando...' : 'Guardar' }}</button>
      </div>

      <!-- Modo de Clientes -->
      <div v-if="settingsData" class="rounded-lg shadow p-6" style="background-color: var(--color-surface)">
        <h2 class="text-lg font-semibold mb-4" style="color: var(--color-text)">Modo de Clientes</h2>
        <div class="grid grid-cols-2 gap-3 mb-4">
          <button @click="settingsData.customer_mode = 'MEMBER'"
            :class="['p-3 rounded-lg border-2 text-left transition-all', settingsData.customer_mode === 'MEMBER' ? 'border-blue-500 shadow-md' : 'border-gray-200']">
            <div class="text-2xl mb-1">👤</div>
            <div class="text-sm font-medium" style="color: var(--color-text)">Member</div>
            <div class="text-xs" style="color: var(--color-text-muted)">Clientes con login y créditos</div>
          </button>
          <button @click="settingsData.customer_mode = 'GUEST'"
            :class="['p-3 rounded-lg border-2 text-left transition-all', settingsData.customer_mode === 'GUEST' ? 'border-blue-500 shadow-md' : 'border-gray-200']">
            <div class="text-2xl mb-1">🎫</div>
            <div class="text-sm font-medium" style="color: var(--color-text)">Guest</div>
            <div class="text-xs" style="color: var(--color-text-muted)">Solo nombre y teléfono</div>
          </button>
        </div>
        <button @click="handleSaveSettings" :disabled="saving" class="px-4 py-2 rounded-lg text-white disabled:opacity-50" :style="{ backgroundColor: 'var(--color-primary)' }">{{ saving ? 'Guardando...' : 'Guardar' }}</button>
      </div>

      <!-- Permisos del Profesional -->
      <div v-if="settingsData" class="rounded-lg shadow p-6" style="background-color: var(--color-surface)">
        <h2 class="text-lg font-semibold mb-4" style="color: var(--color-text)">Permisos del Profesional</h2>
        <div class="mb-4 flex items-center space-x-3">
          <button @click="settingsData.manage_credits = !settingsData.manage_credits" :class="[settingsData.manage_credits ? 'bg-blue-600' : 'bg-gray-300', 'relative inline-flex h-6 w-11 items-center rounded-full transition-colors']">
            <span :class="[settingsData.manage_credits ? 'translate-x-6' : 'translate-x-1', 'inline-block h-4 w-4 transform rounded-full bg-white transition-transform']" />
          </button>
          <div>
            <p class="text-sm font-medium" style="color: var(--color-text)">Puede gestionar créditos</p>
            <p class="text-xs" style="color: var(--color-text-muted)">Si está desactivado, solo el admin puede dar/quitar créditos</p>
          </div>
        </div>
        <button @click="handleSaveSettings" :disabled="saving" class="px-4 py-2 rounded-lg text-white disabled:opacity-50" :style="{ backgroundColor: 'var(--color-primary)' }">{{ saving ? 'Guardando...' : 'Guardar' }}</button>
      </div>

      <!-- Historia Clínica -->
      <div v-if="settingsData" class="rounded-lg shadow p-6" style="background-color: var(--color-surface)">
        <h2 class="text-lg font-semibold mb-4" style="color: var(--color-text)">Historia Clínica</h2>
        <div class="mb-4 flex items-center space-x-3">
          <button @click="settingsData.enable_clinical_history = !settingsData.enable_clinical_history" :class="[settingsData.enable_clinical_history ? 'bg-blue-600' : 'bg-gray-300', 'relative inline-flex h-6 w-11 items-center rounded-full transition-colors']">
            <span :class="[settingsData.enable_clinical_history ? 'translate-x-6' : 'translate-x-1', 'inline-block h-4 w-4 transform rounded-full bg-white transition-transform']" />
          </button>
          <div>
            <p class="text-sm font-medium" style="color: var(--color-text)">Habilitar historia clínica</p>
            <p class="text-xs" style="color: var(--color-text-muted)">Los profesionales podrán registrar historial de cada cliente</p>
          </div>
        </div>
        <p v-if="settingsData.enable_clinical_history" class="text-sm mb-4" style="color: var(--color-text-muted)">
          Los profesionales verán un botón "📋 Historia" en cada reserva para registrar el historial del cliente.
        </p>
        <button @click="handleSaveSettings" :disabled="saving" class="px-4 py-2 rounded-lg text-white disabled:opacity-50" :style="{ backgroundColor: 'var(--color-primary)' }">{{ saving ? 'Guardando...' : 'Guardar' }}</button>
      </div>

      <!-- Feriados -->
      <div class="rounded-lg shadow p-6" style="background-color: var(--color-surface)">
        <div class="flex justify-between items-center mb-4">
          <h2 class="text-lg font-semibold" style="color: var(--color-text)">Feriados</h2>
          <div class="space-x-2">
            <button @click="showImportHoliday = !showImportHoliday" class="px-4 py-2 rounded-lg text-white text-sm" style="background-color: #16a34a">📥 Importar</button>
            <button @click="showAddHoliday = !showAddHoliday" class="px-4 py-2 rounded-lg text-white text-sm" :style="{ backgroundColor: 'var(--color-primary)' }">+ Agregar</button>
          </div>
        </div>

        <div v-if="showImportHoliday" class="rounded-lg p-4 mb-4" style="background-color: #f0fdf4; border: 1px solid #bbf7d0">
          <h3 class="font-semibold mb-2" style="color: #166534">Feriados nacionales Argentina</h3>
          <div class="flex items-center space-x-4 mb-3">
            <label class="text-sm" style="color: var(--color-text)">Año:</label>
            <select v-model="importYear" class="px-3 py-1 border rounded-lg text-sm" :style="{ borderColor: 'var(--color-border)' }">
              <option :value="2025">2025</option>
              <option :value="2026">2026</option>
              <option :value="2027">2027</option>
            </select>
          </div>
          <div v-if="loadingHolidays" class="text-sm mb-3" style="color: var(--color-text-muted)">Cargando feriados de la API...</div>
          <template v-else>
            <p v-if="holidaysAvailable.length === 0" class="text-sm mb-3" style="color: #166534">Todos importados.</p>
            <p v-else class="text-sm mb-3" style="color: var(--color-text-muted)">Se importarán {{ holidaysAvailable.length }} feriados.</p>
            <button @click="handleImportHolidays" :disabled="importing || holidaysAvailable.length === 0" class="px-4 py-2 rounded-lg text-white text-sm disabled:opacity-50" style="background-color: #16a34a">{{ importing ? 'Importando...' : 'Importar' }}</button>
          </template>
        </div>

        <div v-if="showAddHoliday" class="rounded-lg p-4 mb-4" style="background-color: var(--color-primary-subtle)">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Fecha</label>
              <input v-model="holidayForm.date" type="date" class="w-full px-3 py-2 border rounded-lg" :style="{ borderColor: 'var(--color-border)' }" />
            </div>
            <div>
              <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Nombre</label>
              <input v-model="holidayForm.name" type="text" placeholder="Ej: Navidad" class="w-full px-3 py-2 border rounded-lg" :style="{ borderColor: 'var(--color-border)' }" />
            </div>
          </div>
          <button @click="handleAddHoliday" :disabled="!holidayForm.date || !holidayForm.name.trim()" class="mt-3 px-4 py-2 rounded-lg text-white text-sm disabled:opacity-50" :style="{ backgroundColor: 'var(--color-primary)' }">Guardar feriado</button>
        </div>

        <div v-if="holidays.length === 0" class="text-center py-4" style="color: var(--color-text-muted)">No hay feriados.</div>

        <div v-else class="divide-y">
          <div v-for="h in holidays" :key="h.id" class="flex justify-between items-center py-3">
            <div class="flex items-center space-x-3">
              <button @click="handleToggleHoliday(h)" :class="[h.active ? 'bg-green-500' : 'bg-gray-300', 'relative inline-flex h-6 w-11 items-center rounded-full transition-colors']">
                <span :class="[h.active ? 'translate-x-6' : 'translate-x-1', 'inline-block h-4 w-4 transform rounded-full bg-white transition-transform']" />
              </button>
              <div>
                <p class="font-medium" style="color: var(--color-text)">{{ h.name }}</p>
                <p class="text-sm" style="color: var(--color-text-muted)">{{ h.date }}</p>
              </div>
            </div>
            <button @click="handleDeleteHoliday(h.id)" style="color: #dc2626" class="text-sm hover:underline">Eliminar</button>
          </div>
        </div>
      </div>

    </div>
  </div>
</template>
