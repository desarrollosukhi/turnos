<script setup lang="ts">
import { ref, onMounted } from 'vue'

interface ChangelogEntry {
  version: string
  date: string
  changes: {
    category: string
    items: string[]
  }[]
}

const entries = ref<ChangelogEntry[]>([
  {
    version: 'v1.0.0',
    date: '2026-07-30',
    changes: [
      {
        category: 'Multi-Tenant',
        items: [
          'Sistema multi-tenant con aislamiento por company_id',
          'Tabla companies con business_type (YOGA, GYM, PILATES, etc.)',
          'Onboarding: primer usuario crea su empresa',
        ],
      },
      {
        category: 'Roles',
        items: [
          'super_admin — dueño de la plataforma',
          'admin — administrador de empresa',
          'professional — profesional con portal propio',
          'customer — cliente/alumno',
        ],
      },
      {
        category: 'Servicios',
        items: [
          '3 modos: Semanal 🔄, Turnos ⏰, Evento 🎯',
          'Modalidad: Presencial / Virtual / Híbrida',
          'Cupos independientes por modalidad',
        ],
      },
      {
        category: 'Reservas',
        items: [
          'Validación completa (ventana, feriado, cupo, créditos)',
          'Cancelación con devolución de crédito',
          'Cancelación de sesión completa (emergencia)',
          'Marcación de asistencia',
        ],
      },
      {
        category: 'Sistema de Créditos',
        items: [
          'Balance efectivo (excluye expirados)',
          'Vencimiento: 1 mes + 1 día',
          'Consumo FIFO',
          'Admin agrega/quita con confirmación',
        ],
      },
      {
        category: 'Clientes',
        items: [
          'Crear con cuenta (credenciales auto-generadas + copiar)',
          'Crear sin cuenta (solo nombre y teléfono)',
          'Crear cuenta después para clientes sin cuenta',
          'Campos: nombre, email, teléfono, nacimiento, contacto emergencia',
          'Tipo de acceso: créditos o free pass',
        ],
      },
      {
        category: 'Profesionales',
        items: [
          'CRUD con credenciales auto-generadas',
          'Alias (se muestra en lugar del nombre)',
          'Portal propio: dashboard, servicios, reservas, asistencia',
          'Historia clínica configurable por empresa',
        ],
      },
      {
        category: 'Configuración',
        items: [
          'Logo (upload/delete)',
          '16 temas predefinidos con preview visual',
          'Modo gimnasio (horario + free pass)',
          'Ventana de tiempo para reserva/cancelación',
          'WhatsApp del profesional',
        ],
      },
      {
        category: 'Reportes',
        items: [
          '7 tipos de reportes con filtros de fecha',
          'Exportación CSV, Excel, PDF',
          'Presets: esta semana, este mes, este año, últimos 7/30 días',
        ],
      },
      {
        category: 'Feriados',
        items: [
          'Importación de feriados nacionales Argentina (2025-2027)',
          'Creación manual',
          'Toggle activar/desactivar',
        ],
      },
      {
        category: 'UI/UX',
        items: [
          'Calendario mensual con indicadores de color',
          'Toast notifications',
          'Footer "Asterisk Corp" con año dinámico',
          'Título y favicon dinámicos',
          'Logo en todos los layouts',
          '16 temas predefinidos con CSS variables',
          'Diseño responsive',
        ],
      },
    ],
  },
])

const expandedEntry = ref<string | null>(null)

function toggleEntry(version: string) {
  expandedEntry.value = expandedEntry.value === version ? null : version
}
</script>

<template>
  <div>
    <h1 class="text-2xl font-bold mb-6" style="color: var(--color-text)">Changelog</h1>
    <p class="mb-6" style="color: var(--color-text-muted)">Historial de versiones y cambios de la plataforma.</p>

    <div class="space-y-4">
      <div
        v-for="entry in entries"
        :key="entry.version"
        class="rounded-lg shadow overflow-hidden"
        style="background-color: var(--color-surface)"
      >
        <!-- Header -->
        <button
          @click="toggleEntry(entry.version)"
          class="w-full px-6 py-4 flex justify-between items-center hover:opacity-80 transition-opacity"
          style="background-color: var(--color-surface)"
        >
          <div class="flex items-center space-x-3">
            <span class="px-3 py-1 rounded-full text-sm font-bold text-white" style="background-color: var(--color-primary)">
              {{ entry.version }}
            </span>
            <span class="text-sm" style="color: var(--color-text-muted)">{{ entry.date }}</span>
          </div>
          <span class="text-lg" style="color: var(--color-text-muted)">
            {{ expandedEntry === entry.version ? '▼' : '▶' }}
          </span>
        </button>

        <!-- Content -->
        <div v-if="expandedEntry === entry.version" class="px-6 pb-6" style="border-top: 1px solid var(--color-border)">
          <div v-for="change in entry.changes" :key="change.category" class="mt-4">
            <h3 class="font-semibold mb-2" style="color: var(--color-text)">{{ change.category }}</h3>
            <ul class="space-y-1 ml-4">
              <li v-for="(item, idx) in change.items" :key="idx" class="text-sm" style="color: var(--color-text-muted)">
                • {{ item }}
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
