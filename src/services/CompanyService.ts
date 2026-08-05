import { supabase } from '@/supabase/client'
import type { Company, CompanySettings } from '@/types'

export const CompanyService = {
  async getAllActive(): Promise<Company[]> {
    const { data, error } = await supabase
      .from('companies')
      .select('*')
      .eq('active', true)
      .order('name')
    if (error) throw error
    return data
  },

  async getById(id: string): Promise<Company | null> {
    const { data, error } = await supabase
      .from('companies')
      .select('*')
      .eq('id', id)
      .single()
    if (error) throw error
    return data
  },

  async update(id: string, data: Partial<Company>): Promise<Company> {
    const { data: updated, error } = await supabase
      .from('companies')
      .update(data)
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return updated
  },

  async getSettings(companyId: string): Promise<CompanySettings | null> {
    const { data, error } = await supabase
      .from('company_settings')
      .select('*')
      .eq('company_id', companyId)
      .single()
    if (error) throw error
    return data
  },

  async updateSettings(companyId: string, settings: Partial<CompanySettings>): Promise<CompanySettings> {
    const { data, error } = await supabase
      .from('company_settings')
      .update(settings)
      .eq('company_id', companyId)
      .select()
      .single()
    if (error) throw error
    return data
  },

  async uploadLogo(companyId: string, file: File): Promise<string> {
    const fileExt = file.name.split('.').pop()
    const filePath = `${companyId}/logo.${fileExt}`

    const { error: uploadError } = await supabase.storage
      .from('company-logos')
      .upload(filePath, file, { upsert: true })

    if (uploadError) throw uploadError

    const { data } = supabase.storage
      .from('company-logos')
      .getPublicUrl(filePath)

    const publicUrl = data.publicUrl

    await this.updateSettings(companyId, { logo_url: publicUrl })

    return publicUrl
  },

  async deleteLogo(companyId: string): Promise<void> {
    const settings = await this.getSettings(companyId)
    if (!settings?.logo_url) return

    const filePath = settings.logo_url.split('/').slice(-2).join('/')

    const { error } = await supabase.storage
      .from('company-logos')
      .remove([filePath])

    if (error) throw error

    await this.updateSettings(companyId, { logo_url: null })
  },
}
