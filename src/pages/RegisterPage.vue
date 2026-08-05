<script setup lang="ts">
import { useAuthStore } from '@/stores/auth'
import { CompanyService } from '@/services/CompanyService'
import { getBusinessTypeSpanish } from '@/types'
import { useRouter } from 'vue-router'
import { ref, onMounted, computed } from 'vue'
import type { Company } from '@/types'

const authStore = useAuthStore()
const router = useRouter()

const name = ref('')
const email = ref('')
const password = ref('')
const role = ref<'admin' | 'customer'>('admin')
const companyId = ref('')
const loading = ref(false)
const error = ref('')
const registered = ref(false)
const companies = ref<Company[]>([])
const loadingCompanies = ref(true)
const companySearch = ref('')
const showCompanyList = ref(false)

const selectedCompany = computed(() => companies.value.find(c => c.id === companyId.value))

onMounted(async () => {
  try {
    companies.value = await CompanyService.getAllActive()
  } catch (e) { console.error(e) }
  finally { loadingCompanies.value = false }
})

const filteredCompanies = computed(() => {
  if (companySearch.value.length < 2) return []
  const q = companySearch.value.toLowerCase()
  return companies.value.filter(c => c.name.toLowerCase().includes(q))
})

function selectCompany(c: Company) {
  companyId.value = c.id
  companySearch.value = c.name
  showCompanyList.value = false
}

function clearCompany() {
  companyId.value = ''
  companySearch.value = ''
  showCompanyList.value = true
}

async function handleRegister() {
  if (role.value === 'customer' && !companyId.value) {
    error.value = 'Seleccioná una empresa para continuar'
    return
  }
  loading.value = true
  error.value = ''
  try {
    await authStore.register(email.value, password.value, name.value, role.value, companyId.value || undefined)
    registered.value = true
  } catch (e: any) {
    error.value = e.message || 'Error al registrarse'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="rounded-lg shadow p-6" style="background-color: var(--color-surface)">
    <!-- Mensaje post-registro -->
    <div v-if="registered" class="text-center">
      <div class="text-5xl mb-4">✉️</div>
      <h2 class="text-2xl font-bold mb-4" style="color: var(--color-text)">Revisá tu email</h2>
      <p class="mb-4" style="color: var(--color-text-muted)">
        Te enviamos un link de confirmación a <strong>{{ email }}</strong>.
      </p>
      <p class="text-sm mb-6" style="color: var(--color-text-muted)">
        Confirmá tu email y luego iniciá sesión para continuar.
      </p>
      <router-link
        to="/login"
        class="inline-block text-white py-2 px-6 rounded-lg cursor-pointer hover:opacity-90"
        :style="{ backgroundColor: 'var(--color-primary)' }"
      >
        Ir a Iniciar Sesión
      </router-link>
    </div>

    <!-- Formulario de registro -->
    <template v-else>
      <h2 class="text-2xl font-bold text-center mb-6" style="color: var(--color-text)">Crear Cuenta</h2>

      <form @submit.prevent="handleRegister" class="space-y-4">
        <div>
          <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Nombre</label>
          <input
            v-model="name"
            type="text"
            required
            class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2"
            :style="{ borderColor: 'var(--color-border)', '--tw-ring-color': 'var(--color-primary)' }"
          />
        </div>

        <div>
          <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Email</label>
          <input
            v-model="email"
            type="email"
            required
            class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2"
            :style="{ borderColor: 'var(--color-border)', '--tw-ring-color': 'var(--color-primary)' }"
          />
        </div>

        <div>
          <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Contraseña</label>
          <input
            v-model="password"
            type="password"
            required
            minlength="6"
            class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2"
            :style="{ borderColor: 'var(--color-border)', '--tw-ring-color': 'var(--color-primary)' }"
          />
        </div>

        <div>
          <label class="block text-sm font-medium mb-2" style="color: var(--color-text)">¿Qué sos?</label>
          <div class="space-y-2">
            <label class="flex items-center p-3 border rounded-lg cursor-pointer"
              :style="{ borderColor: role === 'admin' ? 'var(--color-primary)' : 'var(--color-border)', backgroundColor: role === 'admin' ? 'var(--color-primary-subtle)' : 'transparent' }">
              <input type="radio" v-model="role" value="admin" class="mr-3" />
              <div>
                <div class="font-medium" style="color: var(--color-text)">Admin de un negocio</div>
                <div class="text-sm" style="color: var(--color-text-muted)">Creo y gestiono mi espacio</div>
              </div>
            </label>
            <label class="flex items-center p-3 border rounded-lg cursor-pointer"
              :style="{ borderColor: role === 'customer' ? 'var(--color-primary)' : 'var(--color-border)', backgroundColor: role === 'customer' ? 'var(--color-primary-subtle)' : 'transparent' }">
              <input type="radio" v-model="role" value="customer" class="mr-3" />
              <div>
                <div class="font-medium" style="color: var(--color-text)">Soy usuario</div>
                <div class="text-sm" style="color: var(--color-text-muted)">Reservo en un negocio existente</div>
              </div>
            </label>
          </div>
        </div>

        <!-- Selector de empresa (solo para customer) -->
        <div v-if="role === 'customer'" class="space-y-2">
          <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">¿A qué negocio pertenecés?</label>

          <!-- Empresa seleccionada -->
          <div v-if="selectedCompany" class="flex items-center justify-between p-3 border rounded-lg" :style="{ borderColor: 'var(--color-primary)', backgroundColor: 'var(--color-primary-subtle)' }">
            <div>
              <div class="font-medium" style="color: var(--color-text)">{{ selectedCompany.name }}</div>
              <div class="text-xs" style="color: var(--color-text-muted)">{{ getBusinessTypeSpanish(selectedCompany.business_type) }}</div>
            </div>
            <button type="button" @click="clearCompany" class="text-sm cursor-pointer" style="color: var(--color-primary)">Cambiar</button>
          </div>

          <!-- Input de búsqueda -->
          <template v-else>
            <input
              v-model="companySearch"
              type="text"
              placeholder="Escribí el nombre de tu negocio..."
              @focus="showCompanyList = true"
              class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2"
              :style="{ borderColor: 'var(--color-border)', '--tw-ring-color': 'var(--color-primary)' }"
            />

            <!-- Lista de resultados -->
            <div v-if="showCompanyList" class="border rounded-lg" :style="{ borderColor: 'var(--color-border)' }">
              <div v-if="loadingCompanies" class="p-3 text-sm" style="color: var(--color-text-muted)">Cargando negocios...</div>
              <div v-else-if="companySearch.length < 2" class="p-3 text-sm" style="color: var(--color-text-muted)">Escribí para buscar tu negocio</div>
              <div v-else-if="filteredCompanies.length === 0" class="p-3 text-sm" style="color: var(--color-text-muted)">No se encontró ningún negocio</div>
              <div v-else class="max-h-48 overflow-y-auto">
                <button
                  v-for="c in filteredCompanies"
                  :key="c.id"
                  type="button"
                  @click="selectCompany(c)"
                  class="w-full text-left p-3 cursor-pointer border-b last:border-b-0 hover:opacity-80"
                  :style="{ borderColor: 'var(--color-border)', backgroundColor: 'transparent' }"
                >
                  <div class="font-medium" style="color: var(--color-text)">{{ c.name }}</div>
                  <div class="text-xs" style="color: var(--color-text-muted)">{{ getBusinessTypeSpanish(c.business_type) }}</div>
                </button>
              </div>
            </div>
          </template>
        </div>

        <div v-if="error" class="text-sm" style="color: #dc2626">
          {{ error }}
        </div>

        <button
          type="submit"
          :disabled="loading || (role === 'customer' && !companyId)"
          class="w-full text-white py-2 px-4 rounded-lg disabled:opacity-50 cursor-pointer hover:opacity-90"
          :style="{ backgroundColor: 'var(--color-primary)' }"
        >
          {{ loading ? 'Creando...' : 'Crear Cuenta' }}
        </button>
      </form>

      <p class="mt-4 text-center text-sm" style="color: var(--color-text-muted)">
        ¿Ya tenés cuenta?
        <router-link to="/login" :style="{ color: 'var(--color-primary)' }" class="hover:underline">
          Iniciá sesión
        </router-link>
      </p>
    </template>
  </div>
</template>
