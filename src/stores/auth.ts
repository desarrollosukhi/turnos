import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { AuthService } from '@/services/AuthService'
import { CompanyService } from '@/services/CompanyService'
import { supabase } from '@/supabase/client'
import type { User, Company, CompanySettings } from '@/types'

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const company = ref<Company | null>(null)
  const companySettings = ref<CompanySettings | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  const isAuthenticated = computed(() => !!user.value)
  const isAdmin = computed(() => user.value?.role === 'admin')
  const isProfessional = computed(() => user.value?.role === 'professional')
  const isSuperAdmin = computed(() => user.value?.role === 'super_admin')
  const companyId = computed(() => user.value?.company_id ?? '')
  const needsCompanySetup = computed(() => isAdmin.value && !user.value?.company_id)
  const businessType = computed(() => company.value?.business_type ?? 'CUSTOM')
  const customerMode = computed(() => companySettings.value?.customer_mode ?? 'MEMBER')
  const bookingMode = computed(() => companySettings.value?.booking_mode ?? 'CLASS')

  async function login(email: string, password: string) {
    loading.value = true
    error.value = null
    try {
      const authUser = await AuthService.login(email, password)
      if (authUser.user) {
        const profile = await AuthService.getUserProfile(authUser.user.id)
        user.value = profile
        if (profile?.company_id) {
          company.value = await CompanyService.getById(profile.company_id)
          companySettings.value = await CompanyService.getSettings(profile.company_id)
        }
      }
    } catch (e: any) {
      error.value = e.message || 'Error al iniciar sesión'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function register(email: string, password: string, name: string, role: string = 'customer', companyId?: string) {
    loading.value = true
    error.value = null
    try {
      const authUser = await AuthService.register(email, password, name, role, companyId)
      if (authUser.user) {
        // Verificar que la sesión esté establecida
        const { data: { session } } = await supabase.auth.getSession()
        if (!session) {
          await new Promise(r => setTimeout(r, 1000))
        }

        const profile = await AuthService.getUserProfile(authUser.user.id)
        user.value = profile
        if (profile?.company_id) {
          company.value = await CompanyService.getById(profile.company_id)
          companySettings.value = await CompanyService.getSettings(profile.company_id)
        }
      }
    } catch (e: any) {
      error.value = e.message || 'Error al registrarse'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function logout() {
    await AuthService.logout()
    user.value = null
    company.value = null
    companySettings.value = null
  }

  async function fetchUser() {
    try {
      const authUser = await AuthService.getCurrentUser()
      if (authUser) {
        const profile = await AuthService.getUserProfile(authUser.id)
        user.value = profile
        if (profile?.company_id) {
          company.value = await CompanyService.getById(profile.company_id)
          companySettings.value = await CompanyService.getSettings(profile.company_id)
        }
      }
    } catch {
      user.value = null
      company.value = null
      companySettings.value = null
    }
  }

  async function createCompany(name: string, businessType: string = 'YOGA') {
    const { data, error } = await supabase.rpc('create_company_for_user', {
      p_name: name,
      p_business_type: businessType,
    })
    if (error) throw error
    await fetchUser()
    return data
  }

  function init() {
    AuthService.onAuthStateChange((authUser) => {
      if (authUser) {
        fetchUser()
      } else {
        user.value = null
        company.value = null
        companySettings.value = null
      }
    })
  }

  return {
    user,
    company,
    companySettings,
    loading,
    error,
    isAuthenticated,
    isAdmin,
    isProfessional,
    isSuperAdmin,
    companyId,
    needsCompanySetup,
    businessType,
    customerMode,
    bookingMode,
    login,
    register,
    logout,
    fetchUser,
    createCompany,
    init,
  }
})
