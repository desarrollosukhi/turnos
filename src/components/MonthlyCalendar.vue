<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  selectedDate: string
  holidays: string[]
  cancelledDates: string[]
  partiallyCancelledDates: string[]
  reservationDates: string[]
  classDays: number[] // días de semana que tienen clases (0=dom, 1=lun, etc.)
}>()

const emit = defineEmits<{
  select: [date: string]
}>()

const today = new Date().toISOString().split('T')[0]

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

  const weeks: { date: string; dayOfMonth: number; isCurrentMonth: boolean; isToday: boolean; isSelected: boolean; hasClasses: boolean; isHoliday: boolean; isCancelled: boolean; isPartiallyCancelled: boolean; hasReservation: boolean }[][] = []

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
            day.hasReservation && day.isCurrentMonth && !day.isSelected ? 'border-2 border-indigo-400 bg-indigo-50' : '',
            !day.isHoliday && !day.isCancelled && day.hasClasses && day.isCurrentMonth && !day.hasReservation ? 'hover:bg-green-50 cursor-pointer' : '',
            !day.hasClasses && day.isCurrentMonth && !day.isHoliday ? 'cursor-default' : '',
          ]"
        >
          <span class="text-xs sm:text-sm">{{ day.dayOfMonth }}</span>

          <!-- Indicators -->
          <div class="flex space-x-0.5 mt-0.5">
            <!-- Holiday indicator -->
            <span
              v-if="day.isHoliday && day.isCurrentMonth"
              class="w-1.5 h-1.5 rounded-full bg-red-500"
              title="Feriado"
            ></span>

            <!-- Cancelled indicator (todos los servicios) -->
            <span
              v-else-if="day.isCancelled && day.isCurrentMonth"
              class="w-1.5 h-1.5 rounded-full bg-gray-400"
              title="Todos los servicios cancelados"
            ></span>

            <!-- Partially cancelled indicator (algunos servicios) -->
            <span
              v-else-if="day.isPartiallyCancelled && day.isCurrentMonth"
              class="w-1.5 h-1.5 rounded-full bg-orange-400"
              title="Algunas clases canceladas"
            ></span>

            <!-- Has classes indicator -->
            <span
              v-else-if="day.hasClasses && day.isCurrentMonth && !day.hasReservation"
              class="w-1.5 h-1.5 rounded-full bg-green-500"
              title="Hay clases"
            ></span>

            <!-- Reservation indicator -->
            <span
              v-if="day.hasReservation && day.isCurrentMonth"
              class="w-1.5 h-1.5 rounded-full bg-indigo-500"
              title="Reservado"
            ></span>
          </div>
        </button>
      </template>
    </div>

    <!-- Legend -->
    <div class="flex flex-wrap items-center justify-center gap-3 mt-4 text-xs text-gray-600">
      <div class="flex items-center space-x-1">
        <span class="w-2 h-2 rounded-full bg-green-500"></span>
        <span>Libre</span>
      </div>
      <div class="flex items-center space-x-1">
        <span class="w-2 h-2 rounded-full bg-indigo-400"></span>
        <span>Reservado</span>
      </div>
      <div class="flex items-center space-x-1">
        <span class="w-2 h-2 rounded-full bg-red-500"></span>
        <span>Feriado</span>
      </div>
      <div class="flex items-center space-x-1">
        <span class="w-2 h-2 rounded-full bg-gray-400"></span>
        <span>Cancelada</span>
      </div>
      <div class="flex items-center space-x-1">
        <span class="w-2 h-2 rounded-full bg-orange-400"></span>
        <span>Parcial</span>
      </div>
    </div>
  </div>
</template>
