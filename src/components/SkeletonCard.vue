<script setup lang="ts">
defineProps<{
  count?: number
  lines?: number
}>()
</script>

<template>
  <div class="grid gap-4" :class="$attrs.class">
    <div v-for="i in (count || 3)" :key="i" class="rounded-lg shadow p-6 animate-pulse" style="background-color: var(--color-surface)">
      <div class="h-4 rounded w-3/4 mb-3" style="background-color: var(--color-primary-subtle)"></div>
      <div v-for="j in (lines || 2)" :key="j" class="h-3 rounded mb-2" :style="{ backgroundColor: 'var(--color-primary-subtle)', width: `${60 + Math.random() * 30}%` }"></div>
      <div class="flex space-x-2 mt-4">
        <div class="h-8 rounded w-24" style="background-color: var(--color-primary-subtle)"></div>
        <div class="h-8 rounded w-20" style="background-color: var(--color-primary-subtle)"></div>
      </div>
    </div>
  </div>
</template>
