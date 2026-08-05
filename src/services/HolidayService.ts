import { supabase } from '@/supabase/client'
import type { Holiday } from '@/types'

export const HolidayService = {
  async getAll(companyId: string): Promise<Holiday[]> {
    const { data, error } = await supabase
      .from('holidays')
      .select('*')
      .eq('company_id', companyId)
      .order('date', { ascending: true })
    if (error) throw error
    return data
  },

  async create(holiday: Omit<Holiday, 'id' | 'created_at' | 'active'>): Promise<Holiday> {
    const { data, error } = await supabase
      .from('holidays')
      .insert({ ...holiday, active: true })
      .select()
      .single()
    if (error) throw error
    return data
  },

  async delete(id: string): Promise<void> {
    const { error } = await supabase
      .from('holidays')
      .delete()
      .eq('id', id)
    if (error) throw error
  },

  async toggleActive(id: string, active: boolean): Promise<void> {
    const { error } = await supabase
      .from('holidays')
      .update({ active })
      .eq('id', id)
    if (error) throw error
  },

  async isHoliday(companyId: string, date: string): Promise<boolean> {
    const { data, error } = await supabase
      .from('holidays')
      .select('id')
      .eq('company_id', companyId)
      .eq('date', date)
      .eq('active', true)
      .limit(1)
    if (error) throw error
    return data && data.length > 0
  },
}
