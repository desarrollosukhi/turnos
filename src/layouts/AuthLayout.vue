<script setup lang="ts">
import { RouterView } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { CompanyService } from '@/services/CompanyService'
import { ref, onMounted } from 'vue'

const authStore = useAuthStore()
const logoUrl = ref<string | null>(null)

onMounted(async () => {
  if (authStore.companyId) {
    try {
      const settings = await CompanyService.getSettings(authStore.companyId)
      logoUrl.value = settings?.logo_url || null
    } catch (e) { console.error(e) }
  }
})
</script>

<template>
  <div class="min-h-screen flex items-center justify-center" style="background-color: var(--color-background)">
    <div class="w-full max-w-md">
      <div v-if="logoUrl" class="text-center mb-6">
        <img :src="logoUrl" alt="Logo" class="h-16 w-auto object-contain mx-auto" />
      </div>
      <RouterView />
    </div>
  </div>
</template>
