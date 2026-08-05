<script setup lang="ts">
const props = defineProps<{
  currentPage: number
  totalPages: number
  totalItems: number
  pageSize: number
}>()

const emit = defineEmits<{
  'update:currentPage': [page: number]
}>()

function goTo(page: number) {
  if (page >= 1 && page <= props.totalPages) {
    emit('update:currentPage', page)
  }
}

const visiblePages = computed(() => {
  const pages: (number | '...')[] = []
  const total = props.totalPages
  const current = props.currentPage

  if (total <= 7) {
    for (let i = 1; i <= total; i++) pages.push(i)
  } else {
    pages.push(1)
    if (current > 3) pages.push('...')
    const start = Math.max(2, current - 1)
    const end = Math.min(total - 1, current + 1)
    for (let i = start; i <= end; i++) pages.push(i)
    if (current < total - 2) pages.push('...')
    pages.push(total)
  }
  return pages
})

import { computed } from 'vue'
</script>

<template>
  <div v-if="totalPages > 1" class="flex items-center justify-between px-4 py-3" style="border-top: 1px solid var(--color-border)">
    <div class="text-sm" style="color: var(--color-text-muted)">
      Mostrando {{ (currentPage - 1) * pageSize + 1 }}-{{ Math.min(currentPage * pageSize, totalItems) }} de {{ totalItems }}
    </div>
    <div class="flex items-center space-x-1">
      <button
        @click="goTo(currentPage - 1)"
        :disabled="currentPage === 1"
        class="px-3 py-1 text-sm rounded disabled:opacity-50"
        :style="{ color: 'var(--color-text)', border: '1px solid var(--color-border)' }"
      >
        ←
      </button>
      <template v-for="(page, idx) in visiblePages" :key="idx">
        <span v-if="page === '...'" class="px-2 text-sm" style="color: var(--color-text-muted)">…</span>
        <button
          v-else
          @click="goTo(page)"
          class="px-3 py-1 text-sm rounded"
          :style="{
            backgroundColor: page === currentPage ? 'var(--color-primary)' : 'transparent',
            color: page === currentPage ? 'white' : 'var(--color-text)',
            border: '1px solid ' + (page === currentPage ? 'var(--color-primary)' : 'var(--color-border)')
          }"
        >
          {{ page }}
        </button>
      </template>
      <button
        @click="goTo(currentPage + 1)"
        :disabled="currentPage === totalPages"
        class="px-3 py-1 text-sm rounded disabled:opacity-50"
        :style="{ color: 'var(--color-text)', border: '1px solid var(--color-border)' }"
      >
        →
      </button>
    </div>
  </div>
</template>
