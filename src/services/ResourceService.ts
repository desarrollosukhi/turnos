import { supabase } from '@/supabase/client'
import type { Resource } from '@/types'

export const ResourceService = {
  async getAll(companyId: string): Promise<Resource[]> {
    const { data, error } = await supabase
      .from('resources')
      .select('*')
      .eq('company_id', companyId)
      .eq('active', true)
      .order('name')
    if (error) throw error
    return data
  },

  async getById(id: string): Promise<Resource | null> {
    const { data, error } = await supabase
      .from('resources')
      .select('*')
      .eq('id', id)
      .single()
    if (error) throw error
    return data
  },

  async create(resourceData: Omit<Resource, 'id'>): Promise<Resource> {
    const { data, error } = await supabase
      .from('resources')
      .insert(resourceData)
      .select()
      .single()
    if (error) throw error
    return data
  },

  async update(id: string, resourceData: Partial<Resource>): Promise<Resource> {
    const { data, error } = await supabase
      .from('resources')
      .update(resourceData)
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data
  },
}
