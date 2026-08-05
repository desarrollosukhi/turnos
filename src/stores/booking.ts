import { defineStore } from 'pinia'
import { ref } from 'vue'
import { BookingService } from '@/services/BookingService'
import type { BookingWithDetails, ModalidadType } from '@/types'
import { useAuthStore } from './auth'

export const useBookingStore = defineStore('booking', () => {
  const bookings = ref<BookingWithDetails[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchUserBookings() {
    const authStore = useAuthStore()
    if (!authStore.user) return

    loading.value = true
    error.value = null
    try {
      bookings.value = await BookingService.getByUser(authStore.user.id)
    } catch (e: any) {
      error.value = e.message || 'Error al cargar reservas'
    } finally {
      loading.value = false
    }
  }

  async function createBooking(serviceId: string, date: string, modality: ModalidadType) {
    const authStore = useAuthStore()
    if (!authStore.user) throw new Error('No autenticado')

    loading.value = true
    error.value = null
    try {
      const result = await BookingService.create(serviceId, date, modality)
      await fetchUserBookings()
      await authStore.fetchUser()
      return result
    } catch (e: any) {
      error.value = e.message || 'Error al crear reserva'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function cancelBooking(bookingId: string) {
    const authStore = useAuthStore()
    if (!authStore.user) throw new Error('No autenticado')

    loading.value = true
    error.value = null
    try {
      const result = await BookingService.cancel(bookingId)
      await fetchUserBookings()
      await authStore.fetchUser()
      return result
    } catch (e: any) {
      error.value = e.message || 'Error al cancelar reserva'
      throw e
    } finally {
      loading.value = false
    }
  }

  return {
    bookings,
    loading,
    error,
    fetchUserBookings,
    createBooking,
    cancelBooking,
  }
})
