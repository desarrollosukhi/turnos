import { defineStore } from 'pinia'
import { ref } from 'vue'
import { ServiceService } from '@/services/ServiceService'
import type { ServiceWithProfessional } from '@/types'
import { useAuthStore } from './auth'

export const useServiceStore = defineStore('service', () => {
  const services = ref<ServiceWithProfessional[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchServices() {
    const authStore = useAuthStore()
    if (!authStore.companyId) return

    loading.value = true
    error.value = null
    try {
      services.value = await ServiceService.getAll(authStore.companyId)
    } catch (e: any) {
      error.value = e.message || 'Error al cargar servicios'
    } finally {
      loading.value = false
    }
  }

  async function getService(id: string) {
    loading.value = true
    try {
      return await ServiceService.getById(id)
    } catch (e: any) {
      error.value = e.message || 'Error al cargar servicio'
      return null
    } finally {
      loading.value = false
    }
  }

  async function createService(serviceData: Omit<ServiceWithProfessional, 'id' | 'professionals'>) {
    const authStore = useAuthStore()
    if (!authStore.companyId) throw new Error('No hay empresa seleccionada')

    loading.value = true
    error.value = null
    try {
      const newService = await ServiceService.create({
        ...serviceData,
        company_id: authStore.companyId,
      })
      await fetchServices()
      return newService
    } catch (e: any) {
      error.value = e.message || 'Error al crear servicio'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function updateService(id: string, serviceData: Partial<ServiceWithProfessional>) {
    loading.value = true
    error.value = null
    try {
      const updated = await ServiceService.update(id, serviceData)
      await fetchServices()
      return updated
    } catch (e: any) {
      error.value = e.message || 'Error al actualizar servicio'
      throw e
    } finally {
      loading.value = false
    }
  }

  return {
    services,
    loading,
    error,
    fetchServices,
    getService,
    createService,
    updateService,
  }
})
