<script setup lang="ts">
import { ref, computed, onMounted, nextTick } from 'vue'
import { marked } from 'marked'
import { RouterLink } from 'vue-router'

marked.setOptions({
  renderer: new marked.Renderer(),
})

function slugify(text: string): string {
  return text
    .toLowerCase()
    .normalize('NFD').replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '')
}

const originalHeading = marked.Renderer.prototype.heading

marked.Renderer.prototype.heading = function ({ text, depth }: { text: string; depth: number }) {
  const id = slugify(typeof text === 'string' ? text : String(text))
  return `<h${depth} id="${id}">${text}</h${depth}>`
}

interface DocSection {
  id: string
  title: string
  content: string
}

interface DocGroup {
  id: string
  title: string
  icon: string
  sections: DocSection[]
}

const activeTab = ref<'admin' | 'professional' | 'customer'>('admin')
const activeSection = ref('')
const mobileMenuOpen = ref(false)

const tabs = [
  { id: 'admin' as const, label: 'Administrador', icon: '👨‍💼' },
  { id: 'professional' as const, label: 'Profesional', icon: '🎓' },
  { id: 'customer' as const, label: 'Cliente', icon: '👤' },
]

const adminDocs: DocGroup[] = [
  {
    id: 'admin-dashboard',
    title: 'Inicio (Dashboard)',
    icon: '📊',
    sections: [
      {
        id: 'admin-dashboard-overview',
        title: 'Vista general',
        content: `## Dashboard del Administrador

El dashboard es tu pantalla principal donde ves un resumen rápido de tu negocio.

### Qué ves en el dashboard

- **Reservas de hoy**: cantidad total de reservas para el día actual
- **Clientes activos**: total de clientes registrados en tu negocio
- **Servicios próximos**: lista de servicios que se impartirán pronto
- **Créditos vendidos**: resumen de actividad de créditos

### Cómo usarlo

1. Iniciá sesión como administrador
2. El dashboard se muestra automáticamente
3. Usá los botones de acceso rápido para ir a otras secciones
4. Actualizá la página para ver datos en tiempo real

> **Tip**: El dashboard se actualiza automáticamente cuando hay cambios en reservas o clientes.`
      }
    ]
  },
  {
    id: 'admin-customers',
    title: 'Clientes',
    icon: '👥',
    sections: [
      {
        id: 'admin-customers-list',
        title: 'Ver y buscar clientes',
        content: `## Gestión de Clientes

### Ver la lista de clientes

1. Andá a **Clientes** en el menú lateral
2. Vas a ver una tabla con todos los clientes registrados
3. Usá la barra de búsqueda para encontrar un cliente específico

### Información de cada cliente

- **Nombre**: nombre completo del cliente
- **Email**: correo electrónico (si tiene cuenta)
- **Teléfono**: número de contacto
- **Créditos**: saldo actual de créditos
- **Estado**: activo o inactivo

### Buscar clientes

1. Escribí nombre, email o teléfono en la barra de búsqueda
2. La lista se filtra automáticamente
3. Para limpiar la búsqueda, borrá el texto`
      },
      {
        id: 'admin-customers-create',
        title: 'Crear cliente',
        content: `## Crear un Nuevo Cliente

### Paso 1: Abrir el formulario

1. Hacé clic en **"+ Agregar cliente"**
2. Se abre un formulario con los campos del cliente

### Paso 2: Completar los datos

**Si tu negocio es modo MIEMBRO (con login):**

1. Completá nombre, email y teléfono
2. El sistema genera credenciales automáticamente
3. Se muestra un recuadro verde con las credenciales
4. **Copiá las credenciales** y compartilas con el cliente

**Si tu negocio es modo INVITADO (sin login):**

1. Completá solo nombre y teléfono
2. No se crea cuenta de acceso
3. El admin gestiona las reservas desde el panel

### Paso 3: Guardar

1. Hacé clic en **"Guardar"**
2. El cliente se agrega a la lista

> **Importante**: En modo MIEMBRO, el cliente debe cambiar su contraseña al iniciar sesión por primera vez.`
      },
      {
        id: 'admin-customers-credits',
        title: 'Administrar créditos',
        content: `## Administrar Créditos de Clientes

### Agregar créditos

1. Buscá al cliente en la lista
2. Hacé clic en **"Agregar créditos"**
3. Ingresá la cantidad de créditos
4. Agregá una descripción (opcional)
5. Confirmá la operación

### Quitar créditos

1. Buscá al cliente en la lista
2. Hacé clic en **"Quitar créditos"**
3. Ingresá la cantidad a quitar
4. Confirmá la operación

### Ver historial de movimientos

1. Hacé clic en el nombre del cliente
2. Andá a la pestaña **"Créditos"**
3. Ahí ves todos los movimientos: cargas, consumos, vencimientos

### Reglas importantes

- Los créditos no pueden ser negativos
- Cada crédito tiene una fecha de vencimiento (1 mes + 1 día)
- Los créditos se consumen en orden FIFO (primero los más antiguos)
- Al cancelar una reserva, se devuelven los créditos`
      }
    ]
  },
  {
    id: 'admin-professionals',
    title: 'Profesionales',
    icon: '🧑‍🏫',
    sections: [
      {
        id: 'admin-professionals-create',
        title: 'Crear profesional',
        content: `## Crear un Profesional

### Paso 1: Abrir el formulario

1. Andá a **Profesionales** en el menú lateral
2. Hacé clic en **"+ Agregar profesional"**

### Paso 2: Completar los datos

1. **Nombre**: nombre del profesional
2. **Alias** (opcional): nombre que se muestra en lugar del nombre real (si está activado en configuración)
3. **Email**: correo electrónico (se usa para login)
4. **Teléfono**: número de contacto
5. **WhatsApp**: número de WhatsApp (opcional)

### Paso 3: Credenciales

Al crear el profesional con email:

1. Se genera automáticamente una contraseña de 8 caracteres
2. Se muestra un recuadro verde con las credenciales
3. **Copiá las credenciales** y compartilas con el profesional
4. El profesional debe cambiar su contraseña al iniciar sesión

### Paso 4: Guardar

1. Hacé clic en **"Guardar"**
2. El profesional aparece en la lista

### Editar profesional

1. Hacé clic en el nombre del profesional
2. Modificá los datos que necesites
3. Guardá los cambios

### Alias

El alias se usa para mostrar un nombre diferente en la interfaz del cliente. Por ejemplo, si el profesional se llama "María González" pero prefiere que la vean como "Profe Mari".

- Activá **"Mostrar alias"** en Configuración → Empresa
- Configurá el alias en cada profesional`
      }
    ]
  },
  {
    id: 'admin-services',
    title: 'Servicios',
    icon: '📋',
    sections: [
      {
        id: 'admin-services-create',
        title: 'Crear servicio',
        content: `## Crear un Servicio

### Paso 1: Abrir el formulario

1. Andá a **Servicios** en el menú lateral
2. Hacé clic en **"+ Agregar servicio"**

### Paso 2: Configurar el servicio

#### Datos básicos

1. **Nombre**: nombre del servicio (ej: "Yoga Vinyasa", "Corte de pelo")
2. **Profesional**: seleccioná qué profesional imparte el servicio
3. **Recurso** (opcional): espacio físico asociado (sala, silla, consultorio)

#### Modalidad

Elegí una o ambas modalidades:

- **Presencial**: clases en el lugar físico
- **Virtual**: clases por videoconferencia
- **Híbrida**: ambas modalidades disponibles

Si elegís presencial o virtual, configurá la **capacidad** (cantidad de lugares disponibles).

#### Frecuencia

**Semanal** (para clases recurrentes):

1. Seleccioná el/los día/s de la semana
2. Configurá hora de inicio y fin
3. La clase se repite cada semana en esos días

**Turnos** (para turnos individuales):

1. Configurá el intervalo de turnos
2. Cada turno tiene duración fija
3. Los clientes eligen un turno específico

**Evento** (para eventos únicos):

1. Seleccioná una fecha específica
2. Configurá hora de inicio y fin
3. El evento ocurre solo una vez

### Paso 3: Guardar

1. Revisá que todos los datos estén correctos
2. Hacé clic en **"Guardar"**
3. El servicio aparece en la lista

### Editar servicio

1. Hacé clic en el nombre del servicio
2. Modificá los datos
3. Guardá los cambios

> **Nota**: Los servicios con reservas activas no se pueden eliminar, solo desactivar.`
      }
    ]
  },
  {
    id: 'admin-bookings',
    title: 'Reservas',
    icon: '📅',
    sections: [
      {
        id: 'admin-bookings-view',
        title: 'Ver reservas',
        content: `## Gestión de Reservas

### Ver todas las reservas

1. Andá a **Reservas** en el menú lateral
2. Vas a ver una tabla con todas las reservas
3. Filtrá por fecha, servicio o estado

### Filtros disponibles

- **Fecha**: seleccioná un día específico
- **Servicio**: filtrá por servicio
- **Estado**: pendiente, confirmada, cancelada, asistió, ausente

### Estados de reserva

- **Pendiente**: reserva creada, esperando confirmación
- **Confirmada**: reserva válida, el cliente asistirá
- **Asistió**: el cliente asistió a la clase
- **Ausente**: el cliente no se presentó
- **Cancelada**: reserva cancelada

### Marcar asistencia

1. En la lista de reservas, buscá al cliente
2. Hacé clic en **"Asistió"** o **"Ausente"**
3. El estado se actualiza automáticamente`
      },
      {
        id: 'admin-bookings-cancel-session',
        title: 'Cancelar sesión',
        content: `## Cancelar una Sesión Completa

Cuando necesitás cancelar una clase por emergencia (enfermedad del profesor, corte de luz, etc.), podés cancelar la sesión completa.

### Qué hace cancelar una sesión

1. Se cancelan **TODAS** las reservas activas de esa fecha y servicio
2. Se **devuelven los créditos** a cada cliente afectado
3. Se marca la sesión como cancelada en el sistema

### Cómo cancelar una sesión

1. Andá a **Reservas**
2. Hacé clic en **"Cancelar sesión"**
3. Seleccioná el servicio y la fecha
4. Escribí el motivo (opcional)
5. Confirmá la cancelación

### Resultado

- Todas las reservas de esa sesión se cancelan automáticamente
- Los clientes reciben sus créditos de vuelta
- El calendario muestra la sesión como cancelada (indicador gris)

> **Importante**: Esta acción no se puede deshacer. Asegurate de seleccionar la fecha correcta.`
      }
    ]
  },
  {
    id: 'admin-reports',
    title: 'Reportes',
    icon: '📈',
    sections: [
      {
        id: 'admin-reports-types',
        title: 'Tipos de reportes',
        content: `## Reportes Disponibles

El sistema genera 7 tipos de reportes para analizar tu negocio.

### 1. Reservas por profesional

Muestra cuántas reservas tiene cada profesional en un período.

- Útil para ver qué profesionales son más demandados
- Ayuda a planificar horarios y нагруз

### 2. Ocupación de servicios

Indica qué porcentaje de los cupos se llenan en cada servicio.

- Identificá servicios con baja ocupación
- Tomá decisiones sobre horarios y capacities

### 3. Consumo de créditos

Detalla cuántos créditos se usaron, cuándo y por quién.

- Seguí el flujo de créditos
- Identificá patrones de consumo

### 4. Tasa de asistencia

Calcula el porcentaje de clientes que asisten vs los que no.

- Medí la satisfacción de los clientes
- Identificá problemas de asistencia

### 5. Clientes nuevos

Muestra cuántos clientes se registraron en un período.

- Seguí el crecimiento de tu negocio
- Evaluá estrategias de captación

### 6. Servicios más demandados

Ranking de servicios por cantidad de reservas.

- Identificá qué servicios son más populares
- Optimizá tu oferta de servicios

### 7. Cancelaciones

Detalla las cancelaciones por motivo y período.

- Identificá patrones de cancelación
- Mejorá tus políticas de cancelación

### Exportar reportes

1. Seleccioná el tipo de reporte
2. Configurá el período
3. Hacé clic en **"Generar"**
4. Elegí el formato: **CSV**, **Excel** o **PDF**
5. Descargá el archivo`
      }
    ]
  },
  {
    id: 'admin-settings',
    title: 'Configuración',
    icon: '⚙️',
    sections: [
      {
        id: 'admin-settings-company',
        title: 'Configuración de empresa',
        content: `## Configuración de tu Empresa

### Datos básicos

1. **Nombre**: nombre de tu negocio
2. **Logo**: subí el logo de tu empresa (formato imagen)
3. **Business Type**: tipo de negocio (Yoga, Gimnasio, Peluquería, etc.)

### Modalidades

- **Permitir virtual**: activá si ofrecés clases virtuales
- **Requerir login**: si los clientes necesitan cuenta para reservar

### Ventana de tiempo

Configurá cuántos minutos antes puede reservar o cancelar un cliente:

- **Minutos para reserva**: cuánto tiempo antes del servicio se puede reservar (default: 30 min)
- **Minutos para cancelación**: cuánto tiempo antes se puede cancelar (default: 30 min)

Si un cliente intenta reservar o cancelar fuera de la ventana, se le muestra un modal con explicación y link de WhatsApp.

### WhatsApp

Configurá el número de WhatsApp para contacto. Se usa en el modal de ventana de tiempo y en el botón de contacto.

### Modo Gimnasio

Si activás el modo gimnasio:

- Los clientes pueden acceder sin reservar (free pass)
- Se configuran horarios de apertura por día
- Se gestiona la asistencia de manera diferente

### Historia Clínica

Si activás la historia clínica:

- Los profesionales pueden completar información clínica de cada cliente
- Se guarda un historial por cliente
- Útil para consultorios médicos, kinesiólogos, etc.

### Temas

Elegí entre 16 temas de colores predefinidos:

1. Hacé clic en Configuración → Temas
2. Previsualizá cada tema
3. Seleccioná el que más te guste
4. Los cambios se aplican inmediatamente`
      },
      {
        id: 'admin-settings-holidays',
        title: 'Feriados',
        content: `## Gestión de Feriados

Los feriados bloquean las reservas en esos días. Si un día es feriado activo, no se pueden hacer reservas.

### Feriados nacionales (auto-sync)

El sistema carga automáticamente los feriados nacionales de Argentina desde la API de ArgentinaDatos.

1. Andá a **Configuración → Feriados**
2. Los feriados se cargan automáticamente al abrir la página
3. Hacé clic en **"🔄 Sincronizar"** para actualizar desde la API
4. Se sincronizan el año actual y el siguiente

### Feriados manuales

Podés crear feriados propios (ej: "Día del establishment", "Feriado local"):

1. Hacé clic en **"+ Agregar"**
2. Ingresá la fecha y el nombre
3. Guardá

### Activar/Desactivar

- Cada feriado tiene un toggle para activarlo o desactivarlo
- Solo los feriados **activos** bloquean las reservas
- Usá **"Activar/Desactivar todos"** para cambiar el estado de todos a la vez

### Buscar feriados

1. Usá el buscador por nombre o fecha
2. La lista se filtra automáticamente

> **Nota**: Los feriados nacionales se sincronizan con la API oficial. Si necesitás feriados locales, crealos manualmente.`
      },
      {
        id: 'admin-settings-announcements',
        title: 'Avisos',
        content: `## Gestión de Avisos

Los avisos son mensajes que se muestran a los clientes cuando inician sesión. Útil para comunicar novedades, recordatorios o cambios de horario.

### Crear un aviso

1. Andá a **Avisos** en el menú lateral
2. Hacé clic en **"+ Crear aviso"**
3. Completá:
   - **Título**: asunto del aviso
   - **Contenido**: mensaje (usá el editor rich text)
   - **Destinatarios**: "Todos los clientes" o un servicio específico
4. Guardá

### Editor rich text

El editor permite:

- **Negrita**, *cursiva*, ~~tachado~~
- Listas con viñetas
- Enlaces
- Títulos y subtítulos
- Código

### Tipos de descarte

Cuando un cliente ve un aviso, tiene dos opciones:

- **"Recordarme después"**: el aviso vuelve a mostrarse la próxima vez que inicie sesión
- **"No mostrar más"**: el aviso no se vuelve a mostrar (se guarda en localStorage)

### Reactivar avisos

Si un cliente descartó un aviso y vos lo reactivás:

1. Andá a **Avisos**
2. Buscá el aviso
3. Hacé clic en **"Reactivar"**
4. El aviso vuelve a mostrarse a ese cliente

### Avisos automáticos

Cuando cancelás una sesión de emergencia, se crea automáticamente un aviso para todos los clientes afectados comunicando la cancelación.`
      }
    ]
  },
]

const professionalDocs: DocGroup[] = [
  {
    id: 'pro-dashboard',
    title: 'Dashboard',
    icon: '📊',
    sections: [
      {
        id: 'pro-dashboard-overview',
        title: 'Vista general',
        content: `## Dashboard del Profesional

Tu dashboard muestra un resumen de tu actividad del día.

### Qué ves

- **Servicios de hoy**: lista de clases que impartís hoy
- **Reservas**: cuántos clientes tiene cada servicio
- **Horarios**: hora de inicio y fin de cada servicio

### Navegación

1. Desde el dashboard, hacé clic en un servicio para ver sus reservas
2. Usá el menú lateral para ir a otras secciones
3. Actualizá la página para ver cambios en tiempo real`
      }
    ]
  },
  {
    id: 'pro-services',
    title: 'Mis Servicios',
    icon: '📋',
    sections: [
      {
        id: 'pro-services-list',
        title: 'Ver servicios asignados',
        content: `## Mis Servicios

### Ver la lista completa

1. Andá a **Mis Servicios** en el menú lateral
2. Vas a ver todos los servicios que te están asignados

### Información de cada servicio

- **Nombre**: nombre del servicio
- **Día**: día de la semana (para servicios semanales)
- **Horario**: hora de inicio y fin
- **Modalidad**: presencial, virtual o híbrida
- **Cupos**: lugares disponibles

### Filtrar servicios

1. Usá los filtros por día o modalidad
2. La lista se actualiza automáticamente`
      }
    ]
  },
  {
    id: 'pro-bookings',
    title: 'Reservas',
    icon: '📅',
    sections: [
      {
        id: 'pro-bookings-view',
        title: 'Ver reservas de mis servicios',
        content: `## Ver Reservas

### Acceder a las reservas

1. Andá a **Reservas** en el menú lateral
2. Seleccioná el servicio que querés consultar
3. Elegí la fecha

### Lista de reservas

Para cada reserva vas a ver:

- **Cliente**: nombre del cliente
- **Estado**: pendiente, confirmada, asistió, ausente
- **Modalidad**: presencial o virtual
- **Horario**: hora del servicio

### Filtrar por fecha

1. Usá el selector de fecha
2. Seleccioná el día que querés consultar
3. La lista se actualiza

### Marcar asistencia

1. En la lista de reservas, buscá al cliente
2. Hacé clic en **"Asistió"** si el cliente se presentó
3. Hacé clic en **"Ausente"** si no se presentó
4. El estado se guarda automáticamente

> **Tip**: Marcar la asistencia ayuda al admin a generar reportes de tasa de asistencia.`
      },
      {
        id: 'pro-clinical-history',
        title: 'Historia clínica',
        content: `## Historia Clínica

Si tu negocio tiene activada la historia clínica, podés acceder a ella desde el portal del profesional.

### Acceder a la historia clínica

1. Andá a **Reservas**
2. Buscá al cliente
3. Hacé clic en **"📋 Historia"**
4. Se abre el formulario de historia clínica

### Completar la historia clínica

1. Los campos predefinidos se muestran automáticamente
2. Completá la información relevante
3. Usá el campo de texto libre para notas adicionales
4. Guardá los cambios

### Información guardada

La historia clínica se guarda por cliente y es accesible:

- Desde cualquier reserva del mismo cliente
- Por otros profesionales de la misma empresa
- Por el administrador

> **Nota**: La historia clínica es confidencial. Solo personal autorizado puede acceder.`
      }
    ]
  },
]

const customerDocs: DocGroup[] = [
  {
    id: 'cust-home',
    title: 'Inicio',
    icon: '🏠',
    sections: [
      {
        id: 'cust-home-overview',
        title: 'Mi pantalla de inicio',
        content: `## Pantalla de Inicio

Cuando iniciás sesión, ves tu pantalla de inicio con información personal.

### Qué ves

- **Créditos disponibles**: saldo actual de tus créditos
- **Links rápidos**: acceso directo a Servicios, Mis Reservas, etc.
- **Avisos**: mensajes importantes de tu negocio (si los hay)

### Navegación

1. Hacé clic en **"Servicios"** para ver el calendario y reservar
2. Hacé clic en **"Mis Reservas"** para ver tus reservas
3. Hacé clic en **"Mis Créditos"** para ver tu saldo e historial
4. Hacé clic en **"Mi Cuenta"** para cambiar tu contraseña`
      }
    ]
  },
  {
    id: 'cust-services',
    title: 'Calendario de Servicios',
    icon: '📅',
    sections: [
      {
        id: 'cust-services-calendar',
        title: 'Navegar el calendario',
        content: `## Calendario de Servicios

### Cómo funciona el calendario

El calendario muestra un resumen mensual con indicadores de color:

- **Verde** 🟢 = hay servicios disponibles para reservar
- **Azul** 🔵 = ya tenés una reserva ese día
- **Rojo** 🔴 = es feriado (no se puede reservar)
- **Gris** ⚪ = servicio cancelado

### Navegar entre meses

1. Usá las flechas **←** **→** para cambiar de mes
2. Hacé clic en **"Hoy"** para volver al día actual
3. Seleccioná un día para ver los servicios disponibles

### Reservar un servicio

1. Seleccioná un día en el calendario
2. Se muestran los servicios disponibles para ese día
3. Hacé clic en **"Reservar"** junto al servicio que querés
4. Si el servicio tiene varias modalidades, elegí:
   - **Presencial**: asistís al lugar físico
   - **Virtual**: asistís por videoconferencia
5. Confirmá la reserva

### Cancelar una reserva

1. Andá a **Mis Reservas**
2. Buscá la reserva que querés cancelar
3. Hacé clic en **"Cancelar"**
4. Confirmá la cancelación
5. Se te devuelven los créditos

> **Importante**: Solo podés cancelar dentro de la ventana de tiempo configurada por el admin. Si intentás cancelar fuera de la ventana, se te mostrará un modal con opciones de contacto.`
      }
    ]
  },
  {
    id: 'cust-bookings',
    title: 'Mis Reservas',
    icon: '📋',
    sections: [
      {
        id: 'cust-bookings-tabs',
        title: 'Ver mis reservas',
        content: `## Mis Reservas

### Pestañas de reservas

Las reservas se organizan en 3 pestañas:

**Pendientes** 🟡
- Reservas futuras que aún no se cumplieron
- Podés cancelarlas si estás dentro de la ventana de tiempo

**Realizadas** 🟢
- Reservas que ya se cumplieron
- Incluye: asistió, ausente

**Canceladas** 🔴
- Reservas que cancelaste o que se cancelaron

### Información de cada reserva

- **Servicio**: nombre de la clase o turno
- **Fecha**: día de la reserva
- **Horario**: hora de inicio y fin
- **Profesional**: quién imparte la clase
- **Estado**: pendiente, asistió, ausente, cancelada
- **Modalidad**: presencial o virtual

### Cancelar una reserva

1. Andá a **Mis Reservas → Pendientes**
2. Buscá la reserva
3. Hacé clic en **"Cancelar"**
4. Confirmá
5. Se te devuelven los créditos automáticamente`
      }
    ]
  },
  {
    id: 'cust-credits',
    title: 'Mis Créditos',
    icon: '💰',
    sections: [
      {
        id: 'cust-credits-balance',
        title: 'Ver saldo y historial',
        content: `## Mis Créditos

### Saldo actual

En la pantalla de créditos ves tu saldo actual de créditos disponibles.

### Historial de movimientos

El historial muestra todos los movimientos de créditos:

- **Carga**: cuando el admin te carga créditos
- **Consumo**: cuando usás un crédito para reservar
- **Devolución**: cuando cancelás una reserva y se te devuelven
- **Vencimiento**: cuando un crédito vence

### Vencimiento de créditos

Cada crédito tiene una fecha de vencimiento:

- Se vence **1 mes + 1 día** después de cargarse
- Los créditos próximos a vencer muestran una advertencia
- Cuando se vencen, no se pueden usar

### Cómo se consumen los créditos

El sistema usa el método **FIFO** (First In, First Out):

1. Se usan primero los créditos más antiguos
2. Si tenés créditos de diferentes fechas, se consume el más viejo
3. Esto maximiza el tiempo que tenés para usar tus créditos

### Ver más movimientos

Si tenés muchos movimientos, hacé clic en **"Ver más"** para cargar más.`
      }
    ]
  },
  {
    id: 'cust-account',
    title: 'Mi Cuenta',
    icon: '👤',
    sections: [
      {
        id: 'cust-account-password',
        title: 'Cambiar contraseña',
        content: `## Mi Cuenta

### Cambiar contraseña

1. Andá a **Mi Cuenta** desde el menú
2. Ingresá tu contraseña actual
3. Ingresá la nueva contraseña
4. Confirmá la nueva contraseña
5. Hacé clic en **"Guardar"**

> **Tip**: Elegí una contraseña segura que combines letras, números y símbolos.`
      }
    ]
  },
]

const allDocs = computed(() => {
  switch (activeTab.value) {
    case 'admin': return adminDocs
    case 'professional': return professionalDocs
    case 'customer': return customerDocs
  }
})

const currentContent = computed(() => {
  if (!activeSection.value) {
    const firstGroup = allDocs.value[0]
    if (firstGroup && firstGroup.sections.length > 0) {
      return firstGroup.sections[0]!.content
    }
    return ''
  }

  for (const group of allDocs.value) {
    for (const section of group.sections) {
      if (section.id === activeSection.value) {
        return section.content
      }
    }
  }

  const firstGroup = allDocs.value[0]
  if (firstGroup && firstGroup.sections.length > 0) {
    return firstGroup.sections[0]!.content
  }
  return ''
})

const renderedContent = computed(() => {
  return marked.parse(currentContent.value) as string
})

const tocHeadings = computed(() => {
  const html = renderedContent.value
  const headings: { id: string; text: string; level: number }[] = []
  const regex = /<h([23])\s*(?:id="([^"]*)")?[^>]*>(.*?)<\/h[23]>/gi
  let match
  let counter = 0
  while ((match = regex.exec(html)) !== null) {
    const level = parseInt(match[1]!)
    const text = (match[3] || '').replace(/<[^>]*>/g, '')
    const id = match[2] || `heading-${counter++}`
    headings.push({ id, text, level })
  }
  return headings
})

function selectSection(id: string) {
  activeSection.value = id
  mobileMenuOpen.value = false
}

onMounted(() => {
  const firstGroup = allDocs.value[0]
  if (firstGroup && firstGroup.sections.length > 0) {
    activeSection.value = firstGroup.sections[0]!.id
  }
})
</script>

<template>
  <div class="docs-layout">
    <!-- Top Tabs -->
    <div class="docs-topbar">
      <div class="docs-topbar-inner">
        <button
          v-for="tab in tabs"
          :key="tab.id"
          @click="activeTab = tab.id; selectSection('')"
          class="docs-tab"
          :class="{ active: activeTab === tab.id }">
          <span class="docs-tab-icon">{{ tab.icon }}</span>
          {{ tab.label }}
        </button>
      </div>
    </div>

    <div class="docs-body">
      <!-- Mobile menu toggle -->
      <button
        @click="mobileMenuOpen = !mobileMenuOpen"
        class="docs-mobile-toggle">
        <svg v-if="!mobileMenuOpen" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 12h16M4 18h16" />
        </svg>
        <svg v-else class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>

      <!-- Mobile overlay -->
      <div
        v-if="mobileMenuOpen"
        class="docs-overlay"
        @click="mobileMenuOpen = false">
      </div>

      <!-- Sidebar -->
      <aside
        :class="['docs-sidebar', { open: mobileMenuOpen }]">
        <nav class="docs-sidebar-nav">
          <div v-for="group in allDocs" :key="group.id" class="docs-sidebar-group">
            <h3 class="docs-sidebar-title">{{ group.title }}</h3>
            <ul class="docs-sidebar-list">
              <li v-for="section in group.sections" :key="section.id">
                <button
                  @click="selectSection(section.id)"
                  class="docs-sidebar-item"
                  :class="{ active: activeSection === section.id }">
                  {{ section.title }}
                </button>
              </li>
            </ul>
          </div>
        </nav>
      </aside>

      <!-- Main content -->
      <main class="docs-content">
        <div class="docs-content-inner">
          <div class="prose" v-html="renderedContent"></div>
        </div>
      </main>

      <!-- Right TOC -->
      <aside class="docs-toc" v-if="tocHeadings.length > 0">
        <h4 class="docs-toc-title">En esta página</h4>
        <ul class="docs-toc-list">
          <li v-for="heading in tocHeadings" :key="heading.id">
            <a
              :href="`#${heading.id}`"
              class="docs-toc-link"
              :class="{ indent: heading.level === 3 }">
              {{ heading.text }}
            </a>
          </li>
        </ul>
      </aside>
    </div>
  </div>
</template>

<style scoped>
html {
  scroll-behavior: smooth;
}

.docs-layout {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  background-color: var(--color-background);
}

/* Top bar */
.docs-topbar {
  position: sticky;
  top: 0;
  z-index: 40;
  background-color: var(--color-surface);
  border-bottom: 1px solid var(--color-border);
}

.docs-topbar-inner {
  max-width: 100%;
  display: flex;
  gap: 0;
  padding: 0;
}

.docs-tab {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.875rem 1.25rem;
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--color-text-muted);
  background: none;
  border: none;
  border-bottom: 2px solid transparent;
  cursor: pointer;
  transition: all 0.2s;
  white-space: nowrap;
}

.docs-tab:hover {
  color: var(--color-text);
}

.docs-tab.active {
  color: var(--color-primary);
  border-bottom-color: var(--color-primary);
}

.docs-tab-icon {
  font-size: 1rem;
}

/* Body layout */
.docs-body {
  display: flex;
  flex: 1;
  position: relative;
}

/* Mobile toggle */
.docs-mobile-toggle {
  display: none;
  position: fixed;
  bottom: 1.5rem;
  right: 1.5rem;
  z-index: 50;
  width: 3rem;
  height: 3rem;
  border-radius: 50%;
  background-color: var(--color-primary);
  color: white;
  border: none;
  cursor: pointer;
  align-items: center;
  justify-content: center;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  transition: transform 0.2s;
}

.docs-mobile-toggle:hover {
  transform: scale(1.1);
}

@media (max-width: 1023px) {
  .docs-mobile-toggle {
    display: flex;
  }
}

/* Overlay */
.docs-overlay {
  display: none;
  position: fixed;
  inset: 0;
  background-color: rgba(0, 0, 0, 0.4);
  z-index: 40;
}

@media (max-width: 1023px) {
  .docs-overlay {
    display: block;
  }
}

/* Sidebar */
.docs-sidebar {
  width: 16rem;
  flex-shrink: 0;
  background-color: var(--color-surface);
  border-right: 1px solid var(--color-border);
  overflow-y: auto;
  position: sticky;
  top: 3.5rem;
  height: calc(100vh - 3.5rem);
}

@media (max-width: 1023px) {
  .docs-sidebar {
    position: fixed;
    top: 0;
    left: 0;
    height: 100vh;
    z-index: 45;
    transform: translateX(-100%);
    transition: transform 0.3s ease;
    border-right: 1px solid var(--color-border);
  }

  .docs-sidebar.open {
    transform: translateX(0);
  }
}

.docs-sidebar-nav {
  padding: 1rem 0;
}

.docs-sidebar-group {
  margin-bottom: 1.5rem;
}

.docs-sidebar-title {
  font-size: 0.8rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--color-text);
  padding: 0 1rem;
  margin-bottom: 0.5rem;
}

.docs-sidebar-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.docs-sidebar-item {
  display: block;
  width: 100%;
  text-align: left;
  padding: 0.4rem 1rem 0.4rem 1.5rem;
  font-size: 0.875rem;
  color: var(--color-text-muted);
  background: none;
  border: none;
  border-left: 3px solid transparent;
  cursor: pointer;
  transition: all 0.15s;
  line-height: 1.4;
}

.docs-sidebar-item:hover {
  color: var(--color-text);
  background-color: var(--color-background);
}

.docs-sidebar-item.active {
  color: var(--color-primary);
  border-left-color: var(--color-primary);
  font-weight: 500;
}

/* Content */
.docs-content {
  flex: 1;
  min-width: 0;
  padding: 2rem 3rem 2rem 3rem;
}

@media (max-width: 1023px) {
  .docs-content {
    padding: 1.5rem;
  }
}

@media (min-width: 1024px) {
  .docs-content {
    max-width: 48rem;
  }
}

.docs-content-inner {
  max-width: 100%;
}

/* Right TOC */
.docs-toc {
  width: 14rem;
  flex-shrink: 0;
  position: sticky;
  top: 3.5rem;
  height: calc(100vh - 3.5rem);
  overflow-y: auto;
  padding: 2rem 1rem 2rem 0;
  border-left: 1px solid var(--color-border);
}

@media (max-width: 1279px) {
  .docs-toc {
    display: none;
  }
}

.docs-toc-title {
  font-size: 0.8rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--color-text);
  margin-bottom: 1rem;
}

.docs-toc-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.docs-toc-link {
  display: block;
  font-size: 0.8rem;
  color: var(--color-text-muted);
  text-decoration: none;
  padding: 0.3rem 0 0.3rem 0.75rem;
  border-left: 2px solid transparent;
  transition: all 0.15s;
  line-height: 1.4;
}

.docs-toc-link:hover {
  color: var(--color-text);
}

.docs-toc-link.indent {
  padding-left: 1.5rem;
}

/* Prose styles */
.prose {
  color: var(--color-text);
}

.prose :deep(h1) {
  font-size: 2.5rem;
  font-weight: 700;
  margin-bottom: 1rem;
  margin-top: 2rem;
  color: var(--color-text);
  line-height: 1.2;
  scroll-margin-top: 5rem;
}

.prose :deep(h2) {
  font-size: 1.75rem;
  font-weight: 600;
  margin-bottom: 0.75rem;
  margin-top: 2.5rem;
  padding-bottom: 0.5rem;
  border-bottom: 1px solid var(--color-border);
  color: var(--color-text);
  scroll-margin-top: 5rem;
}

.prose :deep(h3) {
  font-size: 1.375rem;
  font-weight: 600;
  margin-bottom: 0.5rem;
  margin-top: 1.5rem;
  color: var(--color-text);
  scroll-margin-top: 5rem;
}

.prose :deep(p) {
  margin-bottom: 1rem;
  line-height: 1.75;
  color: var(--color-text-muted);
}

.prose :deep(ul), .prose :deep(ol) {
  margin-bottom: 1rem;
  padding-left: 1.5rem;
}

.prose :deep(li) {
  margin-bottom: 0.5rem;
  line-height: 1.7;
  color: var(--color-text-muted);
}

.prose :deep(ol li) {
  list-style-type: decimal;
}

.prose :deep(ul li) {
  list-style-type: disc;
}

.prose :deep(strong) {
  font-weight: 600;
  color: var(--color-text);
}

.prose :deep(blockquote) {
  border-left: 4px solid var(--color-primary);
  padding: 1rem 1.25rem;
  margin: 1.5rem 0;
  background-color: var(--color-primary-subtle);
  border-radius: 0 0.5rem 0.5rem 0;
}

.prose :deep(blockquote p) {
  margin-bottom: 0;
  color: var(--color-text);
}

.prose :deep(code) {
  background-color: var(--color-background);
  padding: 0.2rem 0.4rem;
  border-radius: 0.25rem;
  font-size: 0.875rem;
  color: var(--color-primary);
}

.prose :deep(pre) {
  background-color: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: 0.5rem;
  padding: 1rem;
  overflow-x: auto;
  margin: 1.5rem 0;
}

.prose :deep(pre code) {
  background: none;
  padding: 0;
  color: var(--color-text);
}
</style>
