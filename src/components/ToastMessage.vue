<script setup lang="ts">
import { ref, watch, computed } from 'vue'

const props = defineProps<{
  message: string
  show: boolean
  type?: 'success' | 'error' | 'info'
  duration?: number
}>()

const emit = defineEmits<{
  close: []
}>()

const visible = ref(false)

watch(() => props.show, (val) => {
  if (val) {
    visible.value = true
    setTimeout(() => {
      visible.value = false
      emit('close')
    }, props.duration || 3000)
  }
})

const toastStyles = {
  success: { bg: '#f0fdf4', border: '#bbf7d0', text: '#166534', icon: '✅' },
  error: { bg: '#fef2f2', border: '#fecaca', text: '#991b1b', icon: '❌' },
  info: { bg: '#eff6ff', border: '#bfdbfe', text: '#1e40af', icon: 'ℹ️' },
}

const style = computed(() => toastStyles[props.type ?? 'success'] ?? toastStyles.success)
</script>

<template>
  <Teleport to="body">
    <Transition name="toast">
      <div
        v-if="visible"
        class="fixed top-4 right-4 z-50 px-4 py-3 rounded-lg shadow-lg flex items-center space-x-3"
        :style="{ backgroundColor: style.bg, border: `1px solid ${style.border}` }"
      >
        <span class="text-lg">{{ style.icon }}</span>
        <span class="text-sm font-medium" :style="{ color: style.text }">{{ message }}</span>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.toast-enter-active {
  transition: all 0.3s ease-out;
}
.toast-leave-active {
  transition: all 0.3s ease-in;
}
.toast-enter-from {
  opacity: 0;
  transform: translateX(100px);
}
.toast-leave-to {
  opacity: 0;
  transform: translateX(100px);
}
</style>
