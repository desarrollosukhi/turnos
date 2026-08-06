<script setup lang="ts">
import { useAuthStore } from '@/stores/auth'
import { useCreditStore } from '@/stores/credit'
import SkeletonStats from '@/components/SkeletonStats.vue'
import SkeletonCard from '@/components/SkeletonCard.vue'
import { ref, computed, onMounted } from 'vue'

const authStore = useAuthStore()
const creditStore = useCreditStore()

const visibleCount = ref(10)

const visibleMovements = computed(() => {
  return creditStore.movements.slice(0, visibleCount.value)
})

const hasMore = computed(() => {
  return creditStore.movements.length > visibleCount.value
})

const remainingCount = computed(() => {
  return creditStore.movements.length - visibleCount.value
})

function loadMore() {
  visibleCount.value += 10
}

const earliestExpiry = computed(() => {
  const now = new Date()
  let earliest: Date | null = null
  for (const m of creditStore.movements) {
    if (m.amount > 0 && m.expires_at) {
      const exp = new Date(m.expires_at)
      if (exp > now && (!earliest || exp < earliest)) {
        earliest = exp
      }
    }
  }
  return earliest
})

const expiryDateFormatted = computed(() => {
  if (!earliestExpiry.value) return ''
  const d = earliestExpiry.value
  const day = d.getDate()
  const month = String(d.getMonth() + 1).padStart(2, '0')
  const year = d.getFullYear()
  return `${day}/${month}/${year}`
})

onMounted(async () => {
  await creditStore.fetchBalance()
  await creditStore.fetchMovements()
})

function formatExpiry(dateStr: string | null): string {
  if (!dateStr) return ''
  return new Date(dateStr).toLocaleDateString('es-AR')
}

function getExpiryClass(expiresAt: string | null): string {
  if (!expiresAt) return ''
  const now = new Date()
  const expiry = new Date(expiresAt)
  const daysLeft = Math.ceil((expiry.getTime() - now.getTime()) / (1000 * 60 * 60 * 24))

  if (daysLeft < 0) return 'text-red-500 line-through'
  if (daysLeft <= 7) return 'text-yellow-600'
  return ''
}

function getExpiryDaysLeft(expiresAt: string): number {
  const now = new Date()
  const expiry = new Date(expiresAt)
  return Math.ceil((expiry.getTime() - now.getTime()) / (1000 * 60 * 60 * 24))
}
</script>

<template>
  <div>
    <h1 class="text-2xl font-bold mb-6" style="color: var(--color-text)">Mis Créditos</h1>

    <SkeletonStats v-if="creditStore.loading" :count="1" class="mb-6" />
    <SkeletonCard v-if="creditStore.loading" :count="3" :lines="2" />

    <template v-else>
      <div class="rounded-lg shadow p-6 mb-6" style="background-color: var(--color-surface)">
      <h2 class="text-lg font-semibold mb-2" style="color: var(--color-text)">Saldo Actual</h2>
      <div class="text-4xl font-bold" :class="creditStore.balance > 0 ? 'text-green-600' : 'text-red-600'">
        {{ creditStore.balance }}
      </div>
      <p class="mt-1" style="color: var(--color-text-muted)">Créditos disponibles</p>
      <div v-if="earliestExpiry" class="mt-3 p-3 rounded-lg" style="background-color: #fef3c7; border: 1px solid #fde68a">
        <div class="flex items-center space-x-2">
          <span class="text-lg">⏰</span>
          <div>
            <p class="text-sm font-medium" style="color: #92400e">Créditos vencen el {{ expiryDateFormatted }}</p>
            <p class="text-xs" style="color: #a16207">Usalos antes de esa fecha para no perderlos</p>
          </div>
        </div>
      </div>
    </div>

    <div class="rounded-lg shadow" style="background-color: var(--color-surface)">
      <div class="p-4" style="border-bottom: 1px solid var(--color-border)">
        <h2 class="text-lg font-semibold" style="color: var(--color-text)">Historial de Movimientos</h2>
      </div>
      <div v-if="creditStore.movements.length === 0" class="p-8 text-center" style="color: var(--color-text-muted)">
        No hay movimientos registrados.
      </div>
      <div v-else class="divide-y" :style="{ borderColor: 'var(--color-border)' }">
        <div v-for="m in visibleMovements" :key="m.id" class="p-4 flex justify-between items-start">
          <div class="flex-1">
            <div class="flex items-center space-x-2 mb-1">
              <p class="font-medium" :class="getExpiryClass(m.expires_at)" style="color: var(--color-text)">{{ m.description }}</p>
              <span v-if="m.expires_at && m.amount > 0" class="px-2 py-0.5 rounded-full text-xs font-medium"
                :style="{
                  backgroundColor: getExpiryDaysLeft(m.expires_at) <= 0 ? '#fef2f2' : getExpiryDaysLeft(m.expires_at) <= 7 ? '#fef3c7' : '#ecfdf5',
                  color: getExpiryDaysLeft(m.expires_at) <= 0 ? '#991b1b' : getExpiryDaysLeft(m.expires_at) <= 7 ? '#92400e' : '#065f46'
                }">
                {{ getExpiryDaysLeft(m.expires_at) <= 0 ? 'Vencido' : `Vence en ${getExpiryDaysLeft(m.expires_at)}d` }}
              </span>
            </div>
            <p class="text-sm" style="color: var(--color-text-muted)">{{ new Date(m.created_at).toLocaleDateString('es-AR') }}</p>
            <p v-if="m.expires_at" class="text-xs mt-1" :class="getExpiryClass(m.expires_at)">
              Vence: {{ formatExpiry(m.expires_at) }}
            </p>
          </div>
          <span :class="[m.amount > 0 ? 'text-green-600' : 'text-red-600', 'font-semibold']">
            {{ m.amount > 0 ? '+' : '' }}{{ m.amount }}
          </span>
        </div>
      </div>
      <!-- Ver más -->
      <div v-if="hasMore" class="p-4 text-center border-t" :style="{ borderColor: 'var(--color-border)' }">
        <button @click="loadMore" class="px-4 py-2 rounded-lg text-sm cursor-pointer hover:opacity-80" :style="{ color: 'var(--color-primary)' }">
          Ver más ({{ remainingCount }} restantes)
        </button>
      </div>
    </div>
    </template>
  </div>
</template>
