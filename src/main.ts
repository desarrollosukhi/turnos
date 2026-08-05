import './assets/main.css'

import { createApp } from 'vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import router from './router'
import { useAuthStore } from './stores/auth'

const app = createApp(App)

app.use(createPinia())
app.use(router)

// Init auth antes de montar para que el listener esté activo
const authStore = useAuthStore()
authStore.init()

app.mount('#app')
