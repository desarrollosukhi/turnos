<script setup lang="ts">
defineProps<{
  open: boolean
}>()

const emit = defineEmits<{
  toggle: []
}>()
</script>

<template>
  <button
    @click="emit('toggle')"
    class="hamburger-btn relative w-8 h-8 flex flex-col justify-center items-center cursor-pointer"
    :aria-label="open ? 'Cerrar menú' : 'Abrir menú'"
  >
    <span
      class="block w-5 h-0.5 transition-all duration-300 ease-in-out"
      :class="open ? 'rotate-45 translate-y-1.5' : ''"
      :style="{ backgroundColor: 'var(--color-text)' }"
    ></span>
    <span
      class="block w-5 h-0.5 transition-all duration-300 ease-in-out mt-1"
      :class="open ? 'opacity-0' : ''"
      :style="{ backgroundColor: 'var(--color-text)' }"
    ></span>
    <span
      class="block w-5 h-0.5 transition-all duration-300 ease-in-out mt-1"
      :class="open ? '-rotate-45 -translate-y-1.5' : ''"
      :style="{ backgroundColor: 'var(--color-text)' }"
    ></span>
  </button>
</template>
