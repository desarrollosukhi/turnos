import { supabase } from '@/supabase/client'
import type { Service, ServiceWithProfessional } from '@/types'

export const ServiceService = {
  async getAll(companyId: string): Promise<ServiceWithProfessional[]> {
    const { data, error } = await supabase
      .from('services')
      .select('*, professionals(*)')
      .eq('company_id', companyId)
      .eq('active', true)
      .order('day_of_week')
      .order('start_time')
    if (error) throw error
    return data
  },

  async getByProfessionalId(professionalId: string): Promise<ServiceWithProfessional[]> {
    const { data, error } = await supabase
      .from('services')
      .select('*, professionals(*)')
      .eq('professional_id', professionalId)
      .eq('active', true)
      .order('day_of_week')
      .order('start_time')
    if (error) throw error
    return data
  },

  async getById(id: string): Promise<ServiceWithProfessional | null> {
    const { data, error } = await supabase
      .from('services')
      .select('*, professionals(*)')
      .eq('id', id)
      .single()
    if (error) throw error
    return data
  },

  async create(serviceData: Omit<Service, 'id'>): Promise<Service> {
    const { data, error } = await supabase
      .from('services')
      .insert(serviceData)
      .select()
      .single()
    if (error) throw error
    return data
  },

  async update(id: string, serviceData: Partial<Service>): Promise<Service> {
    const { data, error } = await supabase
      .from('services')
      .update(serviceData)
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data
  },

  async getAvailability(serviceId: string, date: string) {
    const { data, error } = await supabase
      .rpc('get_class_availability', {
        p_class_id: serviceId,
        p_date: date,
      })
    if (error) throw error
    return data
  },

  async getAppointmentSlots(serviceId: string, date: string) {
    const { data, error } = await supabase
      .rpc('get_appointment_slots', {
        p_service_id: serviceId,
        p_date: date,
      })
    if (error) throw error
    return data
  },

  async getEventDates(companyId: string, startDate: string, endDate: string) {
    const { data, error } = await supabase
      .rpc('get_event_dates', {
        p_company_id: companyId,
        p_start_date: startDate,
        p_end_date: endDate,
      })
    if (error) throw error
    return data
  },
}
