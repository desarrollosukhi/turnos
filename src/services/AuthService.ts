import { supabase } from '@/supabase/client'
import type { User } from '@/types'
import type { AuthChangeEvent, Session } from '@supabase/supabase-js'

export const AuthService = {
  async login(email: string, password: string) {
    console.log('[AuthService] Login attempt:', email)
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    })
    console.log('[AuthService] Login result:', error ? { error: error.message } : { user: data.user?.id })
    if (error) throw error
    return data
  },

  async register(email: string, password: string, name: string, role: string = 'customer', companyId?: string) {
    console.log('[AuthService] Register attempt:', email, role)
    const metaData: Record<string, string> = { name, role }
    if (companyId) metaData.company_id = companyId

    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: metaData,
      },
    })
    console.log('[AuthService] Register result:', error ? { error: error.message } : { user: data.user?.id })
    if (error) throw error
    return data
  },

  async logout() {
    const { error } = await supabase.auth.signOut()
    if (error) throw error
  },

  async getCurrentUser() {
    const { data: { user }, error } = await supabase.auth.getUser()
    if (error) throw error
    return user
  },

  async getUserProfile(userId: string): Promise<User | null> {
    const { data, error } = await supabase
      .from('users')
      .select('*')
      .eq('id', userId)
      .maybeSingle()
    if (error) throw error
    return data
  },

  async isAdmin(userId: string): Promise<boolean> {
    const { data, error } = await supabase
      .from('users')
      .select('role')
      .eq('id', userId)
      .maybeSingle()
    if (error) throw error
    return data?.role === 'admin'
  },

  onAuthStateChange(callback: (user: any) => void) {
    return supabase.auth.onAuthStateChange((event: AuthChangeEvent, session: Session | null) => {
      callback(session?.user ?? null)
    })
  },
}
