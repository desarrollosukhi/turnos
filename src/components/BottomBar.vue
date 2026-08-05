<script setup lang="ts">
import { Home, Calendar, Wallet, User, MoreHorizontal } from 'lucide-vue-next'

defineProps<{
  items: { icon: string; label: string; to: string; active: boolean; isMore?: boolean }[]
}>()

const emit = defineEmits<{
  more: []
}>()

const iconMap: Record<string, any> = {
  home: Home,
  calendar: Calendar,
  wallet: Wallet,
  user: User,
  more: MoreHorizontal,
}
</script>

<template>
  <div class="bottom-bar fixed bottom-0 left-0 right-0 z-50 border-t md:hidden" style="background-color: var(--color-surface); border-color: var(--color-border)">
    <div class="flex justify-around items-end h-16 px-2 pb-1">
      <!-- Izquierda: 2 icons -->
      <router-link
        v-for="item in items.slice(0, 2)"
        :key="item.to"
        :to="item.to"
        class="flex flex-col items-center justify-center flex-1 h-full transition-colors pt-1"
        :style="{ color: item.active ? 'var(--color-primary)' : 'var(--color-text-muted)' }"
      >
        <component :is="iconMap[item.icon] || Home" :size="20" :stroke-width="item.active ? 2.5 : 1.5" />
        <span class="text-[10px] mt-1 font-medium">{{ item.label }}</span>
      </router-link>

      <!-- Centro: Home grande con círculo -->
      <router-link
        :to="items[2]?.to || '/'"
        class="flex flex-col items-center justify-center flex-1 h-full transition-colors relative -mt-4"
        :style="{ color: items[2]?.active ? 'var(--color-primary)' : 'var(--color-text-muted)' }"
      >
        <div
          class="w-12 h-12 rounded-full flex items-center justify-center shadow-lg transition-colors"
          :style="{
            backgroundColor: items[2]?.active ? 'var(--color-primary)' : 'var(--color-surface)',
            border: '3px solid ' + (items[2]?.active ? 'var(--color-primary)' : 'var(--color-border)'),
          }"
        >
          <Home :size="22" :stroke-width="items[2]?.active ? 2.5 : 1.5" :style="{ color: items[2]?.active ? 'white' : 'var(--color-text)' }" />
        </div>
        <span class="text-[10px] mt-1 font-medium" :style="{ color: items[2]?.active ? 'var(--color-primary)' : 'var(--color-text-muted)' }">{{ items[2]?.label }}</span>
      </router-link>

      <!-- Derecha: 2 icons -->
      <template v-for="item in items.slice(3, 5)" :key="item.to">
        <router-link
          v-if="!item.isMore"
          :to="item.to"
          class="flex flex-col items-center justify-center flex-1 h-full transition-colors pt-1"
          :style="{ color: item.active ? 'var(--color-primary)' : 'var(--color-text-muted)' }"
        >
          <component :is="iconMap[item.icon] || Home" :size="20" :stroke-width="item.active ? 2.5 : 1.5" />
          <span class="text-[10px] mt-1 font-medium">{{ item.label }}</span>
        </router-link>
        <button
          v-else
          @click="emit('more')"
          class="flex flex-col items-center justify-center flex-1 h-full transition-colors pt-1 cursor-pointer"
          :style="{ color: item.active ? 'var(--color-primary)' : 'var(--color-text-muted)' }"
        >
          <component :is="iconMap[item.icon] || Home" :size="20" :stroke-width="1.5" />
          <span class="text-[10px] mt-1 font-medium">{{ item.label }}</span>
        </button>
      </template>
    </div>
  </div>
</template>
