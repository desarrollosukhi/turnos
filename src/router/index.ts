import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/supabase/client'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'landing',
      component: () => import('@/pages/LandingPage.vue'),
      meta: { requiresAuth: false, layout: 'landing' },
    },
    {
      path: '/login',
      name: 'login',
      component: () => import('@/pages/LoginPage.vue'),
      meta: { requiresAuth: false, layout: 'auth' },
    },
    {
      path: '/register',
      name: 'register',
      component: () => import('@/pages/RegisterPage.vue'),
      meta: { requiresAuth: false, layout: 'auth' },
    },
    {
      path: '/home',
      name: 'home',
      component: () => import('@/pages/HomePage.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/services',
      name: 'services',
      component: () => import('@/pages/ServicesPage.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/my-bookings',
      name: 'my-bookings',
      component: () => import('@/pages/MyBookingsPage.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/my-credits',
      name: 'my-credits',
      component: () => import('@/pages/MyCreditsPage.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/my-account',
      name: 'my-account',
      component: () => import('@/pages/MyAccountPage.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/contacts',
      name: 'contacts',
      component: () => import('@/pages/ContactsPage.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/saber-mas',
      name: 'saber-mas',
      component: () => import('@/pages/SaberMasPage.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/admin',
      name: 'admin',
      component: () => import('@/pages/admin/AdminDashboardPage.vue'),
      meta: { requiresAuth: true, requiresAdmin: true, layout: 'admin' },
    },
    {
      path: '/admin/customers',
      name: 'admin-customers',
      component: () => import('@/pages/admin/AdminCustomersPage.vue'),
      meta: { requiresAuth: true, requiresAdmin: true, layout: 'admin' },
    },
    {
      path: '/admin/professionals',
      name: 'admin-professionals',
      component: () => import('@/pages/admin/AdminProfessionalsPage.vue'),
      meta: { requiresAuth: true, requiresAdmin: true, layout: 'admin' },
    },
    {
      path: '/admin/services',
      name: 'admin-services',
      component: () => import('@/pages/admin/AdminServicesPage.vue'),
      meta: { requiresAuth: true, requiresAdmin: true, layout: 'admin' },
    },
    {
      path: '/admin/bookings',
      name: 'admin-bookings',
      component: () => import('@/pages/admin/AdminBookingsPage.vue'),
      meta: { requiresAuth: true, requiresAdmin: true, layout: 'admin' },
    },
    {
      path: '/admin/credits',
      name: 'admin-credits',
      component: () => import('@/pages/admin/AdminCreditsPage.vue'),
      meta: { requiresAuth: true, requiresAdmin: true, layout: 'admin' },
    },
    {
      path: '/admin/settings',
      name: 'admin-settings',
      component: () => import('@/pages/admin/AdminSettingsPage.vue'),
      meta: { requiresAuth: true, requiresAdmin: true, layout: 'admin' },
    },
    {
      path: '/admin/reports',
      name: 'admin-reports',
      component: () => import('@/pages/admin/AdminReportsPage.vue'),
      meta: { requiresAuth: true, requiresAdmin: true, layout: 'admin' },
    },
    {
      path: '/admin/announcements',
      name: 'admin-announcements',
      component: () => import('@/pages/admin/AdminAnnouncementsPage.vue'),
      meta: { requiresAuth: true, requiresAdmin: true, layout: 'admin' },
    },
    {
      path: '/professional',
      name: 'professional',
      component: () => import('@/pages/professional/ProfessionalDashboardPage.vue'),
      meta: { requiresAuth: true, requiresProfessional: true, layout: 'professional' },
    },
    {
      path: '/professional/services',
      name: 'professional-services',
      component: () => import('@/pages/professional/ProfessionalServicesPage.vue'),
      meta: { requiresAuth: true, requiresProfessional: true, layout: 'professional' },
    },
    {
      path: '/professional/bookings',
      name: 'professional-bookings',
      component: () => import('@/pages/professional/ProfessionalBookingsPage.vue'),
      meta: { requiresAuth: true, requiresProfessional: true, layout: 'professional' },
    },
    {
      path: '/changelog',
      name: 'changelog',
      component: () => import('@/pages/ChangelogPage.vue'),
      meta: { requiresAuth: false },
    },
    {
      path: '/book/:companyId',
      name: 'book-company',
      component: () => import('@/pages/GuestBookingPage.vue'),
      meta: { requiresAuth: false },
    },
    {
      path: '/book/service/:serviceId',
      name: 'book-service',
      component: () => import('@/pages/GuestBookingPage.vue'),
      meta: { requiresAuth: false },
    },
    {
      path: '/onboarding',
      name: 'onboarding',
      component: () => import('@/pages/OnboardingPage.vue'),
      meta: { requiresAuth: true, requiresAdmin: true, layout: 'auth' },
    },
    {
      path: '/join-company',
      name: 'join-company',
      component: () => import('@/pages/JoinCompanyPage.vue'),
      meta: { requiresAuth: true, layout: 'auth' },
    },
  ],
})

router.beforeEach(async (to, _from) => {
  const authStore = useAuthStore()

  if (!authStore.user) {
    try {
      const { data: { session } } = await supabase.auth.getSession()
      if (session?.user) {
        await authStore.fetchUser()
      }
    } catch {
      // Ignorar errores de sesión
    }
  }

  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    return { name: 'login' }
  }

  // Logged-in user visiting landing → redirect to their home
  if (to.name === 'landing' && authStore.isAuthenticated) {
    if (authStore.isAdmin && authStore.companyId) return { name: 'admin' }
    if (authStore.isProfessional && authStore.companyId) return { name: 'professional' }
    return { name: 'home' }
  }

  // Admin sin empresa → onboarding
  if (authStore.isAuthenticated && authStore.needsCompanySetup && to.name !== 'onboarding') {
    return { name: 'onboarding' }
  }

  // Customer sin empresa → join-company
  if (authStore.isAuthenticated && authStore.user?.role === 'customer' && !authStore.companyId && to.name !== 'join-company') {
    return { name: 'join-company' }
  }

  // Admin con empresa intentando ir a onboarding → redirigir a admin
  if (authStore.isAuthenticated && authStore.isAdmin && authStore.companyId && to.name === 'onboarding') {
    return { name: 'admin' }
  }

  if (to.meta.requiresAdmin && !authStore.isAdmin) {
    return { name: 'home' }
  } else if (to.meta.requiresProfessional && !authStore.isProfessional) {
    return { name: 'home' }
  } else if (to.name === 'home' && authStore.isAdmin && authStore.companyId) {
    return { name: 'admin' }
  } else if (to.name === 'home' && authStore.isProfessional && authStore.companyId) {
    return { name: 'professional' }
  } else if ((to.name === 'login' || to.name === 'register') && authStore.isAuthenticated) {
    if (authStore.isAdmin && authStore.companyId) return { name: 'admin' }
    if (authStore.isProfessional && authStore.companyId) return { name: 'professional' }
    return { name: 'home' }
  }
})

export default router
