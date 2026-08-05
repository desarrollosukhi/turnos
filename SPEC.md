# SPEC.md

## Proyecto

### Plataforma SaaS de Gestión de Reservas para Pequeños Negocios

#### Objetivo

Desarrollar una plataforma web de gestión de reservas para pequeños negocios.

El primer vertical implementado será una escuela de yoga, pero la arquitectura debe permitir adaptarse posteriormente a gimnasios, pilates, peluquerías, barberías, consultorios, nutricionistas, kinesiólogos y otros negocios que trabajen mediante reservas.

El objetivo es resolver la administración diaria de un negocio pequeño, priorizando simplicidad, mantenibilidad y costo cero de infraestructura.

#### Objetivos del MVP

El sistema debe permitir:

- Administrar clientes (con credenciales de acceso o sin ellas, según modo).
- Administrar profesionales (con portal propio).
- Administrar servicios/clases.
- Administrar horarios.
- Reservar (presencial o virtual, individual o grupal).
- Cancelar reservas.
- Cancelar sesiones (emergencias).
- Administrar créditos manualmente.
- Visualizar asistencia.
- Gestionar feriados.
- Ventana de tiempo para reserva/cancelación.

No se implementarán pagos online en el MVP.

#### Filosofía del proyecto

Este proyecto prioriza:

- Simplicidad.
- Código limpio.
- Baja complejidad.
- Mínima cantidad de dependencias.
- Fácil mantenimiento.
- Escalabilidad futura.

Siempre debe preferirse una solución sencilla antes que una solución excesivamente flexible.

No implementar funcionalidades "por si algún día sirven".

#### Stack tecnológico

**Frontend**

- Vue 3
- TypeScript
- Vite
- TailwindCSS

**Backend**

- Supabase

**Servicios utilizados**

- PostgreSQL
- Authentication
- Row Level Security
- Storage (para logos de empresa)

**Hosting**

- GitHub Pages
- Cloudflare Pages
- Vercel

Todo debe funcionar dentro de los planes gratuitos.

#### Arquitectura

La aplicación debe seguir una arquitectura API First.

Toda la información debe residir en Supabase.

El frontend únicamente consume la API.

Nunca implementar lógica crítica únicamente del lado del cliente.

#### Compatibilidad futura

Aunque inicialmente será una aplicación web, toda la arquitectura debe permitir generar posteriormente aplicaciones Android e iOS utilizando Capacitor, reutilizando exactamente el mismo proyecto Vue.

No deben tomarse decisiones que impidan este objetivo.

---

### Business Types

Cada empresa tiene un `business_type` que define su rubro. No cambia la lógica, solo personaliza textos y comportamientos de la UI.

| business_type | Ejemplo | Texto UI "Professionals" | Texto UI "Services" |
|---|---|---|---|
| `YOGA` | Escuela de yoga | Profesores | Clases |
| `GYM` | Gimnasio | Entrenadores | Clases |
| `PILATES` | Centro de pilates | Profesores | Clases |
| `HAIRDRESSER` | Peluquería | Peluqueros | Servicios |
| `BARBER` | Barbería | Barberos | Servicios |
| `MEDICAL` | Consultorio | Profesionales | Turnos |
| `CUSTOM` | Otro | Profesionales | Servicios |

---

### Customer Mode

Cada empresa configura cómo interactúan los clientes.

| Modo | Ejemplo | Comportamiento |
|------|---------|----------------|
| `MEMBER` | Yoga, Crossfit, Pilates | Clientes con login, historial, créditos, reservas |
| `GUEST` | Peluquería, Consultorio | Sin login, solo nombre + teléfono |

**MEMBER:**

- El cliente se registra e inicia sesión.
- Tiene historial de reservas.
- Puede manejar créditos.
- Puede cancelar reservas desde su cuenta.

**GUEST:**

- No necesita cuenta.
- Solo se registra con nombre y teléfono.
- El admin crea la reserva desde el panel.

---

### Booking Mode

Cada empresa configura el tipo de reserva.

| Modo | Ejemplo | Comportamiento |
|------|---------|----------------|
| `CLASS` | Yoga, Crossfit, Pilates | Múltiples personas por turno, cupos |
| `APPOINTMENT` | Peluquería, Consultorio | Un cliente por turno, duración |

**CLASS:**

- Turnos recurrentes (ej: cada lunes a 19:00).
- Múltiples personas por turno.
- Cupos por modalidad (presencial/virtual).
- Reservas grupales.

**APPOINTMENT:**

- Turnos individuales.
- Un cliente por turno.
- Duración del servicio (ej: 30 min corte).
- Sin cupos múltiples.

---

### Roles

#### Super Admin

Puede:

- Administrar toda la plataforma.
- Gestionar empresas/negocios.
- Ver estadísticas globales.
- Gestionar planes y suscripciones.
- No pertenece a ninguna empresa.

#### Admin (de empresa)

Puede:

- Crear clientes (con credenciales de acceso o sin ellas).
- Editar clientes.
- Agregar/quitar créditos (modo MEMBER).
- Crear profesionales (con credenciales de acceso).
- Editar profesionales (nombre, alias, contacto).
- Crear servicios/clases.
- Editar servicios/clases.
- Ver reservas.
- Marcar asistencia.
- Cancelar reservas.
- Cancelar sesiones (emergencias, devuelve créditos).
- Gestionar feriados.
- Configurar ventana de tiempo.
- Configurar WhatsApp.
- Subir logo.
- Configurar alias de profesionales.
- Configurar empresa (business_type, customer_mode, booking_mode).

#### Professional

Puede:

- Iniciar sesión.
- Ver sus servicios/clases asignados.
- Ver reservas de sus servicios/clases.
- Marcar asistencia.

#### Customer (modo MEMBER)

Puede:

- Iniciar sesión.
- Ver créditos.
- Cambiar contraseña.
- Ver servicios disponibles (calendario visual mensual).
- Reservar (seleccionando modalidad cuando corresponda).
- Cancelar reserva.
- Consultar reservas.

#### Guest (modo GUEST)

No tiene portal propio. El admin gestiona todo desde el panel.

---

### Multi-tenant

El sistema es multi-tenant. Cada empresa tiene:

- Sus propios clientes, profesionales, servicios y reservas.
- Configuración independiente.
- Datos aislados por RLS.

La empresa por defecto se llama "Yoga Studio" con ID fijo `00000000-0000-0000-0000-000000000001`.

El primer usuario que se registra en una empresa se convierte automáticamente en administrador.

---

### Modalidad de los servicios

Cada servicio/clase puede ofrecerse en una o ambas modalidades:

- **Presencial**
- **Virtual**

Las modalidades son independientes y deben poder combinarse.

**Casos posibles:**

| Caso | Permite Presencial | Permite Virtual |
|---|---|---|
| Solo presencial | Sí | No |
| Solo virtual | No | Sí |
| Híbrida | Sí | Sí |

La modalidad se configura al crear o editar el servicio.

---

### Modelo de datos

#### Companies

Representa cada negocio.

**Campos:**

- `id` (UUID)
- `name` (TEXT)
- `business_type` (TEXT: 'YOGA' | 'GYM' | 'PILATES' | 'HAIRDRESSER' | 'BARBER' | 'MEDICAL' | 'CUSTOM')
- `active` (BOOLEAN)
- `created_at` (TIMESTAMPTZ)

#### Company Settings

Configuración centralizada de cada empresa.

**Campos:**

- `company_id` (UUID, FK → companies, PK)
- `customer_mode` (TEXT: 'MEMBER' | 'GUEST', default 'MEMBER')
- `booking_mode` (TEXT: 'CLASS' | 'APPOINTMENT', default 'CLASS')
- `manage_credits` (BOOLEAN, default true)
- `allow_virtual` (BOOLEAN, default true)
- `allow_public_booking` (BOOLEAN, default false)
- `require_login` (BOOLEAN, default true)
- `show_alias` (BOOLEAN, default false)
- `whatsapp` (TEXT, nullable)
- `logo_url` (TEXT, nullable)
- `minutos_ventana_reserva` (INTEGER, default 30)
- `minutos_ventana_cancelacion` (INTEGER, default 30)

#### Users

Representa clientes, administradores y super admins.

**Campos:**

- `id` (UUID, FK → auth.users)
- `company_id` (UUID, FK → companies, nullable para super_admin)
- `name` (TEXT)
- `email` (TEXT)
- `phone` (TEXT, nullable)
- `credits` (INTEGER, default 0)
- `active` (BOOLEAN)
- `role` (TEXT: 'super_admin' | 'admin' | 'professional' | 'customer')
- `created_at` (TIMESTAMPTZ)

**Reglas:**

- El primer usuario de cada empresa se asigna como 'admin' automáticamente.
- Los créditos no pueden ser negativos.
- Super admin no tiene `company_id`.

#### Professionals

Representa profesionales (profesores, peluqueros, médicos, etc.).

**Campos:**

- `id` (UUID)
- `company_id` (UUID, FK → companies)
- `user_id` (UUID, FK → auth.users, nullable)
- `name` (TEXT)
- `alias` (TEXT, nullable)
- `email` (TEXT, nullable)
- `phone` (TEXT, nullable)
- `whatsapp` (TEXT, nullable)
- `active` (BOOLEAN)

**Reglas:**

- Si se provee email, se crea automáticamente un usuario de Supabase Auth con rol 'professional'.
- El alias se muestra en lugar del nombre si `show_alias` está activado en la empresa.

#### Resources

Espacios físicos (salas, sillas, consultorios, etc.).

**Campos:**

- `id` (UUID)
- `company_id` (UUID, FK → companies)
- `name` (TEXT)
- `type` (TEXT, nullable — categorización opcional)
- `capacity` (INTEGER, nullable — para modo CLASS)
- `active` (BOOLEAN)

**Ejemplos:**

| business_type | Resource |
|---|---|
| YOGA | Sala Principal, Sala 2 |
| HAIRDRESSER | Silla 1, Silla 2, Lavabo |
| MEDICAL | Consultorio 1, Consultorio 2 |
| GYM | Salón A, Salón B |

#### Services

Representa un servicio o clase (renamed de `classes`).

**Campos:**

- `id` (UUID)
- `company_id` (UUID, FK → companies)
- `professional_id` (UUID, FK → professionals)
- `resource_id` (UUID, FK → resources, nullable)
- `name` (TEXT)
- `day_of_week` (ENUM: lunes-domingo, nullable para APPOINTMENT)
- `start_time` (TIME)
- `end_time` (TIME)
- `duration_minutes` (INTEGER, nullable — para APPOINTMENT)
- `allows_in_person` (BOOLEAN)
- `allows_virtual` (BOOLEAN)
- `in_person_capacity` (INTEGER, nullable)
- `virtual_capacity` (INTEGER, nullable)
- `active` (BOOLEAN)

**Reglas:**

- Si `allows_in_person` es `true`, debe definirse `in_person_capacity`.
- Si `allows_virtual` es `true`, debe definirse `virtual_capacity`.
- Debe existir al menos una modalidad habilitada.
- En modo CLASS: `day_of_week` es obligatorio.
- En modo APPOINTMENT: `duration_minutes` es obligatorio.

#### Bookings

Representa una reserva.

**Campos:**

- `id` (UUID)
- `user_id` (UUID, FK → users, nullable para GUEST)
- `service_id` (UUID, FK → services)
- `date` (DATE)
- `modality` (ENUM: 'in_person' | 'virtual', nullable para APPOINTMENT)
- `status` (ENUM: 'pending' | 'confirmed' | 'cancelled' | 'attended' | 'no_show')
- `guest_name` (TEXT, nullable — para modo GUEST)
- `guest_phone` (TEXT, nullable — para modo GUEST)
- `created_at` (TIMESTAMPTZ)

**Reglas:**

- La modalidad debe ser una de las habilitadas para ese servicio.
- Se valida la ventana de tiempo al reservar y cancelar.
- Se valida que no sea feriado.
- Se valida que la sesión no esté cancelada.
- Una reserva presencial consume cupo presencial; una virtual consume cupo virtual.
- El consumo de créditos es igual para ambas modalidades.
- En modo GUEST: `user_id` es null, se usa `guest_name` y `guest_phone`.
- En modo APPOINTMENT: `modality` es null.

#### Cancelled Service Sessions

Representa la cancelación de una sesión por emergencia.

**Campos:**

- `id` (UUID)
- `company_id` (UUID, FK → companies)
- `service_id` (UUID, FK → services)
- `date` (DATE)
- `reason` (TEXT, nullable)
- `cancelled_by` (UUID, FK → users, nullable)
- `created_at` (TIMESTAMPTZ)

**Reglas:**

- Al cancelar una sesión, se cancelan TODAS las reservas activas de esa fecha y servicio.
- Se devuelven los créditos a cada cliente afectado (modo MEMBER).
- No se puede cancelar una sesión ya cancelada.

#### Holidays

**Campos:**

- `id` (UUID)
- `company_id` (UUID, FK → companies)
- `date` (DATE)
- `name` (TEXT)
- `active` (BOOLEAN, default true)
- `created_at` (TIMESTAMPTZ)

**Reglas:**

- Solo feriados activos bloquean las reservas.
- Se pueden importar feriados nacionales de Argentina (2025-2027).
- Se pueden crear feriados manuales.
- Se pueden activar/desactivar individualmente.

#### Credit Movements

Historial de créditos (solo modo MEMBER).

**Campos:**

- `id` (UUID)
- `user_id` (UUID, FK → users)
- `amount` (INTEGER)
- `description` (TEXT)
- `created_at` (TIMESTAMPTZ)

#### Plans (Futuro — no implementar aún)

Planes de suscripción para SaaS.

**Campos:**

- `id` (UUID)
- `name` (TEXT)
- `price` (DECIMAL)
- `features` (JSONB)
- `active` (BOOLEAN)

#### Subscriptions (Futuro — no implementar aún)

Suscripciones de empresas a planes.

**Campos:**

- `id` (UUID)
- `company_id` (UUID, FK → companies)
- `plan_id` (UUID, FK → plans)
- `status` (TEXT: 'active' | 'cancelled' | 'expired')
- `starts_at` (TIMESTAMPTZ)
- `ends_at` (TIMESTAMPTZ)

---

### Company Settings (Detalle)

Cada empresa tiene una configuración centralizada:

| Setting | Tipo | Default | Descripción |
|---------|------|---------|-------------|
| `customer_mode` | ENUM | MEMBER | CLIENTE con/sin login |
| `booking_mode` | ENUM | CLASS | Reserva grupal o individual |
| `manage_credits` | BOOLEAN | true | Habilitar sistema de créditos |
| `allow_virtual` | BOOLEAN | true | Permitir clases virtuales |
| `allow_public_booking` | BOOLEAN | false | Reservar sin login |
| `require_login` | BOOLEAN | true | Requerir login para reservar |
| `show_alias` | BOOLEAN | false | Mostrar alias en lugar de nombre |
| `whatsapp` | TEXT | null | Número de WhatsApp para contacto |
| `logo_url` | TEXT | null | Logo de la empresa |
| `minutos_ventana_reserva` | INTEGER | 30 | Minutos antes para reservar |
| `minutos_ventana_cancelacion` | INTEGER | 30 | Minutos antes para cancelar |

---

### Resources (Detalle)

Los recursos son espacios físicos que se asocian a servicios/clases.

**Ejemplos por rubro:**

| business_type | Recursos típicos |
|---|---|
| YOGA | Sala Principal, Sala 2, Sala al aire libre |
| GYM | Salón A, Salón B, Pileta |
| HAIRDRESSER | Silla 1, Silla 2, Silla 3, Lavabo |
| BARBER | Silla 1, Silla 2 |
| MEDICAL | Consultorio 1, Consultorio 2, Sala de espera |
| PILATES | Sala Reformers, Sala Mat |

**Reglas:**

- Un servicio puede tener un recurso asociado (nullable).
- Si tiene recurso, se muestra en la reserva.
- La capacidad del recurso puede limitar los cupos.

---

### Ventana de tiempo

Cada empresa configura:

- **Minutos para reserva**: Cuántos minutos antes del servicio puede reservar un cliente (default: 30).
- **Minutos para cancelación**: Cuántos minutos antes del servicio puede cancelar un cliente (default: 30).

Si un cliente intenta reservar o cancelar fuera de la ventana, se le muestra un modal con:

- Mensaje explicativo.
- Botón de WhatsApp para contactar al profesional (si está configurado).

---

### Feriados

**Importación de feriados nacionales:**

- Se pueden importar feriados de Argentina (2025-2027).
- Se selecciona el año y se importan todos los feriados de golpe.
- Se muestran cuáles ya están importados.

**Gestión manual:**

- Se pueden agregar feriados manualmente (fecha + nombre).
- Se pueden eliminar.
- Se pueden activar/desactivar con toggle.

**Efecto:**

- Si un día es feriado (activo), no se pueden reservar servicios.
- Se muestra un banner "Este día es feriado" en la página de servicios.

---

### Calendario visual

La página de servicios muestra un **calendario mensual** con:

- Navegación mes anterior/siguiente.
- Botón "Hoy" para volver al día actual.
- Indicadores de color por día:
  - 🟢 Verde = hay servicios libres
  - 🔵 Azul = ya reservaste
  - 🔴 Rojo = feriado
  - ⚪ Gris = servicio cancelado
- Leyenda de colores.
- Al seleccionar un día, se muestran los servicios de ese día (filtrados por día de semana).

---

### Flujo del administrador

Debe poder:

- Crear cliente (con credenciales si modo MEMBER, o sin ellas si modo GUEST).
- Editar cliente.
- Agregar/quitar créditos (modo MEMBER).
- Crear profesional (con alias, credenciales generadas automáticamente).
- Editar profesional.
- Crear servicios (configurando modalidad, cupos, recurso).
- Modificar servicios.
- Ver reservas.
- Marcar asistencia.
- Cancelar reservas.
- Cancelar sesión (emergencia, devuelve créditos).
- Gestionar feriados.
- Configurar ventana de tiempo.
- Configurar WhatsApp.
- Subir logo de la empresa.
- Configurar alias de profesionales.
- Configurar business_type, customer_mode, booking_mode.

**Al crear cliente/profesional (modo MEMBER):**

1. Se generan credenciales automáticamente (email + contraseña de 8 caracteres).
2. Se muestran en un recuadro verde con botón **📋 Copiar credenciales**.
3. El admin comparte las credenciales.
4. El cliente/profesional debe cambiar la contraseña al iniciar sesión.

**Al crear cliente (modo GUEST):**

1. Solo se ingresa nombre y teléfono.
2. No se crea cuenta de acceso.
3. El admin gestiona las reservas desde el panel.

---

### Flujo del cliente (modo MEMBER)

Debe poder:

- Ver créditos.
- Ver servicios disponibles (calendario visual mensual).
- Reservar (seleccionando modalidad cuando corresponda).
- Cancelar reserva.
- Cambiar contraseña.

**Al reservar:**

1. Seleccionar día en el calendario.
2. Ver los servicios disponibles para ese día.
3. Si el servicio tiene una sola modalidad → reserva automática.
4. Si el servicio es híbrido → elegir Presencial o Virtual.
5. Se valida: ventana de tiempo, feriado, sesión cancelada, cupo disponible, créditos.
6. Se descuenta un crédito.
7. Se crea la reserva.

**Al cancelar:**

1. Se valida la ventana de tiempo.
2. Se libera el cupo.
3. La devolución del crédito es configurable.

---

### Flujo del profesional

Debe poder:

- Ver sus servicios asignados.
- Ver reservas de sus servicios (filtrar por fecha).
- Marcar asistencia (asistió/ausente).

**Portal del profesional:**

- Dashboard con resumen del día.
- Lista de servicios asignados.
- Lista de reservas con acciones de asistencia.

---

### Pantallas

#### Login

#### Registro

#### Home (Cliente — modo MEMBER)

- Créditos disponibles.
- Links a Servicios y Mis Reservas.
- Sección "Mi Cuenta" para cambiar contraseña.

#### Calendario de Servicios

- Calendario mensual con indicadores.
- Al seleccionar día: servicios disponibles con botones de reserva.
- Banner de feriado si aplica.
- Modal de ventana de tiempo si aplica.

#### Mis Reservas

- Listado de reservas con estado, modalidad y profesional (o alias).
- Botón cancelar (valida ventana de tiempo).

#### Mis Créditos

- Saldo actual.
- Historial de movimientos.

#### Panel administrador

**Secciones:**

- Dashboard (resumen).
- Clientes (CRUD + credenciales si modo MEMBER).
- Profesionales (CRUD + alias + credenciales).
- Servicios (CRUD con modalidad, cupos y recurso).
- Reservas (vista global + cancelar sesión + marcar asistencia).
- Créditos (administrar por cliente, solo modo MEMBER).
- Configuración (empresa, logo, nombre, ventana de tiempo, WhatsApp, alias, feriados, business_type, customer_mode, booking_mode).

#### Portal del profesional

**Secciones:**

- Dashboard (servicios de hoy, reservas).
- Mis Servicios (lista completa).
- Reservas (filtrar por fecha, marcar asistencia).

---

### Seguridad

- Utilizar Supabase Auth.
- Implementar Row Level Security (RLS).
- Las policies usan funciones `SECURITY DEFINER` para evitar recursión en la tabla `users`.
- Los clientes solo acceden a sus propios datos.
- Los profesionales solo ven sus servicios y reservas.
- El administrador accede a toda la información de su empresa.
- Super admin accede a toda la plataforma.
- Las credenciales se generan automáticamente y se comparten de forma segura.
- No usar `supabase.auth.admin` en el frontend (requiere service_role key). Usar `signUp()` en su lugar.
- Configurar Auto-confirm email en Supabase para que los usuarios creados puedan loguearse sin verificar.

---

### Diseño

La interfaz debe ser minimalista.

Priorizar:

- rapidez
- claridad
- pocos clics

Evitar pantallas sobrecargadas.

---

### Calidad del código

Todo el proyecto debe escribirse utilizando:

- TypeScript estricto.
- Componentes pequeños.
- Composition API.
- Código reutilizable.
- Sin duplicación.
- Nombres descriptivos.
- Nombres genéricos (no específicos de un rubro).

---

### Organización del proyecto

```
src/
  components/
    MonthlyCalendar.vue
    TimeWindowModal.vue
    HolidayBanner.vue
  pages/
    LoginPage.vue
    RegisterPage.vue
    HomePage.vue
    ServicesPage.vue
    MyBookingsPage.vue
    MyCreditsPage.vue
    admin/
      AdminDashboardPage.vue
      AdminCustomersPage.vue
      AdminProfessionalsPage.vue
      AdminServicesPage.vue
      AdminBookingsPage.vue
      AdminCreditsPage.vue
      AdminSettingsPage.vue
    professional/
      ProfessionalDashboardPage.vue
      ProfessionalServicesPage.vue
      ProfessionalBookingsPage.vue
  layouts/
    DefaultLayout.vue
    AdminLayout.vue
    AuthLayout.vue
    ProfessionalLayout.vue
  stores/
    auth.ts
    service.ts
    booking.ts
    credit.ts
  services/
    AuthService.ts
    UserService.ts
    ServiceService.ts
    BookingService.ts
    CreditService.ts
    ProfessionalService.ts
    CompanyService.ts
    ResourceService.ts
    HolidayService.ts
    HolidaysNational.ts
  composables/
  types/
    index.ts
  router/
    index.ts
  supabase/
    client.ts
  assets/
  utils/
```

### Convenciones

Los servicios encapsulan todo acceso a Supabase.

- AuthService
- UserService
- ServiceService
- BookingService
- CreditService
- ProfessionalService
- CompanyService
- ResourceService
- HolidayService

Nunca acceder a Supabase directamente desde los componentes.

Las funciones SQL encapsulan la lógica de negocio crítica (reserva, cancelación, asistencia, ventanas de tiempo).

Los nombres de tablas, columnas y tipos deben ser genéricos (no específicos de un rubro).

---

### Archivos SQL

| Archivo | Descripción |
|---------|-------------|
| `schema.sql` | Schema completo (tablas, funciones, triggers, RLS) |
| `migration.sql` | Migración multi-tenant |
| `migration-features.sql` | Cancelación, ventana de tiempo, feriados |
| `migration-fix-rls.sql` | Fix recursión RLS + función `is_admin_of` |
| `migration-admin-auto.sql` | Trigger para primer usuario admin |
| `migration-professional-portal.sql` | Portal de profesional + alias |
| `migration-holiday-active.sql` | Campo active en holidays |
| `migration-professional-contact.sql` | Campos de contacto en professionals |
| `migration-resources.sql` | Tabla resources |
| `migration-company-settings.sql` | Tabla company_settings |
| `fix-trigger-create-admin.sql` | Fix trigger + crear admin |

---

### Fuera del alcance del MVP

No implementar:

- Mercado Pago.
- Stripe.
- Paquetes.
- Membresías.
- Notificaciones push.
- Emails transaccionales.
- Lista de espera.
- Estadísticas.
- Reportes.
- Múltiples sedes.
- Calendario complejo (semanal/diario).
- Reglas avanzadas de negocio.
- Planes y suscripciones (preparar tablas, no implementar lógica).

---

### Roadmap

#### Etapa 1 — MVP Yoga (actual)

- Vertical: escuela de yoga.
- Roles: admin, professional, customer.
- booking_mode: CLASS.
- customer_mode: MEMBER.
- Funcionalidades: reservas, créditos, feriados, ventana de tiempo, calendario, portal profesional.

#### Etapa 2 — Multi-empresa funcional

- Múltiples empresas activas.
- Self-registration de empresas.
- Onboarding simplificado.

#### Etapa 3 — SaaS

- Planes y suscripciones.
- Mercado Pago (cobros recurrentes).
- Límites por plan (cantidad de clientes, profesionales, servicios).
- Trial gratuito.
- Dashboard de super admin.

#### Etapa 4 — Otros rubros

- Peluquerías (booking_mode: APPOINTMENT, customer_mode: GUEST).
- Consultorios médicos.
- Crossfit.
- Pilates.
- Barberías.
- Personalización de textos por business_type.

#### Etapa 5 — Aplicaciones móviles

- Capacitor para Android.
- Capacitor para iOS.
- Notificaciones push.
- Recordatorios.

---

### Reglas para el agente de OpenCode

1. Implementar solo funcionalidades definidas en este documento.
2. No agregar funcionalidades "por si acaso".
3. Mantener el código simple y mantenible.
4. Antes de modificar la arquitectura, justificar la necesidad.
5. Priorizar legibilidad sobre optimizaciones prematuras.
6. Mantener separación clara entre UI, lógica de negocio y acceso a datos.
7. Cada funcionalidad debe entregarse completa, con componentes, servicios, tipos y validaciones.
8. Generar código listo para producción, evitando ejemplos o código temporal (TODO, FIXME, mocks o funciones incompletas).
9. No usar `supabase.auth.admin` en el frontend (requiere service_role key). Usar `signUp()` en su lugar.
10. Configurar Auto-confirm email en Supabase para que los usuarios creados puedan loguearse sin verificar.

---

### Configuración de OpenCode + ECC

El proyecto usa **OpenCode** como harness de desarrollo con **ECC** (Ecc Tools) para skills y agentes especializados.

#### Skills del proyecto (`.opencode/skills/`)

| Skill | Uso |
|-------|-----|
| `scaffold-feature` | Crear nuevas funcionalidades siguiendo patrones del proyecto |
| `create-migration` | Crear migraciones SQL idempotentes |
| `fix-bug` | Diagnosticar y arreglar bugs |
| `write-docs` | Generar documentación de usuario |
| `changelog-commit` | Guardar cambios + crear commit |

#### Agents del proyecto (`.opencode/agent/`)

| Agente | Uso |
|--------|-----|
| `documentation` | Generar guías para admin, profesional y cliente |
| `sprint-planner` | Planificar sprints semanales de 7 días |

#### Skills de ECC (vía `skills.paths`)

Skills de ECC disponibles para el proyecto:

| Prioridad | Skill | Uso |
|-----------|-------|-----|
| Alta | `security-review` | Revisar RLS policies |
| Alta | `database-migrations` | Validar migraciones SQL |
| Alta | `tdd-workflow` | Tests antes de implementar |
| Media | `vue-patterns` | Patrones Vue 3 |
| Media | `vite-patterns` | Configuración Vite |
| Media | `frontend-patterns` | Patrones de UI |
| Media | `coding-standards` | Estándares de código |
| Media | `git-workflow` | Flujo de git |
| Baja | `design-system` | Sistema de diseño |
| Baja | `api-design` | Si se agrega API externa |

#### Flujo de desarrollo semanal

| Día | Actividad | Skills usados |
|-----|-----------|---------------|
| 1 | Planificación | `sprint-planner` |
| 2-5 | Desarrollo | `scaffold-feature`, `create-migration`, `fix-bug` |
| 6 | Documentación | `write-docs`, `documentation` |
| 7 | Testing y release | `security-review`, `changelog-commit` |

#### Comandos útiles

| Comando | Uso |
|---------|-----|
| `/plan` | Planificar una feature |
| `/tdd` | Test-driven development |
| `/security-review` | Revisar seguridad |
| `/build-fix` | Arreglar errores de build |

---

Este documento debe considerarse la fuente de verdad del proyecto.
