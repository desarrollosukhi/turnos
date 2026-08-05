<script setup lang="ts">
import { useAuthStore } from '@/stores/auth'
import { CreditService } from '@/services/CreditService'
import { BookingService } from '@/services/BookingService'
import { AnnouncementService } from '@/services/AnnouncementService'
import { getBusinessLabels, getProfessionalDisplayName } from '@/types'
import SkeletonCard from '@/components/SkeletonCard.vue'
import { onMounted, ref, computed } from 'vue'
import type { AnnouncementWithDetails } from '@/types'

const authStore = useAuthStore()
const balance = ref(0)
const labels = computed(() => getBusinessLabels(authStore.businessType))

interface UpcomingBooking {
  id: string
  date: string
  modality: string | null
  services: {
    name: string
    start_time: string
    end_time: string
    professionals: { name: string; alias: string | null } | null
  } | null
}

const upcomingBookings = ref<UpcomingBooking[]>([])
const announcements = ref<AnnouncementWithDetails[]>([])
const loading = ref(true)
const error = ref('')

// Anuncios descartados (localStorage)
function getDismissedIds(): string[] {
  try { return JSON.parse(localStorage.getItem('dismissed_announcements') || '[]') } catch { return [] }
}

function dismissAnnouncement(id: string) {
  const dismissed = getDismissedIds()
  dismissed.push(id)
  localStorage.setItem('dismissed_announcements', JSON.stringify(dismissed))
  announcements.value = announcements.value.filter(a => a.id !== id)
}

onMounted(async () => {
  if (!authStore.user) return
  try {
    const [bal, bookings, anns] = await Promise.all([
      CreditService.getBalance(authStore.user.id),
      BookingService.getByUser(authStore.user.id),
      AnnouncementService.getActive(authStore.companyId || '', authStore.user.id),
    ])
    balance.value = bal
    // Filtrar anuncios descartados
    const dismissed = getDismissedIds()
    console.log('[Home] User:', authStore.user?.id, 'Company:', authStore.companyId)
    console.log('[Home] Announcements raw:', anns)
    console.log('[Home] Dismissed IDs:', dismissed)
    announcements.value = anns.filter(a => !dismissed.includes(a.id))
    console.log('[Home] Announcements after filter:', announcements.value)
    const today = new Date().toISOString().split('T')[0] ?? ''
    upcomingBookings.value = bookings
      .filter(b => b.status === 'pending' && b.date >= today)
      .sort((a, b) => a.date.localeCompare(b.date))
      .slice(0, 3)
  } catch (e: any) { error.value = e.message || 'Error al cargar datos' }
  finally { loading.value = false }
})
</script>

<template>
  <div>
    <h1 class="text-2xl font-bold mb-6" style="color: var(--color-text)">Bienvenido, {{ authStore.user?.name }}</h1>

    <div v-if="error" class="rounded-lg p-4 mb-6" style="background-color: #fef2f2; color: #991b1b">{{ error }}</div>

    <!-- Avisos -->
    <div v-if="announcements.length > 0" class="rounded-lg shadow p-6 mb-6" style="background-color: var(--color-primary-subtle); border: 1px solid var(--color-primary)">
      <div class="flex items-center space-x-2 mb-4">
        <span class="text-xl">📢</span>
        <h2 class="text-lg font-semibold" style="color: var(--color-primary)">Avisos</h2>
      </div>
      <div class="space-y-3">
        <div v-for="a in announcements" :key="a.id" class="rounded-lg p-4" style="background-color: var(--color-surface)">
          <div class="flex justify-between items-start">
            <div>
              <h3 class="font-semibold" style="color: var(--color-text)">{{ a.title }}</h3>
              <p class="text-sm mt-1" style="color: var(--color-text-muted)">{{ a.content }}</p>
              <div class="flex items-center space-x-3 mt-2 text-xs" style="color: var(--color-text-muted)">
                <span>{{ a.professional_name }}</span>
                <span v-if="a.service_name">· {{ a.service_name }}</span>
              </div>
            </div>
            <button @click="dismissAnnouncement(a.id)" class="ml-2 text-sm cursor-pointer hover:opacity-80" style="color: var(--color-text-muted)">✕</button>
          </div>
        </div>
      </div>
    </div>

    <!-- Créditos -->
    <div class="rounded-lg shadow p-6 mb-6" style="background-color: var(--color-surface)">
      <h2 class="text-lg font-semibold mb-2" style="color: var(--color-text)">Mis Créditos</h2>
      <div class="text-4xl font-bold" style="color: var(--color-primary)">{{ loading ? '—' : balance }}</div>
      <p class="mt-2" style="color: var(--color-text-muted)">Créditos disponibles</p>
    </div>

    <!-- Próximas reservas -->
    <div class="rounded-lg shadow p-6 mb-6" style="background-color: var(--color-surface)">
      <div class="flex justify-between items-center mb-4">
        <h2 class="text-lg font-semibold" style="color: var(--color-text)">Próximas reservas</h2>
        <router-link to="/my-bookings" class="text-sm" style="color: var(--color-primary)">Ver todas →</router-link>
      </div>
      <SkeletonCard v-if="loading" :count="2" :lines="2" />
      <div v-else-if="upcomingBookings.length === 0" class="text-center py-4" style="color: var(--color-text-muted)">
        No tenés reservas próximas
      </div>
      <div v-else class="space-y-3">
        <div v-for="b in upcomingBookings" :key="b.id" class="flex justify-between items-center p-3 rounded-lg" style="background-color: var(--color-primary-subtle)">
          <div>
            <p class="font-medium" style="color: var(--color-text)">{{ b.services?.name }}</p>
            <p class="text-sm" style="color: var(--color-text-muted)">
              {{ b.date }} · {{ b.services?.start_time }} - {{ b.services?.end_time }}
              <span v-if="b.services?.professionals" class="ml-1">
                · {{ getProfessionalDisplayName(b.services.professionals as any, false) }}
              </span>
            </p>
          </div>
          <span class="text-sm px-2 py-1 rounded-full" style="background-color: var(--color-primary); color: white">
            {{ b.modality === 'in_person' ? '🏠' : '💻' }}
          </span>
        </div>
      </div>
    </div>

    <!-- Links -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <router-link
        to="/services"
        class="rounded-lg shadow p-6 hover:shadow-md transition-shadow"
        style="background-color: var(--color-surface)"
      >
        <h3 class="text-lg font-semibold" style="color: var(--color-text)">Ver {{ labels.services }}</h3>
        <p style="color: var(--color-text-muted)">Reservá tu próximo turno</p>
      </router-link>

      <router-link
        to="/my-credits"
        class="rounded-lg shadow p-6 hover:shadow-md transition-shadow"
        style="background-color: var(--color-surface)"
      >
        <h3 class="text-lg font-semibold" style="color: var(--color-text)">Mis Créditos</h3>
        <p style="color: var(--color-text-muted)">Historial de movimientos</p>
      </router-link>

      <router-link
        to="/my-account"
        class="rounded-lg shadow p-6 hover:shadow-md transition-shadow"
        style="background-color: var(--color-surface)"
      >
        <h3 class="text-lg font-semibold" style="color: var(--color-text)">Mi Cuenta</h3>
        <p style="color: var(--color-text-muted)">Editá tu perfil</p>
      </router-link>
    </div>
  </div>
</template>
