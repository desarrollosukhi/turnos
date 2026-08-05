import { supabase } from '@/supabase/client'
import type { ClinicalHistoryField, ClinicalHistoryEntry } from '@/types'

export const ClinicalHistoryService = {
  // Fields (configuración de campos por empresa)
  async getFields(companyId: string): Promise<ClinicalHistoryField[]> {
    const { data, error } = await supabase
      .from('clinical_history_fields')
      .select('*')
      .eq('company_id', companyId)
      .eq('active', true)
      .order('sort_order')
    if (error) throw error
    return data
  },

  async createField(field: Omit<ClinicalHistoryField, 'id' | 'created_at'>): Promise<ClinicalHistoryField> {
    const { data, error } = await supabase
      .from('clinical_history_fields')
      .insert(field)
      .select()
      .single()
    if (error) throw error
    return data
  },

  async deleteField(id: string): Promise<void> {
    const { error } = await supabase
      .from('clinical_history_fields')
      .delete()
      .eq('id', id)
    if (error) throw error
  },

  // Entries (registros de historia clínica)
  async getEntries(userId: string, companyId: string): Promise<ClinicalHistoryEntry[]> {
    const { data, error } = await supabase
      .from('clinical_history_entries')
      .select('*')
      .eq('user_id', userId)
      .eq('company_id', companyId)
      .order('created_at', { ascending: false })
    if (error) throw error
    return data
  },

  async getEntriesByProfessional(professionalId: string): Promise<ClinicalHistoryEntry[]> {
    const { data, error } = await supabase
      .from('clinical_history_entries')
      .select('*')
      .eq('professional_id', professionalId)
      .order('created_at', { ascending: false })
    if (error) throw error
    return data
  },

  async createEntry(entry: Omit<ClinicalHistoryEntry, 'id' | 'created_at' | 'updated_at'>): Promise<ClinicalHistoryEntry> {
    const { data, error } = await supabase
      .from('clinical_history_entries')
      .insert(entry)
      .select()
      .single()
    if (error) throw error
    return data
  },

  async updateEntry(id: string, updates: Partial<ClinicalHistoryEntry>): Promise<ClinicalHistoryEntry> {
    const { data, error } = await supabase
      .from('clinical_history_entries')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data
  },

  async getLatestEntry(userId: string, companyId: string): Promise<ClinicalHistoryEntry | null> {
    const { data, error } = await supabase
      .from('clinical_history_entries')
      .select('*')
      .eq('user_id', userId)
      .eq('company_id', companyId)
      .order('created_at', { ascending: false })
      .limit(1)
      .single()
    if (error && error.code !== 'PGRST116') throw error
    return data
  },
}
