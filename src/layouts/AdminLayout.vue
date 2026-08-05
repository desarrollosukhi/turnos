<script setup lang="ts">
import { RouterView, RouterLink, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { CompanyService } from '@/services/CompanyService'
import { getBusinessLabels } from '@/types'
import { useIsMobile } from '@/composables/useMediaQuery'
import HamburgerButton from '@/components/HamburgerButton.vue'
import AppFooter from '@/components/AppFooter.vue'
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'

const authStore = useAuthStore()
const router = useRouter()
const route = useRoute()
const isMobile = useIsMobile()
const sidebarOpen = ref(false)
const logoUrl = ref<string | null>(null)
const companyName = ref('')
const labels = computed(() => getBusinessLabels(authStore.businessType))
const loggingOut = ref(false)

const menuItems = computed(() => [
  { name: 'Dashboard', to: '/admin', icon: '📊' },
  { name: labels.value.customers, to: '/admin/customers', icon: '👥' },
  { name: labels.value.professionals, to: '/admin/professionals', icon: '🎓' },
  { name: labels.value.services, to: '/admin/services', icon: '🧘' },
  { name: 'Reservas', to: '/admin/bookings', icon: '📋' },
  { name: 'Créditos', to: '/admin/credits', icon: '💰' },
  { name: 'Reportes', to: '/admin/reports', icon: '📈' },
  { name: 'Configuración', to: '/admin/settings', icon: '⚙️' },
])

function isActive(path: string): boolean {
  if (path === '/admin') return route.path === '/admin'
  return route.path.startsWith(path)
}

onMounted(async () => {
  if (authStore.companyId) {
    try {
      const company = await CompanyService.getById(authStore.companyId)
      companyName.value = company?.name || ''
      const settings = await CompanyService.getSettings(authStore.companyId)
      logoUrl.value = settings?.logo_url || null
    } catch (e) { console.error(e) }
  }
})

// Cerrar sidebar al navegar en mobile
watch(() => route.path, () => {
  if (isMobile.value) sidebarOpen.value = false
})

async function handleLogout() {
  loggingOut.value = true
  await authStore.logout()
  router.push('/login')
}
</script>

<template>
  <div class="min-h-screen flex" style="background-color: var(--color-background)">
    <!-- Sidebar desktop -->
    <aside
      v-if="!isMobile"
      class="w-64 shadow-sm sticky top-0 h-screen flex flex-col overflow-y-auto flex-shrink-0"
      style="background-color: var(--color-surface)"
    >
      <div class="p-4 flex-1">
        <router-link to="/admin" class="flex items-center space-x-2 mb-6">
          <img v-if="logoUrl" :src="logoUrl" alt="Logo" class="h-8 w-auto object-contain" />
          <span class="text-lg font-bold" :style="{ color: 'var(--color-text)' }">{{ companyName || 'Admin Panel' }}</span>
        </router-link>
        <nav class="space-y-1">
          <router-link
            v-for="item in menuItems"
            :key="item.to"
            :to="item.to"
            class="nav-item flex items-center px-3 py-2 text-sm font-medium rounded-lg transition-colors cursor-pointer"
            :class="{ 'active': isActive(item.to) }"
            :style="{ color: isActive(item.to) ? 'var(--color-primary)' : 'var(--color-text)' }"
          >
            <span class="mr-3">{{ item.icon }}</span>
            {{ item.name }}
          </router-link>
        </nav>
      </div>
      <div class="p-4" style="border-top: 1px solid var(--color-border)">
        <button
          @click="handleLogout"
          :disabled="loggingOut"
          class="w-full text-left px-3 py-2 text-sm font-medium rounded-lg transition-colors cursor-pointer hover:opacity-80 disabled:opacity-50"
          :style="{ color: 'var(--color-text)' }"
        >
          {{ loggingOut ? 'Cerrando sesión...' : 'Cerrar Sesión' }}
        </button>
      </div>
    </aside>

    <!-- Sidebar mobile overlay -->
    <Teleport to="body">
      <Transition name="fade">
        <div
          v-if="isMobile && sidebarOpen"
          class="fixed inset-0 z-40 bg-black/50"
          @click="sidebarOpen = false"
        ></div>
      </Transition>
    </Teleport>

    <aside
      v-if="isMobile"
      class="fixed inset-y-0 left-0 z-50 w-64 shadow-xl flex flex-col overflow-y-auto transition-transform duration-300"
      :class="sidebarOpen ? 'translate-x-0' : '-translate-x-full'"
      style="background-color: var(--color-surface)"
    >
      <div class="p-4 flex-1">
        <div class="flex items-center justify-between mb-6">
          <router-link to="/admin" class="flex items-center space-x-2">
            <img v-if="logoUrl" :src="logoUrl" alt="Logo" class="h-8 w-auto object-contain" />
            <span class="text-lg font-bold" :style="{ color: 'var(--color-text)' }">{{ companyName || 'Admin Panel' }}</span>
          </router-link>
          <HamburgerButton :open="sidebarOpen" @toggle="sidebarOpen = !sidebarOpen" />
        </div>
        <nav class="space-y-1">
          <router-link
            v-for="item in menuItems"
            :key="item.to"
            :to="item.to"
            class="nav-item flex items-center px-3 py-2 text-sm font-medium rounded-lg transition-colors cursor-pointer"
            :class="{ 'active': isActive(item.to) }"
            :style="{ color: isActive(item.to) ? 'var(--color-primary)' : 'var(--color-text)' }"
          >
            <span class="mr-3">{{ item.icon }}</span>
            {{ item.name }}
          </router-link>
        </nav>
      </div>
      <div class="p-4" style="border-top: 1px solid var(--color-border)">
        <button
          @click="handleLogout"
          :disabled="loggingOut"
          class="w-full text-left px-3 py-2 text-sm font-medium rounded-lg transition-colors cursor-pointer hover:opacity-80 disabled:opacity-50"
          :style="{ color: 'var(--color-text)' }"
        >
          {{ loggingOut ? 'Cerrando sesión...' : 'Cerrar Sesión' }}
        </button>
      </div>
    </aside>

    <!-- Contenido principal -->
    <div class="flex-1 flex flex-col min-w-0">
      <!-- Top bar mobile -->
      <div v-if="isMobile" class="sticky top-0 z-30 flex items-center justify-between px-4 py-3 shadow-sm" style="background-color: var(--color-surface); border-bottom: 1px solid var(--color-border)">
        <HamburgerButton :open="sidebarOpen" @toggle="sidebarOpen = !sidebarOpen" />
        <router-link to="/admin" class="flex items-center space-x-2">
          <img v-if="logoUrl" :src="logoUrl" alt="Logo" class="h-6 w-auto object-contain" />
          <span class="text-sm font-bold" :style="{ color: 'var(--color-text)' }">{{ companyName || 'Admin' }}</span>
        </router-link>
        <div class="w-8"></div>
      </div>
      <main class="flex-1 p-4 md:p-6">
        <RouterView />
      </main>
      <AppFooter />
    </div>
  </div>
</template>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
