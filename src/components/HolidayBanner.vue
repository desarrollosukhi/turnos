<script setup lang="ts">
defineProps<{
  show: boolean
}>()
</script>

<template>
  <div v-if="show" class="border-l-4 p-4 mb-4" style="background-color: var(--color-primary-subtle); border-color: var(--color-primary)">
    <div class="flex">
      <div class="flex-shrink-0">
        <span class="text-2xl">🎌</span>
      </div>
      <div class="ml-3">
        <p class="text-sm font-medium" style="color: var(--color-text)">
          Este día es feriado
        </p>
        <p class="text-sm mt-1" style="color: var(--color-text-muted)">
          No hay clases disponibles. Las clases se reanudarán el próximo día hábil.
        </p>
      </div>
    </div>
  </div>
</template>
