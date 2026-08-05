<script setup lang="ts">
defineProps<{
  count?: number
}>()
</script>

<template>
  <div class="grid gap-4" :class="$attrs.class">
    <div v-for="i in (count || 3)" :key="i" class="rounded-lg shadow p-6 animate-pulse" style="background-color: var(--color-surface)">
      <div class="h-4 rounded w-1/2 mb-3" style="background-color: var(--color-primary-subtle)"></div>
      <div class="h-8 rounded w-1/3 mb-2" style="background-color: var(--color-primary-subtle)"></div>
      <div class="h-3 rounded w-2/3" style="background-color: var(--color-primary-subtle)"></div>
    </div>
  </div>
</template>
