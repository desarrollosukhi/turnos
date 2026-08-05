<script setup lang="ts">
import { computed } from 'vue'
import { useAuthStore } from '@/stores/auth'

const props = defineProps<{
  show: boolean
  tipo: 'reservar' | 'cancelar'
  minutosParaClase: number
  ventana: number
}>()

const emit = defineEmits<{
  close: []
}>()

const authStore = useAuthStore()

const whatsappUrl = computed(() => {
  if (!authStore.companySettings?.whatsapp) return null
  const phone = authStore.companySettings.whatsapp.replace(/[^0-9]/g, '')
  return `https://wa.me/${phone}`
})

const mensaje = computed(() => {
  if (props.tipo === 'reservar') {
    return `No podés reservar porque quedan menos de ${props.ventana} minutos para que comience.`
  }
  return `No podés cancelar porque quedan menos de ${props.ventana} minutos para que comience.`
})
</script>

<template>
  <Teleport to="body">
    <div v-if="show" class="fixed inset-0 z-50 flex items-center justify-center">
      <div class="fixed inset-0 bg-black/50" @click="emit('close')"></div>
      <div class="relative rounded-lg shadow-xl max-w-md w-full mx-4 p-6" style="background-color: var(--color-surface)">
        <div class="text-center">
          <div class="text-4xl mb-4">⏰</div>
          <h3 class="text-lg font-semibold mb-2" style="color: var(--color-text)">Fuera del tiempo permitido</h3>
          <p class="mb-6" style="color: var(--color-text-muted)">{{ mensaje }}</p>
          <div v-if="whatsappUrl" class="mb-4">
            <p class="text-sm mb-2" style="color: var(--color-text-muted)">Si tenés una emergencia, contactá al profesional:</p>
            <a :href="whatsappUrl" target="_blank" class="group relative inline-flex items-center px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700">
              <span class="mr-2">💬</span> WhatsApp
              <span class="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 px-3 py-1.5 text-xs text-white bg-gray-800 rounded-lg opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none whitespace-nowrap z-10">
                Contactá al profesional para resolver tu reserva
              </span>
            </a>
          </div>
          <div v-else class="mb-4">
            <p class="text-sm" style="color: var(--color-text-muted)">Si tenés una emergencia, contactá al profesional directamente.</p>
          </div>
          <button @click="emit('close')" class="px-4 py-2 rounded-lg cursor-pointer hover:opacity-80" :style="{ backgroundColor: 'var(--color-primary-subtle)', color: 'var(--color-text)' }">Entendido</button>
        </div>
      </div>
    </div>
  </Teleport>
</template>
