<script setup lang="ts">
import { BookingService } from '@/services/BookingService'
import { ServiceService } from '@/services/ServiceService'
import { ProfessionalService } from '@/services/ProfessionalService'
import { useAuthStore } from '@/stores/auth'
import { exportToCSV } from '@/utils/exportUtils'
import PaginationBar from '@/components/PaginationBar.vue'
import SkeletonTable from '@/components/SkeletonTable.vue'
import { ref, computed, onMounted, watch } from 'vue'
import ToastMessage from '@/components/ToastMessage.vue'

const authStore = useAuthStore()
const bookings = ref<any[]>([])
const services = ref<any[]>([])
const professionals = ref<any[]>([])
const loading = ref(true)
const error = ref('')
const selectedService = ref('')
const selectedProfessional = ref('')
const selectedDate = ref(new Date().toISOString().split('T')[0] ?? '')
const processingId = ref<string | null>(null)

// Cancelar sesión
const showCancelSessionModal = ref(false)
const cancelSessionService = ref('')
const cancelSessionDate = ref(new Date().toISOString().split('T')[0] ?? '')
const cancelSessionReason = ref('')
const cancellingSession = ref(false)
const showToast = ref(false)
const toastMessage = ref('')
const toastType = ref<'success' | 'error' | 'info'>('success')

// Paginación
const currentPage = ref(1)
const pageSize = 20

const dayNames = ['domingo', 'lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado']

// Servicios filtrados por fecha del modal de cancelación
const servicesForDate = computed(() => {
  if (!cancelSessionDate.value) return services.value
  const date = new Date(cancelSessionDate.value + 'T12:00:00')
  const dayName = dayNames[date.getDay()]
  return services.value.filter(s => {
    if (s.frequency === 'weekly') return s.days_of_week?.includes(dayName)
    if (s.frequency === 'one_time') return s.event_date === cancelSessionDate.value
    return true
  })
})

// Reset servicio seleccionado si ya no está disponible en la nueva fecha
watch(cancelSessionDate, () => {
  if (cancelSessionService.value && !servicesForDate.value.find(s => s.id === cancelSessionService.value)) {
    cancelSessionService.value = ''
  }
})

onMounted(async () => {
  await Promise.all([fetchBookings(), fetchServices(), fetchProfessionals()])
  loading.value = false
})

async function fetchBookings() { try { bookings.value = await BookingService.getAll() } catch (e: any) { error.value = e.message } }
async function fetchServices() { if (!authStore.companyId) return; try { services.value = await ServiceService.getAll(authStore.companyId) } catch (e: any) { error.value = e.message } }
async function fetchProfessionals() { if (!authStore.companyId) return; try { professionals.value = await ProfessionalService.getAll(authStore.companyId) } catch (e: any) { error.value = e.message } }

async function markAttendance(bookingId: string, status: 'attended' | 'no_show') {
  processingId.value = bookingId
  try { await BookingService.markAttendance(bookingId, status); await fetchBookings() } catch (e: any) { error.value = e.message }
  finally { processingId.value = null }
}

async function cancelBooking(bookingId: string) {
  if (!confirm('¿Cancelar reserva? Se devolverá el crédito al cliente.')) return
  processingId.value = bookingId
  try { await BookingService.adminCancel(bookingId); await fetchBookings() } catch (e: any) { error.value = e.message }
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
    await fetchBookings()
  } catch (e: any) {
    toastMessage.value = e.message || 'Error al cancelar sesión'
    toastType.value = 'error'
    showToast.value = true
  } finally {
    cancellingSession.value = false
  }
}

const filteredBookings = computed(() => {
  let r = bookings.value
  if (selectedService.value) r = r.filter(b => b.service_id === selectedService.value)
  if (selectedProfessional.value) r = r.filter(b => b.services?.professional_id === selectedProfessional.value)
  if (selectedDate.value) r = r.filter(b => b.date === selectedDate.value)
  return r
})

const paginatedBookings = computed(() => {
  const start = (currentPage.value - 1) * pageSize
  return filteredBookings.value.slice(start, start + pageSize)
})

const totalPages = computed(() => Math.ceil(filteredBookings.value.length / pageSize))

const statusLabels: Record<string, string> = {
  pending: 'Pendiente',
  cancelled: 'Cancelada',
  attended: 'Asistió',
  no_show: 'Ausente',
}

const getEstadoBadgeClass = (s: string) => {
  switch (s) { case 'pending': return 'bg-blue-100 text-blue-800'; case 'confirmed': return 'bg-indigo-100 text-indigo-800'; case 'cancelled': return 'bg-red-100 text-red-800'; case 'attended': return 'bg-green-100 text-green-800'; case 'no_show': return 'bg-yellow-100 text-yellow-800'; default: return 'bg-gray-100 text-gray-800' }
}

function handleExportCSV() {
  const data = filteredBookings.value.map(b => ({
    Cliente: b.users?.name || b.guest_name || '',
    Servicio: b.services?.name || '',
    Fecha: b.date,
    Modalidad: b.modality === 'in_person' ? 'Presencial' : 'Virtual',
    Estado: b.status,
  }))
  exportToCSV(data, `reservas-${new Date().toISOString().split('T')[0]}`)
}
</script>

<template>
  <div>
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold" style="color: var(--color-text)">Reservas</h1>
      <div class="flex space-x-2">
        <button @click="showCancelSessionModal = true" class="text-sm px-3 py-2 rounded-lg cursor-pointer hover:opacity-90" style="background-color: #dc2626; color: white">
          ⛔ Cancelar sesión
        </button>
        <button @click="handleExportCSV" class="text-sm px-3 py-2 rounded-lg border" :style="{ borderColor: 'var(--color-border)', color: 'var(--color-text)' }">
          📄 CSV
        </button>
      </div>
    </div>
    <div class="rounded-lg shadow p-4 mb-6" style="background-color: var(--color-surface)">
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div>
          <label class="block text-sm font-medium mb-1" style="color: var(--color-text-muted)">Servicio</label>
          <select v-model="selectedService" class="w-full px-3 py-2 border rounded-lg" :style="{ borderColor: 'var(--color-border)' }">
            <option value="">Todos</option>
            <option v-for="s in services" :key="s.id" :value="s.id">{{ s.name }}</option>
          </select>
        </div>
        <div>
          <label class="block text-sm font-medium mb-1" style="color: var(--color-text-muted)">Profesional</label>
          <select v-model="selectedProfessional" class="w-full px-3 py-2 border rounded-lg" :style="{ borderColor: 'var(--color-border)' }">
            <option value="">Todos</option>
            <option v-for="p in professionals" :key="p.id" :value="p.id">{{ p.name }}</option>
          </select>
        </div>
        <div>
          <label class="block text-sm font-medium mb-1" style="color: var(--color-text-muted)">Fecha</label>
          <input v-model="selectedDate" type="date" class="w-full px-3 py-2 border rounded-lg" :style="{ borderColor: 'var(--color-border)' }" />
        </div>
      </div>
    </div>
    <div v-if="error" class="rounded-lg p-4 mb-6" style="background-color: #fef2f2; color: #991b1b">{{ error }}</div>
    <SkeletonTable v-if="loading" :rows="5" :cols="6" />
    <div v-else-if="filteredBookings.length === 0" class="text-center py-8" style="color: var(--color-text-muted)">No hay reservas.</div>

    <!-- Desktop: tabla -->
    <div v-else class="hidden md:block rounded-lg shadow overflow-hidden" style="background-color: var(--color-surface)">
      <table class="min-w-full divide-y" :style="{ borderColor: 'var(--color-border)' }">
        <thead :style="{ backgroundColor: 'var(--color-primary-subtle)' }">
          <tr>
            <th class="px-6 py-3 text-left text-xs font-medium uppercase" style="color: var(--color-text-muted)">Cliente</th>
            <th class="px-6 py-3 text-left text-xs font-medium uppercase" style="color: var(--color-text-muted)">Servicio</th>
            <th class="px-6 py-3 text-left text-xs font-medium uppercase" style="color: var(--color-text-muted)">Fecha</th>
            <th class="px-6 py-3 text-left text-xs font-medium uppercase" style="color: var(--color-text-muted)">Modalidad</th>
            <th class="px-6 py-3 text-left text-xs font-medium uppercase" style="color: var(--color-text-muted)">Estado</th>
            <th class="px-6 py-3 text-left text-xs font-medium uppercase" style="color: var(--color-text-muted)">Acciones</th>
          </tr>
        </thead>
        <tbody class="divide-y" :style="{ borderColor: 'var(--color-border)' }">
          <tr v-for="b in paginatedBookings" :key="b.id" :style="{ backgroundColor: 'var(--color-surface)' }">
            <td class="px-6 py-4 whitespace-nowrap text-sm" style="color: var(--color-text)">
              <div>{{ b.users?.name || b.guest_name || 'Sin nombre' }}</div>
              <div v-if="b.guest_phone" class="text-xs" style="color: var(--color-text-muted)">📱 {{ b.guest_phone }}</div>
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm" style="color: var(--color-text)">{{ b.services?.name }}</td>
            <td class="px-6 py-4 whitespace-nowrap text-sm" style="color: var(--color-text-muted)">{{ b.date }}</td>
            <td class="px-6 py-4 whitespace-nowrap text-sm" style="color: var(--color-text)">{{ b.modality === 'in_person' ? '🏠 Presencial' : '💻 Virtual' }}</td>
            <td class="px-6 py-4 whitespace-nowrap"><span :class="[getEstadoBadgeClass(b.status), 'px-2 inline-flex text-xs leading-5 font-semibold rounded-full']">{{ statusLabels[b.status] || b.status }}</span></td>
            <td class="px-6 py-4 whitespace-nowrap text-sm space-x-2">
              <button v-if="b.status === 'pending'" @click="markAttendance(b.id, 'attended')" :disabled="processingId === b.id" class="text-green-600 hover:text-green-800 disabled:opacity-50">✓ Asistió</button>
              <button v-if="b.status === 'pending'" @click="markAttendance(b.id, 'no_show')" :disabled="processingId === b.id" class="text-yellow-600 hover:text-yellow-800 disabled:opacity-50">✗ Ausente</button>
              <button v-if="b.status === 'pending'" @click="cancelBooking(b.id)" :disabled="processingId === b.id" class="text-red-600 hover:text-red-800 disabled:opacity-50">Cancelar</button>
              <a v-if="b.guest_name" :href="`https://wa.me/${b.guest_phone?.replace(/[^0-9]/g, '')}?text=${encodeURIComponent('Reserva: ' + b.services?.name + ' ' + b.date)}`" target="_blank" class="text-green-600 hover:text-green-800">📱 WhatsApp</a>
            </td>
          </tr>
        </tbody>
      </table>
      <PaginationBar
        :current-page="currentPage"
        :total-pages="totalPages"
        :total-items="filteredBookings.length"
        :page-size="pageSize"
        @update:currentPage="currentPage = $event"
      />
    </div>

    <!-- Mobile: cards -->
    <div v-if="filteredBookings.length > 0" class="md:hidden space-y-3">
      <div v-for="b in paginatedBookings" :key="b.id" class="rounded-lg shadow p-4" style="background-color: var(--color-surface)">
        <div class="flex justify-between items-start mb-2">
          <div class="font-semibold" style="color: var(--color-text)">{{ b.users?.name || b.guest_name || 'Sin nombre' }}</div>
          <span :class="[getEstadoBadgeClass(b.status), 'px-2 py-0.5 text-xs font-semibold rounded-full']">{{ statusLabels[b.status] || b.status }}</span>
        </div>
        <div class="text-sm mb-1" style="color: var(--color-text)">{{ b.services?.name }} · {{ b.modality === 'in_person' ? '🏠' : '💻' }}</div>
        <div class="text-xs mb-3" style="color: var(--color-text-muted)">{{ b.date }}</div>
        <div v-if="b.status === 'pending'" class="flex flex-wrap gap-2">
          <button @click="markAttendance(b.id, 'attended')" :disabled="processingId === b.id" class="text-xs px-2 py-1 rounded text-green-600 border border-green-300 disabled:opacity-50">✓ Asistió</button>
          <button @click="markAttendance(b.id, 'no_show')" :disabled="processingId === b.id" class="text-xs px-2 py-1 rounded text-yellow-600 border border-yellow-300 disabled:opacity-50">✗ Ausente</button>
          <button @click="cancelBooking(b.id)" :disabled="processingId === b.id" class="text-xs px-2 py-1 rounded text-red-600 border border-red-300 disabled:opacity-50">Cancelar</button>
          <a v-if="b.guest_name" :href="`https://wa.me/${b.guest_phone?.replace(/[^0-9]/g, '')}?text=${encodeURIComponent('Reserva: ' + b.services?.name + ' ' + b.date)}`" target="_blank" class="text-xs px-2 py-1 rounded text-green-600 border border-green-300">📱 WhatsApp</a>
        </div>
      </div>
      <PaginationBar
        :current-page="currentPage"
        :total-pages="totalPages"
        :total-items="filteredBookings.length"
        :page-size="pageSize"
        @update:currentPage="currentPage = $event"
      />
    </div>

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
                  <option v-for="s in servicesForDate" :key="s.id" :value="s.id">{{ s.name }}</option>
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
