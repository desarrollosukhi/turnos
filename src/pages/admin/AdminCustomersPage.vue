<script setup lang="ts">
import { UserService } from '@/services/UserService'
import { useAuthStore } from '@/stores/auth'
import { getBusinessLabels } from '@/types'
import { exportToCSV } from '@/utils/exportUtils'
import SkeletonTable from '@/components/SkeletonTable.vue'
import PaginationBar from '@/components/PaginationBar.vue'
import ToastMessage from '@/components/ToastMessage.vue'
import { ref, computed, onMounted } from 'vue'
import type { User } from '@/types'

const authStore = useAuthStore()
const labels = computed(() => getBusinessLabels(authStore.businessType))
const customers = ref<User[]>([])
const loading = ref(true)
const error = ref('')
const showForm = ref(false)
const editingId = ref<string | null>(null)
const createdCredentials = ref<{ email: string; tempPassword: string } | null>(null)
const copied = ref(false)
const customerMode = ref<'with_account' | 'without_account'>('with_account')

const form = ref({
  name: '', email: '', phone: '',
  birth_date: '', emergency_contact_name: '', emergency_contact_phone: '',
})

// Créditos
const showCreditModal = ref(false)
const customerSearch = ref('')
const showToast = ref(false)
const toastMessage = ref('')
const toastType = ref<'success' | 'error' | 'info'>('success')

const filteredCustomers = computed(() => {
  if (!customerSearch.value) return customers.value
  const q = customerSearch.value.toLowerCase()
  return customers.value.filter(c => c.name.toLowerCase().includes(q) || c.email?.toLowerCase().includes(q) || c.phone?.includes(q))
})
const creditModalData = ref<{ userId: string; userName: string; amount: number } | null>(null)

// Paginación
const currentPage = ref(1)
const pageSize = 20
const paginatedCustomers = computed(() => {
  const start = (currentPage.value - 1) * pageSize
  return filteredCustomers.value.slice(start, start + pageSize)
})
const totalPages = computed(() => Math.ceil(filteredCustomers.value.length / pageSize))

onMounted(() => fetchCustomers())

async function fetchCustomers() {
  if (!authStore.companyId) return
  loading.value = true
  try { customers.value = await UserService.getAll(authStore.companyId) }
  catch (e: any) { error.value = e.message }
  finally { loading.value = false }
}

function resetForm() {
  form.value = { name: '', email: '', phone: '', birth_date: '', emergency_contact_name: '', emergency_contact_phone: '' }
  editingId.value = null
}

function startEdit(c: User) {
  editingId.value = c.id
  form.value = {
    name: c.name, email: c.email || '', phone: c.phone || '',
    birth_date: c.birth_date || '', emergency_contact_name: c.emergency_contact_name || '',
    emergency_contact_phone: c.emergency_contact_phone || '',
  }
  showForm.value = true
  createdCredentials.value = null
}

async function handleCreate() {
  error.value = ''
  try {
    if (customerMode.value === 'with_account') {
      if (!form.value.email) { error.value = 'El email es requerido para crear con cuenta'; return }
      const result = await UserService.create({ ...form.value, company_id: authStore.companyId })
      createdCredentials.value = { email: form.value.email, tempPassword: result.tempPassword }
    } else {
      if (!form.value.phone) { error.value = 'El teléfono es requerido para crear sin cuenta'; return }
      await UserService.createWithoutAccount({ name: form.value.name, phone: form.value.phone, birth_date: form.value.birth_date || undefined, emergency_contact_name: form.value.emergency_contact_name || undefined, emergency_contact_phone: form.value.emergency_contact_phone || undefined, company_id: authStore.companyId })
    }
    showForm.value = false
    resetForm()
    customerMode.value = 'with_account'
    await fetchCustomers()
  } catch (e: any) { error.value = e.message }
}

async function handleUpdate() {
  if (!editingId.value) return
  error.value = ''
  try {
    await UserService.update(editingId.value, {
      name: form.value.name,
      email: form.value.email || undefined,
      phone: form.value.phone || undefined,
      birth_date: form.value.birth_date || undefined,
      emergency_contact_name: form.value.emergency_contact_name || undefined,
      emergency_contact_phone: form.value.emergency_contact_phone || undefined,
    } as any)
    showForm.value = false
    resetForm()
    await fetchCustomers()
  } catch (e: any) { error.value = e.message }
}

async function copyCredentials() {
  if (!createdCredentials.value) return
  const text = `Credenciales de acceso\n\nEmail: ${createdCredentials.value.email}\nContraseña: ${createdCredentials.value.tempPassword}\n\nIniciá sesión en: ${window.location.origin}`
  await navigator.clipboard.writeText(text)
  copied.value = true
  setTimeout(() => { copied.value = false }, 2000)
}

function openCreditModal(userId: string, userName: string, amount: number) {
  creditModalData.value = { userId, userName, amount: Math.abs(amount) }
  showCreditModal.value = true
}

function handleCreditAction(type: 'add' | 'deduct') {
  if (!creditModalData.value || creditModalData.value.amount <= 0) return
  creditModalData.value.amount = type === 'add' ? creditModalData.value.amount : -creditModalData.value.amount
  confirmCreditOperation()
}

async function confirmCreditOperation() {
  if (!creditModalData.value) return
  try {
    await UserService.addCredits(creditModalData.value.userId, creditModalData.value.amount)
    showCreditModal.value = false
    creditModalData.value = null
    await fetchCustomers()
    toastMessage.value = 'Créditos actualizados'
    toastType.value = 'success'
    showToast.value = true
  } catch (e: any) {
    error.value = e.message
    toastMessage.value = e.message || 'Error al actualizar créditos'
    toastType.value = 'error'
    showToast.value = true
  }
}

async function handleCreateAccount(customer: User) {
  if (!confirm(`¿Crear cuenta de acceso para ${customer.name}?`)) return
  try {
    const result = await UserService.createAccount(customer.id)
    createdCredentials.value = { email: result.email, tempPassword: result.tempPassword }
    await fetchCustomers()
  } catch (e: any) { error.value = e.message }
}

function handleExportCSV() {
  const data = customers.value.map(c => ({
    Nombre: c.name,
    Email: c.email || '',
    Teléfono: c.phone || '',
    Créditos: c.credits,
    Cuenta: c.has_account ? 'Con cuenta' : 'Sin cuenta',
  }))
  exportToCSV(data, `clientes-${authStore.companyId}`)
}
</script>

<template>
  <div>
    <ToastMessage :show="showToast" :message="toastMessage" :type="toastType" @close="showToast = false" />
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold" style="color: var(--color-text)">{{ labels.customers }}</h1>
      <div class="flex space-x-2">
        <button @click="handleExportCSV" class="text-sm px-3 py-2 rounded-lg border" :style="{ borderColor: 'var(--color-border)', color: 'var(--color-text)' }">
          📄 CSV
        </button>
        <button @click="showForm = !showForm; resetForm()" class="text-white px-4 py-2 rounded-lg" :style="{ backgroundColor: 'var(--color-primary)' }">
          {{ showForm ? 'Cancelar' : '+ Nuevo' }}
        </button>
      </div>
    </div>

    <!-- Credenciales generadas -->
    <div v-if="createdCredentials" class="rounded-lg border p-6 mb-6" style="background-color: #f0fdf4; border-color: #bbf7d0">
      <div class="flex justify-between items-start">
        <div>
          <h3 class="font-semibold mb-2" style="color: #166534">Credenciales generadas</h3>
          <p class="text-sm mb-1" style="color: #166534"><strong>Email:</strong> {{ createdCredentials.email }}</p>
          <p class="text-sm mb-3" style="color: #166534"><strong>Contraseña:</strong> <code class="px-2 py-1 rounded font-mono" style="background-color: #bbf7d0; color: #166534">{{ createdCredentials.tempPassword }}</code></p>
          <button @click="copyCredentials" class="px-4 py-2 rounded-lg text-white text-sm" style="background-color: #16a34a">
            {{ copied ? '✅ ¡Copiado!' : '📋 Copiar credenciales' }}
          </button>
        </div>
        <button @click="createdCredentials = null" style="color: #166534" class="text-lg">✕</button>
      </div>
    </div>

    <!-- Formulario crear/editar -->
    <div v-if="showForm" class="rounded-lg shadow p-6 mb-6" style="background-color: var(--color-surface)">
      <h2 class="text-lg font-semibold mb-4" style="color: var(--color-text)">{{ editingId ? 'Editar' : 'Crear' }} Cliente</h2>

      <!-- Modo de creación (solo al crear) -->
      <div v-if="!editingId" class="flex space-x-4 mb-4">
        <label class="flex items-center space-x-2 cursor-pointer p-3 rounded-lg border-2" :class="customerMode === 'with_account' ? 'border-blue-500' : 'border-gray-200'">
          <input type="radio" v-model="customerMode" value="with_account" class="text-blue-600" />
          <div>
            <div class="font-medium text-sm" style="color: var(--color-text)">Con cuenta</div>
            <div class="text-xs" style="color: var(--color-text-muted)">Puede loguearse y reservar</div>
          </div>
        </label>
        <label class="flex items-center space-x-2 cursor-pointer p-3 rounded-lg border-2" :class="customerMode === 'without_account' ? 'border-blue-500' : 'border-gray-200'">
          <input type="radio" v-model="customerMode" value="without_account" class="text-blue-600" />
          <div>
            <div class="font-medium text-sm" style="color: var(--color-text)">Sin cuenta</div>
            <div class="text-xs" style="color: var(--color-text-muted)">Solo nombre y teléfono</div>
          </div>
        </label>
      </div>

      <form @submit.prevent="editingId ? handleUpdate() : handleCreate()" class="space-y-4">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Nombre *</label>
            <input v-model="form.name" type="text" required class="w-full px-3 py-2 border rounded-lg" :style="{ borderColor: 'var(--color-border)' }" />
          </div>
          <div v-if="customerMode === 'with_account' || editingId">
            <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Email {{ editingId ? '' : '*' }}</label>
            <input v-model="form.email" type="email" :required="!editingId && customerMode === 'with_account'" class="w-full px-3 py-2 border rounded-lg" :style="{ borderColor: 'var(--color-border)' }" />
          </div>
          <div>
            <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Teléfono</label>
            <input v-model="form.phone" type="tel" class="w-full px-3 py-2 border rounded-lg" :style="{ borderColor: 'var(--color-border)' }" />
          </div>
          <div>
            <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Fecha de nacimiento</label>
            <input v-model="form.birth_date" type="date" class="w-full px-3 py-2 border rounded-lg" :style="{ borderColor: 'var(--color-border)' }" />
          </div>
          <div>
            <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Contacto de emergencia (nombre)</label>
            <input v-model="form.emergency_contact_name" type="text" class="w-full px-3 py-2 border rounded-lg" :style="{ borderColor: 'var(--color-border)' }" />
          </div>
          <div>
            <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Contacto de emergencia (teléfono)</label>
            <input v-model="form.emergency_contact_phone" type="tel" class="w-full px-3 py-2 border rounded-lg" :style="{ borderColor: 'var(--color-border)' }" />
          </div>
        </div>
        <div v-if="error" class="text-sm" style="color: #dc2626">{{ error }}</div>
        <button type="submit" class="text-white px-6 py-2 rounded-lg" :style="{ backgroundColor: 'var(--color-primary)' }">
          {{ editingId ? 'Guardar Cambios' : (customerMode === 'with_account' ? 'Crear con cuenta' : 'Crear sin cuenta') }}
        </button>
      </form>
    </div>

    <!-- Error -->
    <div v-if="error && !showForm" class="rounded-lg p-4 mb-6" style="background-color: #fef2f2; color: #991b1b">{{ error }}</div>

    <!-- Loading -->
    <SkeletonTable v-if="loading" :rows="5" :cols="6" />

    <!-- Tabla -->
    <div v-if="customers.length === 0 && !loading" class="rounded-lg shadow p-8 text-center" style="background-color: var(--color-surface)">
      <p style="color: var(--color-text-muted)">No hay clientes creados.</p>
    </div>

    <template v-if="customers.length > 0 && !loading">
      <!-- Búsqueda -->
      <div class="mb-4">
        <input v-model="customerSearch" type="text" placeholder="🔍 Buscar por nombre, email o teléfono..."
          class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2"
          :style="{ borderColor: 'var(--color-border)', '--tw-ring-color': 'var(--color-primary)' }" />
      </div>

      <!-- Desktop: tabla -->
      <div v-if="filteredCustomers.length === 0" class="rounded-lg shadow p-8 text-center" style="background-color: var(--color-surface)">
        <p style="color: var(--color-text-muted)">No se encontraron clientes</p>
      </div>

      <div v-else class="hidden md:block rounded-lg shadow overflow-hidden" style="background-color: var(--color-surface)">
      <table class="min-w-full divide-y" :style="{ borderColor: 'var(--color-border)' }">
        <thead :style="{ backgroundColor: 'var(--color-primary-subtle)' }">
          <tr>
            <th class="px-6 py-3 text-left text-xs font-medium uppercase" style="color: var(--color-text-muted)">Nombre</th>
            <th class="px-6 py-3 text-left text-xs font-medium uppercase" style="color: var(--color-text-muted)">Email</th>
            <th class="px-6 py-3 text-left text-xs font-medium uppercase" style="color: var(--color-text-muted)">Teléfono</th>
            <th class="px-6 py-3 text-left text-xs font-medium uppercase" style="color: var(--color-text-muted)">Créditos</th>
            <th class="px-6 py-3 text-left text-xs font-medium uppercase" style="color: var(--color-text-muted)">Cuenta</th>
            <th class="px-6 py-3 text-left text-xs font-medium uppercase" style="color: var(--color-text-muted)">Acciones</th>
          </tr>
        </thead>
        <tbody class="divide-y" :style="{ borderColor: 'var(--color-border)' }">
          <tr v-for="c in paginatedCustomers" :key="c.id" :style="{ backgroundColor: 'var(--color-surface)' }">
            <td class="px-6 py-4 whitespace-nowrap font-medium" style="color: var(--color-text)">{{ c.name }}</td>
            <td class="px-6 py-4 whitespace-nowrap" style="color: var(--color-text-muted)">{{ c.email || '-' }}</td>
            <td class="px-6 py-4 whitespace-nowrap" style="color: var(--color-text-muted)">{{ c.phone || '-' }}</td>
            <td class="px-6 py-4 whitespace-nowrap">
              <span class="px-2 inline-flex text-xs font-semibold rounded-full" style="background-color: var(--color-primary-subtle); color: var(--color-primary)">
                {{ c.credits }}
              </span>
            </td>
            <td class="px-6 py-4 whitespace-nowrap">
              <span v-if="c.has_account" class="px-2 inline-flex text-xs font-semibold rounded-full bg-green-100 text-green-800">Con cuenta</span>
              <span v-else class="px-2 inline-flex text-xs font-semibold rounded-full bg-yellow-100 text-yellow-800">Sin cuenta</span>
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm space-x-2">
              <button @click="openCreditModal(c.id, c.name, 0)" class="text-sm px-2 py-1 rounded border cursor-pointer" :style="{ borderColor: 'var(--color-border)', color: 'var(--color-primary)' }">💰 Créditos</button>
              <button @click="startEdit(c)" style="color: var(--color-primary)">✏️ Editar</button>
              <button v-if="!c.has_account" @click="handleCreateAccount(c)" class="text-sm font-medium" style="color: var(--color-primary)">🔑 Crear cuenta</button>
            </td>
          </tr>
        </tbody>
      </table>
      <PaginationBar
        :current-page="currentPage"
        :total-pages="totalPages"
        :total-items="filteredCustomers.length"
        :page-size="pageSize"
        @update:currentPage="currentPage = $event"
      />
    </div>

    <!-- Mobile: cards -->
    <div v-if="customers.length > 0" class="md:hidden space-y-3">
      <div v-for="c in paginatedCustomers" :key="c.id" class="rounded-lg shadow p-4" style="background-color: var(--color-surface)">
        <div class="flex justify-between items-start mb-2">
          <div class="font-semibold" style="color: var(--color-text)">{{ c.name }}</div>
          <span v-if="c.has_account" class="px-2 py-0.5 text-xs font-semibold rounded-full bg-green-100 text-green-800">Con cuenta</span>
          <span v-else class="px-2 py-0.5 text-xs font-semibold rounded-full bg-yellow-100 text-yellow-800">Sin cuenta</span>
        </div>
        <div class="text-sm mb-1" style="color: var(--color-text-muted)">📱 {{ c.phone || '-' }} · 💰 {{ c.credits }} créditos</div>
        <div v-if="c.email" class="text-xs mb-3" style="color: var(--color-text-muted)">{{ c.email }}</div>
        <div class="flex flex-wrap gap-2">
          <button @click="openCreditModal(c.id, c.name, 0)" class="text-xs px-2 py-1 rounded border cursor-pointer" :style="{ borderColor: 'var(--color-border)', color: 'var(--color-primary)' }">💰 Créditos</button>
          <button @click="startEdit(c)" class="text-xs px-2 py-1 rounded border" :style="{ borderColor: 'var(--color-border)', color: 'var(--color-primary)' }">✏️ Editar</button>
          <button v-if="!c.has_account" @click="handleCreateAccount(c)" class="text-xs px-2 py-1 rounded border" :style="{ borderColor: 'var(--color-border)', color: 'var(--color-primary)' }">🔑 Crear cuenta</button>
        </div>
      </div>
      <PaginationBar
        :current-page="currentPage"
        :total-pages="totalPages"
        :total-items="filteredCustomers.length"
        :page-size="pageSize"
        @update:currentPage="currentPage = $event"
      />
    </div>
    </template>

    <!-- Modal de créditos -->
    <div v-if="showCreditModal && creditModalData" class="fixed inset-0 z-50 flex items-center justify-center">
      <div class="fixed inset-0 bg-black/50" @click="showCreditModal = false"></div>
      <div class="relative rounded-lg shadow-xl max-w-md w-full mx-4 p-6" style="background-color: var(--color-surface)">
        <h3 class="text-lg font-semibold mb-2" style="color: var(--color-text)">
          Créditos — {{ creditModalData.userName }}
        </h3>
        <p class="text-sm mb-4" style="color: var(--color-text-muted)">Ingresá la cantidad de créditos a agregar o restar.</p>

        <div class="flex items-center space-x-3 mb-4">
          <button @click="creditModalData.amount = Math.max(0, creditModalData.amount - 1)"
            class="w-10 h-10 rounded-lg flex items-center justify-center text-lg font-bold cursor-pointer hover:opacity-80"
            style="background-color: var(--color-primary-subtle); color: var(--color-text)">−</button>
          <input v-model.number="creditModalData.amount" type="number" min="0"
            class="flex-1 text-center text-2xl font-bold px-3 py-2 border rounded-lg focus:outline-none focus:ring-2"
            :style="{ borderColor: 'var(--color-border)', '--tw-ring-color': 'var(--color-primary)', color: 'var(--color-text)' }" />
          <button @click="creditModalData.amount++"
            class="w-10 h-10 rounded-lg flex items-center justify-center text-lg font-bold cursor-pointer hover:opacity-80"
            style="background-color: var(--color-primary-subtle); color: var(--color-text)">+</button>
        </div>

        <div class="flex justify-end space-x-3">
          <button @click="showCreditModal = false" class="px-4 py-2 rounded-lg cursor-pointer" style="background-color: var(--color-primary-subtle); color: var(--color-text)">
            Cancelar
          </button>
          <button @click="handleCreditAction('add')"
            :disabled="creditModalData.amount <= 0"
            class="px-4 py-2 rounded-lg text-white cursor-pointer disabled:opacity-50"
            style="background-color: var(--color-primary)">
            Agregar
          </button>
          <button @click="handleCreditAction('deduct')"
            :disabled="creditModalData.amount <= 0"
            class="px-4 py-2 rounded-lg text-white cursor-pointer disabled:opacity-50"
            style="background-color: #dc2626">
            Restar
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
