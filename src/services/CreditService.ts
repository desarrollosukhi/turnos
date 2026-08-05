import { supabase } from '@/supabase/client'
import type { CreditMovement } from '@/types'

export const CreditService = {
  async getBalance(userId: string): Promise<number> {
    const { data, error } = await supabase
      .rpc('get_effective_credits', { p_user_id: userId })
    if (error) throw error
    return data
  },

  async getExpiringCredits(userId: string): Promise<number> {
    const { data, error } = await supabase
      .rpc('get_expiring_credits', { p_user_id: userId })
    if (error) throw error
    return data
  },

  async getMovements(userId: string): Promise<CreditMovement[]> {
    const { data, error } = await supabase
      .from('credit_movements')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
    if (error) throw error
    return data
  },

  async addCredits(userId: string, amount: number, description: string): Promise<string> {
    const { data, error } = await supabase
      .rpc('add_credits', {
        p_user_id: userId,
        p_amount: amount,
        p_description: description,
      })
    if (error) throw error
    return data
  },

  async deductCredits(userId: string, amount: number, description: string): Promise<string> {
    const { data, error } = await supabase
      .rpc('add_credits', {
        p_user_id: userId,
        p_amount: -amount,
        p_description: description,
      })
    if (error) throw error
    return data
  },
}
