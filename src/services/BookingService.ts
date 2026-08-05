import { supabase } from '@/supabase/client'
import type { Booking, BookingWithDetails, ModalidadType, BookingWindow, CancelledServiceSessionWithService } from '@/types'

export const BookingService = {
  async getByUser(userId: string): Promise<BookingWithDetails[]> {
    const { data, error } = await supabase
      .from('bookings')
      .select('*, services(*, professionals(*))')
      .eq('user_id', userId)
      .order('date', { ascending: false })
    if (error) throw error
    return data
  },

  async getByService(serviceId: string, date: string): Promise<BookingWithDetails[]> {
    const { data, error } = await supabase
      .from('bookings')
      .select('*, services(*, professionals(*)), users(*)')
      .eq('service_id', serviceId)
      .eq('date', date)
      .order('created_at')
    if (error) throw error
    return data
  },

  async getAll(): Promise<BookingWithDetails[]> {
    const { data, error } = await supabase
      .from('bookings')
      .select('*, services(*, professionals(*)), users(*)')
      .order('date', { ascending: false })
    if (error) throw error
    return data
  },

  async create(serviceId: string, date: string, modality: ModalidadType): Promise<string> {
    const { data, error } = await supabase
      .rpc('book_service', {
        p_service_id: serviceId,
        p_date: date,
        p_modality: modality,
      })
    if (error) throw error
    return data
  },

  async cancel(bookingId: string): Promise<string> {
    const { data, error } = await supabase
      .rpc('cancel_booking', {
        p_booking_id: bookingId,
      })
    if (error) throw error
    return data
  },

  async adminCancel(bookingId: string): Promise<string> {
    const { data, error } = await supabase
      .rpc('admin_cancel_booking', {
        p_booking_id: bookingId,
      })
    if (error) throw error
    return data
  },

  async markAttendance(bookingId: string, status: 'attended' | 'no_show'): Promise<string> {
    const { data, error } = await supabase
      .rpc('mark_attendance', {
        p_booking_id: bookingId,
        p_estado: status,
      })
    if (error) throw error
    return data
  },

  async checkWindow(serviceId: string, date: string, companyId: string): Promise<BookingWindow> {
    const { data, error } = await supabase
      .rpc('check_booking_window', {
        p_service_id: serviceId,
        p_date: date,
        p_company_id: companyId,
      })
    if (error) throw error
    return data[0]
  },

  async cancelServiceSession(serviceId: string, date: string, reason?: string): Promise<string> {
    const { data, error } = await supabase
      .rpc('cancel_service_session', {
        p_service_id: serviceId,
        p_date: date,
        p_reason: reason || null,
      })
    if (error) throw error
    return data
  },

  async isSessionCancelled(serviceId: string, date: string): Promise<boolean> {
    const { data, error } = await supabase
      .rpc('is_service_session_cancelled', {
        p_service_id: serviceId,
        p_date: date,
      })
    if (error) throw error
    return data
  },
}
