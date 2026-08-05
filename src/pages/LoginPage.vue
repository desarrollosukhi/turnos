<script setup lang="ts">
import { useAuthStore } from '@/stores/auth'
import { useRouter } from 'vue-router'
import { ref } from 'vue'

const authStore = useAuthStore()
const router = useRouter()
const email = ref('')
const password = ref('')
const loading = ref(false)
const error = ref('')

async function handleLogin() {
  loading.value = true
  error.value = ''
  try {
    await authStore.login(email.value, password.value)
    router.push('/')
  } catch (e: any) {
    if (e.message?.includes('Email not confirmed')) {
      error.value = 'Tu email no fue confirmado. Revisá tu casilla de correo y hacé clic en el link de confirmación.'
    } else {
      error.value = e.message || 'Error al iniciar sesión'
    }
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="rounded-lg shadow p-6" style="background-color: var(--color-surface)">
    <h2 class="text-2xl font-bold text-center mb-6" style="color: var(--color-text)">Iniciar Sesión</h2>
    <form @submit.prevent="handleLogin" class="space-y-4">
      <div>
        <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Email</label>
        <input v-model="email" type="email" required class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2" :style="{ borderColor: 'var(--color-border)', '--tw-ring-color': 'var(--color-primary)' }" />
      </div>
      <div>
        <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Contraseña</label>
        <input v-model="password" type="password" required class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2" :style="{ borderColor: 'var(--color-border)', '--tw-ring-color': 'var(--color-primary)' }" />
      </div>
      <div v-if="error" class="text-sm" style="color: #dc2626">{{ error }}</div>
      <button type="submit" :disabled="loading" class="w-full text-white py-2 px-4 rounded-lg disabled:opacity-50 cursor-pointer hover:opacity-90" :style="{ backgroundColor: 'var(--color-primary)' }">{{ loading ? 'Ingresando...' : 'Ingresar' }}</button>
    </form>
    <p class="mt-4 text-center text-sm" style="color: var(--color-text-muted)">¿No tenés cuenta? <router-link to="/register" :style="{ color: 'var(--color-primary)' }" class="hover:underline">Registrate</router-link></p>
  </div>
</template>
