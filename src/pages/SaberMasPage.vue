<script setup lang="ts">
const currentYear = new Date().getFullYear()
</script>

<template>
  <div class="max-w-lg mx-auto text-center">
    <!-- Logo y nombre -->
    <div class="mb-8">
      <svg class="h-16 w-auto mx-auto mb-4" viewBox="0 0 4946.29 4946.29" xmlns="http://www.w3.org/2000/svg">
        <path fill="#e63605" fill-rule="evenodd" d="M4852.35,2109.8c-79.29-61.34-194.85-65.82-294.34-15.71-65.82,49.74-176.53,124.54-321.64,194.85-156.33,74.8-679.56,328.37-1198.29,151.84-113.32-38.52-203.83-88.26-271.9-129.03h43.01c61.34-4.49,224.4-25.06,579.7-271.9,197.1-135.76,348.94-242.35,514.25-434.96,147.36-169.8,353.43-412.15,335.1-702-11.22-154.09-79.29-233.38-92.75-251.33-25.06-27.3-117.81-133.52-249.08-117.81-99.48,13.46-183.63,90.51-219.54,197.1-11.22,81.53-36.28,212.81-88.26,366.89-56.47,163.06-249.08,713.59-738.27,955.94-106.59,51.99-206.07,81.53-283.12,99.48,8.98-11.22,20.57-20.57,29.55-31.79,40.77-47.5,140.25-176.53,217.29-602.51,43.01-235.62,74.8-418.88,56.47-672.82-15.71-224.4-40.77-541.18-260.3-733.79C2494.65,10.17,2388.06,1.2,2367.87,1.2c-36.28-2.24-176.53-11.22-258.06,92.75-61.34,79.29-65.82,194.85-15.71,294.34,49.74,65.82,124.54,176.53,194.85,321.64,74.8,156.33,328.37,679.56,151.84,1198.29-38.52,113.32-88.26,203.83-129.03,271.9v-43.01c-4.49-61.34-25.06-224.4-271.9-579.7-135.76-197.1-242.35-348.94-434.96-514.25-169.8-147.36-412.15-353.43-702-335.1-154.09,11.22-233.38,79.29-251.33,92.75-27.3,25.06-133.52,117.81-117.81,249.08,13.46,99.48,90.51,183.63,197.1,219.54,81.53,11.22,212.81,36.28,366.89,88.26,163.06,56.47,713.59,249.08,955.94,738.27,51.99,106.59,81.53,206.07,99.48,283.12-11.22-8.98-20.57-20.57-31.79-29.55-47.5-40.77-176.53-140.25-602.51-217.29-235.62-43.01-418.88-74.8-672.82-56.47-224.4,15.71-541.18,40.77-733.79,260.3C10.17,2451.64,1.2,2558.23,1.2,2578.43c-2.24,36.28-11.22,176.53,92.75,258.06,79.29,61.34,194.85,65.82,294.34,15.71,65.82-49.74,176.53-124.54,321.64-194.85,156.33-74.8,679.56-328.37,1198.29-151.84,113.32,38.52,203.83,88.26,271.9,129.03h-43.01c-61.34,4.49-224.4,25.06-579.7,271.9-197.1,135.76-348.94,242.35-514.25,434.96-147.36,169.8-353.43,412.15-335.1,702,11.22,154.09,79.29,233.38,92.75,251.33,25.06,27.3,117.81,133.52,249.08,117.81,99.48-13.46,183.63-90.51,219.54-197.1,11.22-81.53,36.28-212.81,88.26-366.89,56.47-163.06,249.08-713.59,738.27-955.94,106.59-51.99,206.07-81.53,283.12-99.48-8.98,11.22-20.57,20.57-29.55,31.79-40.77,47.5-140.25,176.53-217.29,602.51-43.01,235.62-74.8,418.88-56.47,672.82,15.71,224.4,40.77,541.18,260.3,733.79,115.57,102.1,222.16,111.08,242.35,111.08,36.28,2.24,176.53,11.22,258.06-92.75,61.34-79.29,65.82-194.85,15.71-294.34-49.74-65.82-124.54-176.53-194.85-321.64-74.8-156.33-328.37-679.56-151.84-1198.29,38.52-113.32,88.26-203.83,129.03-271.9v43.01c4.49,61.34,25.06,224.4,271.9,579.7,135.76,197.1,242.35,348.94,434.96,514.25,169.8,147.36,412.15,353.43,702,335.1,154.09-11.22,233.38-79.29,251.33-92.75,27.3-25.06,133.52-117.81,117.81-249.08-13.46-99.48-90.51-183.63-197.1-219.54-81.53-11.22-212.81-36.28-366.89-88.26-163.06-56.47-713.59-249.08-955.94-738.27-51.99-106.59-81.53-206.07-99.48-283.12,11.22,8.98,20.57,20.57,31.79,29.55,47.5,40.77,176.53,140.25,602.51,217.29,235.62,43.01,418.88,74.8,672.83,56.47,224.4-15.71,541.18-40.77,733.79-260.3,102.1-115.57,111.08-222.16,111.08-242.35,2.24-36.28,11.22-176.53-92.75-258.06h0Z"/>
      </svg>
      <h1 class="text-2xl font-bold" style="color: var(--color-text)">Asterisk</h1>
      <p class="text-sm" style="color: var(--color-text-muted)">Sistema de Gestión de Reservas</p>
      <p class="text-xs mt-1" style="color: var(--color-text-muted)">v1.0.0</p>
    </div>

    <!-- Acerca de -->
    <div class="rounded-lg shadow p-6 mb-6 text-left" style="background-color: var(--color-surface)">
      <h2 class="text-lg font-semibold mb-3" style="color: var(--color-text)">Acerca de</h2>
      <p class="text-sm mb-3" style="color: var(--color-text-muted)">
        Asterisk es una plataforma de gestión de reservas diseñada para pequeños negocios.
        Simplifica la administración diaria de clases, turnos y servicios.
      </p>
      <p class="text-sm" style="color: var(--color-text-muted)">
        Desarrollada por <strong>Asterisk Consultora</strong>, una empresa de tecnología
        enfocada en crear soluciones simples y efectivas para emprendedores.
      </p>
    </div>

    <!-- Características -->
    <div class="rounded-lg shadow p-6 mb-6 text-left" style="background-color: var(--color-surface)">
      <h2 class="text-lg font-semibold mb-3" style="color: var(--color-text)">Características</h2>
      <ul class="space-y-2 text-sm" style="color: var(--color-text-muted)">
        <li class="flex items-start"><span class="mr-2">✅</span> Reservá desde tu celular</li>
        <li class="flex items-start"><span class="mr-2">✅</span> Cancelá cuando quieras</li>
        <li class="flex items-start"><span class="mr-2">✅</span> Seguí tu historial de asistencia</li>
        <li class="flex items-start"><span class="mr-2">✅</span> Gestioná créditos y pagos</li>
        <li class="flex items-start"><span class="mr-2">✅</span> Recibí notificaciones importantes</li>
        <li class="flex items-start"><span class="mr-2">✅</span> Contactá a tus profesores al instante</li>
      </ul>
    </div>

    <!-- Contacto Asterisk -->
    <div class="rounded-lg shadow p-6 mb-6 text-left" style="background-color: var(--color-surface)">
      <h2 class="text-lg font-semibold mb-3" style="color: var(--color-text)">Contacto</h2>
      <p class="text-sm mb-4" style="color: var(--color-text-muted)">
        ¿Querés este sistema para tu negocio? Contactanos para conocer más.
      </p>
      <div class="flex flex-wrap gap-3">
        <a href="https://asteriskconsultora.com/" target="_blank"
          class="inline-flex items-center px-4 py-2 rounded-lg text-white text-sm cursor-pointer hover:opacity-90"
          style="background-color: #e63605">
          Visitar asteriskconsultora.com
        </a>
        <a href="https://wa.me/5493534746217" target="_blank"
          class="inline-flex items-center px-4 py-2 rounded-lg text-white text-sm cursor-pointer hover:opacity-90"
          style="background-color: #25d366">
          <svg class="w-4 h-4 mr-1.5" viewBox="0 0 24 24" fill="currentColor"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.197 1.36.168 1.871.101.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.273-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.621-.235-.374a9.87 9.87 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.924c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.924a11.821 11.821 0 00-3.48-8.413z"/></svg>
          WhatsApp
        </a>
      </div>
    </div>

    <!-- Footer info -->
    <div class="text-center">
      <p class="text-xs" style="color: var(--color-text-muted)">
        © {{ currentYear }} Asterisk Corp · Todos los derechos reservados
      </p>
      <router-link to="/changelog" class="text-xs hover:underline" style="color: var(--color-primary)">
        Ver changelog
      </router-link>
    </div>
  </div>
</template>
