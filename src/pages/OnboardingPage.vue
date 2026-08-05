<script setup lang="ts">
import { useAuthStore } from '@/stores/auth'
import { useRouter } from 'vue-router'
import { ref } from 'vue'
import type { BusinessType } from '@/types'

const authStore = useAuthStore()
const router = useRouter()

const form = ref({
  name: '',
  business_type: 'YOGA' as BusinessType,
})

const loading = ref(false)
const error = ref('')

const businessTypes: { value: BusinessType; label: string }[] = [
  { value: 'YOGA', label: 'Yoga' },
  { value: 'GYM', label: 'Gimnasio' },
  { value: 'PILATES', label: 'Pilates' },
  { value: 'HAIRDRESSER', label: 'Peluquería' },
  { value: 'BARBER', label: 'Barbería' },
  { value: 'MEDICAL', label: 'Consultorio' },
  { value: 'CUSTOM', label: 'Otro' },
]

async function handleCreate() {
  loading.value = true
  error.value = ''
  try {
    await authStore.createCompany(form.value.name, form.value.business_type)
    router.push('/admin')
  } catch (e: any) {
    error.value = e.message || 'Error al crear empresa'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="max-w-md mx-auto">
    <div class="text-center mb-8">
      <div class="text-5xl mb-4">🏢</div>
      <h1 class="text-2xl font-bold mb-2" style="color: var(--color-text)">Creá tu negocio</h1>
      <p style="color: var(--color-text-muted)">Configurá tu espacio para empezar a gestionar reservas</p>
    </div>

    <div class="rounded-lg shadow p-6" style="background-color: var(--color-surface)">
      <form @submit.prevent="handleCreate" class="space-y-4">
        <div>
          <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Nombre del negocio</label>
          <input
            v-model="form.name"
            type="text"
            required
            placeholder="Ej: Yoga Studio"
            class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2"
            :style="{ borderColor: 'var(--color-border)', '--tw-ring-color': 'var(--color-primary)' }"
          />
        </div>

        <div>
          <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Tipo de negocio</label>
          <select
            v-model="form.business_type"
            class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2"
            :style="{ borderColor: 'var(--color-border)', '--tw-ring-color': 'var(--color-primary)' }"
          >
            <option v-for="bt in businessTypes" :key="bt.value" :value="bt.value">
              {{ bt.label }}
            </option>
          </select>
        </div>

        <div v-if="error" class="text-sm" style="color: #dc2626">
          {{ error }}
        </div>

        <button
          type="submit"
          :disabled="loading || !form.name.trim()"
          class="w-full py-2 px-4 rounded-lg text-white disabled:opacity-50 cursor-pointer"
          :style="{ backgroundColor: 'var(--color-primary)' }"
        >
          {{ loading ? 'Creando...' : 'Crear negocio' }}
        </button>
      </form>
    </div>
  </div>
</template>
