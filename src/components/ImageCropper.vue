<script setup lang="ts">
import { ref } from 'vue'
import { Cropper } from 'vue-advanced-cropper'
import 'vue-advanced-cropper/dist/style.css'

const props = defineProps<{
  show: boolean
  imageSrc: string
}>()

const emit = defineEmits<{
  apply: [blob: Blob]
  cancel: []
}>()

const stencilShape = ref<'rectangle' | 'circle'>('rectangle')
const cropperRef = ref<any>(null)

function handleApply() {
  const { canvas } = cropperRef.value?.getResult()
  if (!canvas) return
  canvas.toBlob((blob: Blob | null) => {
    if (blob) emit('apply', blob)
  }, 'image/png')
}

function handleRotate() {
  if (cropperRef.value) {
    cropperRef.value.rotate(90)
  }
}
</script>

<template>
  <Teleport to="body">
    <Transition name="modal">
      <div v-if="show" class="fixed inset-0 z-50 flex items-center justify-center">
        <div class="fixed inset-0 bg-black/50" @click="emit('cancel')"></div>
        <div class="relative rounded-lg shadow-xl max-w-2xl w-full mx-4 p-6 max-h-[90vh] overflow-y-auto" style="background-color: var(--color-surface)">
          <h3 class="text-lg font-semibold mb-4" style="color: var(--color-text)">Editar logo</h3>

          <!-- Cropper -->
          <div class="rounded-lg overflow-hidden mb-4" style="height: 400px">
            <Cropper
              ref="cropperRef"
              :src="imageSrc"
              :stencil-props="{
                handlers: {},
                movable: true,
                resizable: true,
              }"
              :canvas="true"
              :auto-zoom="true"
              class="h-full"
            />
          </div>

          <!-- Controles -->
          <div class="flex items-center justify-between mb-4">
            <div class="flex items-center space-x-4">
              <button
                @click="handleRotate"
                class="px-3 py-1.5 rounded-lg text-sm cursor-pointer hover:opacity-80"
                :style="{ backgroundColor: 'var(--color-primary-subtle)', color: 'var(--color-text)' }"
              >
                ↻ Rotar
              </button>
            </div>
            <p class="text-xs" style="color: var(--color-text-muted)">Arrastrá para mover, scroll para zoom</p>
          </div>

          <!-- Botones -->
          <div class="flex justify-end space-x-3">
            <button
              @click="emit('cancel')"
              class="px-4 py-2 rounded-lg cursor-pointer"
              :style="{ backgroundColor: 'var(--color-primary-subtle)', color: 'var(--color-text)' }"
            >
              Cancelar
            </button>
            <button
              @click="handleApply"
              class="px-4 py-2 rounded-lg text-white cursor-pointer hover:opacity-90"
              :style="{ backgroundColor: 'var(--color-primary)' }"
            >
              Aplicar
            </button>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.modal-enter-active {
  transition: all 0.2s ease-out;
}
.modal-leave-active {
  transition: all 0.15s ease-in;
}
.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}
</style>
