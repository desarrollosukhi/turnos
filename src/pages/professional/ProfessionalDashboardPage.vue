<script setup lang="ts">
import { useAuthStore } from '@/stores/auth'
import { ProfessionalService } from '@/services/ProfessionalService'
import { ServiceService } from '@/services/ServiceService'
import { BookingService } from '@/services/BookingService'
import { AnnouncementService } from '@/services/AnnouncementService'
import ToastMessage from '@/components/ToastMessage.vue'
import SkeletonStats from '@/components/SkeletonStats.vue'
import SkeletonCard from '@/components/SkeletonCard.vue'
import { onMounted, ref } from 'vue'
import type { ServiceWithProfessional, BookingWithDetails } from '@/types'

const authStore = useAuthStore()
const professionalName = ref('')
const professionalId = ref('')
const todayServices = ref<ServiceWithProfessional[]>([])
const todayBookings = ref<BookingWithDetails[]>([])
const loading = ref(true)

// Anuncio
const showAnnouncementForm = ref(false)
const announcementForm = ref({ title: '', content: '', service_id: '' })
const savingAnnouncement = ref(false)
const showToast = ref(false)
const toastMessage = ref('')
const toastType = ref<'success' | 'error' | 'info'>('success')

const dayNames = ['domingo', 'lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado']

onMounted(async () => { await loadData() })

async function loadData() {
  if (!authStore.user) return
  loading.value = true
  try {
    const professional = await ProfessionalService.getByUserId(authStore.user.id)
    if (!professional) return

    professionalId.value = professional.id
    professionalName.value = professional.name
    const today = new Date()
    const todayStr = today.toISOString().split('T')[0] ?? ''
    const dayName = dayNames[today.getDay()] ?? ''

    const allServices = await ServiceService.getByProfessionalId(professional.id)
    todayServices.value = allServices.filter(s =>
      s.frequency === 'weekly' && s.days_of_week?.includes(dayName as any)
    )

    for (const svc of todayServices.value) {
      const bookings = await BookingService.getByService(svc.id, todayStr)
      todayBookings.value.push(...bookings.filter(b => b.status === 'pending'))
    }
  } catch (e) { console.error(e) }
  finally { loading.value = false }
}

async function handlePublishAnnouncement() {
  if (!announcementForm.value.title.trim() || !announcementForm.value.content.trim()) return
  savingAnnouncement.value = true
  try {
    await AnnouncementService.create({
      company_id: authStore.companyId!,
      professional_id: professionalId.value || null,
      service_id: announcementForm.value.service_id || null,
      title: announcementForm.value.title,
      content: announcementForm.value.content,
      target: announcementForm.value.service_id ? 'service_bookings' : 'all',
      date_from: new Date().toISOString().split('T')[0] ?? '',
      date_to: null,
      active: true,
    })
    announcementForm.value = { title: '', content: '', service_id: '' }
    showAnnouncementForm.value = false
    toastMessage.value = 'Aviso publicado'
    toastType.value = 'success'
    showToast.value = true
  } catch (e: any) {
    toastMessage.value = e.message || 'Error al publicar'
    toastType.value = 'error'
    showToast.value = true
  } finally {
    savingAnnouncement.value = false
  }
}
</script>

<template>
  <div>
    <ToastMessage :show="showToast" :message="toastMessage" :type="toastType" @close="showToast = false" />

    <h1 class="text-2xl font-bold mb-2" style="color: var(--color-text)">Hola, {{ professionalName || authStore.user?.name }}</h1>
    <p class="mb-6" style="color: var(--color-text-muted)">Portal del profesional</p>

    <SkeletonStats v-if="loading" :count="3" class="grid-cols-1 md:grid-cols-3 mb-6" />
    <SkeletonCard v-if="loading" :count="2" :lines="2" />

    <div v-else class="space-y-6">
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div class="rounded-lg shadow p-6" style="background-color: var(--color-surface)">
          <h2 class="text-lg font-semibold mb-2" style="color: var(--color-text)">Servicios de hoy</h2>
          <div class="text-4xl font-bold" style="color: var(--color-primary)">{{ todayServices.length }}</div>
        </div>
        <div class="rounded-lg shadow p-6" style="background-color: var(--color-surface)">
          <h2 class="text-lg font-semibold mb-2" style="color: var(--color-text)">Reservas hoy</h2>
          <div class="text-4xl font-bold" style="color: var(--color-primary)">{{ todayBookings.length }}</div>
        </div>
        <button @click="showAnnouncementForm = !showAnnouncementForm" class="rounded-lg shadow p-6 text-left hover:shadow-md transition-shadow cursor-pointer" style="background-color: var(--color-primary-subtle)">
          <h2 class="text-lg font-semibold mb-2" style="color: var(--color-primary)">📢 Publicar aviso</h2>
          <p class="text-sm" style="color: var(--color-text-muted)">Informá a tus alumnos</p>
        </button>
      </div>

      <!-- Formulario de anuncio -->
      <div v-if="showAnnouncementForm" class="rounded-lg shadow p-6" style="background-color: var(--color-surface)">
        <h3 class="font-semibold mb-4" style="color: var(--color-text)">Nuevo aviso</h3>
        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Título</label>
            <input v-model="announcementForm.title" type="text" placeholder="Ej: Cambio de horario"
              class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2"
              :style="{ borderColor: 'var(--color-border)', '--tw-ring-color': 'var(--color-primary)' }" />
          </div>
          <div>
            <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Mensaje</label>
            <textarea v-model="announcementForm.content" rows="3" placeholder="Escribí el aviso para tus alumnos..."
              class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2"
              :style="{ borderColor: 'var(--color-border)', '--tw-ring-color': 'var(--color-primary)' }"></textarea>
          </div>
          <div>
            <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Servicio (opcional)</label>
            <select v-model="announcementForm.service_id"
              class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2"
              :style="{ borderColor: 'var(--color-border)', '--tw-ring-color': 'var(--color-primary)' }">
              <option value="">Todos los servicios</option>
              <option v-for="svc in todayServices" :key="svc.id" :value="svc.id">{{ svc.name }}</option>
            </select>
          </div>
          <div class="flex space-x-3">
            <button @click="handlePublishAnnouncement" :disabled="savingAnnouncement || !announcementForm.title.trim() || !announcementForm.content.trim()"
              class="px-4 py-2 rounded-lg text-white disabled:opacity-50 cursor-pointer hover:opacity-90"
              :style="{ backgroundColor: 'var(--color-primary)' }">
              {{ savingAnnouncement ? 'Publicando...' : 'Publicar' }}
            </button>
            <button @click="showAnnouncementForm = false"
              class="px-4 py-2 rounded-lg cursor-pointer"
              :style="{ backgroundColor: 'var(--color-primary-subtle)', color: 'var(--color-text)' }">
              Cancelar
            </button>
          </div>
        </div>
      </div>

      <div class="rounded-lg shadow p-6" style="background-color: var(--color-surface)">
        <h2 class="text-lg font-semibold mb-4" style="color: var(--color-text)">Servicios de hoy</h2>
        <div v-if="todayServices.length === 0" style="color: var(--color-text-muted)">No tenés servicios hoy.</div>
        <div v-else class="space-y-3">
          <div v-for="svc in todayServices" :key="svc.id" class="flex justify-between items-center p-3 rounded-lg" style="background-color: var(--color-primary-subtle)">
            <div>
              <p class="font-medium" style="color: var(--color-text)">{{ svc.name }}</p>
              <p class="text-sm" style="color: var(--color-text-muted)">{{ svc.start_time }} - {{ svc.end_time }}</p>
            </div>
            <span class="text-sm" style="color: var(--color-text-muted)">{{ todayBookings.filter(b => b.service_id === svc.id).length }} reservas</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
