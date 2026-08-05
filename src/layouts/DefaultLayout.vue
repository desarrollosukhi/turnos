<script setup lang="ts">
import { RouterView, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { getBusinessLabels } from '@/types'
import { useIsMobile } from '@/composables/useMediaQuery'
import BottomBar from '@/components/BottomBar.vue'
import AppFooter from '@/components/AppFooter.vue'
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'

const authStore = useAuthStore()
const router = useRouter()
const route = useRoute()
const isMobile = useIsMobile()
const labels = computed(() => getBusinessLabels(authStore.businessType))
const loggingOut = ref(false)
const showMoreMenu = ref(false)

const logoUrl = computed(() => authStore.companySettings?.logo_url || null)
const companyName = computed(() => authStore.company?.name || '')

function isActive(path: string): boolean {
  if (path === '/') return route.path === '/'
  return route.path.startsWith(path)
}

// Bottom bar items para mobile
const bottomBarItems = computed(() => [
  { icon: 'calendar', label: labels.value.services, to: '/services', active: isActive('/services') },
  { icon: 'wallet', label: 'Créditos', to: '/my-credits', active: isActive('/my-credits') },
  { icon: 'home', label: 'Inicio', to: '/', active: isActive('/') },
  { icon: 'user', label: 'Cuenta', to: '/my-account', active: isActive('/my-account') },
  { icon: 'more', label: 'Más', to: '', active: false, isMore: true },
])

function handleMore() {
  showMoreMenu.value = !showMoreMenu.value
}

function closeMoreMenu() {
  showMoreMenu.value = false
}

async function handleLogout() {
  loggingOut.value = true
  showMoreMenu.value = false
  await authStore.logout()
  router.push('/login')
}
</script>

<template>
  <div class="min-h-screen flex flex-col" style="background-color: var(--color-background)">
    <!-- Navbar desktop -->
    <nav v-if="!isMobile" style="background-color: var(--color-surface); border-bottom: 1px solid var(--color-border)">
      <div class="px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
          <div class="flex items-center">
            <router-link to="/" class="flex items-center space-x-2">
              <img v-if="logoUrl" :src="logoUrl" alt="Logo" class="h-8 w-auto object-contain" />
              <span class="text-xl font-bold" :style="{ color: 'var(--color-text)' }">{{ companyName || 'Reservas' }}</span>
            </router-link>
          </div>
          <div class="flex items-center space-x-1 overflow-x-auto whitespace-nowrap">
            <router-link v-if="authStore.isAuthenticated && !authStore.isAdmin && !authStore.isProfessional" to="/"
              class="nav-link px-3 py-2 text-sm font-medium rounded-lg transition-colors"
              :class="{ 'active': isActive('/') }"
              :style="{ color: isActive('/') ? 'var(--color-primary)' : 'var(--color-text)' }">Inicio</router-link>
            <router-link v-if="authStore.isAuthenticated && !authStore.isAdmin && !authStore.isProfessional" to="/services"
              class="nav-link px-3 py-2 text-sm font-medium rounded-lg transition-colors"
              :class="{ 'active': isActive('/services') }"
              :style="{ color: isActive('/services') ? 'var(--color-primary)' : 'var(--color-text)' }">{{ labels.services }}</router-link>
            <router-link v-if="authStore.isAuthenticated && !authStore.isAdmin && !authStore.isProfessional" to="/my-bookings"
              class="nav-link px-3 py-2 text-sm font-medium rounded-lg transition-colors"
              :class="{ 'active': isActive('/my-bookings') }"
              :style="{ color: isActive('/my-bookings') ? 'var(--color-primary)' : 'var(--color-text)' }">Mis Reservas</router-link>
            <router-link v-if="authStore.isAuthenticated && !authStore.isAdmin && !authStore.isProfessional" to="/my-credits"
              class="nav-link px-3 py-2 text-sm font-medium rounded-lg transition-colors"
              :class="{ 'active': isActive('/my-credits') }"
              :style="{ color: isActive('/my-credits') ? 'var(--color-primary)' : 'var(--color-text)' }">Mis Créditos</router-link>
            <router-link v-if="authStore.isAuthenticated && !authStore.isAdmin && !authStore.isProfessional" to="/my-account"
              class="nav-link px-3 py-2 text-sm font-medium rounded-lg transition-colors"
              :class="{ 'active': isActive('/my-account') }"
              :style="{ color: isActive('/my-account') ? 'var(--color-primary)' : 'var(--color-text)' }">Mi Cuenta</router-link>
            <router-link v-if="authStore.isAuthenticated && !authStore.isAdmin && !authStore.isProfessional" to="/contacts"
              class="nav-link px-3 py-2 text-sm font-medium rounded-lg transition-colors"
              :class="{ 'active': isActive('/contacts') }"
              :style="{ color: isActive('/contacts') ? 'var(--color-primary)' : 'var(--color-text)' }">Contactos</router-link>
            <router-link v-if="authStore.isAdmin && authStore.companyId" to="/admin"
              class="nav-link px-3 py-2 text-sm font-medium rounded-lg transition-colors"
              :class="{ 'active': isActive('/admin') }"
              :style="{ color: isActive('/admin') ? 'var(--color-primary)' : 'var(--color-text)' }">Admin</router-link>
            <router-link v-if="authStore.isProfessional && authStore.companyId" to="/professional"
              class="nav-link px-3 py-2 text-sm font-medium rounded-lg transition-colors"
              :class="{ 'active': isActive('/professional') }"
              :style="{ color: isActive('/professional') ? 'var(--color-primary)' : 'var(--color-text)' }">Portal</router-link>
            <button v-if="authStore.isAuthenticated" @click="handleLogout" :disabled="loggingOut" class="nav-link px-3 py-2 text-sm font-medium rounded-lg transition-colors hover:opacity-80 disabled:opacity-50 cursor-pointer" :style="{ color: 'var(--color-text)' }">{{ loggingOut ? 'Saliendo...' : 'Salir' }}</button>
          </div>
        </div>
      </div>
    </nav>

    <!-- Navbar mobile: solo logo + nombre -->
    <nav v-if="isMobile" class="sticky top-0 z-30" style="background-color: var(--color-surface); border-bottom: 1px solid var(--color-border)">
      <div class="flex items-center justify-center px-4 h-14">
        <router-link to="/" class="flex items-center space-x-2">
          <img v-if="logoUrl" :src="logoUrl" alt="Logo" class="h-6 w-auto object-contain" />
          <span class="text-sm font-bold" :style="{ color: 'var(--color-text)' }">{{ companyName || 'Reservas' }}</span>
        </router-link>
      </div>
    </nav>

    <!-- Contenido principal -->
    <main class="flex-1 py-6 px-4 sm:px-6 lg:px-8" :class="isMobile ? 'pb-20' : ''">
      <RouterView />
    </main>

    <!-- Footer solo en desktop -->
    <AppFooter v-if="!isMobile" />

    <!-- Bottom bar mobile -->
    <BottomBar
      v-if="isMobile && authStore.isAuthenticated && !authStore.isAdmin && !authStore.isProfessional"
      :items="bottomBarItems"
      @more="handleMore"
    />

    <!-- Menú popup de "Más" -->
    <Transition name="popup">
      <div v-if="showMoreMenu" class="fixed bottom-20 right-4 z-50 rounded-xl shadow-xl p-2 min-w-[180px] md:hidden" style="background-color: var(--color-surface); border: 1px solid var(--color-border)">
        <router-link to="/contacts" @click="closeMoreMenu" class="flex items-center px-3 py-2.5 text-sm rounded-lg transition-colors hover:opacity-80" :style="{ color: 'var(--color-text)' }">
          <span class="mr-2">📞</span> Contactos
        </router-link>
        <router-link to="/saber-mas" @click="closeMoreMenu" class="flex items-center px-3 py-2.5 text-sm rounded-lg transition-colors hover:opacity-80" :style="{ color: 'var(--color-text)' }">
          <span class="mr-2">ℹ️</span> Saber más
        </router-link>
        <div class="border-t my-1" style="border-color: var(--color-border)"></div>
        <button v-if="authStore.isAuthenticated" @click="handleLogout" class="w-full text-left flex items-center px-3 py-2.5 text-sm rounded-lg transition-colors cursor-pointer hover:opacity-80" :style="{ color: 'var(--color-text)' }">
          <span class="mr-2">🚪</span> {{ loggingOut ? 'Cerrando...' : 'Salir' }}
        </button>
      </div>
    </Transition>

    <!-- Overlay para cerrar menú -->
    <div v-if="showMoreMenu" class="fixed inset-0 z-40 md:hidden" @click="closeMoreMenu"></div>

    <!-- Menú popup de "Más" -->
    <Transition name="popup">
      <div v-if="showMoreMenu" class="fixed bottom-20 right-4 z-50 rounded-xl shadow-xl p-2 min-w-[200px] md:hidden" style="background-color: var(--color-surface); border: 1px solid var(--color-border)">
        <router-link to="/contacts" @click="closeMoreMenu" class="flex items-center px-3 py-2.5 text-sm rounded-lg transition-colors hover:opacity-80" :style="{ color: 'var(--color-text)' }">
          <span class="mr-2">📞</span> Contactos
        </router-link>
        <router-link to="/saber-mas" @click="closeMoreMenu" class="flex items-center px-3 py-2.5 text-sm rounded-lg transition-colors hover:opacity-80" :style="{ color: 'var(--color-text)' }">
          <span class="mr-2">ℹ️</span> Saber más
        </router-link>
        <div class="border-t my-1" style="border-color: var(--color-border)"></div>
        <button v-if="authStore.isAuthenticated" @click="handleLogout" class="w-full text-left flex items-center px-3 py-2.5 text-sm rounded-lg transition-colors cursor-pointer hover:opacity-80" :style="{ color: 'var(--color-text)' }">
          <span class="mr-2">🚪</span> {{ loggingOut ? 'Cerrando...' : 'Salir' }}
        </button>
      </div>
    </Transition>
  </div>
</template>

<style scoped>
.popup-enter-active {
  transition: all 0.2s ease-out;
}
.popup-leave-active {
  transition: all 0.15s ease-in;
}
.popup-enter-from,
.popup-leave-to {
  opacity: 0;
  transform: translateY(10px);
}
</style>
