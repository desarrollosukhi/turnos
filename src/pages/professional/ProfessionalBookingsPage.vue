<script setup lang="ts">
import { useAuthStore } from '@/stores/auth'
import { CompanyService } from '@/services/CompanyService'
import { ProfessionalService } from '@/services/ProfessionalService'
import { ServiceService } from '@/services/ServiceService'
import { BookingService } from '@/services/BookingService'
import ClinicalHistoryModal from '@/components/ClinicalHistoryModal.vue'
import SkeletonTable from '@/components/SkeletonTable.vue'
import { onMounted, ref } from 'vue'
import type { BookingWithDetails } from '@/types'

const authStore = useAuthStore()
const bookings = ref<BookingWithDetails[]>([])
const loading = ref(true)
const selectedDate = ref(new Date().toISOString().split('T')[0] ?? '')
const professionalId = ref('')
const enableClinicalHistory = ref(false)
const processingId = ref<string | null>(null)

// Modal
const showClinicalModal = ref(false)
const selectedUserId = ref('')
const selectedUserName = ref('')
const selectedBookingId = ref('')

onMounted(async () => {
  await loadBookings()
  if (authStore.companyId) {
    const settings = await CompanyService.getSettings(authStore.companyId)
    enableClinicalHistory.value = settings?.enable_clinical_history === true
  }
})

async function loadBookings() {
  if (!authStore.user) return
  loading.value = true
  try {
    const professional = await ProfessionalService.getByUserId(authStore.user.id)
    if (!professional) return
    professionalId.value = professional.id

    const services = await ServiceService.getByProfessionalId(professional.id)
    if (services.length === 0) return

    const allBookings: BookingWithDetails[] = []
    for (const svc of services) {
      const svcBookings = await BookingService.getByService(svc.id, selectedDate.value)
      allBookings.push(...svcBookings)
    }
    bookings.value = allBookings
  } catch (e) { console.error(e) }
  finally { loading.value = false }
}

async function markAttendance(bookingId: string, status: 'attended' | 'no_show') {
  processingId.value = bookingId
  try {
    await BookingService.markAttendance(bookingId, status)
    await loadBookings()
  } catch (e) { console.error(e) }
  finally { processingId.value = null }
}

function openClinicalHistory(userId: string, userName: string, bookingId: string) {
  selectedUserId.value = userId
  selectedUserName.value = userName
  selectedBookingId.value = bookingId
  showClinicalModal.value = true
}

const getEstadoBadgeClass = (status: string) => {
  switch (status) {
    case 'pending': return 'bg-blue-100 text-blue-800'
    case 'cancelled': return 'bg-red-100 text-red-800'
    case 'attended': return 'bg-green-100 text-green-800'
    case 'no_show': return 'bg-yellow-100 text-yellow-800'
    default: return 'bg-gray-100 text-gray-800'
  }
}
</script>

<template>
  <div>
    <h1 class="text-2xl font-bold mb-6" style="color: var(--color-text)">Reservas de mis servicios</h1>

    <div class="rounded-lg shadow p-4 mb-6" style="background-color: var(--color-surface)">
      <label class="block text-sm font-medium mb-1" style="color: var(--color-text-muted)">Fecha</label>
      <input v-model="selectedDate" type="date" @change="loadBookings"
        class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2"
        :style="{ borderColor: 'var(--color-border)', '--tw-ring-color': 'var(--color-primary)' }" />
    </div>

    <SkeletonTable v-if="loading" :rows="5" :cols="5" />

    <div v-else-if="bookings.length === 0" class="text-center py-8" style="color: var(--color-text-muted)">No hay reservas.</div>

    <!-- Desktop: tabla -->
    <div v-else class="hidden md:block rounded-lg shadow overflow-hidden" style="background-color: var(--color-surface)">
      <table class="min-w-full divide-y" :style="{ borderColor: 'var(--color-border)' }">
        <thead :style="{ backgroundColor: 'var(--color-primary-subtle)' }">
          <tr>
            <th class="px-6 py-3 text-left text-xs font-medium uppercase" style="color: var(--color-text-muted)">Cliente</th>
            <th class="px-6 py-3 text-left text-xs font-medium uppercase" style="color: var(--color-text-muted)">Servicio</th>
            <th class="px-6 py-3 text-left text-xs font-medium uppercase" style="color: var(--color-text-muted)">Fecha</th>
            <th class="px-6 py-3 text-left text-xs font-medium uppercase" style="color: var(--color-text-muted)">Estado</th>
            <th class="px-6 py-3 text-left text-xs font-medium uppercase" style="color: var(--color-text-muted)">Acciones</th>
          </tr>
        </thead>
        <tbody class="divide-y" :style="{ borderColor: 'var(--color-border)' }">
          <tr v-for="b in bookings" :key="b.id" :style="{ backgroundColor: 'var(--color-surface)' }">
            <td class="px-6 py-4 whitespace-nowrap text-sm" style="color: var(--color-text)">{{ b.users?.name }}</td>
            <td class="px-6 py-4 whitespace-nowrap text-sm" style="color: var(--color-text)">{{ b.services?.name }}</td>
            <td class="px-6 py-4 whitespace-nowrap text-sm" style="color: var(--color-text-muted)">{{ b.date }}</td>
            <td class="px-6 py-4 whitespace-nowrap">
              <span :class="[getEstadoBadgeClass(b.status), 'px-2 inline-flex text-xs leading-5 font-semibold rounded-full']">{{ b.status }}</span>
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm space-x-2">
              <button v-if="b.status === 'pending'" @click="markAttendance(b.id, 'attended')" :disabled="processingId === b.id" class="text-green-600 hover:text-green-800 disabled:opacity-50">✓ Asistió</button>
              <button v-if="b.status === 'pending'" @click="markAttendance(b.id, 'no_show')" :disabled="processingId === b.id" class="text-yellow-600 hover:text-yellow-800 disabled:opacity-50">✗ Ausente</button>
              <button v-if="enableClinicalHistory && b.users?.name" @click="openClinicalHistory(b.user_id!, b.users.name, b.id)" class="text-blue-600 hover:text-blue-800">📋 Historia</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Mobile: cards -->
    <div v-if="bookings.length > 0" class="md:hidden space-y-3">
      <div v-for="b in bookings" :key="b.id" class="rounded-lg shadow p-4" style="background-color: var(--color-surface)">
        <div class="flex justify-between items-start mb-2">
          <div class="font-semibold" style="color: var(--color-text)">{{ b.users?.name }}</div>
          <span :class="[getEstadoBadgeClass(b.status), 'px-2 py-0.5 text-xs font-semibold rounded-full']">{{ b.status }}</span>
        </div>
        <div class="text-sm mb-1" style="color: var(--color-text)">{{ b.services?.name }}</div>
        <div class="text-xs mb-3" style="color: var(--color-text-muted)">{{ b.date }}</div>
        <div v-if="b.status === 'pending'" class="flex flex-wrap gap-2">
          <button @click="markAttendance(b.id, 'attended')" :disabled="processingId === b.id" class="text-xs px-2 py-1 rounded text-green-600 border border-green-300 disabled:opacity-50">✓ Asistió</button>
          <button @click="markAttendance(b.id, 'no_show')" :disabled="processingId === b.id" class="text-xs px-2 py-1 rounded text-yellow-600 border border-yellow-300 disabled:opacity-50">✗ Ausente</button>
          <button v-if="enableClinicalHistory && b.users?.name" @click="openClinicalHistory(b.user_id!, b.users.name, b.id)" class="text-xs px-2 py-1 rounded text-blue-600 border border-blue-300">📋 Historia</button>
        </div>
      </div>
    </div>

    <ClinicalHistoryModal
      :show="showClinicalModal"
      :user-id="selectedUserId"
      :user-name="selectedUserName"
      :professional-id="professionalId"
      :booking-id="selectedBookingId"
      @close="showClinicalModal = false"
      @saved="loadBookings"
    />
  </div>
</template>
