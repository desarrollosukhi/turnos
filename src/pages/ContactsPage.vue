<script setup lang="ts">
import { useAuthStore } from '@/stores/auth'
import { CompanyService } from '@/services/CompanyService'
import { ProfessionalService } from '@/services/ProfessionalService'
import ToastMessage from '@/components/ToastMessage.vue'
import SkeletonCard from '@/components/SkeletonCard.vue'
import { onMounted, ref } from 'vue'
import type { Professional } from '@/types'

const authStore = useAuthStore()

const companyPhone = ref('')
const companyWhatsapp = ref('')
const companyName = ref('')
const professionals = ref<Professional[]>([])
const loading = ref(true)

const showToast = ref(false)
const toastMessage = ref('')
const toastType = ref<'success' | 'error' | 'info'>('success')

onMounted(async () => {
  if (!authStore.companyId) return
  try {
    const [settings, company, profs] = await Promise.all([
      CompanyService.getSettings(authStore.companyId),
      CompanyService.getById(authStore.companyId),
      ProfessionalService.getAll(authStore.companyId),
    ])
    companyName.value = company?.name || ''
    companyWhatsapp.value = settings?.whatsapp || ''
    professionals.value = profs.filter(p => p.active)
  } catch (e) { console.error(e) }
  finally { loading.value = false }
})

async function copyToClipboard(text: string) {
  await navigator.clipboard.writeText(text)
  toastMessage.value = 'Número copiado'
  toastType.value = 'success'
  showToast.value = true
}

function formatPhone(phone: string): string {
  return phone.replace(/[^0-9+]/g, '')
}
</script>

<template>
  <div>
    <ToastMessage :show="showToast" :message="toastMessage" :type="toastType" @close="showToast = false" />

    <h1 class="text-2xl font-bold mb-6" style="color: var(--color-text)">Contactos</h1>

    <SkeletonCard v-if="loading" :count="3" :lines="2" />

    <template v-else>
      <!-- Empresa -->
      <div v-if="companyWhatsapp" class="rounded-lg shadow p-6 mb-6" style="background-color: var(--color-surface)">
        <h2 class="text-lg font-semibold mb-4" style="color: var(--color-text)">🏢 {{ companyName }}</h2>
        <div class="flex items-center justify-between p-3 rounded-lg" style="background-color: var(--color-primary-subtle)">
          <div>
            <p class="text-sm font-medium" style="color: var(--color-text)">📱 WhatsApp</p>
            <p class="text-sm" style="color: var(--color-text-muted)">{{ companyWhatsapp }}</p>
          </div>
          <div class="flex space-x-2">
            <a :href="`https://wa.me/${formatPhone(companyWhatsapp)}`" target="_blank"
              class="px-3 py-1.5 rounded-lg text-white text-sm cursor-pointer hover:opacity-90"
              style="background-color: #25d366">
              Abrir
            </a>
            <button @click="copyToClipboard(companyWhatsapp)"
              class="px-3 py-1.5 rounded-lg text-sm cursor-pointer hover:opacity-80"
              :style="{ backgroundColor: 'var(--color-primary-subtle)', color: 'var(--color-primary)' }">
              Copiar
            </button>
          </div>
        </div>
      </div>

      <!-- Profesionales -->
      <div v-if="professionals.length > 0" class="rounded-lg shadow p-6" style="background-color: var(--color-surface)">
        <h2 class="text-lg font-semibold mb-4" style="color: var(--color-text)">👨‍🏫 Profesionales</h2>
        <div class="space-y-3">
          <div v-for="p in professionals" :key="p.id" class="p-4 rounded-lg" style="background-color: var(--color-primary-subtle)">
            <p class="font-semibold mb-2" style="color: var(--color-text)">{{ p.name }}</p>
            <div class="space-y-2">
              <div v-if="p.whatsapp" class="flex items-center justify-between">
                <div>
                  <p class="text-sm" style="color: var(--color-text-muted)">📱 WhatsApp: {{ p.whatsapp }}</p>
                </div>
                <div class="flex space-x-2">
                  <a :href="`https://wa.me/${formatPhone(p.whatsapp)}`" target="_blank"
                    class="px-3 py-1.5 rounded-lg text-white text-sm cursor-pointer hover:opacity-90"
                    style="background-color: #25d366">
                    Abrir
                  </a>
                  <button @click="copyToClipboard(p.whatsapp)"
                    class="px-3 py-1.5 rounded-lg text-sm cursor-pointer hover:opacity-80"
                    :style="{ backgroundColor: 'var(--color-primary-subtle)', color: 'var(--color-primary)', border: '1px solid var(--color-border)' }">
                    Copiar
                  </button>
                </div>
              </div>
              <div v-if="p.phone" class="flex items-center justify-between">
                <div>
                  <p class="text-sm" style="color: var(--color-text-muted)">📞 Teléfono: {{ p.phone }}</p>
                </div>
                <div class="flex space-x-2">
                  <a :href="`tel:${formatPhone(p.phone)}`"
                    class="px-3 py-1.5 rounded-lg text-white text-sm cursor-pointer hover:opacity-90"
                    style="background-color: var(--color-primary)">
                    Llamar
                  </a>
                  <button @click="copyToClipboard(p.phone)"
                    class="px-3 py-1.5 rounded-lg text-sm cursor-pointer hover:opacity-80"
                    :style="{ backgroundColor: 'var(--color-primary-subtle)', color: 'var(--color-primary)', border: '1px solid var(--color-border)' }">
                    Copiar
                  </button>
                </div>
              </div>
              <div v-if="!p.whatsapp && !p.phone" class="text-sm" style="color: var(--color-text-muted)">
                Sin datos de contacto
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Sin contactos -->
      <div v-if="!companyWhatsapp && professionals.length === 0" class="rounded-lg shadow p-8 text-center" style="background-color: var(--color-surface)">
        <p style="color: var(--color-text-muted)">No hay datos de contacto configurados.</p>
        <p class="text-sm mt-1" style="color: var(--color-text-muted)">El administrador puede agregar WhatsApp en Configuración.</p>
      </div>
    </template>
  </div>
</template>
