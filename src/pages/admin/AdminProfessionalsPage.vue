<script setup lang="ts">
import { ProfessionalService } from '@/services/ProfessionalService'
import { useAuthStore } from '@/stores/auth'
import { getBusinessLabels } from '@/types'
import PaginationBar from '@/components/PaginationBar.vue'
import SkeletonTable from '@/components/SkeletonTable.vue'
import { ref, computed, onMounted } from 'vue'
import type { Professional } from '@/types'

const authStore = useAuthStore()
const labels = computed(() => getBusinessLabels(authStore.businessType))
const professionals = ref<Professional[]>([])
const loading = ref(true)
const error = ref('')
const showForm = ref(false)
const editingId = ref<string | null>(null)
const createdCredentials = ref<{ email: string; tempPassword: string } | null>(null)
const copied = ref(false)

const form = ref({ name: '', alias: '', email: '', phone: '', whatsapp: '' })
const saving = ref(false)

// Paginación
const currentPage = ref(1)
const pageSize = 20
const paginatedProfessionals = computed(() => {
  const start = (currentPage.value - 1) * pageSize
  return professionals.value.slice(start, start + pageSize)
})
const totalPages = computed(() => Math.ceil(professionals.value.length / pageSize))

onMounted(() => fetchProfessionals())

async function fetchProfessionals() {
  if (!authStore.companyId) return
  loading.value = true
  try { professionals.value = await ProfessionalService.getAll(authStore.companyId) }
  catch (e: any) { error.value = e.message }
  finally { loading.value = false }
}

function resetForm() { form.value = { name: '', alias: '', email: '', phone: '', whatsapp: '' }; editingId.value = null }

function startEdit(p: Professional) {
  editingId.value = p.id
  form.value = { name: p.name, alias: p.alias || '', email: p.email || '', phone: p.phone || '', whatsapp: p.whatsapp || '' }
  showForm.value = true
}

async function handleSubmit() {
  if (!authStore.companyId) return
  error.value = ''
  saving.value = true
  try {
    if (editingId.value) {
      await ProfessionalService.update(editingId.value, { name: form.value.name, alias: form.value.alias || null, email: form.value.email || null, phone: form.value.phone || null, whatsapp: form.value.whatsapp || null })
    } else {
      const result = await ProfessionalService.create({ company_id: authStore.companyId, ...form.value, alias: form.value.alias || undefined, email: form.value.email || undefined, phone: form.value.phone || undefined, whatsapp: form.value.whatsapp || undefined })
      if (result.tempPassword && form.value.email) createdCredentials.value = { email: form.value.email, tempPassword: result.tempPassword }
    }
    showForm.value = false; resetForm(); await fetchProfessionals()
  } catch (e: any) { error.value = e.message }
  finally { saving.value = false }
}

async function copyCredentials() {
  if (!createdCredentials.value) return
  await navigator.clipboard.writeText(`Credenciales\n\nEmail: ${createdCredentials.value.email}\nContraseña: ${createdCredentials.value.tempPassword}\n\nIniciá sesión en: ${window.location.origin}`)
  copied.value = true; setTimeout(() => { copied.value = false }, 2000)
}
</script>

<template>
  <div>
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold">{{ labels.professionals }}</h1>
      <button @click="showForm = !showForm; resetForm()" class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
        {{ showForm ? 'Cancelar' : `+ Nuevo ${labels.professionals.slice(0, -1)}` }}
      </button>
    </div>

    <div v-if="createdCredentials" class="bg-green-50 border border-green-200 rounded-lg p-6 mb-6">
      <h3 class="font-semibold text-green-800 mb-2">Credenciales generadas</h3>
      <p class="text-sm text-green-700 mb-1"><strong>Email:</strong> {{ createdCredentials.email }}</p>
      <p class="text-sm text-green-700 mb-3"><strong>Contraseña:</strong> <code class="bg-green-100 px-2 py-1 rounded font-mono">{{ createdCredentials.tempPassword }}</code></p>
      <button @click="copyCredentials" class="bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 text-sm">
        {{ copied ? '✅ ¡Copiado!' : '📋 Copiar credenciales' }}
      </button>
    </div>

    <div v-if="showForm" class="rounded-lg shadow p-6 mb-6" style="background-color: var(--color-surface)">
      <form @submit.prevent="handleSubmit" class="space-y-4">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div><label class="block text-sm font-medium text-gray-700 mb-1">Nombre *</label><input v-model="form.name" type="text" required class="w-full px-3 py-2 border border-gray-300 rounded-lg" /></div>
          <div><label class="block text-sm font-medium text-gray-700 mb-1">Alias</label><input v-model="form.alias" type="text" class="w-full px-3 py-2 border border-gray-300 rounded-lg" /></div>
        </div>
        <div><label class="block text-sm font-medium text-gray-700 mb-1">Email</label><input v-model="form.email" type="email" class="w-full px-3 py-2 border border-gray-300 rounded-lg" /></div>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div><label class="block text-sm font-medium text-gray-700 mb-1">Teléfono</label><input v-model="form.phone" type="tel" class="w-full px-3 py-2 border border-gray-300 rounded-lg" /></div>
          <div><label class="block text-sm font-medium text-gray-700 mb-1">WhatsApp</label><input v-model="form.whatsapp" type="tel" class="w-full px-3 py-2 border border-gray-300 rounded-lg" /></div>
        </div>
        <button type="submit" class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 disabled:opacity-50" :disabled="saving">{{ saving ? 'Guardando...' : (editingId ? 'Guardar' : 'Crear') }}</button>
      </form>
    </div>

    <div v-if="error" class="bg-red-50 text-red-600 p-4 rounded-lg mb-6">{{ error }}</div>

    <SkeletonTable v-if="loading" :rows="5" :cols="4" />

    <div v-else-if="professionals.length === 0" class="rounded-lg shadow p-8 text-center" style="background-color: var(--color-surface)">
      <p style="color: var(--color-text-muted)">No hay {{ labels.professionals.toLowerCase() }} creados.</p>
    </div>

    <div v-else class="rounded-lg shadow overflow-hidden" style="background-color: var(--color-surface)">
      <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
          <tr>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Nombre</th>
            <th class="hidden md:table-cell px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Alias</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Email</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Acciones</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-200" style="background-color: var(--color-surface)">
          <tr v-for="p in paginatedProfessionals" :key="p.id">
            <td class="px-6 py-4 whitespace-nowrap font-medium">{{ p.name }}</td>
            <td class="hidden md:table-cell px-6 py-4 whitespace-nowrap text-gray-500">{{ p.alias || '-' }}</td>
            <td class="px-6 py-4 whitespace-nowrap text-gray-500">{{ p.email || '-' }}</td>
            <td class="px-6 py-4 whitespace-nowrap text-sm">
              <button @click="startEdit(p)" class="text-blue-600 hover:text-blue-800 mr-2">Editar</button>
            </td>
          </tr>
        </tbody>
      </table>
      <PaginationBar
        :current-page="currentPage"
        :total-pages="totalPages"
        :total-items="professionals.length"
        :page-size="pageSize"
        @update:currentPage="currentPage = $event"
      />
    </div>
  </div>
</template>
