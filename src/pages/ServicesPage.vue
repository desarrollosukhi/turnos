<script setup lang="ts">
import { useServiceStore } from '@/stores/service'
import { useBookingStore } from '@/stores/booking'
import { useAuthStore } from '@/stores/auth'
import { BookingService } from '@/services/BookingService'
import { HolidayService } from '@/services/HolidayService'
import { CompanyService } from '@/services/CompanyService'
import { getProfessionalDisplayName, ALL_DAYS } from '@/types'
import { supabase } from '@/supabase/client'
import { onMounted, ref, computed, watch } from 'vue'
import MonthlyCalendar from '@/components/MonthlyCalendar.vue'
import TimeWindowModal from '@/components/TimeWindowModal.vue'
import HolidayBanner from '@/components/HolidayBanner.vue'
import SkeletonCard from '@/components/SkeletonCard.vue'
import type { BookingWindow } from '@/types'

const serviceStore = useServiceStore()
const bookingStore = useBookingStore()
const authStore = useAuthStore()

const selectedDate = ref<string>(new Date().toISOString().split('T')[0] ?? '')
const isHoliday = ref(false)
const showModal = ref(false)
const modalTipo = ref<'reservar' | 'cancelar'>('reservar')
const modalMinutos = ref(0)
const modalVentana = ref(0)
const selectedServiceId = ref<string | null>(null)
const selectedModality = ref<'in_person' | 'virtual' | null>(null)
const companySettings = ref<any>(null)
const companyData = ref<any>(null)
const monthError = ref('')

// Filtros de búsqueda
const searchQuery = ref('')
const selectedProfessionalFilter = ref('')
const selectedModalityFilter = ref('')

const holidayDates = ref<string[]>([])
const cancelledDates = ref<string[]>([])
const reservationDates = ref<string[]>([])
const userBookings = ref<{ date: string; service_id: string }[]>([])
const dayNames = ['domingo', 'lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado']

const windowCache = ref<Map<string, BookingWindow>>(new Map())

// Días que tienen servicios recurrentes
const serviceDays = computed(() => {
  const days = new Set<number>()
  serviceStore.services.forEach(s => {
    if (s.frequency === 'weekly' && s.days_of_week) {
      s.days_of_week.forEach(d => {
        const idx = dayNames.indexOf(d)
        if (idx !== -1) days.add(idx)
      })
    }
  })
  return Array.from(days)
})

// Servicios filtrados por el día seleccionado
const filteredServices = computed(() => {
  const date = new Date(selectedDate.value + 'T12:00:00')
  const diaNombre = dayNames[date.getDay()]

  let result = serviceStore.services.filter(s => {
    if (s.frequency === 'weekly') {
      return s.days_of_week?.includes(diaNombre as any)
    } else if (s.frequency === 'one_time') {
      return s.event_date === selectedDate.value
    }
    return true
  })

  // Filtro por búsqueda de texto
  if (searchQuery.value) {
    const q = searchQuery.value.toLowerCase()
    result = result.filter(s =>
      s.name.toLowerCase().includes(q) ||
      s.professionals?.name.toLowerCase().includes(q)
    )
  }

  // Filtro por profesional
  if (selectedProfessionalFilter.value) {
    result = result.filter(s => s.professional_id === selectedProfessionalFilter.value)
  }

  // Filtro por modalidad
  if (selectedModalityFilter.value === 'in_person') {
    result = result.filter(s => s.allows_in_person)
  } else if (selectedModalityFilter.value === 'virtual') {
    result = result.filter(s => s.allows_virtual)
  }

  return result
})

// Profesionales únicos de los servicios disponibles
const uniqueProfessionals = computed(() => {
  const map = new Map<string, string>()
  serviceStore.services.forEach(s => {
    if (s.professionals) {
      map.set(s.professional_id, s.professionals.name)
    }
  })
  return Array.from(map.entries()).map(([id, name]) => ({ id, name }))
})

// IDs de servicios que el usuario ya reservó para el día seleccionado
const bookedServiceIds = computed(() => {
  return new Set(
    userBookings.value
      .filter(b => b.date === selectedDate.value)
      .map(b => b.service_id)
  )
})

// Gym schedule for the selected day
const gymSchedule = computed(() => {
  if (!companySettings.value?.gym_mode || !companyData.value?.gym_schedule) return null
  const date = new Date(selectedDate.value + 'T12:00:00')
  const diaNombre = dayNames[date.getDay()]
  if (!diaNombre) return null
  return companyData.value.gym_schedule[diaNombre] || null
})

// Check if user has free pass
const hasFreePass = computed(() => {
  return authStore.user?.access_type === 'free_pass'
})

// Check if gym mode is active
const isGymMode = computed(() => {
  return companySettings.value?.gym_mode === true
})

const selectedDateFormatted = computed(() => {
  const date = new Date(selectedDate.value + 'T12:00:00')
  return date.toLocaleDateString('es-AR', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })
})

onMounted(async () => {
  await serviceStore.fetchServices()
  if (authStore.companyId) {
    companySettings.value = await CompanyService.getSettings(authStore.companyId)
    companyData.value = await CompanyService.getById(authStore.companyId)
  }
  await loadMonthData()
  await checkHoliday()
})

watch(selectedDate, async () => {
  windowCache.value.clear()
  await loadMonthData()
  await checkHoliday()
})

async function loadMonthData() {
  if (!authStore.companyId) return

  const date = new Date(selectedDate.value + 'T12:00:00')
  const year = date.getFullYear()
  const month = date.getMonth()
  const startDate = `${year}-${String(month + 1).padStart(2, '0')}-01`
  const endDate = `${year}-${String(month + 2).padStart(2, '0')}-01`
  monthError.value = ''

  try {
    const holidays = await HolidayService.getAll(authStore.companyId)
    holidayDates.value = holidays
      .filter(h => h.active && h.date >= startDate && h.date < endDate)
      .map(h => h.date)
  } catch { monthError.value = 'Error al cargar feriados' }

  try {
    const { data } = await supabase
      .from('cancelled_service_sessions')
      .select('date')
      .eq('company_id', authStore.companyId)
      .gte('date', startDate)
      .lt('date', endDate)
    cancelledDates.value = data?.map(c => c.date) || []
  } catch { monthError.value = 'Error al cargar sesiones canceladas' }

  if (authStore.user) {
    try {
      const { data } = await supabase
        .from('bookings')
        .select('date, service_id')
        .eq('user_id', authStore.user.id)
        .gte('date', startDate)
        .lt('date', endDate)
        .eq('status', 'pending')
      userBookings.value = data || []
      reservationDates.value = data?.map(b => b.date) || []
    } catch { monthError.value = 'Error al cargar tus reservas' }
  }
}

async function checkHoliday() {
  if (!authStore.companyId) return
  isHoliday.value = await HolidayService.isHoliday(authStore.companyId, selectedDate.value)
}

async function getWindow(serviceId: string): Promise<BookingWindow | null> {
  const key = `${serviceId}-${selectedDate.value}`
  if (windowCache.value.has(key)) return windowCache.value.get(key)!
  if (!authStore.companyId) return null
  try {
    const window = await BookingService.checkWindow(serviceId, selectedDate.value, authStore.companyId)
    windowCache.value.set(key, window)
    return window
  } catch { return null }
}

async function handleReserve(serviceId: string, modality: 'in_person' | 'virtual') {
  const window = await getWindow(serviceId)
  if (window && !window.puede_reservar) {
    modalTipo.value = 'reservar'
    modalMinutos.value = window.minutos_para_clase
    modalVentana.value = window.ventana_reserva
    showModal.value = true
    return
  }
  selectedServiceId.value = serviceId
  selectedModality.value = modality
  await bookingStore.createBooking(serviceId, selectedDate.value, modality)
  await loadMonthData()
}

function handleCalendarSelect(date: string) {
  selectedDate.value = date
  windowCache.value.clear()
}

const getModalityLabel = (a: boolean, v: boolean) => {
  if (a && v) return 'Híbrida'
  if (a) return 'Presencial'
  return 'Virtual'
}

const getModalityIcon = (a: boolean, v: boolean) => {
  if (a && v) return '🏠💻'
  if (a) return '🏠'
  return '💻'
}
</script>

<template>
  <div>
    <h1 class="text-2xl font-bold mb-6" style="color: var(--color-text)">Servicios Disponibles</h1>

    <div v-if="monthError" class="rounded-lg p-4 mb-6" style="background-color: #fef2f2; color: #991b1b">{{ monthError }}</div>

    <MonthlyCalendar
      :selected-date="selectedDate"
      :holidays="holidayDates"
      :cancelled-dates="cancelledDates"
      :reservation-dates="reservationDates"
      :class-days="serviceDays"
      @select="handleCalendarSelect"
      class="mb-6"
    />

    <HolidayBanner :show="isHoliday" />

    <!-- Barra de búsqueda y filtros -->
    <div v-if="!isHoliday && serviceStore.services.length > 3" class="rounded-lg shadow p-4 mb-6" style="background-color: var(--color-surface)">
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div>
          <input
            v-model="searchQuery"
            type="text"
            placeholder="🔍 Buscar clase o profesional..."
            class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2"
            :style="{ borderColor: 'var(--color-border)', '--tw-ring-color': 'var(--color-primary)' }"
          />
        </div>
        <div>
          <select
            v-model="selectedProfessionalFilter"
            class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2"
            :style="{ borderColor: 'var(--color-border)', '--tw-ring-color': 'var(--color-primary)' }"
          >
            <option value="">Todos los profesionales</option>
            <option v-for="p in uniqueProfessionals" :key="p.id" :value="p.id">{{ p.name }}</option>
          </select>
        </div>
        <div>
          <select
            v-model="selectedModalityFilter"
            class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2"
            :style="{ borderColor: 'var(--color-border)', '--tw-ring-color': 'var(--color-primary)' }"
          >
            <option value="">Todas las modalidades</option>
            <option value="in_person">🏠 Presencial</option>
            <option value="virtual">💻 Virtual</option>
          </select>
        </div>
      </div>
    </div>

    <!-- Gym mode: show schedule -->
    <div v-if="isGymMode && gymSchedule && !isHoliday" class="rounded-lg p-4 mb-6" style="background-color: var(--color-primary-subtle); border: 1px solid var(--color-primary)">
      <div class="flex items-center space-x-2">
        <span class="text-lg">🏋️</span>
        <div>
          <p class="font-semibold" style="color: var(--color-primary)">Modo Gimnasio</p>
          <p class="text-sm" style="color: var(--color-text)">
            <template v-if="hasFreePass">
              🎫 Free Pass — Gimnasio abierto de {{ gymSchedule.start }} a {{ gymSchedule.end }}
            </template>
            <template v-else>
              💰 Modo créditos — Cada clase cuesta créditos
            </template>
          </p>
        </div>
      </div>
    </div>

    <!-- Free pass: show schedule without booking buttons -->
    <div v-if="isGymMode && hasFreePass && gymSchedule && !isHoliday" class="rounded-lg shadow p-6 mb-6" style="background-color: var(--color-surface)">
      <div class="flex items-center space-x-3">
        <span class="text-3xl">🎫</span>
        <div>
          <p class="font-semibold text-lg" style="color: var(--color-text)">Free Pass Activo</p>
          <p style="color: var(--color-text-muted)">Podés asistir de {{ gymSchedule.start }} a {{ gymSchedule.end }}</p>
          <p class="text-sm mt-1" style="color: var(--color-text-muted)">No necesitás reservar. Solo presentate en el horario.</p>
        </div>
      </div>
    </div>

    <div class="flex items-center justify-between mb-4">
      <h2 class="text-lg font-semibold capitalize" style="color: var(--color-text)">{{ selectedDateFormatted }}</h2>
      <span v-if="filteredServices.length > 0" class="text-sm" style="color: var(--color-text-muted)">
        {{ filteredServices.length }} servicio(s)
      </span>
    </div>

    <SkeletonCard v-if="serviceStore.loading" :count="2" :lines="3" class="grid-cols-1" />

    <div v-else-if="filteredServices.length === 0 && !isHoliday" class="rounded-lg shadow p-8 text-center" style="background-color: var(--color-surface)">
      <p style="color: var(--color-text-muted)">No hay servicios este día</p>
      <p class="text-sm mt-1" style="color: var(--color-text-muted)">Seleccioná otro día en el calendario</p>
    </div>

    <div v-else class="grid gap-4">
      <div v-for="svc in filteredServices" :key="svc.id" class="rounded-lg shadow p-6" style="background-color: var(--color-surface)">
        <div class="flex justify-between items-start">
          <div>
            <div class="flex items-center space-x-2 mb-1">
              <h3 class="text-lg font-semibold" style="color: var(--color-text)">{{ svc.name }}</h3>
              <span
                class="text-lg cursor-help"
                :title="svc.frequency === 'weekly' ? 'Se repite cada semana en los días seleccionados' : svc.frequency === 'appointment' ? 'Turnos individuales cada ' + svc.slot_interval_minutes + ' min' : 'Evento único el ' + svc.event_date"
              >
                {{ svc.frequency === 'weekly' ? '🔄' : svc.frequency === 'appointment' ? '⏰' : '🎯' }}
              </span>
            </div>
            <p style="color: var(--color-text-muted)">
              {{ svc.start_time }} - {{ svc.end_time }}
              <template v-if="svc.frequency === 'appointment'"> | Turnos cada {{ svc.slot_interval_minutes }} min</template>
            </p>
            <p class="text-sm" style="color: var(--color-text-muted)">
              {{ svc.professionals ? getProfessionalDisplayName(svc.professionals, companySettings?.show_alias || false) : '' }}
            </p>
            <div class="mt-2 flex items-center space-x-2">
              <span class="text-sm">
                {{ getModalityIcon(svc.allows_in_person, svc.allows_virtual) }}
                {{ getModalityLabel(svc.allows_in_person, svc.allows_virtual) }}
              </span>
            </div>
          </div>
          <div class="flex space-x-2">
            <!-- Gym mode + Free pass: sin botón de reserva -->
            <template v-if="isGymMode && hasFreePass">
              <span class="text-sm px-3 py-1 rounded" style="background-color: var(--color-primary-subtle); color: var(--color-primary)">
                🎫 Acceso libre
              </span>
            </template>
            <!-- Ya reservado -->
            <template v-else-if="bookedServiceIds.has(svc.id)">
              <router-link
                to="/my-bookings"
                class="px-4 py-2 rounded-lg text-sm font-medium cursor-pointer"
                style="background-color: #fef3c7; color: #92400e"
              >
                ✓ Ya reservado
              </router-link>
            </template>
            <!-- Créditos: botones de reserva normales -->
            <template v-else>
              <button
                v-if="svc.allows_in_person"
                @click="handleReserve(svc.id, 'in_person')"
                :disabled="bookingStore.loading || isHoliday"
                class="px-4 py-2 rounded-lg text-white disabled:opacity-50 text-sm cursor-pointer"
                :style="{ backgroundColor: 'var(--color-primary)' }"
              >
                🏠 Reservar Presencial
              </button>
              <button
                v-if="svc.allows_virtual"
                @click="handleReserve(svc.id, 'virtual')"
                :disabled="bookingStore.loading || isHoliday"
                class="px-4 py-2 rounded-lg text-white disabled:opacity-50 text-sm cursor-pointer"
                style="background-color: #16a34a"
              >
                💻 Reservar Virtual
              </button>
            </template>
          </div>
        </div>
        <div v-if="bookingStore.error && selectedServiceId === svc.id" class="mt-2 text-sm" style="color: #dc2626">
          {{ bookingStore.error }}
        </div>
      </div>
    </div>

    <TimeWindowModal :show="showModal" :tipo="modalTipo" :minutos-para-clase="modalMinutos" :ventana="modalVentana" @close="showModal = false" />
  </div>
</template>
