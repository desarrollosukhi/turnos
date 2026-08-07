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
    version: 'v1.1.1',
    date: '2026-08-07',
    changes: [
      {
        category: 'Calendario mensual',
        items: [
          'Fix: encabezado de días de semana ahora empieza en Domingo, alineado con la numeración real de la grilla',
        ],
      },
      {
        category: 'Horarios y fechas — Formato consistente',
        items: [
          'Todos los horarios se muestran como HH:mm, sin segundos (antes HH:mm:ss)',
          'Fechas de eventos únicos se muestran en formato local es-AR (ej. "lun. 11 ago.")',
          'Aplicado en: servicios disponibles del cliente, próximas reservas del home, y listado de servicios del admin',
        ],
      },
      {
        category: 'Reservas del cliente — Responsive',
        items: [
          'Botones de reserva (Presencial / Virtual) rediseñados para mobile: se apilan en columna y ocupan el ancho completo',
          'Card de servicio pasa de fila a columna en pantallas chicas para evitar que el contenido se apriete',
        ],
      },
      {
        category: 'Configuración — Modo de Clientes',
        items: [
          'Etiquetas traducidas al español: "Miembro" y "Invitado" (antes MEMBER/GUEST)',
          'Popover con ícono "?" explicando qué significa cada modo',
          'Popover con ícono "?" en el toggle "Mostrar alias" explicando que reemplaza el nombre del profesional por su apodo',
          'Popovers funcionan con tap/click (no solo hover), para uso correcto en mobile, con cierre automático al tocar afuera',
        ],
      },
      {
        category: 'Admin Servicios',
        items: [
          'Fix: error de parseo en botón "+ Nuevo" (statements múltiples en @click) — refactorizado a función toggleForm',
        ],
      },
    ],
  },
  {
    version: 'v1.1.0',
    date: '2026-08-05',
    changes: [
      {
        category: 'Feriados — Auto-sync desde API',
        items: [
          'Feriados nacionales se cargan automáticamente desde ArgentinaDatos al abrir Configuración',
          'Botón "🔄 Sincronizar" para refrescar manualmente desde la API',
          'Se sincronizan año actual + siguiente automáticamente',
          'Badge "Nacional" en feriados que provienen de la API',
          'Eliminado panel de importación manual (año selector + botón Importar)',
          'Botón único "Activar/Desactivar todos" (se alterna según estado actual)',
          'Lista colapsada (muestra 4 feriados) con botón "Ver todos"',
          'Buscador de feriados por nombre o fecha',
          'Fix: RLS policy de UPDATE faltante en tabla holidays',
          'Feedback visual: spinner + texto durante activar/desactivar todos',
          'Cursor pointer en todos los toggles',
        ],
      },
      {
        category: 'Avisos (Anuncios)',
        items: [
          'CRUD completo de avisos para administradores',
          'Editor de rich text (Tiptap) para contenido',
          'Dos modos de descarte: "Recordarme" (sesión) y "No mostrar" (permanente)',
          'Reactivación de avisos descartados por el admin',
          'Anuncios de cancelación de sesión se muestran a todos los alumnos',
        ],
      },
      {
        category: 'Reservas del cliente — Tabs',
        items: [
          'Tabs Pendientes / Realizadas / Canceladas con conteo',
          'Labels de estado en español (Pendiente, Asistió, Ausente, Cancelada)',
        ],
      },
      {
        category: 'Créditos — Paginación',
        items: ['Botón "Ver más" para historial de movimientos (carga de 10 en 10)'],
      },
      {
        category: 'Calendario',
        items: ['Fix: indicador de reserva solo se muestra si no hay sesión cancelada'],
      },
      {
        category: 'Admin Reservas',
        items: ['Excluir servicios ya cancelados del modal de cancelación de sesión'],
      },
      {
        category: 'Dependencias',
        items: [
          '@tiptap/vue-3, @tiptap/starter-kit, @tiptap/pm — editor rich text',
          'marked — renderizado de markdown',
        ],
      },
    ],
  },
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
    <p class="mb-6" style="color: var(--color-text-muted)">
      Historial de versiones y cambios de la plataforma.
    </p>

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
            <span
              class="px-3 py-1 rounded-full text-sm font-bold text-white"
              style="background-color: var(--color-primary)"
            >
              {{ entry.version }}
            </span>
            <span class="text-sm" style="color: var(--color-text-muted)">{{ entry.date }}</span>
          </div>
          <span class="text-lg" style="color: var(--color-text-muted)">
            {{ expandedEntry === entry.version ? '▼' : '▶' }}
          </span>
        </button>

        <!-- Content -->
        <div
          v-if="expandedEntry === entry.version"
          class="px-6 pb-6"
          style="border-top: 1px solid var(--color-border)"
        >
          <div v-for="change in entry.changes" :key="change.category" class="mt-4">
            <h3 class="font-semibold mb-2" style="color: var(--color-text)">
              {{ change.category }}
            </h3>
            <ul class="space-y-1 ml-4">
              <li
                v-for="(item, idx) in change.items"
                :key="idx"
                class="text-sm"
                style="color: var(--color-text-muted)"
              >
                • {{ item }}
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
