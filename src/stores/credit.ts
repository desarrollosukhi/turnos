import { defineStore } from 'pinia'
import { ref } from 'vue'
import { CreditService } from '@/services/CreditService'
import type { CreditMovement } from '@/types'
import { useAuthStore } from './auth'

export const useCreditStore = defineStore('credit', () => {
  const balance = ref(0)
  const expiringCredits = ref(0)
  const movements = ref<CreditMovement[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchBalance() {
    const authStore = useAuthStore()
    if (!authStore.user) return

    loading.value = true
    try {
      balance.value = await CreditService.getBalance(authStore.user.id)
      expiringCredits.value = await CreditService.getExpiringCredits(authStore.user.id)
    } catch (e: any) {
      error.value = e.message || 'Error al obtener créditos'
    } finally {
      loading.value = false
    }
  }

  async function fetchMovements() {
    const authStore = useAuthStore()
    if (!authStore.user) return

    loading.value = true
    try {
      movements.value = await CreditService.getMovements(authStore.user.id)
    } catch (e: any) {
      error.value = e.message || 'Error al obtener movimientos'
    } finally {
      loading.value = false
    }
  }

  return {
    balance,
    expiringCredits,
    movements,
    loading,
    error,
    fetchBalance,
    fetchMovements,
  }
})
