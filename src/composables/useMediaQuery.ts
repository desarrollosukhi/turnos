import { ref, onMounted, onUnmounted } from 'vue'

export function useMediaQuery(query: string) {
  const matches = ref(false)
  const media = window.matchMedia(query)

  function update() {
    matches.value = media.matches
  }

  onMounted(() => {
    update()
    media.addEventListener('change', update)
  })

  onUnmounted(() => {
    media.removeEventListener('change', update)
  })

  return matches
}

export function useIsMobile() {
  return useMediaQuery('(max-width: 767px)')
}
