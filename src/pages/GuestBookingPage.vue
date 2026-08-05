<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRoute } from 'vue-router'
import { CompanyService } from '@/services/CompanyService'
import { ServiceService } from '@/services/ServiceService'
import { HolidayService } from '@/services/HolidayService'
import { supabase } from '@/supabase/client'
import MonthlyCalendar from '@/components/MonthlyCalendar.vue'
import GuestBookingModal from '@/components/GuestBookingModal.vue'
import type { ServiceWithProfessional } from '@/types'

const route = useRoute()
const companyId = computed(() => route.params.companyId as string)
const serviceId = computed(() => route.params.serviceId as string | undefined)

const company = ref<{ name: string } | null>(null)
const services = ref<ServiceWithProfessional[]>([])
const loading = ref(true)
const error = ref('')
const selectedDate = ref(new Date().toISOString().split('T')[0] ?? '')
const isHoliday = ref(false)
const holidayDates = ref<string[]>([])

// Modal
const showModal = ref(false)
const selectedService = ref<ServiceWithProfessional | null>(null)
const selectedModality = ref<'in_person' | 'virtual'>('in_person')

const dayNames = ['domingo', 'lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado']

const serviceDays = computed(() => {
  const days = new Set<number>()
  services.value.forEach(s => {
    if (s.frequency === 'weekly' && s.days_of_week) {
      s.days_of_week.forEach(d => {
        const idx = dayNames.indexOf(d)
        if (idx !== -1) days.add(idx)
      })
    }
  })
  return Array.from(days)
})

const filteredServices = computed(() => {
  const date = new Date(selectedDate.value + 'T12:00:00')
  const diaNombre = dayNames[date.getDay()]
  return services.value.filter(s => {
    if (s.frequency === 'weekly') {
      return s.days_of_week?.includes(diaNombre as any)
    } else if (s.frequency === 'one_time') {
      return s.event_date === selectedDate.value
    }
    return true
  })
})

onMounted(async () => {
  try {
    company.value = await CompanyService.getById(companyId.value)

    if (serviceId.value) {
      const svc = await ServiceService.getById(serviceId.value)
      services.value = svc ? [svc] : []
    } else {
      services.value = await ServiceService.getAll(companyId.value)
    }

    const holidays = await HolidayService.getAll(companyId.value)
    holidayDates.value = holidays.filter(h => h.active).map(h => h.date)
    isHoliday.value = holidayDates.value.includes(selectedDate.value)
  } catch (e: any) { error.value = e.message }
  finally { loading.value = false }
})

function handleCalendarSelect(date: string) {
  selectedDate.value = date
  isHoliday.value = holidayDates.value.includes(date)
}

function openBookingModal(svc: ServiceWithProfessional) {
  selectedService.value = svc
  selectedModality.value = svc.allows_in_person ? 'in_person' : 'virtual'
  showModal.value = true
}
</script>

<template>
  <div class="min-h-screen" style="background-color: var(--color-background)">
    <!-- Header -->
    <div style="background-color: var(--color-surface); border-bottom: 1px solid var(--color-border)">
      <div class="max-w-4xl mx-auto px-4 py-4">
        <h1 class="text-xl font-bold" style="color: var(--color-text)">{{ company?.name || 'Cargando...' }}</h1>
        <p class="text-sm" style="color: var(--color-text-muted)">Reservá tu turno sin crear cuenta</p>
      </div>
    </div>

    <div class="max-w-4xl mx-auto px-4 py-6">
      <!-- Loading -->
      <div v-if="loading" class="text-center py-8">
        <div class="animate-spin rounded-full h-8 w-8 border-b-2 mx-auto" style="border-color: var(--color-primary); border-bottom-color: transparent"></div>
      </div>

      <!-- Error -->
      <div v-if="error" class="rounded-lg p-4 mb-6" style="background-color: #fef2f2; color: #991b1b">{{ error }}</div>

      <template v-else>
        <!-- Calendario -->
        <MonthlyCalendar
          :selected-date="selectedDate"
          :holidays="holidayDates"
          :cancelled-dates="[]"
          :reservation-dates="[]"
          :class-days="serviceDays"
          @select="handleCalendarSelect"
          class="mb-6"
        />

        <!-- Banner feriado -->
        <div v-if="isHoliday" class="rounded-lg p-4 mb-6" style="background-color: #fef2f2; border: 1px solid #fecaca; color: #991b1b">
          Este día es feriado. No se pueden hacer reservas.
        </div>

        <!-- Servicios -->
        <div v-if="filteredServices.length === 0" class="rounded-lg shadow p-8 text-center" style="background-color: var(--color-surface)">
          <p style="color: var(--color-text-muted)">No hay servicios disponibles para esta fecha.</p>
        </div>

        <div v-else class="grid gap-4">
          <div v-for="svc in filteredServices" :key="svc.id" class="rounded-lg shadow p-6" style="background-color: var(--color-surface)">
            <div class="flex justify-between items-start">
              <div>
                <h3 class="text-lg font-semibold" style="color: var(--color-text)">{{ svc.name }}</h3>
                <p style="color: var(--color-text-muted)">{{ svc.start_time }} - {{ svc.end_time }}</p>
                <p class="text-sm" style="color: var(--color-text-muted)">{{ svc.professionals?.name }}</p>
                <div class="mt-2 flex items-center space-x-2">
                  <span v-if="svc.allows_in_person" class="text-sm">🏠 Presencial ({{ svc.in_person_capacity }} cupos)</span>
                  <span v-if="svc.allows_virtual" class="text-sm">💻 Virtual ({{ svc.virtual_capacity }} cupos)</span>
                </div>
              </div>
              <button
                @click="openBookingModal(svc)"
                class="px-4 py-2 rounded-lg text-white text-sm cursor-pointer hover:opacity-90"
                :style="{ backgroundColor: 'var(--color-primary)' }"
              >
                Reservar
              </button>
            </div>
          </div>
        </div>
      </template>
    </div>

    <!-- Guest Booking Modal -->
    <GuestBookingModal
      :show="showModal"
      :service="selectedService"
      :company-id="companyId"
      :selected-date="selectedDate"
      :initial-modality="selectedModality"
      @close="showModal = false"
    />
  </div>
</template>
