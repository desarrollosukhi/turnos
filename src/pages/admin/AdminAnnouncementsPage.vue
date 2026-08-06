<script setup lang="ts">
import { useAuthStore } from '@/stores/auth'
import { ServiceService } from '@/services/ServiceService'
import { AnnouncementService } from '@/services/AnnouncementService'
import ToastMessage from '@/components/ToastMessage.vue'
import TiptapEditor from '@/components/TiptapEditor.vue'
import { ref, onMounted } from 'vue'
import type { AnnouncementWithDetails, AnnouncementTarget } from '@/types'

const authStore = useAuthStore()

const announcements = ref<AnnouncementWithDetails[]>([])
const services = ref<any[]>([])
const loading = ref(true)
const error = ref('')

// Formulario
const showForm = ref(false)
const form = ref({
  title: '',
  content: '',
  target: 'all' as AnnouncementTarget,
  service_id: '',
})
const saving = ref(false)

// Toast
const showToast = ref(false)
const toastMessage = ref('')
const toastType = ref<'success' | 'error' | 'info'>('success')

onMounted(async () => {
  if (!authStore.companyId) return
  try {
    const [anns, svcs] = await Promise.all([
      AnnouncementService.getActive(authStore.companyId),
      ServiceService.getAll(authStore.companyId),
    ])
    announcements.value = anns
    services.value = svcs
  } catch (e: any) { error.value = e.message }
  finally { loading.value = false }
})

async function handleCreate() {
  if (!form.value.title.trim() || !form.value.content.trim() || form.value.content === '<p></p>') return
  saving.value = true
  try {
    await AnnouncementService.create({
      company_id: authStore.companyId!,
      professional_id: null,
      service_id: form.value.target === 'service_bookings' ? form.value.service_id : null,
      title: form.value.title,
      content: form.value.content,
      target: form.value.target,
      date_from: new Date().toISOString().split('T')[0] ?? '',
      date_to: null,
      active: true,
    })
    form.value = { title: '', content: '', target: 'all', service_id: '' }
    showForm.value = false
    announcements.value = await AnnouncementService.getActive(authStore.companyId!)
    toastMessage.value = 'Aviso publicado'
    toastType.value = 'success'
    showToast.value = true
  } catch (e: any) {
    toastMessage.value = e.message || 'Error al publicar'
    toastType.value = 'error'
    showToast.value = true
  } finally {
    saving.value = false
  }
}

async function toggleActive(ann: AnnouncementWithDetails) {
  try {
    await AnnouncementService.update(ann.id, { active: !ann.active })
    if (!ann.active) await AnnouncementService.reactivate(ann.id)
    announcements.value = await AnnouncementService.getActive(authStore.companyId!)
    toastMessage.value = ann.active ? 'Aviso desactivado' : 'Aviso activado'
    toastType.value = 'success'
    showToast.value = true
  } catch (e: any) {
    toastMessage.value = e.message || 'Error'
    toastType.value = 'error'
    showToast.value = true
  }
}

async function deleteAnnouncement(id: string) {
  if (!confirm('¿Eliminar este aviso?')) return
  try {
    await AnnouncementService.delete(id)
    announcements.value = announcements.value.filter(a => a.id !== id)
    toastMessage.value = 'Aviso eliminado'
    toastType.value = 'success'
    showToast.value = true
  } catch (e: any) {
    toastMessage.value = e.message || 'Error'
    toastType.value = 'error'
    showToast.value = true
  }
}
</script>

<template>
  <div>
    <ToastMessage :show="showToast" :message="toastMessage" :type="toastType" @close="showToast = false" />

    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold" style="color: var(--color-text)">Avisos</h1>
      <button @click="showForm = !showForm" class="px-4 py-2 rounded-lg text-white cursor-pointer hover:opacity-90" :style="{ backgroundColor: 'var(--color-primary)' }">
        {{ showForm ? 'Cancelar' : '+ Nuevo aviso' }}
      </button>
    </div>

    <!-- Formulario -->
    <div v-if="showForm" class="rounded-lg shadow p-6 mb-6" style="background-color: var(--color-surface)">
      <h2 class="font-semibold mb-4" style="color: var(--color-text)">Nuevo aviso</h2>
      <div class="space-y-4">
        <div>
          <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Título</label>
          <input v-model="form.title" type="text" placeholder="Ej: Cambio de horario"
            class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2"
            :style="{ borderColor: 'var(--color-border)', '--tw-ring-color': 'var(--color-primary)' }" />
        </div>
        <div>
          <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Mensaje</label>
          <TiptapEditor v-model="form.content" />
        </div>
        <div>
          <label class="block text-sm font-medium mb-2" style="color: var(--color-text)">¿Para quién?</label>
          <div class="flex flex-wrap gap-2">
            <button @click="form.target = 'all'; form.service_id = ''"
              class="px-4 py-2 rounded-lg text-sm cursor-pointer border"
              :style="{ borderColor: form.target === 'all' ? 'var(--color-primary)' : 'var(--color-border)', backgroundColor: form.target === 'all' ? 'var(--color-primary-subtle)' : 'transparent', color: 'var(--color-text)' }">
              📢 Todos los alumnos
            </button>
            <button @click="form.target = 'service_bookings'"
              class="px-4 py-2 rounded-lg text-sm cursor-pointer border"
              :style="{ borderColor: form.target === 'service_bookings' ? 'var(--color-primary)' : 'var(--color-border)', backgroundColor: form.target === 'service_bookings' ? 'var(--color-primary-subtle)' : 'transparent', color: 'var(--color-text)' }">
              🎯 Solo los de una clase/turno/evento
            </button>
          </div>
        </div>
        <div v-if="form.target === 'service_bookings'">
          <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Seleccionar servicio</label>
          <select v-model="form.service_id"
            class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2"
            :style="{ borderColor: 'var(--color-border)', '--tw-ring-color': 'var(--color-primary)' }">
            <option value="">Seleccionar servicio...</option>
            <option v-for="s in services" :key="s.id" :value="s.id">{{ s.name }}</option>
          </select>
        </div>
        <div class="flex space-x-3">
          <button @click="handleCreate" :disabled="saving || !form.title.trim()"
            class="px-4 py-2 rounded-lg text-white cursor-pointer disabled:opacity-50 hover:opacity-90"
            :style="{ backgroundColor: 'var(--color-primary)' }">
            {{ saving ? 'Publicando...' : 'Publicar aviso' }}
          </button>
          <button @click="showForm = false" class="px-4 py-2 rounded-lg cursor-pointer" :style="{ backgroundColor: 'var(--color-primary-subtle)', color: 'var(--color-text)' }">
            Cancelar
          </button>
        </div>
      </div>
    </div>

    <!-- Lista de anuncios -->
    <div v-if="loading" class="text-center py-8">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 mx-auto" style="border-color: var(--color-primary); border-bottom-color: transparent"></div>
    </div>

    <div v-else-if="announcements.length === 0" class="rounded-lg shadow p-8 text-center" style="background-color: var(--color-surface)">
      <p style="color: var(--color-text-muted)">No hay avisos publicados.</p>
    </div>

    <div v-else class="space-y-3">
      <div v-for="ann in announcements" :key="ann.id" class="rounded-lg shadow p-4" style="background-color: var(--color-surface)">
        <div class="flex justify-between items-start">
          <div class="flex-1">
            <div class="flex items-center space-x-2 mb-1">
              <h3 class="font-semibold" style="color: var(--color-text)">{{ ann.title }}</h3>
              <span v-if="!ann.active" class="px-2 py-0.5 text-xs rounded-full" style="background-color: #fef2f2; color: #991b1b">Inactivo</span>
              <span v-if="ann.target === 'service_bookings'" class="px-2 py-0.5 text-xs rounded-full" style="background-color: var(--color-primary-subtle); color: var(--color-primary)">{{ ann.service_name }}</span>
              <span v-else class="px-2 py-0.5 text-xs rounded-full" style="background-color: #ecfdf5; color: #065f46">Todos</span>
            </div>
            <div class="text-sm mt-1 prose prose-sm max-w-none" style="color: var(--color-text-muted)" v-html="ann.content"></div>
            <p class="text-xs mt-1" style="color: var(--color-text-muted)">
              {{ ann.professional_name }} · {{ new Date(ann.created_at).toLocaleDateString('es-AR') }}
            </p>
          </div>
          <div class="flex space-x-2 ml-4">
            <button @click="toggleActive(ann)" class="text-sm cursor-pointer" :style="{ color: ann.active ? 'var(--color-text-muted)' : 'var(--color-primary)' }">
              {{ ann.active ? 'Desactivar' : 'Activar' }}
            </button>
            <button @click="deleteAnnouncement(ann.id)" class="text-sm cursor-pointer" style="color: #dc2626">Eliminar</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
