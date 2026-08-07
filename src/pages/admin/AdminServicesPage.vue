<script setup lang="ts">
import { useServiceStore } from '@/stores/service'
import { ProfessionalService } from '@/services/ProfessionalService'
import { useAuthStore } from '@/stores/auth'
import { getBusinessLabels, FREQUENCY_OPTIONS, ALL_DAYS } from '@/types'
import SkeletonCard from '@/components/SkeletonCard.vue'
import { ref, computed, onMounted } from 'vue'
import type { Professional, DiaSemana, Frequency } from '@/types'
import { formatDate, formatTime } from '@/utils/dateUtils'

const authStore = useAuthStore()
const serviceStore = useServiceStore()
const labels = computed(() => getBusinessLabels(authStore.businessType))
const professionals = ref<Professional[]>([])
const loading = ref(true)
const error = ref('')
const showForm = ref(false)
const editingId = ref<string | null>(null)
const saving = ref(false)

const form = ref({
  name: '',
  professional_id: '',
  frequency: 'weekly' as Frequency,
  days_of_week: [] as DiaSemana[],
  start_time: '',
  end_time: '',
  duration_minutes: null as number | null,
  slot_interval_minutes: null as number | null,
  appointment_start: '',
  appointment_end: '',
  event_date: '',
  event_end_date: '',
  allows_in_person: false,
  allows_virtual: false,
  in_person_capacity: null as number | null,
  virtual_capacity: null as number | null,
})

onMounted(async () => {
  await Promise.all([serviceStore.fetchServices(), fetchProfessionals()])
  loading.value = false
})

async function fetchProfessionals() {
  if (!authStore.companyId) return
  try {
    professionals.value = await ProfessionalService.getAll(authStore.companyId)
  } catch (e: any) {
    error.value = e.message
  }
}

function resetForm() {
  form.value = {
    name: '',
    professional_id: '',
    frequency: 'weekly',
    days_of_week: [],
    start_time: '',
    end_time: '',
    duration_minutes: null,
    slot_interval_minutes: null,
    appointment_start: '',
    appointment_end: '',
    event_date: '',
    event_end_date: '',
    allows_in_person: false,
    allows_virtual: false,
    in_person_capacity: null,
    virtual_capacity: null,
  }
  editingId.value = null
}

function startEdit(s: any) {
  editingId.value = s.id
  form.value = {
    name: s.name,
    professional_id: s.professional_id,
    frequency: s.frequency || 'weekly',
    days_of_week: s.days_of_week || (s.day_of_week ? [s.day_of_week] : []),
    start_time: s.start_time,
    end_time: s.end_time,
    duration_minutes: s.duration_minutes,
    slot_interval_minutes: s.slot_interval_minutes,
    appointment_start: s.appointment_start || '',
    appointment_end: s.appointment_end || '',
    event_date: s.event_date || '',
    event_end_date: s.event_end_date || '',
    allows_in_person: s.allows_in_person,
    allows_virtual: s.allows_virtual,
    in_person_capacity: s.in_person_capacity,
    virtual_capacity: s.virtual_capacity,
  }
  showForm.value = true
}

function toggleDay(day: DiaSemana) {
  const idx = form.value.days_of_week.indexOf(day)
  if (idx >= 0) form.value.days_of_week.splice(idx, 1)
  else form.value.days_of_week.push(day)
}

async function handleSubmit() {
  if (!authStore.companyId) return
  if (!form.value.allows_in_person && !form.value.allows_virtual) {
    error.value = 'Habilitá al menos una modalidad'
    return
  }
  if (form.value.frequency === 'weekly' && form.value.days_of_week.length === 0) {
    error.value = 'Seleccioná al menos un día'
    return
  }

  saving.value = true
  try {
    const payload: any = { ...form.value, company_id: authStore.companyId }

    // Limpiar campos que no aplican según el modo
    if (payload.frequency !== 'appointment') {
      payload.slot_interval_minutes = null
      payload.appointment_start = null
      payload.appointment_end = null
    }
    if (payload.frequency !== 'one_time') {
      payload.event_date = null
      payload.event_end_date = null
    }
    if (payload.frequency !== 'weekly') {
      payload.days_of_week = null
    }
    if (payload.frequency === 'weekly') {
      payload.duration_minutes = null
    }

    if (editingId.value) {
      await serviceStore.updateService(editingId.value, payload)
    } else {
      await serviceStore.createService(payload)
    }
    showForm.value = false
    resetForm()
  } catch (e: any) {
    error.value = e.message
  } finally {
    saving.value = false
  }
}

async function toggleActive(s: any) {
  try {
    await serviceStore.updateService(s.id, { active: !s.active })
    await serviceStore.fetchServices()
  } catch (e: any) {
    error.value = e.message
  }
}
function toggleForm() {
  showForm.value = !showForm.value
  resetForm()
}
</script>

<template>
  <div>
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold" style="color: var(--color-text)">{{ labels.services }}</h1>
      <button
        @click="toggleForm"
        class="text-white px-4 py-2 rounded-lg"
        :style="{ backgroundColor: 'var(--color-primary)' }"
      >
        {{ showForm ? 'Cancelar' : '+ Nuevo' }}
      </button>
    </div>

    <!-- Formulario -->
    <div
      v-if="showForm"
      class="rounded-lg shadow p-6 mb-6"
      style="background-color: var(--color-surface)"
    >
      <h2 class="text-lg font-semibold mb-4" style="color: var(--color-text)">
        {{ editingId ? 'Editar' : 'Crear' }} Servicio
      </h2>
      <form @submit.prevent="handleSubmit" class="space-y-4">
        <!-- Nombre + Profesional -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium mb-1" style="color: var(--color-text)"
              >Nombre *</label
            >
            <input
              v-model="form.name"
              type="text"
              required
              class="w-full px-3 py-2 border rounded-lg"
              :style="{ borderColor: 'var(--color-border)' }"
            />
          </div>
          <div>
            <label class="block text-sm font-medium mb-1" style="color: var(--color-text)"
              >Profesional *</label
            >
            <select
              v-model="form.professional_id"
              required
              class="w-full px-3 py-2 border rounded-lg"
              :style="{ borderColor: 'var(--color-border)' }"
            >
              <option value="">Seleccionar...</option>
              <option v-for="p in professionals" :key="p.id" :value="p.id">{{ p.name }}</option>
            </select>
          </div>
        </div>

        <!-- Frecuencia con iconos y tooltips -->
        <div>
          <label class="block text-sm font-medium mb-2" style="color: var(--color-text)"
            >Frecuencia</label
          >
          <div class="grid grid-cols-3 gap-3">
            <button
              v-for="opt in FREQUENCY_OPTIONS"
              :key="opt.value"
              type="button"
              @click="form.frequency = opt.value"
              :class="[
                'p-3 rounded-lg border-2 text-left transition-all',
                form.frequency === opt.value ? 'border-blue-500 shadow-md' : 'border-gray-200',
              ]"
              :title="opt.description"
            >
              <div class="text-2xl mb-1">{{ opt.icon }}</div>
              <div class="text-sm font-medium" style="color: var(--color-text)">
                {{ opt.label }}
              </div>
              <div class="text-xs" style="color: var(--color-text-muted)">
                {{ opt.description }}
              </div>
            </button>
          </div>
        </div>

        <!-- SEMANAL: Días de la semana -->
        <div v-if="form.frequency === 'weekly'">
          <label class="block text-sm font-medium mb-2" style="color: var(--color-text)"
            >Días de la semana</label
          >
          <div class="flex flex-wrap gap-2">
            <button
              v-for="day in ALL_DAYS"
              :key="day.value"
              type="button"
              @click="toggleDay(day.value)"
              :class="[
                'px-4 py-2 rounded-lg border text-sm font-medium transition-all',
                form.days_of_week.includes(day.value) ? 'text-white' : 'border-gray-300',
              ]"
              :style="
                form.days_of_week.includes(day.value)
                  ? { backgroundColor: 'var(--color-primary)' }
                  : { color: 'var(--color-text)' }
              "
            >
              {{ day.short }}
            </button>
          </div>
        </div>

        <!-- HORARIO: Todos los modos -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div v-if="form.frequency !== 'one_time'">
            <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">{{
              form.frequency === 'appointment' ? 'Horario desde' : 'Hora inicio'
            }}</label>
            <input
              v-model="form.start_time"
              type="time"
              required
              class="w-full px-3 py-2 border rounded-lg"
              :style="{ borderColor: 'var(--color-border)' }"
            />
          </div>
          <div v-if="form.frequency !== 'one_time'">
            <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">{{
              form.frequency === 'appointment' ? 'Horario hasta' : 'Hora fin'
            }}</label>
            <input
              v-model="form.end_time"
              type="time"
              required
              class="w-full px-3 py-2 border rounded-lg"
              :style="{ borderColor: 'var(--color-border)' }"
            />
          </div>
        </div>

        <!-- TURNO: Intervalo -->
        <div v-if="form.frequency === 'appointment'" class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium mb-1" style="color: var(--color-text)"
              >Intervalo (minutos) *</label
            >
            <input
              v-model.number="form.slot_interval_minutes"
              type="number"
              min="5"
              max="120"
              required
              class="w-full px-3 py-2 border rounded-lg"
              :style="{ borderColor: 'var(--color-border)' }"
            />
            <p class="text-xs mt-1" style="color: var(--color-text-muted)">
              Cada cuántos minutos hay un turno disponible
            </p>
          </div>
          <div>
            <label class="block text-sm font-medium mb-1" style="color: var(--color-text)"
              >Duración (minutos)</label
            >
            <input
              v-model.number="form.duration_minutes"
              type="number"
              min="5"
              class="w-full px-3 py-2 border rounded-lg"
              :style="{ borderColor: 'var(--color-border)' }"
            />
          </div>
        </div>

        <!-- EVENTO: Fecha -->
        <div v-if="form.frequency === 'one_time'" class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium mb-1" style="color: var(--color-text)"
              >Fecha del evento *</label
            >
            <input
              v-model="form.event_date"
              type="date"
              required
              class="w-full px-3 py-2 border rounded-lg"
              :style="{ borderColor: 'var(--color-border)' }"
            />
          </div>
          <div>
            <label class="block text-sm font-medium mb-1" style="color: var(--color-text)"
              >Fecha fin (opcional, para cursos)</label
            >
            <input
              v-model="form.event_end_date"
              type="date"
              class="w-full px-3 py-2 border rounded-lg"
              :style="{ borderColor: 'var(--color-border)' }"
            />
          </div>
        </div>

        <!-- Modalidad -->
        <div class="flex items-center space-x-6">
          <label class="flex items-center space-x-2">
            <input v-model="form.allows_in_person" type="checkbox" class="rounded" />
            <span style="color: var(--color-text)">🏠 Presencial</span>
          </label>
          <input
            v-if="form.allows_in_person"
            v-model.number="form.in_person_capacity"
            type="number"
            min="1"
            placeholder="Cupos"
            class="w-24 px-2 py-1 border rounded"
            :style="{ borderColor: 'var(--color-border)' }"
          />
          <label class="flex items-center space-x-2">
            <input v-model="form.allows_virtual" type="checkbox" class="rounded" />
            <span style="color: var(--color-text)">💻 Virtual</span>
          </label>
          <input
            v-if="form.allows_virtual"
            v-model.number="form.virtual_capacity"
            type="number"
            min="1"
            placeholder="Cupos"
            class="w-24 px-2 py-1 border rounded"
            :style="{ borderColor: 'var(--color-border)' }"
          />
        </div>

        <div v-if="error" class="text-sm" style="color: #dc2626">{{ error }}</div>

        <button
          type="submit"
          class="text-white px-6 py-2 rounded-lg disabled:opacity-50"
          :disabled="saving"
          :style="{ backgroundColor: 'var(--color-primary)' }"
        >
          {{ saving ? 'Guardando...' : editingId ? 'Guardar Cambios' : 'Crear Servicio' }}
        </button>
      </form>
    </div>

    <div
      v-if="error && !showForm"
      class="rounded-lg p-4 mb-6"
      style="background-color: #fef2f2; color: #991b1b"
    >
      {{ error }}
    </div>

    <SkeletonCard
      v-if="loading"
      :count="3"
      :lines="3"
      class="grid-cols-1 md:grid-cols-2 lg:grid-cols-3"
    />

    <div
      v-else-if="serviceStore.services.length === 0"
      class="rounded-lg shadow p-8 text-center"
      style="background-color: var(--color-surface)"
    >
      <p style="color: var(--color-text-muted)">No hay servicios creados.</p>
    </div>

    <div v-else class="grid gap-4">
      <div
        v-for="s in serviceStore.services"
        :key="s.id"
        class="rounded-lg shadow p-4"
        :style="{
          backgroundColor: s.active ? 'var(--color-surface)' : 'var(--color-primary-subtle)',
          opacity: s.active ? 1 : 0.6,
        }"
      >
        <div class="flex justify-between items-start">
          <div>
            <div class="flex items-center space-x-2 mb-1">
              <h3 class="font-semibold" style="color: var(--color-text)">{{ s.name }}</h3>
              <span
                class="text-lg cursor-help"
                :title="FREQUENCY_OPTIONS.find((f) => f.value === s.frequency)?.description"
              >
                {{ FREQUENCY_OPTIONS.find((f) => f.value === s.frequency)?.icon }}
              </span>
              <span
                :class="[
                  s.active ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800',
                  'px-2 py-0.5 rounded-full text-xs font-medium',
                ]"
              >
                {{ s.active ? 'Activo' : 'Inactivo' }}
              </span>
            </div>
            <p class="text-sm capitalize" style="color: var(--color-text-muted)">
              <template v-if="s.frequency === 'weekly'">
                {{
                  s.days_of_week
                    ?.map((d) => ALL_DAYS.find((day) => day.value === d)?.short)
                    .join(', ')
                }}
                {{ formatTime(s.start_time) }} - {{ formatTime(s.end_time) }}
              </template>
              <template v-else-if="s.frequency === 'appointment'">
                Turnos cada {{ s.slot_interval_minutes }} min |
                {{ formatTime(s.appointment_start) }} -
                {{ formatTime(s.appointment_end) }}
              </template>
              <template v-else-if="s.frequency === 'one_time'">
                {{ formatDate(s.event_date) }} · {{ formatTime(s.start_time) }} -
                {{ formatTime(s.end_time) }}
              </template>
            </p>
            <p class="text-sm" style="color: var(--color-text-muted)">
              {{ s.professionals?.name }}
            </p>
            <div class="mt-1 flex items-center space-x-2 text-sm">
              <span v-if="s.allows_in_person">🏠 {{ s.in_person_capacity }} cupos</span>
              <span v-if="s.allows_virtual">💻 {{ s.virtual_capacity }} cupos</span>
            </div>
          </div>
          <div class="flex items-center space-x-3">
            <button
              @click="toggleActive(s)"
              :class="[
                s.active
                  ? 'text-red-600 hover:text-red-800'
                  : 'text-green-600 hover:text-green-800',
                'text-sm font-medium',
              ]"
            >
              {{ s.active ? 'Desactivar' : 'Activar' }}
            </button>
            <button @click="startEdit(s)" style="color: var(--color-primary)" class="text-sm">
              Editar
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
