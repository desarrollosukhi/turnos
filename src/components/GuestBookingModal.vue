<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { supabase } from '@/supabase/client'

const props = defineProps<{
  show: boolean
  service: any
  companyId: string
  selectedDate: string
  initialModality: 'in_person' | 'virtual'
}>()

const emit = defineEmits<{
  close: []
}>()

const name = ref('')
const phone = ref('')
const email = ref('')
const modality = ref<'in_person' | 'virtual'>(props.initialModality)
const loading = ref(false)
const error = ref('')
const confirmed = ref(false)

const company = ref<any>(null)

onMounted(async () => {
  if (props.companyId) {
    const { data } = await supabase.from('companies').select('name').eq('id', props.companyId).single()
    company.value = data
  }
})

async function handleConfirm() {
  if (!name.value || !phone.value) { error.value = 'Nombre y teléfono son requeridos'; return }
  loading.value = true
  error.value = ''
  try {
    const { data, error: rpcError } = await supabase.rpc('book_service_guest', {
      p_service_id: props.service.id,
      p_date: props.selectedDate,
      p_modality: modality.value,
      p_guest_name: name.value,
      p_guest_phone: phone.value,
      p_guest_email: email.value || null,
    })
    if (rpcError) throw rpcError
    confirmed.value = true
  } catch (e: any) { error.value = e.message || 'Error al crear reserva' }
  finally { loading.value = false }
}

const whatsappUrl = computed(() => {
  if (!company.value || !props.service) return null
  const msg = encodeURIComponent(`Reserva confirmada:\n${props.service.name}\n${props.selectedDate} ${props.service.start_time}\nCliente: ${name.value} - ${phone.value}`)
  return `https://wa.me/${company.value.whatsapp || ''}?text=${msg}`
})
</script>

<template>
  <Teleport to="body">
    <div v-if="show" class="fixed inset-0 z-50 flex items-center justify-center">
      <div class="fixed inset-0 bg-black/50" @click="emit('close')"></div>
      <div class="relative bg-white rounded-lg shadow-xl max-w-md w-full mx-4 p-6">

        <!-- Formulario -->
        <template v-if="!confirmed">
          <h2 class="text-lg font-semibold mb-4 text-gray-900">Reservar: {{ service?.name }}</h2>
          <p class="text-sm text-gray-600 mb-4">{{ selectedDate }} {{ service?.start_time }} - {{ service?.end_time }}</p>

          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Nombre *</label>
              <input v-model="name" type="text" required class="w-full px-3 py-2 border border-gray-300 rounded-lg" />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Teléfono *</label>
              <input v-model="phone" type="tel" required class="w-full px-3 py-2 border border-gray-300 rounded-lg" />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Email (opcional)</label>
              <input v-model="email" type="email" class="w-full px-3 py-2 border border-gray-300 rounded-lg" />
            </div>
            <div v-if="service?.allows_in_person && service?.allows_virtual">
              <label class="block text-sm font-medium text-gray-700 mb-1">Modalidad</label>
              <select v-model="modality" class="w-full px-3 py-2 border border-gray-300 rounded-lg">
                <option value="in_person">🏠 Presencial</option>
                <option value="virtual">💻 Virtual</option>
              </select>
            </div>
          </div>

          <div v-if="error" class="text-red-600 text-sm mt-4">{{ error }}</div>

          <div class="flex justify-end space-x-3 mt-6">
            <button @click="emit('close')" class="px-4 py-2 text-gray-600 hover:text-gray-800">Cancelar</button>
            <button @click="handleConfirm" :disabled="loading" class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50">
              {{ loading ? 'Reservando...' : 'Confirmar Reserva' }}
            </button>
          </div>
        </template>

        <!-- Confirmación -->
        <template v-else>
          <div class="text-center">
            <div class="text-5xl mb-4">✅</div>
            <h2 class="text-lg font-semibold mb-2 text-gray-900">Reserva confirmada</h2>
            <p class="text-gray-600 mb-1">{{ service?.name }}</p>
            <p class="text-gray-500 text-sm mb-4">{{ selectedDate }} {{ service?.start_time }} - {{ service?.end_time }}</p>
            <p class="text-sm text-gray-600 mb-4">
              {{ name }} - {{ phone }}
            </p>

            <div v-if="whatsappUrl" class="mb-4">
              <a :href="whatsappUrl" target="_blank" class="group relative inline-flex items-center px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700">
                <span class="mr-2">📱</span> Enviar por WhatsApp
                <span class="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 px-3 py-1.5 text-xs text-white bg-gray-800 rounded-lg opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none whitespace-nowrap z-10">
                  Envía los detalles de tu reserva por WhatsApp
                </span>
              </a>
            </div>

            <button @click="emit('close')" class="px-4 py-2 bg-gray-200 text-gray-800 rounded-lg hover:bg-gray-300">
              Cerrar
            </button>
          </div>
        </template>

      </div>
    </div>
  </Teleport>
</template>
