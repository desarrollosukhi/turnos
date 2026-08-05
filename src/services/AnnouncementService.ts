import { supabase } from '@/supabase/client'
import type { Announcement, AnnouncementWithDetails } from '@/types'

export const AnnouncementService = {
  async getActive(companyId: string, userId?: string): Promise<AnnouncementWithDetails[]> {
    const { data, error } = await supabase
      .rpc('get_active_announcements', {
        p_company_id: companyId,
        p_user_id: userId || null,
      })
    if (error) throw error
    return data || []
  },

  async getByCompany(companyId: string): Promise<AnnouncementWithDetails[]> {
    const { data, error } = await supabase
      .rpc('get_active_announcements', {
        p_company_id: companyId,
        p_user_id: null,
      })
    if (error) throw error
    return data || []
  },

  async create(announcement: Omit<Announcement, 'id' | 'created_at'>): Promise<Announcement> {
    const { data, error } = await supabase
      .from('announcements')
      .insert(announcement)
      .select()
      .single()
    if (error) throw error
    return data
  },

  async update(id: string, announcement: Partial<Announcement>): Promise<Announcement> {
    const { data, error } = await supabase
      .from('announcements')
      .update(announcement)
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data
  },

  async delete(id: string): Promise<void> {
    const { error } = await supabase
      .from('announcements')
      .delete()
      .eq('id', id)
    if (error) throw error
  },
}
