<script setup lang="ts">
import { RouterLink } from 'vue-router'
</script>

<template>
  <div class="min-h-screen flex flex-col" style="background-color: var(--color-background)">
    <!-- Nav -->
    <nav class="sticky top-0 z-50 border-b backdrop-blur-md" style="background-color: rgba(255,255,255,0.9); border-color: var(--color-border)">
      <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex items-center justify-between h-16">
          <RouterLink to="/" class="flex items-center gap-2">
            <div class="w-8 h-8 rounded-lg flex items-center justify-center" style="background-color: var(--color-primary)">
              <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
            </div>
            <span class="text-lg font-bold" style="color: var(--color-text)">Reservas</span>
          </RouterLink>

          <div class="hidden md:flex items-center gap-8">
            <a href="#features" class="text-sm font-medium hover:opacity-70 transition-opacity" style="color: var(--color-text-muted)">Características</a>
            <a href="#how-it-works" class="text-sm font-medium hover:opacity-70 transition-opacity" style="color: var(--color-text-muted)">Cómo funciona</a>
            <a href="#contact" class="text-sm font-medium hover:opacity-70 transition-opacity" style="color: var(--color-text-muted)">Contacto</a>
          </div>

          <div class="flex items-center gap-3">
            <RouterLink to="/login"
              class="hidden sm:inline-flex items-center px-4 py-2 text-sm font-medium rounded-lg transition-opacity"
              style="color: var(--color-primary)">
              Iniciar sesión
            </RouterLink>
            <RouterLink to="/register"
              class="inline-flex items-center px-4 py-2 text-sm font-medium text-white rounded-lg transition-opacity hover:opacity-90"
              style="background-color: var(--color-primary)">
              Crear cuenta
            </RouterLink>
          </div>
        </div>
      </div>
    </nav>

    <main class="flex-1">
      <slot />
    </main>

    <footer class="border-t py-8" style="border-color: var(--color-border)">
      <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex flex-col sm:flex-row items-center justify-between gap-4">
          <p class="text-sm" style="color: var(--color-text-muted)">
            &copy; {{ new Date().getFullYear() }} Reservas &middot; Todos los derechos reservados
          </p>
          <div class="flex items-center gap-4">
            <RouterLink to="/login" class="text-sm hover:underline" style="color: var(--color-primary)">Iniciar sesión</RouterLink>
            <RouterLink to="/changelog" class="text-sm hover:underline" style="color: var(--color-primary)">Changelog</RouterLink>
          </div>
        </div>
      </div>
    </footer>
  </div>
</template>
