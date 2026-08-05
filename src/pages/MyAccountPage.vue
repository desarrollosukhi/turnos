<script setup lang="ts">
import { useAuthStore } from '@/stores/auth'
import { UserService } from '@/services/UserService'
import ToastMessage from '@/components/ToastMessage.vue'
import SkeletonCard from '@/components/SkeletonCard.vue'
import { ref, onMounted } from 'vue'

const authStore = useAuthStore()

const form = ref({
  name: '',
  phone: '',
  birth_date: '',
  emergency_contact_name: '',
  emergency_contact_phone: '',
})

const loading = ref(true)
const saving = ref(false)
const error = ref('')
const showToast = ref(false)
const toastMessage = ref('')
const toastType = ref<'success' | 'error' | 'info'>('success')

onMounted(() => {
  if (authStore.user) {
    form.value = {
      name: authStore.user.name || '',
      phone: authStore.user.phone || '',
      birth_date: authStore.user.birth_date || '',
      emergency_contact_name: authStore.user.emergency_contact_name || '',
      emergency_contact_phone: authStore.user.emergency_contact_phone || '',
    }
  }
  loading.value = false
})

async function handleSave() {
  if (!authStore.user) return
  saving.value = true
  error.value = ''
  try {
    await UserService.update(authStore.user.id, {
      name: form.value.name,
      phone: form.value.phone || undefined,
      birth_date: form.value.birth_date || undefined,
      emergency_contact_name: form.value.emergency_contact_name || undefined,
      emergency_contact_phone: form.value.emergency_contact_phone || undefined,
    } as any)
    await authStore.fetchUser()
    toastMessage.value = 'Perfil actualizado'
    toastType.value = 'success'
    showToast.value = true
  } catch (e: any) {
    error.value = e.message || 'Error al guardar'
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div class="max-w-xl mx-auto">
    <ToastMessage :show="showToast" :message="toastMessage" :type="toastType" @close="showToast = false" />

    <h1 class="text-2xl font-bold mb-6" style="color: var(--color-text)">Mi Cuenta</h1>

    <SkeletonCard v-if="loading" :count="1" :lines="6" />

    <div v-else class="rounded-lg shadow p-6" style="background-color: var(--color-surface)">
      <form @submit.prevent="handleSave" class="space-y-4">
        <div>
          <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Nombre</label>
          <input
            v-model="form.name"
            type="text"
            required
            class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2"
            :style="{ borderColor: 'var(--color-border)', '--tw-ring-color': 'var(--color-primary)' }"
          />
        </div>

        <div>
          <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Email</label>
          <input
            :value="authStore.user?.email"
            type="email"
            disabled
            class="w-full px-3 py-2 border rounded-lg opacity-60 cursor-not-allowed"
            :style="{ borderColor: 'var(--color-border)' }"
          />
          <p class="text-xs mt-1" style="color: var(--color-text-muted)">El email no se puede cambiar desde aquí</p>
        </div>

        <div>
          <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Teléfono</label>
          <input
            v-model="form.phone"
            type="tel"
            class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2"
            :style="{ borderColor: 'var(--color-border)', '--tw-ring-color': 'var(--color-primary)' }"
          />
        </div>

        <div>
          <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Fecha de nacimiento</label>
          <input
            v-model="form.birth_date"
            type="date"
            class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2"
            :style="{ borderColor: 'var(--color-border)', '--tw-ring-color': 'var(--color-primary)' }"
          />
        </div>

        <div class="pt-4" style="border-top: 1px solid var(--color-border)">
          <h3 class="text-sm font-semibold mb-3" style="color: var(--color-text)">Contacto de emergencia</h3>
        </div>

        <div>
          <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Nombre</label>
          <input
            v-model="form.emergency_contact_name"
            type="text"
            class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2"
            :style="{ borderColor: 'var(--color-border)', '--tw-ring-color': 'var(--color-primary)' }"
          />
        </div>

        <div>
          <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Teléfono</label>
          <input
            v-model="form.emergency_contact_phone"
            type="tel"
            class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2"
            :style="{ borderColor: 'var(--color-border)', '--tw-ring-color': 'var(--color-primary)' }"
          />
        </div>

        <div v-if="error" class="text-sm" style="color: #dc2626">{{ error }}</div>

        <button
          type="submit"
          :disabled="saving"
          class="w-full text-white py-2 px-4 rounded-lg disabled:opacity-50 cursor-pointer hover:opacity-90"
          :style="{ backgroundColor: 'var(--color-primary)' }"
        >
          {{ saving ? 'Guardando...' : 'Guardar cambios' }}
        </button>
      </form>
    </div>
  </div>
</template>
