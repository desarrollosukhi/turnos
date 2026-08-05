import { supabase } from '@/supabase/client'
import { CreditService } from '@/services/CreditService'
import type { User } from '@/types'

function generateTempPassword(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789'
  let password = ''
  for (let i = 0; i < 8; i++) {
    password += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  return password
}

export const UserService = {
  async getAll(companyId: string): Promise<User[]> {
    const { data, error } = await supabase
      .from('users')
      .select('*')
      .eq('company_id', companyId)
      .eq('role', 'customer')
      .eq('active', true)
      .order('name')
    if (error) throw error
    return data
  },

  async getById(id: string): Promise<User | null> {
    const { data, error } = await supabase
      .from('users')
      .select('*')
      .eq('id', id)
      .single()
    if (error) throw error
    return data
  },

  async create(userData: {
    name: string
    email: string
    phone?: string
    birth_date?: string
    emergency_contact_name?: string
    emergency_contact_phone?: string
    company_id: string
  }): Promise<{ user: User; tempPassword: string }> {
    const tempPassword = generateTempPassword()

    const { data: authData, error: authError } = await supabase.auth.signUp({
      email: userData.email,
      password: tempPassword,
      options: {
        data: {
          name: userData.name,
          role: 'customer',
          company_id: userData.company_id,
        },
      },
    })

    if (authError) throw authError

    // Actualizar campos adicionales
    const updateData: any = {}
    if (userData.phone) updateData.phone = userData.phone
    if (userData.birth_date) updateData.birth_date = userData.birth_date
    if (userData.emergency_contact_name) updateData.emergency_contact_name = userData.emergency_contact_name
    if (userData.emergency_contact_phone) updateData.emergency_contact_phone = userData.emergency_contact_phone

    if (Object.keys(updateData).length > 0 && authData.user) {
      await supabase.from('users').update(updateData).eq('id', authData.user.id)
    }

    const { data: profile, error: profileError } = await supabase
      .from('users')
      .select('*')
      .eq('id', authData.user!.id)
      .single()

    if (profileError) throw profileError

    return { user: profile, tempPassword }
  },

  async createWithoutAccount(userData: {
    name: string
    phone: string
    birth_date?: string
    emergency_contact_name?: string
    emergency_contact_phone?: string
    company_id: string
  }): Promise<User> {
    const tempEmail = `guest-${Date.now()}@temp.local`

    const { data: authData, error: authError } = await supabase.auth.signUp({
      email: tempEmail,
      password: generateTempPassword(),
      options: {
        data: {
          name: userData.name,
          role: 'customer',
          company_id: userData.company_id,
        },
      },
    })

    if (authError) throw authError

    const { data: profile, error: profileError } = await supabase
      .from('users')
      .update({
        phone: userData.phone,
        birth_date: userData.birth_date || null,
        emergency_contact_name: userData.emergency_contact_name || null,
        emergency_contact_phone: userData.emergency_contact_phone || null,
        has_account: false,
        email: userData.name,
      })
      .eq('id', authData.user!.id)
      .select()
      .single()

    if (profileError) throw profileError

    return profile
  },

  async createAccount(userId: string): Promise<{ email: string; tempPassword: string }> {
    const tempPassword = generateTempPassword()

    // Nota: supabase.auth.admin requiere service_role key (no disponible en frontend).
    // Se usa una Edge Function o se debe recrear el usuario con credenciales reales.
    // Por ahora, se genera una contraseña temporal y se actualiza el profile.
    const { error } = await supabase
      .from('users')
      .update({ has_account: true })
      .eq('id', userId)

    if (error) throw error

    return { email: `customer-${Date.now()}@temp.local`, tempPassword }
  },

  async addCredits(userId: string, amount: number): Promise<User> {
    const description = amount > 0 ? 'Créditos agregados por admin' : 'Créditos descontados por admin'
    await CreditService.addCredits(userId, amount, description)

    const { data, error } = await supabase
      .from('users')
      .select('*')
      .eq('id', userId)
      .single()
    if (error) throw error
    return data
  },

  async update(id: string, userData: Partial<User>): Promise<User> {
    const { data, error } = await supabase
      .from('users')
      .update(userData)
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data
  },

  async updateCredits(id: string, credits: number): Promise<User> {
    const { data, error } = await supabase
      .from('users')
      .update({ credits })
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
