<script setup lang="ts">
import { useBookingStore } from '@/stores/booking'
import { useAuthStore } from '@/stores/auth'
import { BookingService } from '@/services/BookingService'
import { CompanyService } from '@/services/CompanyService'
import { getProfessionalDisplayName } from '@/types'
import { onMounted, ref } from 'vue'
import TimeWindowModal from '@/components/TimeWindowModal.vue'
import ConfirmModal from '@/components/ConfirmModal.vue'
import SkeletonCard from '@/components/SkeletonCard.vue'
import type { BookingWindow } from '@/types'

const bookingStore = useBookingStore()
const authStore = useAuthStore()
const companySettings = ref<any>(null)

const cancelingId = ref<string | null>(null)
const showModal = ref(false)
const modalTipo = ref<'reservar' | 'cancelar'>('cancelar')
const modalMinutos = ref(0)
const modalVentana = ref(0)

// Confirm modal
const showConfirm = ref(false)
const confirmBookingId = ref('')

const dayNames = ['domingo', 'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado']

function formatDateAR(dateStr: string): string {
  const date = new Date(dateStr + 'T12:00:00')
  const day = dayNames[date.getDay()]
  const dayOfMonth = date.getDate()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const year = date.getFullYear()
  return `${day} ${dayOfMonth}/${month}/${year}`
}

onMounted(async () => {
  await bookingStore.fetchUserBookings()
  if (authStore.companyId) {
    companySettings.value = await CompanyService.getSettings(authStore.companyId)
  }
})

function handleCancel(bookingId: string) {
  confirmBookingId.value = bookingId
  showConfirm.value = true
}

async function confirmCancel() {
  showConfirm.value = false
  const bookingId = confirmBookingId.value
  if (!bookingId) return

  const booking = bookingStore.bookings.find(b => b.id === bookingId)
  if (!booking) return

  try {
    const window = await BookingService.checkWindow(booking.service_id, booking.date, authStore.companyId)
    if (window && !window.puede_cancelar) {
      modalTipo.value = 'cancelar'
      modalMinutos.value = window.minutos_para_clase
      modalVentana.value = window.ventana_cancelacion
      showModal.value = true
      return
    }
  } catch { /* backend validará */ }

  cancelingId.value = bookingId
  try { await bookingStore.cancelBooking(bookingId) }
  finally { cancelingId.value = null }
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
    <h1 class="text-2xl font-bold mb-6" style="color: var(--color-text)">Mis Reservas</h1>

    <SkeletonCard v-if="bookingStore.loading" :count="3" :lines="3" class="grid-cols-1 md:grid-cols-2 lg:grid-cols-3" />

    <div v-else-if="bookingStore.bookings.length === 0" class="text-center py-8" style="color: var(--color-text-muted)">
      No tenés reservas activas.
    </div>

    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      <div v-for="booking in bookingStore.bookings" :key="booking.id" class="rounded-lg shadow p-4" style="background-color: var(--color-surface)">
        <div class="flex justify-between items-start">
          <div>
            <h3 class="font-semibold" style="color: var(--color-text)">{{ booking.services?.name }}</h3>
            <p class="text-sm" style="color: var(--color-text-muted)">
              {{ booking.services?.day_of_week }} {{ booking.services?.start_time }} - {{ booking.services?.end_time }}
            </p>
            <p class="text-sm" style="color: var(--color-text-muted)">
              {{ booking.services?.professionals ? getProfessionalDisplayName(booking.services.professionals, companySettings?.show_alias || false) : '' }}
            </p>
            <p class="text-sm" style="color: var(--color-text-muted)">📅 {{ formatDateAR(booking.date) }}</p>
            <div class="mt-2 flex items-center space-x-2">
              <span class="text-sm">
                {{ booking.modality === 'in_person' ? '🏠' : '💻' }}
                {{ booking.modality === 'in_person' ? 'Presencial' : 'Virtual' }}
              </span>
              <span :class="[getEstadoBadgeClass(booking.status), 'px-2 py-1 rounded-full text-xs font-medium']">
                {{ booking.status }}
              </span>
            </div>
          </div>
          <button v-if="booking.status === 'pending'" @click="handleCancel(booking.id)"
            :disabled="cancelingId === booking.id"
            class="text-red-600 hover:text-red-800 text-sm font-medium disabled:opacity-50 cursor-pointer">
            {{ cancelingId === booking.id ? 'Cancelando...' : 'Cancelar' }}
          </button>
        </div>
        <div v-if="bookingStore.error" class="mt-2 text-sm" style="color: #dc2626">{{ bookingStore.error }}</div>
      </div>
    </div>

    <TimeWindowModal :show="showModal" :tipo="modalTipo" :minutos-para-clase="modalMinutos"
      :ventana="modalVentana" @close="showModal = false" />

    <ConfirmModal
      :show="showConfirm"
      title="Cancelar reserva"
      message="¿Estás seguro? Se devolverá tu crédito."
      icon="⚠️"
      confirm-text="Sí, cancelar"
      confirm-color="#dc2626"
      @confirm="confirmCancel"
      @cancel="showConfirm = false"
    />
  </div>
</template>
