# Guía de Migraciones Supabase

## Sistema de Gestión de Reservas — Multi-tenant

---

## Estructura de archivos

```
supabase/
├── schema.sql                          ← Schema completo (para proyectos nuevos)
├── MIGRACIONES.md                      ← Este documento
├── migration-appointment-events.sql    ← 3 modos de servicio
├── migration-credits-and-customers.sql ← Créditos vencimiento + campos clientes
├── migration-customers-improvements.sql← Campo has_account
├── migration-feriados-activo.sql       ← Campo activo en holidays
├── migration-fix-bugs.sql              ← Fix is_holiday + is_service_session_cancelled
├── migration-dashboard-kpis.sql        ← KPIs para admin dashboard
├── migration-waitlist.sql              ← Lista de espera
├── migration-admin-cancel.sql          ← Admin cancela reservas + fix mark_attendance
├── migration-join-company.sql          ← Customers se unen a empresas existentes
├── migration-fix-credits-expiry.sql    ← Fix: créditos agregados ahora vencen a 31 días
├── migration-fix-credits-description.sql ← Fix: descripción de reserva incluye nombre del servicio
├── migration-fix-users-update.sql      ← Fix: usuarios pueden actualizar su propio perfil
├── migration-fix-dashboard-kpis.sql    ← Fix: dashboard admin muestra datos reales
├── migration-logo-storage.sql          ← Storage bucket para logos
├── migration-onboarding.sql            ← Registro sin empresa
├── migration-reports.sql               ← Funciones de reportes
├── migration-teacher-portal.sql        ← Portal de profesor + alias
├── migration-teachers-contact.sql      ← Campos contacto teachers
├── migration-theme.sql                 ← Temas predefinidos
└── archive/                            ← Migraciones obsoletas
    ├── create-admin-user.sql
    ├── fix-rls-recursion.sql
    ├── fix-rls-recursion-v2.sql
    ├── fix-trigger-create-admin.sql
    ├── migration.sql
    ├── migration-admin-auto.sql
    ├── migration-features.sql
    ├── migration-fix-columns.sql
    ├── migration-fix-rls.sql
    └── migration-saas-refactor.sql
```

---

## Para proyectos NUEVOS

Ejecutar solo:

```sql
-- Pegar contenido de schema.sql en SQL Editor → Run
```

---

## Para proyectos EXISTENTES

Ejecutar en orden las migraciones que falten:

| # | Archivo | Descripción | ¿Cuándo ejecutar? |
|---|---------|-------------|-------------------|
| 1 | `migration-teacher-portal.sql` | Portal profesor + alias + user_id | Si no se ejecutó |
| 2 | `migration-teachers-contact.sql` | Campos email/telefono/whatsapp en teachers | Si no se ejecutó |
| 3 | `migration-feriados-activo.sql` | Campo activo en holidays | Si no se ejecutó |
| 4 | `migration-theme.sql` | Temas predefinidos | Si no se ejecutó |
| 5 | `migration-logo-storage.sql` | Storage bucket para logos | Si no se ejecutó |
| 6 | `migration-onboarding.sql` | Registro sin empresa + create_company_for_user | Si no se ejecutó |
| 7 | `migration-reports.sql` | Funciones de reportes | Si no se ejecutó |
| 8 | `migration-appointment-events.sql` | 3 modos de servicio | Si no se ejecutó |
| 9 | `migration-customers-improvements.sql` | Campo has_account | Si no se ejecutó |
| 10 | `migration-credits-and-customers.sql` | Créditos vencimiento + campos clientes | Si no se ejecutó |
| 11 | `migration-fix-bugs.sql` | Fix is_holiday (active filter) + is_service_session_cancelled (SECURITY DEFINER) | Ahora |
| 12 | `migration-dashboard-kpis.sql` | KPIs para admin dashboard (reservas, clientes, créditos, asistencia) | Ahora |
| 13 | `migration-waitlist.sql` | Lista de espera (tabla + funciones RPC) | Ahora |
| 14 | `migration-admin-cancel.sql` | Admin cancela reservas + fix mark_attendance (valida asignación profesional) | Ahora |
| 15 | `migration-join-company.sql` | Customers se unen a empresas existentes (función join_company) | Ahora |
| 16 | `migration-fix-credits-expiry.sql` | Fix: créditos agregados por admin ahora vencen a 31 días | Ahora |
| 17 | `migration-fix-credits-description.sql` | Fix: descripción de reserva incluye nombre del servicio | Ahora |
| 18 | `migration-fix-users-update.sql` | Fix: usuarios pueden actualizar su propio perfil | Ahora |
| 19 | `migration-fix-dashboard-kpis.sql` | Fix: dashboard admin muestra datos reales | Ahora |

---

## Resumen de cada migración

### `schema.sql`
Schema completo del proyecto. Incluye todas las tablas, funciones, triggers y RLS.

### `migration-teacher-portal.sql`
- Agrega `user_id` y `alias` a `teachers`
- Agrega `mostrar_alias` a `company_settings`
- Crea policies para portal de profesor
- Crea función `get_professional_display_name`

### `migration-teachers-contact.sql`
- Agrega `email`, `telefono`, `whatsapp` a `teachers`

### `migration-feriados-activo.sql`
- Agrega campo `activo` a `holidays`

### `migration-theme.sql`
- Agrega columnas de tema a `company_settings` (primary_color, background_color, etc.)

### `migration-logo-storage.sql`
- Crea bucket `company-logos` en Supabase Storage
- Policies de lectura pública y escritura por admin

### `migration-onboarding.sql`
- Hace `company_id` nullable en `users`
- Reescribe trigger `handle_new_user`
- Crea función `create_company_for_user`

### `migration-reports.sql`
- 8 funciones RPC de reportes

### `migration-appointment-events.sql`
- Campo `frequency` (weekly/appointment/one_time)
- Campo `days_of_week` (array)
- Campos de configuración de turnos
- Campos de eventos
- Función `get_appointment_slots`

### `migration-customers-improvements.sql`
- Campo `has_account` en `users`

### `migration-credits-and-customers.sql`
- Campo `expires_at` en `credit_movements`
- Campos `birth_date`, `emergency_contact_name`, `emergency_contact_phone` en `users`
- Funciones `get_effective_credits` y `get_expiring_credits`

### `migration-fix-bugs.sql`
- Fix `is_holiday`: filtrar por `active = true` (feriados desactivados no bloquean reservas)
- Fix `is_service_session_cancelled`: agregar `SECURITY DEFINER` para bypass RLS

### `migration-dashboard-kpis.sql`
- Función `get_admin_dashboard_kpis`: reservas hoy, semana, clientes activos, créditos totales, tasa de asistencia

### `migration-waitlist.sql`
- Tabla `waitlist` con RLS
- Función `join_waitlist`: unirse a la lista de espera
- Función `leave_waitlist`: salir de la lista
- Función `process_waitlist_for_slot`: procesar siguiente en cola al cancelar

### `migration-admin-cancel.sql`
- Función `admin_cancel_booking`: admin cancela reservas con devolución de crédito
- Fix `mark_attendance`: valida que el profesional esté asignado al servicio

### `migration-join-company.sql`
- Función `join_company`: permite a customers/profesionales unirse a una empresa existente

### `migration-fix-credits-expiry.sql`
- Fix `add_credits`: ahora setea `expires_at` (31 días) para montos positivos

### `migration-fix-credits-description.sql`
- Fix `book_service`: descripción de movimiento incluye nombre del servicio

### `migration-fix-users-update.sql`
- Policy `users_update_own`: permite usuario actualizar su propio perfil

### `migration-fix-dashboard-kpis.sql`
- Fix `get_admin_dashboard_kpis`: usa variables en vez de subqueries, elimina valor inexistente 'confirmed'

### `archive/`
Migraciones obsoletas que ya fueron ejecutadas o reemplazadas.

---

## Orden de ejecución para proyecto existente

1. Verificar qué migraciones ya se ejecutaron
2. Ejecutar las que faltan en orden numérico
3. Cada migración es idempotente (puede ejecutarse múltiples veces sin errores)
