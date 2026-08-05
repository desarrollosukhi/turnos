<script setup lang="ts">
import { useAuthStore } from '@/stores/auth'
import { CreditService } from '@/services/CreditService'
import { UserService } from '@/services/UserService'
import SkeletonCard from '@/components/SkeletonCard.vue'
import { ref, computed, onMounted } from 'vue'
import type { User } from '@/types'

const authStore = useAuthStore()
const customers = ref<User[]>([])
const selectedCustomer = ref<User | null>(null)
const movements = ref<any[]>([])
const loading = ref(true)
const error = ref('')
const creditForm = ref({ amount: 0, description: '' })
const customerSearch = ref('')

const filteredCustomers = computed(() => {
  if (!customerSearch.value) return customers.value
  const q = customerSearch.value.toLowerCase()
  return customers.value.filter(c => c.name.toLowerCase().includes(q) || c.email?.toLowerCase().includes(q))
})

onMounted(async () => { await fetchCustomers(); loading.value = false })

async function fetchCustomers() {
  if (!authStore.companyId) return
  try { customers.value = await UserService.getAll(authStore.companyId) } catch (e: any) { error.value = e.message }
}

async function selectCustomer(c: User) {
  selectedCustomer.value = c
  try { movements.value = await CreditService.getMovements(c.id); console.log('[Credits] Movements:', movements.value) } catch (e: any) { error.value = e.message }
}

async function handleAdd() {
  if (!selectedCustomer.value || creditForm.value.amount <= 0) return
  try { await CreditService.addCredits(selectedCustomer.value.id, creditForm.value.amount, creditForm.value.description || 'Créditos agregados'); await selectCustomer(selectedCustomer.value); await fetchCustomers(); creditForm.value = { amount: 0, description: '' } }
  catch (e: any) { error.value = e.message }
}

async function handleDeduct() {
  if (!selectedCustomer.value || creditForm.value.amount <= 0) return
  try { await CreditService.deductCredits(selectedCustomer.value.id, creditForm.value.amount, creditForm.value.description || 'Créditos descontados'); await selectCustomer(selectedCustomer.value); await fetchCustomers(); creditForm.value = { amount: 0, description: '' } }
  catch (e: any) { error.value = e.message }
}
</script>

<template>
  <div>
    <h1 class="text-2xl font-bold mb-6">Créditos</h1>
    <div v-if="error" class="bg-red-50 text-red-600 p-4 rounded-lg mb-6">{{ error }}</div>
    <SkeletonCard v-if="loading" :count="4" :lines="2" class="grid-cols-1 lg:grid-cols-3" />
    <div v-else class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <div class="lg:col-span-1">
        <div class="rounded-lg shadow" style="background-color: var(--color-surface)">
          <div class="p-4 border-b"><h2 class="font-semibold mb-2">Seleccionar Cliente</h2>
            <input v-model="customerSearch" type="text" placeholder="🔍 Buscar por nombre o email..."
              class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:ring-2"
              :style="{ borderColor: 'var(--color-border)', '--tw-ring-color': 'var(--color-primary)' }" />
          </div>
          <div class="divide-y max-h-80 overflow-y-auto">
            <button v-for="c in filteredCustomers" :key="c.id" @click="selectCustomer(c)"
              :class="[selectedCustomer?.id === c.id ? 'bg-blue-50' : '', 'w-full text-left p-4 hover:bg-gray-50']">
              <div class="font-medium">{{ c.name }}</div>
              <div class="text-sm text-gray-500">{{ c.credits }} créditos</div>
            </button>
            <div v-if="filteredCustomers.length === 0" class="p-4 text-center text-sm text-gray-500">No se encontraron clientes</div>
          </div>
        </div>
      </div>
      <div class="lg:col-span-2">
        <div v-if="!selectedCustomer" class="rounded-lg shadow p-8 text-center text-gray-500" style="background-color: var(--color-surface)">Seleccioná un cliente</div>
        <template v-else>
          <div class="rounded-lg shadow p-6 mb-6" style="background-color: var(--color-surface)">
            <h2 class="font-semibold mb-4">Créditos — {{ selectedCustomer.name }}</h2>
            <div class="text-3xl font-bold text-blue-600 mb-4">{{ selectedCustomer.credits }}</div>
            <div class="flex flex-col sm:flex-row sm:space-x-4 space-y-2 sm:space-y-0">
              <input v-model.number="creditForm.amount" type="number" min="1" placeholder="Cantidad" class="flex-1 px-3 py-2 border border-gray-300 rounded-lg" />
              <input v-model="creditForm.description" type="text" placeholder="Descripción" class="flex-1 px-3 py-2 border border-gray-300 rounded-lg" />
            </div>
            <div class="flex space-x-4 mt-4">
              <button @click="handleAdd" :disabled="creditForm.amount <= 0" class="bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 disabled:opacity-50">+ Agregar</button>
              <button @click="handleDeduct" :disabled="creditForm.amount <= 0 || selectedCustomer.credits < creditForm.amount" class="bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700 disabled:opacity-50">- Descontar</button>
            </div>
          </div>
          <div class="rounded-lg shadow" style="background-color: var(--color-surface)">
            <div class="p-4 border-b"><h3 class="font-semibold">Historial</h3></div>
            <div v-if="movements.length === 0" class="p-4 text-center text-gray-500">Sin movimientos.</div>
            <div v-else class="divide-y">
              <div v-for="m in movements" :key="m.id" class="p-4 flex justify-between items-center">
                <div>
                  <p class="font-medium">{{ m.description }}</p>
                  <p class="text-sm text-gray-500">{{ new Date(m.created_at).toLocaleDateString() }}</p>
                  <p v-if="m.expires_at && m.amount > 0" class="text-xs" :class="new Date(m.expires_at) < new Date() ? 'text-red-500' : new Date(m.expires_at) < new Date(Date.now() + 7*24*60*60*1000) ? 'text-yellow-600' : 'text-gray-400'">
                    Vence: {{ new Date(m.expires_at).toLocaleDateString() }}
                  </p>
                </div>
                <span :class="[m.amount > 0 ? 'text-green-600' : 'text-red-600', 'font-semibold']">{{ m.amount > 0 ? '+' : '' }}{{ m.amount }}</span>
              </div>
            </div>
          </div>
        </template>
      </div>
    </div>
  </div>
</template>
