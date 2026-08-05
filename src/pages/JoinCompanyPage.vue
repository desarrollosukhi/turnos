<script setup lang="ts">
import { useAuthStore } from '@/stores/auth'
import { CompanyService } from '@/services/CompanyService'
import { getBusinessTypeSpanish } from '@/types'
import { supabase } from '@/supabase/client'
import { useRouter } from 'vue-router'
import { ref, computed, onMounted } from 'vue'
import type { Company } from '@/types'

const authStore = useAuthStore()
const router = useRouter()

const companies = ref<Company[]>([])
const loading = ref(true)
const joining = ref(false)
const error = ref('')
const companyId = ref('')
const companySearch = ref('')
const showCompanyList = ref(false)
const joined = ref(false)

const selectedCompany = computed(() => companies.value.find(c => c.id === companyId.value))

onMounted(async () => {
  if (!authStore.user) {
    router.push('/login')
    return
  }
  try {
    companies.value = await CompanyService.getAllActive()
  } catch (e: any) { error.value = e.message }
  finally { loading.value = false }
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

async function handleJoin() {
  if (!companyId.value) return
  joining.value = true
  error.value = ''
  try {
    const { data, error: rpcError } = await supabase.rpc('join_company', {
      p_company_id: companyId.value,
    })
    if (rpcError) throw rpcError
    joined.value = true
    await authStore.fetchUser()
  } catch (e: any) {
    error.value = e.message || 'Error al unirse a la empresa'
  } finally {
    joining.value = false
  }
}
</script>

<template>
  <div class="max-w-md mx-auto">
    <!-- Éxito -->
    <div v-if="joined" class="text-center">
      <div class="text-5xl mb-4">✅</div>
      <h1 class="text-2xl font-bold mb-2" style="color: var(--color-text)">¡Listo!</h1>
      <p class="mb-6" style="color: var(--color-text-muted)">Te uniste a la empresa exitosamente.</p>
      <router-link
        to="/"
        class="inline-block text-white py-2 px-6 rounded-lg cursor-pointer hover:opacity-90"
        :style="{ backgroundColor: 'var(--color-primary)' }"
      >
        Ir al inicio
      </router-link>
    </div>

    <!-- Selector de empresa -->
    <template v-else>
      <div class="text-center mb-8">
        <div class="text-5xl mb-4">👋</div>
        <h1 class="text-2xl font-bold mb-2" style="color: var(--color-text)">Unirse a un negocio</h1>
        <p style="color: var(--color-text-muted)">Elegí el negocio al que pertenecés para empezar a reservar.</p>
      </div>

      <div v-if="loading" class="text-center py-8">
        <div class="animate-spin rounded-full h-8 w-8 border-b-2 mx-auto" style="border-color: var(--color-primary); border-bottom-color: transparent"></div>
      </div>

      <div v-else class="rounded-lg shadow p-6" style="background-color: var(--color-surface)">
        <!-- Empresa seleccionada -->
        <div v-if="selectedCompany" class="flex items-center justify-between p-3 border rounded-lg mb-4" :style="{ borderColor: 'var(--color-primary)', backgroundColor: 'var(--color-primary-subtle)' }">
          <div>
            <div class="font-medium" style="color: var(--color-text)">{{ selectedCompany.name }}</div>
            <div class="text-xs" style="color: var(--color-text-muted)">{{ getBusinessTypeSpanish(selectedCompany.business_type) }}</div>
          </div>
          <button type="button" @click="companyId = ''; companySearch = ''; showCompanyList = true" class="text-sm cursor-pointer" style="color: var(--color-primary)">Cambiar</button>
        </div>

        <!-- Input de búsqueda -->
        <template v-else>
          <input
            v-model="companySearch"
            type="text"
            placeholder="Escribí el nombre de tu negocio..."
            @focus="showCompanyList = true"
            class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 mb-4"
            :style="{ borderColor: 'var(--color-border)', '--tw-ring-color': 'var(--color-primary)' }"
          />

          <!-- Lista de resultados -->
          <div v-if="showCompanyList" class="border rounded-lg mb-4" :style="{ borderColor: 'var(--color-border)' }">
            <div v-if="companySearch.length < 2" class="p-3 text-sm" style="color: var(--color-text-muted)">Escribí para buscar tu negocio</div>
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

        <div v-if="error" class="text-sm mb-4" style="color: #dc2626">{{ error }}</div>

        <button
          @click="handleJoin"
          :disabled="!companyId || joining"
          class="w-full text-white py-2 px-4 rounded-lg disabled:opacity-50 cursor-pointer hover:opacity-90"
          :style="{ backgroundColor: 'var(--color-primary)' }"
        >
          {{ joining ? 'Uniendo...' : 'Unirme' }}
        </button>
      </div>
    </template>
  </div>
</template>
