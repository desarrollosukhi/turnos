<script setup lang="ts">
import { useBookingStore } from '@/stores/booking'
import { useAuthStore } from '@/stores/auth'
import { BookingService } from '@/services/BookingService'
import { CompanyService } from '@/services/CompanyService'
import { getProfessionalDisplayName } from '@/types'
import { onMounted, ref, computed } from 'vue'
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
const activeTab = ref<'pending' | 'past' | 'cancelled'>('pending')

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

// Conteo por tab
const pendingCount = computed(() => bookingStore.bookings.filter(b => b.status === 'pending').length)
const pastCount = computed(() => bookingStore.bookings.filter(b => b.status === 'attended' || b.status === 'no_show').length)
const cancelledCount = computed(() => bookingStore.bookings.filter(b => b.status === 'cancelled').length)

// Filtrado por tab
const filteredBookings = computed(() => {
  switch (activeTab.value) {
    case 'pending': return bookingStore.bookings.filter(b => b.status === 'pending')
    case 'past': return bookingStore.bookings.filter(b => b.status === 'attended' || b.status === 'no_show')
    case 'cancelled': return bookingStore.bookings.filter(b => b.status === 'cancelled')
    default: return bookingStore.bookings
  }
})

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

const statusLabels: Record<string, string> = {
  pending: 'Pendiente',
  cancelled: 'Cancelada',
  attended: 'Asistió',
  no_show: 'Ausente',
}
</script>

<template>
  <div>
    <h1 class="text-2xl font-bold mb-6" style="color: var(--color-text)">Mis Reservas</h1>

    <!-- Tabs -->
    <div v-if="!bookingStore.loading && bookingStore.bookings.length > 0" class="flex space-x-1 mb-6 border-b" :style="{ borderColor: 'var(--color-border)' }">
      <button @click="activeTab = 'pending'"
        class="px-4 py-2 text-sm font-medium rounded-t-lg transition-colors cursor-pointer"
        :style="{ backgroundColor: activeTab === 'pending' ? 'var(--color-primary-subtle)' : 'transparent', color: activeTab === 'pending' ? 'var(--color-primary)' : 'var(--color-text-muted)', borderBottom: activeTab === 'pending' ? '2px solid var(--color-primary)' : '2px solid transparent' }">
        Pendientes ({{ pendingCount }})
      </button>
      <button @click="activeTab = 'past'"
        class="px-4 py-2 text-sm font-medium rounded-t-lg transition-colors cursor-pointer"
        :style="{ backgroundColor: activeTab === 'past' ? 'var(--color-primary-subtle)' : 'transparent', color: activeTab === 'past' ? 'var(--color-primary)' : 'var(--color-text-muted)', borderBottom: activeTab === 'past' ? '2px solid var(--color-primary)' : '2px solid transparent' }">
        Realizadas ({{ pastCount }})
      </button>
      <button @click="activeTab = 'cancelled'"
        class="px-4 py-2 text-sm font-medium rounded-t-lg transition-colors cursor-pointer"
        :style="{ backgroundColor: activeTab === 'cancelled' ? 'var(--color-primary-subtle)' : 'transparent', color: activeTab === 'cancelled' ? 'var(--color-primary)' : 'var(--color-text-muted)', borderBottom: activeTab === 'cancelled' ? '2px solid var(--color-primary)' : '2px solid transparent' }">
        Canceladas ({{ cancelledCount }})
      </button>
    </div>

    <SkeletonCard v-if="bookingStore.loading" :count="3" :lines="3" class="grid-cols-1 md:grid-cols-2 lg:grid-cols-3" />

    <div v-else-if="filteredBookings.length === 0" class="text-center py-8" style="color: var(--color-text-muted)">
      No hay reservas en esta categoría.
    </div>

    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      <div v-for="booking in filteredBookings" :key="booking.id" class="rounded-lg shadow p-4" style="background-color: var(--color-surface)">
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
                {{ statusLabels[booking.status] || booking.status }}
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
