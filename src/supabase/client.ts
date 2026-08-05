import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://rplbavcwifoyqbwhcvyi.supabase.co'
const supabaseKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY || 'sb_publishable_bbWjXWEm1dbPa-vS8OE0xQ_JEJ_eAE7'

export const supabase = createClient(supabaseUrl, supabaseKey)
