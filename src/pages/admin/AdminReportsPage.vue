<script setup lang="ts">
import { useAuthStore } from '@/stores/auth'
import { ReportService } from '@/services/ReportService'
import { exportToCSV, exportToExcel, exportToPDF, getDatePresets } from '@/utils/exportUtils'
import type { ReportType, ReportBookingsByProfessional, ReportOccupancy, ReportCreditConsumption, ReportAttendanceRate, ReportCustomerGrowth, ReportServicePopularity, ReportCancellation } from '@/types'
import { ref, computed } from 'vue'

const authStore = useAuthStore()

const reportType = ref<ReportType>('bookings_by_professional')
const startDate = ref(new Date().toISOString().split('T')[0])
const endDate = ref(new Date().toISOString().split('T')[0])
const loading = ref(false)
const error = ref('')
const reportData = ref<any[]>([])

const presets = getDatePresets()

const reportTypes: { value: ReportType; label: string; description: string }[] = [
  { value: 'bookings_by_professional', label: 'Reservas por profesional', description: 'Cantidad de reservas, asistencias y cancelaciones por profesional' },
  { value: 'occupancy', label: 'Ocupación de servicios', description: 'Porcentaje de cupos llenos por servicio' },
  { value: 'credit_consumption', label: 'Consumo de créditos', description: 'Créditos consumidos vs agregados por cliente' },
  { value: 'attendance_rate', label: 'Tasa de asistencia', description: 'Porcentaje de asistencia por período' },
  { value: 'customer_growth', label: 'Clientes nuevos', description: 'Registros nuevos por mes' },
  { value: 'service_popularity', label: 'Servicios más demandados', description: 'Ranking de servicios por cantidad de reservas' },
  { value: 'cancellations', label: 'Cancelaciones', description: 'Sesiones canceladas con motivos' },
]

function applyPreset(preset: { start: string; end: string }) {
  startDate.value = preset.start
  endDate.value = preset.end
}

async function generateReport() {
  if (!authStore.companyId) return
  if (!startDate.value || !endDate.value) {
    error.value = 'Seleccioná fechas de inicio y fin'
    return
  }
  loading.value = true
  error.value = ''
  reportData.value = []

  try {
    switch (reportType.value) {
      case 'bookings_by_professional':
        reportData.value = await ReportService.bookingsByProfessional(authStore.companyId, startDate.value, endDate.value)
        break
      case 'occupancy':
        reportData.value = await ReportService.occupancy(authStore.companyId, startDate.value, endDate.value)
        break
      case 'credit_consumption':
        reportData.value = await ReportService.creditConsumption(authStore.companyId, startDate.value, endDate.value)
        break
      case 'attendance_rate':
        reportData.value = await ReportService.attendanceRate(authStore.companyId, startDate.value, endDate.value)
        break
      case 'customer_growth':
        reportData.value = await ReportService.customerGrowth(authStore.companyId, startDate.value, endDate.value)
        break
      case 'service_popularity':
        reportData.value = await ReportService.servicePopularity(authStore.companyId, startDate.value, endDate.value)
        break
      case 'cancellations':
        reportData.value = await ReportService.cancellations(authStore.companyId, startDate.value, endDate.value)
        break
    }
  } catch (e: any) {
    error.value = e.message || 'Error al generar reporte'
  } finally {
    loading.value = false
  }
}

function handleExportCSV() {
  exportToCSV(reportData.value, `reporte-${reportType.value}-${startDate.value}-${endDate.value}`)
}

function handleExportExcel() {
  exportToExcel(reportData.value, `reporte-${reportType.value}-${startDate.value}-${endDate.value}`)
}

function handleExportPDF() {
  const title = reportTypes.find(r => r.value === reportType.value)?.label || 'Reporte'
  const columns = reportColumns.value.map(c => ({ header: c.label, key: c.key }))
  exportToPDF(reportData.value, columns, `${title} (${startDate.value} - ${endDate.value})`, `reporte-${reportType.value}-${startDate.value}-${endDate.value}`)
}

interface ReportColumn {
  key: string
  label: string
}

const reportColumns = computed((): ReportColumn[] => {
  switch (reportType.value) {
    case 'bookings_by_professional':
      return [
        { key: 'professional_name', label: 'Profesional' },
        { key: 'total_reservations', label: 'Total' },
        { key: 'attended', label: 'Asistió' },
        { key: 'no_show', label: 'Ausente' },
        { key: 'cancelled', label: 'Cancelada' },
        { key: 'attendance_rate', label: '% Asistencia' },
      ]
    case 'occupancy':
      return [
        { key: 'service_name', label: 'Servicio' },
        { key: 'professional_name', label: 'Profesional' },
        { key: 'total_bookings', label: 'Reservas' },
        { key: 'total_capacity', label: 'Capacidad' },
        { key: 'occupancy_rate', label: '% Ocupación' },
      ]
    case 'credit_consumption':
      return [
        { key: 'customer_name', label: 'Cliente' },
        { key: 'credits_consumed', label: 'Consumidos' },
        { key: 'credits_added', label: 'Agregados' },
        { key: 'net_balance', label: 'Saldo Neto' },
      ]
    case 'attendance_rate':
      return [
        { key: 'period', label: 'Período' },
        { key: 'total_reservations', label: 'Total' },
        { key: 'attended', label: 'Asistió' },
        { key: 'no_show', label: 'Ausente' },
        { key: 'cancelled', label: 'Cancelada' },
        { key: 'attendance_rate', label: '% Asistencia' },
      ]
    case 'customer_growth':
      return [
        { key: 'month', label: 'Mes' },
        { key: 'new_customers', label: 'Nuevos Clientes' },
      ]
    case 'service_popularity':
      return [
        { key: 'service_name', label: 'Servicio' },
        { key: 'professional_name', label: 'Profesional' },
        { key: 'total_reservations', label: 'Reservas' },
        { key: 'percentage', label: '% del Total' },
      ]
    case 'cancellations':
      return [
        { key: 'cancellation_date', label: 'Fecha' },
        { key: 'service_name', label: 'Servicio' },
        { key: 'professional_name', label: 'Profesional' },
        { key: 'reason', label: 'Motivo' },
      ]
    default:
      return []
  }
})
</script>

<template>
  <div>
    <h1 class="text-2xl font-bold mb-6" style="color: var(--color-text)">Reportes</h1>

    <!-- Filtros -->
    <div class="rounded-lg shadow p-6 mb-6" style="background-color: var(--color-surface)">
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
        <!-- Tipo de reporte -->
        <div>
          <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Tipo de reporte</label>
          <select
            v-model="reportType"
            class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2"
            :style="{ borderColor: 'var(--color-border)', '--tw-ring-color': 'var(--color-primary)' }"
          >
            <option v-for="rt in reportTypes" :key="rt.value" :value="rt.value">
              {{ rt.label }}
            </option>
          </select>
        </div>

        <!-- Fecha inicio -->
        <div>
          <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Fecha inicio</label>
          <input
            v-model="startDate"
            type="date"
            class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2"
            :style="{ borderColor: 'var(--color-border)', '--tw-ring-color': 'var(--color-primary)' }"
          />
        </div>

        <!-- Fecha fin -->
        <div>
          <label class="block text-sm font-medium mb-1" style="color: var(--color-text)">Fecha fin</label>
          <input
            v-model="endDate"
            type="date"
            class="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2"
            :style="{ borderColor: 'var(--color-border)', '--tw-ring-color': 'var(--color-primary)' }"
          />
        </div>
      </div>

      <!-- Presets de fechas -->
      <div class="flex flex-wrap gap-2 mb-4">
        <button
          v-for="preset in presets"
          :key="preset.label"
          @click="applyPreset(preset)"
          class="px-3 py-1 text-sm rounded-full border transition-colors hover:bg-[var(--color-primary-subtle)]"
          :style="{ borderColor: 'var(--color-border)', color: 'var(--color-text)' }"
        >
          {{ preset.label }}
        </button>
      </div>

      <!-- Botón generar -->
      <button
        @click="generateReport"
        :disabled="loading"
        class="text-white px-6 py-2 rounded-lg disabled:opacity-50"
        :style="{ backgroundColor: 'var(--color-primary)' }"
      >
        {{ loading ? 'Generando...' : 'Generar Reporte' }}
      </button>
    </div>

    <!-- Error -->
    <div v-if="error" class="rounded-lg p-4 mb-6" style="background-color: #fef2f2; color: #991b1b">
      {{ error }}
    </div>

    <!-- Resultados -->
    <div v-if="reportData.length > 0" class="rounded-lg shadow overflow-hidden" style="background-color: var(--color-surface)">
      <!-- Header con exportación -->
      <div class="p-4 flex justify-between items-center" style="border-bottom: 1px solid var(--color-border)">
        <h2 class="font-semibold" style="color: var(--color-text)">
          {{ reportTypes.find(r => r.value === reportType)?.label }}
          <span class="text-sm font-normal" style="color: var(--color-text-muted)">
            ({{ startDate }} al {{ endDate }})
          </span>
        </h2>
        <div class="flex space-x-2">
          <button @click="handleExportCSV" class="px-3 py-1 text-sm rounded border" :style="{ borderColor: 'var(--color-border)', color: 'var(--color-text)' }">
            📄 CSV
          </button>
          <button @click="handleExportExcel" class="px-3 py-1 text-sm rounded border" :style="{ borderColor: 'var(--color-border)', color: 'var(--color-text)' }">
            📊 Excel
          </button>
          <button @click="handleExportPDF" class="px-3 py-1 text-sm rounded border" :style="{ borderColor: 'var(--color-border)', color: 'var(--color-text)' }">
            📑 PDF
          </button>
        </div>
      </div>

      <!-- Tabla -->
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y" :style="{ borderColor: 'var(--color-border)' }">
          <thead :style="{ backgroundColor: 'var(--color-primary-subtle)' }">
            <tr>
              <th
                v-for="col in reportColumns"
                :key="col.key"
                class="px-6 py-3 text-left text-xs font-medium uppercase"
                style="color: var(--color-text-muted)"
              >
                {{ col.label }}
              </th>
            </tr>
          </thead>
          <tbody class="divide-y" :style="{ borderColor: 'var(--color-border)' }">
            <tr v-for="(row, idx) in reportData" :key="idx" :style="{ backgroundColor: idx % 2 === 0 ? 'var(--color-surface)' : 'var(--color-primary-subtle)' }">
              <td
                v-for="col in reportColumns"
                :key="col.key"
                class="px-6 py-4 whitespace-nowrap text-sm"
                style="color: var(--color-text)"
              >
                {{ row[col.key] ?? '-' }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Empty state -->
    <div v-if="!loading && reportData.length === 0 && !error" class="rounded-lg shadow p-8 text-center" style="background-color: var(--color-surface)">
      <p style="color: var(--color-text-muted)">Seleccioná un tipo de reporte y fechas, luego hacé clic en "Generar Reporte".</p>
    </div>
  </div>
</template>
