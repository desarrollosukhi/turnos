<script setup lang="ts">
import { RouterLink } from 'vue-router'
import { Calendar, Users, BarChart3, CreditCard, Settings, Clock, ChevronRight, Shield, Bell, CheckCircle } from 'lucide-vue-next'

const features = [
  { icon: Calendar, title: 'Calendario visual', description: 'Vista mensual con indicadores de color. Reservá y cancelá en un solo clic.' },
  { icon: Users, title: 'Gestión de clientes', description: 'Base de datos completa con historial, créditos y comunicación directa.' },
  { icon: CreditCard, title: 'Sistema de créditos', description: 'Administrá créditos de tus alumnos, historial de movimientos y vencimientos.' },
  { icon: BarChart3, title: 'Reportes', description: 'Asistencia, ocupación, cancelaciones y más. Exportá en CSV, Excel o PDF.' },
  { icon: Settings, title: 'Configuración flexible', description: 'Adaptá el sistema a tu negocio: horarios, profesionales, modalidades y más.' },
  { icon: Bell, title: 'Avisos y comunicaciones', description: 'Creá anuncios para tus alumnos. Cancelaciones y novedades al instante.' },
  { icon: Clock, title: 'Ventana de tiempo', description: 'Configurá cuándo pueden reservar y cancelar. Protegé tu agenda.' },
  { icon: Shield, title: 'Seguro y privado', description: 'Cada negocio tiene sus datos aislados. Tus clientes están seguros.' },
]

const steps = [
  { number: '1', title: 'Creá tu cuenta', description: 'Registrate en segundos sin configuración compleja.' },
  { number: '2', title: 'Configurá tu negocio', description: 'Agregá profesionales, servicios y horarios.' },
  { number: '3', title: 'Recibí reservas', description: 'Tus alumnos reservan online desde cualquier dispositivo.' },
]

const useCases = [
  { emoji: '🧘', title: 'Escuelas de yoga', description: 'Clases grupales con cupos por modalidad.' },
  { emoji: '💪', title: 'Gimnasios', description: 'Entrenadores, horarios y control de asistencia.' },
  { emoji: '✂️', title: 'Peluquerías', description: 'Turnos individuales por profesional.' },
  { emoji: '🏥', title: 'Consultorios', description: 'Citas médicas con gestión de pacientes.' },
]
</script>

<template>
  <div>
    <!-- Hero -->
    <section class="py-20 sm:py-28">
      <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
        <h1 class="text-4xl sm:text-5xl lg:text-6xl font-bold tracking-tight leading-tight" style="color: var(--color-text)">
          Gestión de reservas<br />
          <span style="color: var(--color-primary)">sin complicaciones</span>
        </h1>
        <p class="mt-6 text-lg sm:text-xl max-w-2xl mx-auto" style="color: var(--color-text-muted)">
          La plataforma simple para que tu negocio acepte reservas online.
          Calendario, créditos, reportes y más en un solo lugar.
        </p>
        <div class="mt-10 flex flex-col sm:flex-row items-center justify-center gap-4">
          <RouterLink to="/register"
            class="inline-flex items-center gap-2 px-8 py-3 text-base font-semibold text-white rounded-xl transition-all hover:scale-105 hover:shadow-lg"
            style="background-color: var(--color-primary)">
            Empezá gratis
            <ChevronRight class="w-5 h-5" />
          </RouterLink>
          <a href="#features"
            class="inline-flex items-center gap-2 px-8 py-3 text-base font-semibold rounded-xl border transition-colors hover:opacity-80"
            style="color: var(--color-text-muted); border-color: var(--color-border)">
            Conocé más
          </a>
        </div>

        <!-- Mockup placeholder -->
        <div class="mt-16 mx-auto max-w-4xl">
          <div class="rounded-2xl border p-2 shadow-2xl" style="background-color: var(--color-surface); border-color: var(--color-border)">
            <div class="rounded-xl overflow-hidden" style="background-color: var(--color-background)">
              <svg viewBox="0 0 900 500" class="w-full h-auto" xmlns="http://www.w3.org/2000/svg">
                <rect width="900" height="500" fill="var(--color-surface)" rx="12"/>
                <rect width="900" height="56" fill="var(--color-background)" rx="12"/>
                <rect y="56" width="900" height="1" fill="var(--color-border)"/>
                <rect x="20" y="16" width="120" height="24" rx="6" fill="var(--color-primary)" opacity="0.1"/>
                <rect x="20" y="20" width="80" height="16" rx="4" fill="var(--color-primary)" opacity="0.3"/>
                <rect x="0" y="57" width="200" height="443" fill="var(--color-surface)"/>
                <rect x="0" y="57" width="200" height="443" fill="var(--color-border)" opacity="0.3"/>
                <rect x="16" y="80" width="168" height="32" rx="8" fill="var(--color-primary)" opacity="0.15"/>
                <rect x="16" y="128" width="168" height="32" rx="8" fill="transparent"/>
                <rect x="16" y="176" width="168" height="32" rx="8" fill="transparent"/>
                <rect x="16" y="224" width="168" height="32" rx="8" fill="transparent"/>
                <rect x="224" y="80" width="656" height="400" rx="12" fill="var(--color-surface)"/>
                <rect x="248" y="100" width="140" height="20" rx="6" fill="var(--color-text)" opacity="0.15"/>
                <g opacity="0.6">
                  <rect x="248" y="140" width="80" height="60" rx="8" fill="var(--color-background)"/>
                  <rect x="340" y="140" width="80" height="60" rx="8" fill="var(--color-background)"/>
                  <rect x="432" y="140" width="80" height="60" rx="8" fill="var(--color-primary)" opacity="0.2"/>
                  <rect x="524" y="140" width="80" height="60" rx="8" fill="var(--color-background)"/>
                  <rect x="616" y="140" width="80" height="60" rx="8" fill="var(--color-background)"/>
                  <rect x="708" y="140" width="80" height="60" rx="8" fill="var(--color-background)"/>
                  <rect x="800" y="140" width="80" height="60" rx="8" fill="var(--color-background)"/>
                  <rect x="248" y="210" width="80" height="60" rx="8" fill="var(--color-background)"/>
                  <rect x="340" y="210" width="80" height="60" rx="8" fill="#22c55e" opacity="0.2"/>
                  <rect x="432" y="210" width="80" height="60" rx="8" fill="var(--color-background)"/>
                  <rect x="524" y="210" width="80" height="60" rx="8" fill="var(--color-background)"/>
                  <rect x="616" y="210" width="80" height="60" rx="8" fill="#22c55e" opacity="0.2"/>
                  <rect x="708" y="210" width="80" height="60" rx="8" fill="var(--color-background)"/>
                  <rect x="800" y="210" width="80" height="60" rx="8" fill="var(--color-background)"/>
                  <rect x="248" y="280" width="80" height="60" rx="8" fill="var(--color-background)"/>
                  <rect x="340" y="280" width="80" height="60" rx="8" fill="var(--color-background)"/>
                  <rect x="432" y="280" width="80" height="60" rx="8" fill="#ef4444" opacity="0.15"/>
                  <rect x="524" y="280" width="80" height="60" rx="8" fill="var(--color-background)"/>
                  <rect x="616" y="280" width="80" height="60" rx="8" fill="var(--color-background)"/>
                  <rect x="708" y="280" width="80" height="60" rx="8" fill="#22c55e" opacity="0.2"/>
                  <rect x="800" y="280" width="80" height="60" rx="8" fill="var(--color-background)"/>
                  <rect x="248" y="350" width="80" height="60" rx="8" fill="var(--color-background)"/>
                  <rect x="340" y="350" width="80" height="60" rx="8" fill="var(--color-background)"/>
                  <rect x="432" y="350" width="80" height="60" rx="8" fill="var(--color-background)"/>
                  <rect x="524" y="350" width="80" height="60" rx="8" fill="#22c55e" opacity="0.2"/>
                  <rect x="616" y="350" width="80" height="60" rx="8" fill="var(--color-background)"/>
                  <rect x="708" y="350" width="80" height="60" rx="8" fill="var(--color-background)"/>
                  <rect x="800" y="350" width="80" height="60" rx="8" fill="var(--color-background)"/>
                </g>
              </svg>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Use Cases -->
    <section class="py-20" style="background-color: var(--color-surface)">
      <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-14">
          <h2 class="text-3xl font-bold" style="color: var(--color-text)">¿Para quién es?</h2>
          <p class="mt-4 text-lg" style="color: var(--color-text-muted)">Ideal para cualquier negocio que trabaje con reservas</p>
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          <div v-for="uc in useCases" :key="uc.title"
            class="rounded-xl border p-6 text-center transition-all hover:shadow-md hover:-translate-y-1"
            style="background-color: var(--color-background); border-color: var(--color-border)">
            <div class="text-4xl mb-4">{{ uc.emoji }}</div>
            <h3 class="font-semibold mb-2" style="color: var(--color-text)">{{ uc.title }}</h3>
            <p class="text-sm" style="color: var(--color-text-muted)">{{ uc.description }}</p>
          </div>
        </div>
      </div>
    </section>

    <!-- Features -->
    <section id="features" class="py-20">
      <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-14">
          <h2 class="text-3xl font-bold" style="color: var(--color-text)">Todo lo que necesitás</h2>
          <p class="mt-4 text-lg" style="color: var(--color-text-muted)">Herramientas pensadas para simplificar tu día a día</p>
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          <div v-for="f in features" :key="f.title"
            class="rounded-xl border p-6 transition-all hover:shadow-md hover:-translate-y-1"
            style="background-color: var(--color-surface); border-color: var(--color-border)">
            <div class="w-10 h-10 rounded-lg flex items-center justify-center mb-4" style="background-color: var(--color-primary-subtle)">
              <component :is="f.icon" class="w-5 h-5" style="color: var(--color-primary)" />
            </div>
            <h3 class="font-semibold mb-2" style="color: var(--color-text)">{{ f.title }}</h3>
            <p class="text-sm" style="color: var(--color-text-muted)">{{ f.description }}</p>
          </div>
        </div>
      </div>
    </section>

    <!-- How it works -->
    <section id="how-it-works" class="py-20" style="background-color: var(--color-surface)">
      <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-14">
          <h2 class="text-3xl font-bold" style="color: var(--color-text)">Cómo funciona</h2>
          <p class="mt-4 text-lg" style="color: var(--color-text-muted)">En 3 pasos estás listo</p>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div v-for="step in steps" :key="step.number" class="text-center">
            <div class="w-14 h-14 rounded-full flex items-center justify-center mx-auto mb-5 text-xl font-bold text-white"
              style="background-color: var(--color-primary)">
              {{ step.number }}
            </div>
            <h3 class="font-semibold mb-2" style="color: var(--color-text)">{{ step.title }}</h3>
            <p class="text-sm" style="color: var(--color-text-muted)">{{ step.description }}</p>
          </div>
        </div>
      </div>
    </section>

    <!-- Screenshots -->
    <section class="py-20">
      <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-14">
          <h2 class="text-3xl font-bold" style="color: var(--color-text)">Interfaz simple y clara</h2>
          <p class="mt-4 text-lg" style="color: var(--color-text-muted)">Diseñada para que la uses todos los días sin estrés</p>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
          <!-- Admin Dashboard mockup -->
          <div class="rounded-2xl border p-2 shadow-lg" style="background-color: var(--color-surface); border-color: var(--color-border)">
            <div class="rounded-xl overflow-hidden p-6" style="background-color: var(--color-background)">
              <svg viewBox="0 0 400 280" class="w-full h-auto" xmlns="http://www.w3.org/2000/svg">
                <rect width="400" height="280" fill="var(--color-surface)" rx="8"/>
                <text x="20" y="30" font-family="system-ui" font-size="14" font-weight="bold" fill="var(--color-text)">Dashboard</text>
                <rect x="16" y="44" width="110" height="60" rx="8" fill="var(--color-primary)" opacity="0.1"/>
                <rect x="16" y="44" width="110" height="4" rx="2" fill="var(--color-primary)" opacity="0.4"/>
                <text x="28" y="70" font-family="system-ui" font-size="10" fill="var(--color-text-muted)">Reservas hoy</text>
                <text x="28" y="88" font-family="system-ui" font-size="18" font-weight="bold" fill="var(--color-text)">24</text>
                <rect x="142" y="44" width="110" height="60" rx="8" fill="#22c55e" opacity="0.1"/>
                <rect x="142" y="44" width="110" height="4" rx="2" fill="#22c55e" opacity="0.4"/>
                <text x="154" y="70" font-family="system-ui" font-size="10" fill="var(--color-text-muted)">Clientes</text>
                <text x="154" y="88" font-family="system-ui" font-size="18" font-weight="bold" fill="var(--color-text)">156</text>
                <rect x="268" y="44" width="116" height="60" rx="8" fill="#f59e0b" opacity="0.1"/>
                <rect x="268" y="44" width="116" height="4" rx="2" fill="#f59e0b" opacity="0.4"/>
                <text x="280" y="70" font-family="system-ui" font-size="10" fill="var(--color-text-muted)">Créditos vendidos</text>
                <text x="280" y="88" font-family="system-ui" font-size="18" font-weight="bold" fill="var(--color-text)">89</text>
                <rect x="16" y="120" width="368" height="32" rx="6" fill="var(--color-background)"/>
                <text x="28" y="140" font-family="system-ui" font-size="10" fill="var(--color-text-muted)">Próximas reservas</text>
                <rect x="16" y="160" width="368" height="28" rx="4" fill="transparent"/>
                <circle cx="30" cy="174" r="8" fill="var(--color-primary)" opacity="0.2"/>
                <rect x="46" y="168" width="100" height="12" rx="4" fill="var(--color-text)" opacity="0.1"/>
                <rect x="160" y="168" width="60" height="12" rx="4" fill="#22c55e" opacity="0.2"/>
                <rect x="240" y="168" width="80" height="12" rx="4" fill="var(--color-text)" opacity="0.06"/>
                <rect x="16" y="196" width="368" height="28" rx="4" fill="transparent"/>
                <circle cx="30" cy="210" r="8" fill="#22c55e" opacity="0.2"/>
                <rect x="46" y="204" width="90" height="12" rx="4" fill="var(--color-text)" opacity="0.1"/>
                <rect x="150" y="204" width="50" height="12" rx="4" fill="#22c55e" opacity="0.2"/>
                <rect x="220" y="204" width="70" height="12" rx="4" fill="var(--color-text)" opacity="0.06"/>
                <rect x="16" y="232" width="368" height="28" rx="4" fill="transparent"/>
                <circle cx="30" cy="246" r="8" fill="#f59e0b" opacity="0.2"/>
                <rect x="46" y="240" width="110" height="12" rx="4" fill="var(--color-text)" opacity="0.1"/>
                <rect x="170" y="240" width="55" height="12" rx="4" fill="#22c55e" opacity="0.2"/>
                <rect x="240" y="240" width="90" height="12" rx="4" fill="var(--color-text)" opacity="0.06"/>
              </svg>
            </div>
          </div>

          <!-- Client Calendar mockup -->
          <div class="rounded-2xl border p-2 shadow-lg" style="background-color: var(--color-surface); border-color: var(--color-border)">
            <div class="rounded-xl overflow-hidden p-6" style="background-color: var(--color-background)">
              <svg viewBox="0 0 400 280" class="w-full h-auto" xmlns="http://www.w3.org/2000/svg">
                <rect width="400" height="280" fill="var(--color-surface)" rx="8"/>
                <text x="20" y="30" font-family="system-ui" font-size="14" font-weight="bold" fill="var(--color-text)">Agosto 2026</text>
                <text x="40" y="55" font-family="system-ui" font-size="9" fill="var(--color-text-muted)">Lun</text>
                <text x="90" y="55" font-family="system-ui" font-size="9" fill="var(--color-text-muted)">Mar</text>
                <text x="140" y="55" font-family="system-ui" font-size="9" fill="var(--color-text-muted)">Mié</text>
                <text x="190" y="55" font-family="system-ui" font-size="9" fill="var(--color-text-muted)">Jue</text>
                <text x="240" y="55" font-family="system-ui" font-size="9" fill="var(--color-text-muted)">Vie</text>
                <text x="290" y="55" font-family="system-ui" font-size="9" fill="var(--color-text-muted)">Sáb</text>
                <text x="340" y="55" font-family="system-ui" font-size="9" fill="var(--color-text-muted)">Dom</text>
                <circle cx="48" cy="78" r="14" fill="#22c55e" opacity="0.2"/>
                <text x="44" y="82" font-family="system-ui" font-size="10" fill="var(--color-text)">29</text>
                <circle cx="98" cy="78" r="14" fill="#22c55e" opacity="0.2"/>
                <text x="94" y="82" font-family="system-ui" font-size="10" fill="var(--color-text)">30</text>
                <circle cx="148" cy="78" r="14" fill="var(--color-primary)" opacity="0.15"/>
                <text x="144" y="82" font-family="system-ui" font-size="10" fill="var(--color-text)">31</text>
                <circle cx="198" cy="78" r="14" fill="var(--color-background)"/>
                <text x="194" y="82" font-family="system-ui" font-size="10" fill="var(--color-text-muted)">1</text>
                <circle cx="248" cy="78" r="14" fill="#22c55e" opacity="0.2"/>
                <text x="244" y="82" font-family="system-ui" font-size="10" fill="var(--color-text)">2</text>
                <circle cx="298" cy="78" r="14" fill="var(--color-background)"/>
                <text x="294" y="82" font-family="system-ui" font-size="10" fill="var(--color-text-muted)">3</text>
                <circle cx="348" cy="78" r="14" fill="var(--color-background)"/>
                <text x="344" y="82" font-family="system-ui" font-size="10" fill="var(--color-text-muted)">4</text>
                <circle cx="48" cy="110" r="14" fill="var(--color-background)"/>
                <text x="44" y="114" font-family="system-ui" font-size="10" fill="var(--color-text-muted)">5</text>
                <circle cx="98" cy="110" r="14" fill="#22c55e" opacity="0.2"/>
                <text x="94" y="114" font-family="system-ui" font-size="10" fill="var(--color-text)">6</text>
                <circle cx="148" cy="110" r="14" fill="var(--color-background)"/>
                <text x="144" y="114" font-family="system-ui" font-size="10" fill="var(--color-text-muted)">7</text>
                <circle cx="198" cy="110" r="14" fill="#22c55e" opacity="0.2"/>
                <text x="194" y="114" font-family="system-ui" font-size="10" fill="var(--color-text)">8</text>
                <circle cx="248" cy="110" r="14" fill="var(--color-background)"/>
                <text x="244" y="114" font-family="system-ui" font-size="10" fill="var(--color-text-muted)">9</text>
                <circle cx="298" cy="110" r="14" fill="var(--color-background)"/>
                <text x="294" y="114" font-family="system-ui" font-size="10" fill="var(--color-text-muted)">10</text>
                <circle cx="348" cy="110" r="14" fill="var(--color-background)"/>
                <text x="344" y="114" font-family="system-ui" font-size="10" fill="var(--color-text-muted)">11</text>
                <circle cx="48" cy="142" r="14" fill="#22c55e" opacity="0.2"/>
                <text x="44" y="146" font-family="system-ui" font-size="10" fill="var(--color-text)">12</text>
                <circle cx="98" cy="142" r="14" fill="var(--color-background)"/>
                <text x="94" y="146" font-family="system-ui" font-size="10" fill="var(--color-text-muted)">13</text>
                <circle cx="148" cy="142" r="14" fill="var(--color-primary)" opacity="0.3" stroke="var(--color-primary)" stroke-width="2"/>
                <text x="144" y="146" font-family="system-ui" font-size="10" font-weight="bold" fill="var(--color-primary)">14</text>
                <circle cx="198" cy="142" r="14" fill="var(--color-background)"/>
                <text x="194" y="146" font-family="system-ui" font-size="10" fill="var(--color-text-muted)">15</text>
                <circle cx="248" cy="142" r="14" fill="#ef4444" opacity="0.15"/>
                <text x="244" y="146" font-family="system-ui" font-size="10" fill="#ef4444">16</text>
                <circle cx="298" cy="142" r="14" fill="var(--color-background)"/>
                <text x="294" y="146" font-family="system-ui" font-size="10" fill="var(--color-text-muted)">17</text>
                <circle cx="348" cy="142" r="14" fill="var(--color-background)"/>
                <text x="344" y="146" font-family="system-ui" font-size="10" fill="var(--color-text-muted)">18</text>
                <circle cx="48" cy="174" r="14" fill="var(--color-background)"/>
                <text x="44" y="178" font-family="system-ui" font-size="10" fill="var(--color-text-muted)">19</text>
                <circle cx="98" cy="174" r="14" fill="#22c55e" opacity="0.2"/>
                <text x="94" y="178" font-family="system-ui" font-size="10" fill="var(--color-text)">20</text>
                <circle cx="148" cy="174" r="14" fill="var(--color-background)"/>
                <text x="144" y="178" font-family="system-ui" font-size="10" fill="var(--color-text-muted)">21</text>
                <circle cx="198" cy="174" r="14" fill="var(--color-background)"/>
                <text x="194" y="178" font-family="system-ui" font-size="10" fill="var(--color-text-muted)">22</text>
                <circle cx="248" cy="174" r="14" fill="#22c55e" opacity="0.2"/>
                <text x="244" y="178" font-family="system-ui" font-size="10" fill="var(--color-text)">23</text>
                <circle cx="298" cy="174" r="14" fill="var(--color-background)"/>
                <text x="294" y="178" font-family="system-ui" font-size="10" fill="var(--color-text-muted)">24</text>
                <circle cx="348" cy="174" r="14" fill="var(--color-background)"/>
                <text x="344" y="178" font-family="system-ui" font-size="10" fill="var(--color-text-muted)">25</text>
                <rect x="20" y="220" width="360" height="48" rx="8" fill="var(--color-background)"/>
                <circle cx="44" cy="244" r="6" fill="#22c55e" opacity="0.3"/>
                <text x="56" y="248" font-family="system-ui" font-size="9" fill="var(--color-text-muted)">Disponible</text>
                <circle cx="124" cy="244" r="6" fill="var(--color-primary)" opacity="0.3"/>
                <text x="136" y="248" font-family="system-ui" font-size="9" fill="var(--color-text-muted)">Reservado</text>
                <circle cx="210" cy="244" r="6" fill="#ef4444" opacity="0.2"/>
                <text x="222" y="248" font-family="system-ui" font-size="9" fill="var(--color-text-muted)">Feriado</text>
                <circle cx="280" cy="244" r="6" fill="var(--color-text-muted)" opacity="0.15"/>
                <text x="292" y="248" font-family="system-ui" font-size="9" fill="var(--color-text-muted)">Cancelado</text>
              </svg>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- CTA -->
    <section id="contact" class="py-20" style="background-color: var(--color-surface)">
      <div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
        <h2 class="text-3xl font-bold mb-4" style="color: var(--color-text)">¿Listo para organizar tu negocio?</h2>
        <p class="text-lg mb-10" style="color: var(--color-text-muted)">
          Creá tu cuenta en un minuto y empezá a gestionar tus reservas hoy mismo.
        </p>
        <RouterLink to="/register"
          class="inline-flex items-center gap-2 px-10 py-4 text-lg font-semibold text-white rounded-xl transition-all hover:scale-105 hover:shadow-lg"
          style="background-color: var(--color-primary)">
          Creá tu cuenta gratis
          <ChevronRight class="w-5 h-5" />
        </RouterLink>
      </div>
    </section>
  </div>
</template>
