<script setup lang="ts">
import { useAuthStore } from '@/stores/auth'
import { CompanyService } from '@/services/CompanyService'
import { ProfessionalService } from '@/services/ProfessionalService'
import { ServiceService } from '@/services/ServiceService'
import { BookingService } from '@/services/BookingService'
import ClinicalHistoryModal from '@/components/ClinicalHistoryModal.vue'
import SkeletonTable from '@/components/SkeletonTable.vue'
import { onMounted, ref, computed, watch } from 'vue'
import ToastMessage from '@/components/ToastMessage.vue'
import type { BookingWithDetails } from '@/types'

const authStore = useAuthStore()
const bookings = ref<BookingWithDetails[]>([])
const loading = ref(true)
const selectedDate = ref(new Date().toISOString().split('T')[0] ?? '')
const professionalId = ref('')
const enableClinicalHistory = ref(false)
const processingId = ref<string | null>(null)

// Modal clínica
const showClinicalModal = ref(false)
const selectedUserId = ref('')
const selectedUserName = ref('')
const selectedBookingId = ref('')

// Cancelar sesión
const showCancelSessionModal = ref(false)
const cancelSessionService = ref('')
const cancelSessionDate = ref(new Date().toISOString().split('T')[0] ?? '')
const cancelSessionReason = ref('')
const cancellingSession = ref(false)
const myServices = ref<any[]>([])
const showToast = ref(false)
const toastMessage = ref('')
const toastType = ref<'success' | 'error' | 'info'>('success')

const dayNames = ['domingo', 'lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado']

// Servicios del profesional filtrados por fecha del modal
const myServicesForDate = computed(() => {
  if (!cancelSessionDate.value) return myServices.value
  const date = new Date(cancelSessionDate.value + 'T12:00:00')
  const dayName = dayNames[date.getDay()]
  return myServices.value.filter(s => {
    if (s.frequency === 'weekly') return s.days_of_week?.includes(dayName)
    if (s.frequency === 'one_time') return s.event_date === cancelSessionDate.value
    return true
  })
})

// Reset servicio seleccionado si ya no está disponible
watch(cancelSessionDate, () => {
  if (cancelSessionService.value && !myServicesForDate.value.find(s => s.id === cancelSessionService.value)) {
    cancelSessionService.value = ''
  }
})

onMounted(async () => {
  await loadBookings()
  if (authStore.companyId) {
    const settings = await CompanyService.getSettings(authStore.companyId)
    enableClinicalHistory.value = settings?.enable_clinical_history === true
  }
})

async function loadMyServices() {
  if (!authStore.user) return
  const professional = await ProfessionalService.getByUserId(authStore.user.id)
  if (professional) {
    myServices.value = await ServiceService.getByProfessionalId(professional.id)
  }
}

async function loadBookings() {
  if (!authStore.user) return
  loading.value = true
  try {
    const professional = await ProfessionalService.getByUserId(authStore.user.id)
    if (!professional) return
    professionalId.value = professional.id

    const services = await ServiceService.getByProfessionalId(professional.id)
    myServices.value = services
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

async function handleCancelSession() {
  if (!cancelSessionService.value || !cancelSessionDate.value) return
  cancellingSession.value = true
  try {
    const result = await BookingService.cancelServiceSession(cancelSessionService.value, cancelSessionDate.value, cancelSessionReason.value || undefined)
    showCancelSessionModal.value = false
    cancelSessionReason.value = ''
    toastMessage.value = result
    toastType.value = 'success'
    showToast.value = true
    await loadBookings()
  } catch (e: any) {
    toastMessage.value = e.message || 'Error al cancelar sesión'
    toastType.value = 'error'
    showToast.value = true
  } finally {
    cancellingSession.value = false
  }
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
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold" style="color: var(--color-text)">Reservas de mis servicios</h1>
      <button @click="showCancelSessionModal = true" class="text-sm px-3 py-2 rounded-lg cursor-pointer hover:opacity-90" style="background-color: #dc2626; color: white">
        ⛔ Cancelar sesión
      </button>
    </div>

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

    <!-- Toast -->
    <ToastMessage :show="showToast" :message="toastMessage" :type="toastType" @close="showToast = false" />

    <!-- Modal Cancelar Sesión -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="showCancelSessionModal" class="fixed inset-0 z-50 flex items-center justify-center">
          <div class="fixed inset-0 bg-black/50" @click="showCancelSessionModal = false"></div>
          <div class="relative rounded-lg shadow-xl max-w-md w-full mx-4 p-6" style="background-color: var(--color-surface)">
            <h3 class="text-lg font-semibold mb-4" style="color: var(--color-text)">⛔ Cancelar sesión</h3>
            <p class="text-sm mb-4" style="color: var(--color-text-muted)">
              Se cancelarán <strong>todas</strong> las reservas pendientes de esta sesión. Se devolverán los créditos a cada alumno afectado.
            </p>

            <div class="space-y-3">
              <div>
                <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Servicio</label>
                <select v-model="cancelSessionService" class="w-full px-3 py-2 border rounded-lg" :style="{ borderColor: 'var(--color-border)' }">
                  <option value="">Seleccionar servicio...</option>
                  <option v-for="s in myServicesForDate" :key="s.id" :value="s.id">{{ s.name }}</option>
                </select>
              </div>
              <div>
                <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Fecha</label>
                <input v-model="cancelSessionDate" type="date" class="w-full px-3 py-2 border rounded-lg" :style="{ borderColor: 'var(--color-border)' }" />
              </div>
              <div>
                <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Motivo (opcional)</label>
                <input v-model="cancelSessionReason" type="text" placeholder="Ej: Emergencia, mantenimiento..." class="w-full px-3 py-2 border rounded-lg" :style="{ borderColor: 'var(--color-border)' }" />
              </div>
            </div>

            <div class="flex justify-end space-x-3 mt-6">
              <button @click="showCancelSessionModal = false" class="px-4 py-2 rounded-lg cursor-pointer" :style="{ backgroundColor: 'var(--color-primary-subtle)', color: 'var(--color-text)' }">Cancelar</button>
              <button @click="handleCancelSession" :disabled="!cancelSessionService || !cancelSessionDate || cancellingSession" class="px-4 py-2 rounded-lg text-white cursor-pointer disabled:opacity-50" style="background-color: #dc2626">
                {{ cancellingSession ? 'Cancelando...' : 'Cancelar sesión' }}
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>
