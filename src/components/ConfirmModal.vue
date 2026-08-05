<script setup lang="ts">
defineProps<{
  show: boolean
  title: string
  message: string
  icon?: string
  confirmText?: string
  cancelText?: string
  confirmColor?: string
}>()

const emit = defineEmits<{
  confirm: []
  cancel: []
}>()
</script>

<template>
  <Teleport to="body">
    <Transition name="modal">
      <div v-if="show" class="fixed inset-0 z-50 flex items-center justify-center">
        <div class="fixed inset-0 bg-black/50" @click="emit('cancel')"></div>
        <div class="relative rounded-lg shadow-xl max-w-sm w-full mx-4 p-6" style="background-color: var(--color-surface)">
          <div class="text-center">
            <div class="text-4xl mb-4">{{ icon || '❓' }}</div>
            <h3 class="text-lg font-semibold mb-2" style="color: var(--color-text)">{{ title }}</h3>
            <p class="text-sm mb-6" style="color: var(--color-text-muted)">{{ message }}</p>
            <div class="flex justify-center space-x-3">
              <button
                @click="emit('cancel')"
                class="px-4 py-2 rounded-lg cursor-pointer hover:opacity-80"
                :style="{ backgroundColor: 'var(--color-primary-subtle)', color: 'var(--color-text)' }"
              >
                {{ cancelText || 'Cancelar' }}
              </button>
              <button
                @click="emit('confirm')"
                class="px-4 py-2 rounded-lg text-white cursor-pointer hover:opacity-90"
                :style="{ backgroundColor: confirmColor || 'var(--color-primary)' }"
              >
                {{ confirmText || 'Confirmar' }}
              </button>
            </div>
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
.modal-enter-from {
  opacity: 0;
}
.modal-leave-to {
  opacity: 0;
}
</style>
