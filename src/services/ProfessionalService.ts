import { supabase } from '@/supabase/client'
import type { Professional } from '@/types'

function generateTempPassword(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789'
  let password = ''
  for (let i = 0; i < 8; i++) {
    password += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  return password
}

export const ProfessionalService = {
  async getAll(companyId: string): Promise<Professional[]> {
    const { data, error } = await supabase
      .from('professionals')
      .select('*')
      .eq('company_id', companyId)
      .order('name')
    if (error) throw error
    return data
  },

  async getById(id: string): Promise<Professional | null> {
    const { data, error } = await supabase
      .from('professionals')
      .select('*')
      .eq('id', id)
      .single()
    if (error) throw error
    return data
  },

  async getByUserId(userId: string): Promise<Professional | null> {
    const { data, error } = await supabase
      .from('professionals')
      .select('*')
      .eq('user_id', userId)
      .single()
    if (error) throw error
    return data
  },

  async create(professionalData: {
    company_id: string
    name: string
    alias?: string
    email?: string
    phone?: string
    whatsapp?: string
  }): Promise<{ professional: Professional; tempPassword: string }> {
    const tempPassword = generateTempPassword()

    if (professionalData.email) {
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email: professionalData.email,
        password: tempPassword,
        options: {
          data: {
            name: professionalData.name,
            role: 'professional',
            company_id: professionalData.company_id,
          },
        },
      })

      if (authError) throw authError

      const { data: professional, error: professionalError } = await supabase
        .from('professionals')
        .insert({
          ...professionalData,
          user_id: authData.user!.id,
          active: true,
        })
        .select()
        .single()

      if (professionalError) throw professionalError
      return { professional, tempPassword }
    }

    const { data: professional, error: professionalError } = await supabase
      .from('professionals')
      .insert({
        ...professionalData,
        active: true,
      })
      .select()
      .single()

    if (professionalError) throw professionalError
    return { professional, tempPassword: '' }
  },

  async update(id: string, professionalData: Partial<Professional>): Promise<Professional> {
    const { data, error } = await supabase
      .from('professionals')
      .update(professionalData)
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data
  },

  async resetPassword(_userId: string): Promise<string> {
    throw new Error('Función no disponible aún. Requiriere Supabase Edge Function con service_role key.')
  },
}
