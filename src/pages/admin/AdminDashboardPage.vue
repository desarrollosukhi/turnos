<script setup lang="ts">
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/supabase/client'
import { getBusinessLabels } from '@/types'
import SkeletonStats from '@/components/SkeletonStats.vue'
import { ref, computed, onMounted } from 'vue'

const authStore = useAuthStore()
const labels = computed(() => getBusinessLabels(authStore.businessType))

const kpis = ref({ reservas_hoy: 0, reservas_semana: 0, clientes_activos: 0, creditos_total: 0, tasa_asistencia: 0 })
const loading = ref(true)

onMounted(async () => {
  if (!authStore.companyId) return
  try {
    const { data, error } = await supabase.rpc('get_admin_dashboard_kpis', { p_company_id: authStore.companyId })
    console.log('[Dashboard] KPIs data:', data, 'error:', error)
    if (Array.isArray(data) && data.length > 0) {
      kpis.value = data[0]
    } else if (data && typeof data === 'object') {
      kpis.value = data
    }
  } catch (e) { console.error('[Dashboard] Error:', e) }
  finally { loading.value = false }
})
</script>

<template>
  <div>
    <h1 class="text-2xl font-bold mb-6" style="color: var(--color-text)">Panel de Administración</h1>

    <!-- KPIs -->
    <SkeletonStats v-if="loading" :count="5" class="grid-cols-2 md:grid-cols-3 lg:grid-cols-5 mb-8" />
    <div v-else class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4 mb-8">
      <div class="rounded-lg shadow p-4" style="background-color: var(--color-surface)">
        <div class="text-2xl mb-1">📅</div>
        <div class="text-2xl font-bold" style="color: var(--color-primary)">{{ loading ? '—' : kpis.reservas_hoy }}</div>
        <div class="text-xs" style="color: var(--color-text-muted)">Reservas hoy</div>
      </div>
      <div class="rounded-lg shadow p-4" style="background-color: var(--color-surface)">
        <div class="text-2xl mb-1">📆</div>
        <div class="text-2xl font-bold" style="color: var(--color-primary)">{{ loading ? '—' : kpis.reservas_semana }}</div>
        <div class="text-xs" style="color: var(--color-text-muted)">Reservas semana</div>
      </div>
      <div class="rounded-lg shadow p-4" style="background-color: var(--color-surface)">
        <div class="text-2xl mb-1">👥</div>
        <div class="text-2xl font-bold" style="color: var(--color-primary)">{{ loading ? '—' : kpis.clientes_activos }}</div>
        <div class="text-xs" style="color: var(--color-text-muted)">{{ labels.customers }} activos</div>
      </div>
      <div class="rounded-lg shadow p-4" style="background-color: var(--color-surface)">
        <div class="text-2xl mb-1">💰</div>
        <div class="text-2xl font-bold" style="color: var(--color-primary)">{{ loading ? '—' : kpis.creditos_total }}</div>
        <div class="text-xs" style="color: var(--color-text-muted)">Créditos totales</div>
      </div>
      <div class="rounded-lg shadow p-4" style="background-color: var(--color-surface)">
        <div class="text-2xl mb-1">✅</div>
        <div class="text-2xl font-bold" style="color: var(--color-primary)">{{ loading ? '—' : kpis.tasa_asistencia + '%' }}</div>
        <div class="text-xs" style="color: var(--color-text-muted)">Asistencia (30d)</div>
      </div>
    </div>

    <!-- Navegación -->
    <h2 class="text-lg font-semibold mb-4" style="color: var(--color-text)">Accesos rápidos</h2>
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      <router-link to="/admin/customers" class="rounded-lg shadow p-6 hover:shadow-md transition-shadow" style="background-color: var(--color-surface)">
        <div class="text-3xl mb-2">👥</div>
        <h3 class="font-semibold" style="color: var(--color-text)">{{ labels.customers }}</h3>
      </router-link>
      <router-link to="/admin/professionals" class="rounded-lg shadow p-6 hover:shadow-md transition-shadow" style="background-color: var(--color-surface)">
        <div class="text-3xl mb-2">🎓</div>
        <h3 class="font-semibold" style="color: var(--color-text)">{{ labels.professionals }}</h3>
      </router-link>
      <router-link to="/admin/services" class="rounded-lg shadow p-6 hover:shadow-md transition-shadow" style="background-color: var(--color-surface)">
        <div class="text-3xl mb-2">🧘</div>
        <h3 class="font-semibold" style="color: var(--color-text)">{{ labels.services }}</h3>
      </router-link>
      <router-link to="/admin/bookings" class="rounded-lg shadow p-6 hover:shadow-md transition-shadow" style="background-color: var(--color-surface)">
        <div class="text-3xl mb-2">📋</div>
        <h3 class="font-semibold" style="color: var(--color-text)">Reservas</h3>
      </router-link>
      <router-link to="/admin/credits" class="rounded-lg shadow p-6 hover:shadow-md transition-shadow" style="background-color: var(--color-surface)">
        <div class="text-3xl mb-2">💰</div>
        <h3 class="font-semibold" style="color: var(--color-text)">Créditos</h3>
      </router-link>
      <router-link to="/admin/reports" class="rounded-lg shadow p-6 hover:shadow-md transition-shadow" style="background-color: var(--color-surface)">
        <div class="text-3xl mb-2">📊</div>
        <h3 class="font-semibold" style="color: var(--color-text)">Reportes</h3>
      </router-link>
      <router-link to="/admin/settings" class="rounded-lg shadow p-6 hover:shadow-md transition-shadow" style="background-color: var(--color-surface)">
        <div class="text-3xl mb-2">⚙️</div>
        <h3 class="font-semibold" style="color: var(--color-text)">Configuración</h3>
      </router-link>
    </div>
  </div>
</template>
