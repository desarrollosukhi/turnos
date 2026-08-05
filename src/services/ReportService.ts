import { supabase } from '@/supabase/client'
import type {
  ReportBookingsByProfessional,
  ReportOccupancy,
  ReportCreditConsumption,
  ReportAttendanceRate,
  ReportCustomerGrowth,
  ReportServicePopularity,
  ReportCancellation,
  ReportMyBookings,
} from '@/types'

export const ReportService = {
  async bookingsByProfessional(companyId: string, startDate: string, endDate: string): Promise<ReportBookingsByProfessional[]> {
    const { data, error } = await supabase.rpc('report_bookings_by_professional', {
      p_company_id: companyId,
      p_start_date: startDate,
      p_end_date: endDate,
    })
    if (error) throw error
    return data
  },

  async occupancy(companyId: string, startDate: string, endDate: string): Promise<ReportOccupancy[]> {
    const { data, error } = await supabase.rpc('report_occupancy', {
      p_company_id: companyId,
      p_start_date: startDate,
      p_end_date: endDate,
    })
    if (error) throw error
    return data
  },

  async creditConsumption(companyId: string, startDate: string, endDate: string): Promise<ReportCreditConsumption[]> {
    const { data, error } = await supabase.rpc('report_credit_consumption', {
      p_company_id: companyId,
      p_start_date: startDate,
      p_end_date: endDate,
    })
    if (error) throw error
    return data
  },

  async attendanceRate(companyId: string, startDate: string, endDate: string, professionalId?: string): Promise<ReportAttendanceRate[]> {
    const { data, error } = await supabase.rpc('report_attendance_rate', {
      p_company_id: companyId,
      p_start_date: startDate,
      p_end_date: endDate,
      p_professional_id: professionalId || null,
    })
    if (error) throw error
    return data
  },

  async customerGrowth(companyId: string, startDate: string, endDate: string): Promise<ReportCustomerGrowth[]> {
    const { data, error } = await supabase.rpc('report_customer_growth', {
      p_company_id: companyId,
      p_start_date: startDate,
      p_end_date: endDate,
    })
    if (error) throw error
    return data
  },

  async servicePopularity(companyId: string, startDate: string, endDate: string): Promise<ReportServicePopularity[]> {
    const { data, error } = await supabase.rpc('report_service_popularity', {
      p_company_id: companyId,
      p_start_date: startDate,
      p_end_date: endDate,
    })
    if (error) throw error
    return data
  },

  async cancellations(companyId: string, startDate: string, endDate: string): Promise<ReportCancellation[]> {
    const { data, error } = await supabase.rpc('report_cancellations', {
      p_company_id: companyId,
      p_start_date: startDate,
      p_end_date: endDate,
    })
    if (error) throw error
    return data
  },

  async myBookings(userId: string, startDate: string, endDate: string): Promise<ReportMyBookings[]> {
    const { data, error } = await supabase.rpc('report_my_bookings', {
      p_user_id: userId,
      p_start_date: startDate,
      p_end_date: endDate,
    })
    if (error) throw error
    return data
  },
}
