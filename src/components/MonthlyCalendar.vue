<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  selectedDate: string
  holidays: string[]
  cancelledDates: string[]
  partiallyCancelledDates: string[]
  reservationDates: string[]
  attendedDates: string[]
  classDays: number[] // días de semana que tienen clases (0=dom, 1=lun, etc.)
}>()

const today = new Date().toISOString().split('T')[0] ?? ''

const emit = defineEmits<{
  select: [date: string]
}>()

const currentMonth = computed(() => {
  const date = new Date(props.selectedDate + 'T12:00:00')
  return date.getMonth()
})

const currentYear = computed(() => {
  const date = new Date(props.selectedDate + 'T12:00:00')
  return date.getFullYear()
})

const monthName = computed(() => {
  const date = new Date(currentYear.value, currentMonth.value)
  return date.toLocaleDateString('es-AR', { month: 'long', year: 'numeric' })
})

const weeks = computed(() => {
  const year = currentYear.value
  const month = currentMonth.value
  const firstDay = new Date(year, month, 1)
  const lastDay = new Date(year, month + 1, 0)
  const startDayOfWeek = firstDay.getDay() // 0=dom, 1=lun...
  const totalDays = lastDay.getDate()

  const weeks: { date: string; dayOfMonth: number; isCurrentMonth: boolean; isToday: boolean; isSelected: boolean; hasClasses: boolean; isHoliday: boolean; isCancelled: boolean; isPartiallyCancelled: boolean; hasReservation: boolean; isAttended: boolean; isPast: boolean }[][] = []

  let currentWeek: typeof weeks[0] = []

  // Días del mes anterior
  const prevMonthLastDay = new Date(year, month, 0).getDate()
  for (let i = startDayOfWeek - 1; i >= 0; i--) {
    const day = prevMonthLastDay - i
    const m = month === 0 ? 11 : month - 1
    const y = month === 0 ? year - 1 : year
    const dateStr = `${y}-${String(m + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`
    currentWeek.push({
      date: dateStr,
      dayOfMonth: day,
      isCurrentMonth: false,
      isToday: dateStr === today,
      isSelected: dateStr === props.selectedDate,
      hasClasses: props.classDays.includes(new Date(dateStr + 'T12:00:00').getDay()),
      isHoliday: props.holidays.includes(dateStr),
      isCancelled: props.cancelledDates.includes(dateStr),
      isPartiallyCancelled: props.partiallyCancelledDates.includes(dateStr),
      hasReservation: props.reservationDates.includes(dateStr),
      isAttended: props.attendedDates.includes(dateStr),
      isPast: dateStr < today,
    })
  }

  // Días del mes actual
  for (let day = 1; day <= totalDays; day++) {
    const dateStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`
    currentWeek.push({
      date: dateStr,
      dayOfMonth: day,
      isCurrentMonth: true,
      isToday: dateStr === today,
      isSelected: dateStr === props.selectedDate,
      hasClasses: props.classDays.includes(new Date(dateStr + 'T12:00:00').getDay()),
      isHoliday: props.holidays.includes(dateStr),
      isCancelled: props.cancelledDates.includes(dateStr),
      isPartiallyCancelled: props.partiallyCancelledDates.includes(dateStr),
      hasReservation: props.reservationDates.includes(dateStr),
      isAttended: props.attendedDates.includes(dateStr),
      isPast: dateStr < today,
    })

    if (currentWeek.length === 7) {
      weeks.push(currentWeek)
      currentWeek = []
    }
  }

  // Días del mes siguiente
  if (currentWeek.length > 0) {
    let nextDay = 1
    while (currentWeek.length < 7) {
      const m = month === 11 ? 0 : month + 1
      const y = month === 11 ? year + 1 : year
      const dateStr = `${y}-${String(m + 1).padStart(2, '0')}-${String(nextDay).padStart(2, '0')}`
      currentWeek.push({
        date: dateStr,
        dayOfMonth: nextDay,
        isCurrentMonth: false,
        isToday: dateStr === today,
        isSelected: dateStr === props.selectedDate,
        hasClasses: props.classDays.includes(new Date(dateStr + 'T12:00:00').getDay()),
        isHoliday: props.holidays.includes(dateStr),
        isCancelled: props.cancelledDates.includes(dateStr),
        isPartiallyCancelled: props.partiallyCancelledDates.includes(dateStr),
        hasReservation: props.reservationDates.includes(dateStr),
        isAttended: props.attendedDates.includes(dateStr),
        isPast: dateStr < today,
      })
      nextDay++
    }
    weeks.push(currentWeek)
  }

  return weeks
})

function prevMonth() {
  const date = new Date(props.selectedDate + 'T12:00:00')
  date.setMonth(date.getMonth() - 1)
  emit('select', date.toISOString().split('T')[0] ?? '')
}

function nextMonth() {
  const date = new Date(props.selectedDate + 'T12:00:00')
  date.setMonth(date.getMonth() + 1)
  emit('select', date.toISOString().split('T')[0] ?? '')
}

function goToToday() {
  emit('select', today ?? '')
}

function selectDate(date: string) {
  emit('select', date)
}

const weekDays = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa', 'Do']
</script>

<template>
  <div class="rounded-lg shadow p-4" style="background-color: var(--color-surface)">
    <!-- Header -->
    <div class="flex items-center justify-between mb-4">
      <button
        @click="prevMonth"
        class="p-2 hover:bg-gray-100 rounded-lg text-gray-600"
      >
        ◄
      </button>
      <div class="flex items-center space-x-3">
        <h3 class="text-lg font-semibold capitalize">{{ monthName }}</h3>
        <button
          @click="goToToday"
          class="text-sm text-blue-600 hover:text-blue-800"
        >
          Hoy
        </button>
      </div>
      <button
        @click="nextMonth"
        class="p-2 hover:bg-gray-100 rounded-lg text-gray-600"
      >
        ►
      </button>
    </div>

    <!-- Week days header -->
    <div class="grid grid-cols-7 gap-1 mb-2">
      <div
        v-for="day in weekDays"
        :key="day"
        class="text-center text-xs font-medium text-gray-500 py-1"
      >
        {{ day }}
      </div>
    </div>

    <!-- Calendar grid -->
    <div class="grid grid-cols-7 gap-1">
      <template v-for="(week, weekIndex) in weeks" :key="weekIndex">
        <button
          v-for="day in week"
          :key="day.date"
          @click="selectDate(day.date)"
          :class="[
            'relative flex flex-col items-center justify-center p-1 sm:p-2 rounded-lg text-sm transition-all min-h-[48px] sm:min-h-[60px]',
            day.isCurrentMonth ? 'text-gray-900' : 'text-gray-300',
            day.isSelected ? 'ring-2 ring-blue-500 bg-blue-50 font-bold' : '',
            day.isToday && !day.isSelected ? 'ring-1 ring-blue-300' : '',
            day.isHoliday && day.isCurrentMonth ? 'bg-red-50 border-2 border-red-300' : '',
            day.isCancelled && day.isCurrentMonth ? 'bg-gray-50 border-2 border-gray-300' : '',
            day.isPartiallyCancelled && day.isCurrentMonth && !day.isSelected ? 'bg-orange-50 border-2 border-orange-300' : '',
            day.hasReservation && day.isCurrentMonth && !day.isSelected ? 'border-2 border-indigo-400 bg-indigo-50' : '',
            day.isAttended && day.isCurrentMonth && !day.isSelected ? 'border-2 border-emerald-400 bg-emerald-50' : '',
            day.isPast && day.isCurrentMonth && !day.isSelected ? 'opacity-50 cursor-not-allowed' : '',
            !day.isPast && !day.isHoliday && !day.isCancelled && day.hasClasses && day.isCurrentMonth && !day.hasReservation ? 'hover:bg-green-50 cursor-pointer' : '',
            !day.hasClasses && day.isCurrentMonth && !day.isHoliday && !day.isPast ? 'cursor-default' : '',
          ]"
        >
          <span class="text-xs sm:text-sm">{{ day.dayOfMonth }}</span>

          <!-- Indicators -->
          <div class="flex space-x-0.5 mt-0.5">
            <!-- Holiday indicator -->
            <span
              v-if="day.isHoliday && day.isCurrentMonth"
              class="w-1.5 h-1.5 rounded-full bg-red-500"
              title="Feriado — No hay clases este día"
            ></span>

            <!-- Cancelled indicator (todos los servicios) -->
            <span
              v-else-if="day.isCancelled && day.isCurrentMonth"
              class="w-1.5 h-1.5 rounded-full bg-gray-400"
              title="Todos los servicios cancelados — No hay clases disponibles"
            ></span>

            <!-- Partially cancelled indicator (algunos servicios) -->
            <span
              v-else-if="day.isPartiallyCancelled && day.isCurrentMonth"
              class="w-1.5 h-1.5 rounded-full bg-orange-400"
              title="Algunas clases canceladas — Hay otras disponibles"
            ></span>

            <!-- Attended indicator -->
            <span
              v-else-if="day.isAttended && day.isCurrentMonth"
              class="w-1.5 h-1.5 rounded-full bg-emerald-500"
              title="Asististe a todas las clases"
            ></span>

            <!-- Has classes indicator -->
            <span
              v-else-if="day.hasClasses && day.isCurrentMonth && !day.hasReservation"
              class="w-1.5 h-1.5 rounded-full bg-green-500"
              title="Hay clases disponibles — Hacé clic para ver servicios"
            ></span>

            <!-- Reservation indicator -->
            <span
              v-else-if="day.hasReservation && day.isCurrentMonth"
              class="w-1.5 h-1.5 rounded-full bg-indigo-500"
              title="Tenés reserva este día"
            ></span>
          </div>
        </button>
      </template>
    </div>

    <!-- Legend -->
    <div class="flex flex-wrap items-center justify-center gap-3 mt-4 text-xs text-gray-600">
      <div class="flex items-center space-x-1 group relative">
        <span class="w-2 h-2 rounded-full bg-green-500"></span>
        <span>Libre</span>
        <span class="hidden group-hover:inline-block absolute bottom-full left-1/2 -translate-x-1/2 mb-1 px-2 py-1 text-xs text-white bg-gray-800 rounded whitespace-nowrap z-10">Hay clases disponibles este día</span>
      </div>
      <div class="flex items-center space-x-1 group relative">
        <span class="w-2 h-2 rounded-full bg-indigo-400"></span>
        <span>Reservado</span>
        <span class="hidden group-hover:inline-block absolute bottom-full left-1/2 -translate-x-1/2 mb-1 px-2 py-1 text-xs text-white bg-gray-800 rounded whitespace-nowrap z-10">Tenés una reserva pendiente</span>
      </div>
      <div class="flex items-center space-x-1 group relative">
        <span class="w-2 h-2 rounded-full bg-emerald-500"></span>
        <span>Asistido</span>
        <span class="hidden group-hover:inline-block absolute bottom-full left-1/2 -translate-x-1/2 mb-1 px-2 py-1 text-xs text-white bg-gray-800 rounded whitespace-nowrap z-10">Asististe a todas las clases</span>
      </div>
      <div class="flex items-center space-x-1 group relative">
        <span class="w-2 h-2 rounded-full bg-red-500"></span>
        <span>Feriado</span>
        <span class="hidden group-hover:inline-block absolute bottom-full left-1/2 -translate-x-1/2 mb-1 px-2 py-1 text-xs text-white bg-gray-800 rounded whitespace-nowrap z-10">Día feriado — no hay clases</span>
      </div>
      <div class="flex items-center space-x-1 group relative">
        <span class="w-2 h-2 rounded-full bg-gray-400"></span>
        <span>Cancelada</span>
        <span class="hidden group-hover:inline-block absolute bottom-full left-1/2 -translate-x-1/2 mb-1 px-2 py-1 text-xs text-white bg-gray-800 rounded whitespace-nowrap z-10">Todos los servicios cancelados</span>
      </div>
      <div class="flex items-center space-x-1 group relative">
        <span class="w-2 h-2 rounded-full bg-orange-400"></span>
        <span>Parcial</span>
        <span class="hidden group-hover:inline-block absolute bottom-full left-1/2 -translate-x-1/2 mb-1 px-2 py-1 text-xs text-white bg-gray-800 rounded whitespace-nowrap z-10">Algunas clases canceladas — hay otras disponibles</span>
      </div>
    </div>
  </div>
</template>
