<script setup lang="ts">
defineProps<{
  rows?: number
  cols?: number
}>()
</script>

<template>
  <div class="rounded-lg shadow overflow-hidden animate-pulse" style="background-color: var(--color-surface)">
    <!-- Header -->
    <div class="px-6 py-3 flex space-x-6" style="background-color: var(--color-primary-subtle)">
      <div v-for="i in (cols || 4)" :key="i" class="h-3 rounded" :style="{ backgroundColor: 'var(--color-primary)', width: `${15 + Math.random() * 20}%`, opacity: 0.3 }"></div>
    </div>
    <!-- Rows -->
    <div v-for="i in (rows || 5)" :key="i" class="px-6 py-4 flex space-x-6 border-b" :style="{ borderColor: 'var(--color-border)' }">
      <div v-for="j in (cols || 4)" :key="j" class="h-4 rounded" :style="{ backgroundColor: 'var(--color-primary-subtle)', width: `${20 + Math.random() * 25}%` }"></div>
    </div>
  </div>
</template>
