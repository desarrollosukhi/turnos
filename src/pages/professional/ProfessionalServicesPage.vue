<script setup lang="ts">
import { useAuthStore } from '@/stores/auth'
import { ProfessionalService } from '@/services/ProfessionalService'
import { ServiceService } from '@/services/ServiceService'
import SkeletonCard from '@/components/SkeletonCard.vue'
import { onMounted, ref } from 'vue'
import type { ServiceWithProfessional } from '@/types'

const authStore = useAuthStore()
const services = ref<ServiceWithProfessional[]>([])
const loading = ref(true)

const dayLabels: Record<string, string> = {
  lunes: 'Lunes', martes: 'Martes', miercoles: 'Miércoles',
  jueves: 'Jueves', viernes: 'Viernes', sabado: 'Sábado', domingo: 'Domingo',
}

onMounted(async () => {
  if (!authStore.user) return
  try {
    const professional = await ProfessionalService.getByUserId(authStore.user.id)
    if (professional) {
      services.value = await ServiceService.getByProfessionalId(professional.id)
    }
  } catch (e) { console.error(e) }
  finally { loading.value = false }
})
</script>

<template>
  <div>
    <h1 class="text-2xl font-bold mb-6" style="color: var(--color-text)">Mis Servicios</h1>
    <SkeletonCard v-if="loading" :count="3" :lines="2" class="grid-cols-1 md:grid-cols-2 lg:grid-cols-3" />
    <div v-else-if="services.length === 0" class="text-center py-8" style="color: var(--color-text-muted)">No tenés servicios asignados.</div>
    <div v-else class="grid gap-4">
      <div v-for="svc in services" :key="svc.id" class="rounded-lg shadow p-4 sm:p-6" style="background-color: var(--color-surface)">
        <h3 class="text-lg font-semibold" style="color: var(--color-text)">{{ svc.name }}</h3>
        <p style="color: var(--color-text-muted)">{{ dayLabels[svc.day_of_week!] || svc.day_of_week }} {{ svc.start_time }} - {{ svc.end_time }}</p>
        <div class="mt-2 flex items-center space-x-2">
          <span v-if="svc.allows_in_person" class="text-sm">🏠 Presencial ({{ svc.in_person_capacity }} cupos)</span>
          <span v-if="svc.allows_virtual" class="text-sm">💻 Virtual ({{ svc.virtual_capacity }} cupos)</span>
        </div>
      </div>
    </div>
  </div>
</template>
