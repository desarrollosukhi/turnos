<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import { ClinicalHistoryService } from '@/services/ClinicalHistoryService'
import { useAuthStore } from '@/stores/auth'
import type { ClinicalHistoryField, ClinicalHistoryEntry } from '@/types'

const props = defineProps<{
  show: boolean
  userId: string
  userName: string
  professionalId: string
  bookingId?: string
}>()

const emit = defineEmits<{
  close: []
  saved: []
}>()

const authStore = useAuthStore()
const fields = ref<ClinicalHistoryField[]>([])
const entry = ref<ClinicalHistoryEntry | null>(null)
const fieldValues = ref<Record<string, string>>({})
const freeText = ref('')
const loading = ref(false)
const saving = ref(false)

onMounted(async () => {
  if (props.show) await loadData()
})

watch(() => props.show, async (val) => {
  if (val) await loadData()
})

async function loadData() {
  if (!authStore.companyId) return
  loading.value = true
  try {
    fields.value = await ClinicalHistoryService.getFields(authStore.companyId)
    entry.value = await ClinicalHistoryService.getLatestEntry(props.userId, authStore.companyId)
    if (entry.value) {
      fieldValues.value = { ...entry.value.field_values }
      freeText.value = entry.value.free_text || ''
    } else {
      fieldValues.value = {}
      freeText.value = ''
    }
  } catch (e) { console.error(e) }
  finally { loading.value = false }
}

async function handleSave() {
  saving.value = true
  try {
    if (entry.value) {
      await ClinicalHistoryService.updateEntry(entry.value.id, {
        field_values: fieldValues.value,
        free_text: freeText.value || null,
      })
    } else {
      await ClinicalHistoryService.createEntry({
        user_id: props.userId,
        company_id: authStore.companyId!,
        professional_id: props.professionalId,
        booking_id: props.bookingId || null,
        field_values: fieldValues.value,
        free_text: freeText.value || null,
      })
    }
    emit('saved')
    emit('close')
  } catch (e: any) { console.error(e) }
  finally { saving.value = false }
}
</script>

<template>
  <Teleport to="body">
    <div v-if="show" class="fixed inset-0 z-50 flex items-center justify-center">
      <div class="fixed inset-0 bg-black/50" @click="emit('close')"></div>
      <div class="relative rounded-lg shadow-xl max-w-2xl w-full mx-4 p-6 max-h-[80vh] overflow-y-auto" style="background-color: var(--color-surface)">
        <div class="flex justify-between items-center mb-4">
          <h2 class="text-lg font-semibold" style="color: var(--color-text)">
            Historia Clínica — {{ userName }}
          </h2>
          <button @click="emit('close')" style="color: var(--color-text-muted)" class="text-xl">✕</button>
        </div>

        <div v-if="loading" class="text-center py-8">
          <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div>
        </div>

        <div v-else>
          <p v-if="entry" class="text-sm mb-4" style="color: var(--color-text-muted)">
            Última actualización: {{ new Date(entry.updated_at).toLocaleString('es-AR') }}
          </p>

          <!-- Campos predefinidos -->
          <div class="space-y-4 mb-6">
            <div v-for="field in fields" :key="field.id">
              <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">
                {{ field.field_name }}
                <span v-if="field.is_required" style="color: #dc2626">*</span>
              </label>
              <textarea
                v-model="fieldValues[field.field_name]"
                rows="2"
                class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2"
                :style="{ borderColor: 'var(--color-border)', '--tw-ring-color': 'var(--color-primary)' }"
                :placeholder="'Ingrese ' + field.field_name.toLowerCase()"
              ></textarea>
            </div>
          </div>

          <!-- Texto libre -->
          <div class="mb-6">
            <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">
              Notas adicionales
            </label>
            <textarea
              v-model="freeText"
              rows="3"
              class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2"
              :style="{ borderColor: 'var(--color-border)', '--tw-ring-color': 'var(--color-primary)' }"
              placeholder="Observaciones, notas, etc."
            ></textarea>
          </div>

          <!-- Botones -->
          <div class="flex justify-end space-x-3">
            <button
              @click="emit('close')"
              class="px-4 py-2 rounded-lg"
              :style="{ backgroundColor: 'var(--color-primary-subtle)', color: 'var(--color-text)' }"
            >
              Cancelar
            </button>
            <button
              @click="handleSave"
              :disabled="saving"
              class="px-4 py-2 rounded-lg text-white disabled:opacity-50"
              :style="{ backgroundColor: 'var(--color-primary)' }"
            >
              {{ saving ? 'Guardando...' : 'Guardar' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>
