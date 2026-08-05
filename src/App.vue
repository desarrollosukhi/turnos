<script setup lang="ts">
import { RouterView, useRoute } from 'vue-router'
import { computed, watch } from 'vue'
import DefaultLayout from '@/layouts/DefaultLayout.vue'
import AdminLayout from '@/layouts/AdminLayout.vue'
import AuthLayout from '@/layouts/AuthLayout.vue'
import ProfessionalLayout from '@/layouts/ProfessionalLayout.vue'
import { useTheme } from '@/composables/useTheme'
import { useAuthStore } from '@/stores/auth'

const route = useRoute()
const authStore = useAuthStore()
useTheme()

const layout = computed(() => {
  const layoutName = route.meta.layout as string
  if (layoutName === 'admin') return AdminLayout
  if (layoutName === 'auth') return AuthLayout
  if (layoutName === 'professional') return ProfessionalLayout
  return DefaultLayout
})

// Actualizar título dinámicamente
watch(() => authStore.company?.name, (newName) => {
  document.title = newName ? `${newName} — Reservas` : 'Reservas'
}, { immediate: true })

// Actualizar favicon dinámicamente
watch(() => authStore.companySettings?.logo_url, (newUrl) => {
  if (newUrl) {
    const link = document.querySelector("link[rel='icon']") as HTMLLinkElement
    if (link) link.href = newUrl
  }
}, { immediate: true })
</script>

<template>
  <component :is="layout">
    <RouterView />
  </component>
</template>
