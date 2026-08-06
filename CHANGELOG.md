# Changelog

## v1.1.0 — Avisos, UX y Fixes (2026-08-05)

### Avisos (Anuncios)
- CRUD completo de avisos para administradores (`/admin/announcements`)
- Editor de rich text (Tiptap) para contenido de avisos
- Dos modos de descarte: "Recordarme" (sesión) y "No mostrar" (permanente en localStorage)
- Reactivación de avisos: si el admin reactiva un aviso descartado, vuelve a mostrarse al cliente
- Anuncios de cancelación de sesión ahora se muestran a todos los alumnos (target: 'all')
- Fecha de anuncios automáticos usa `CURRENT_DATE` en vez de la fecha de la sesión
- Migración: columna `reactivated_at` en tabla `announcements`
- Fix: función SQL `get_active_announcements` ahora retorna `reactivated_at`
- Fix: `DROP FUNCTION` necesario para cambiar tipo de retorno de la función

### Reservas del cliente — Tabs
- Tabs Pendientes / Realizadas / Canceladas con conteo
- Labels de estado en español (Pendiente, Asistió, Ausente, Cancelada)

### Créditos — Paginación
- Botón "Ver más" para historial de movimientos (carga de 10 en 10)

### Calendario
- Fix: indicador de reserva solo se muestra si no hay sesión cancelada (`v-else-if`)

### Admin Reservas
- Excluir servicios ya cancelados del modal de cancelación de sesión
- Fetch de `cancelled_service_sessions` para filtrar correctamente

### Panel administrador
- Nuevo menú "Avisos" en sidebar del admin

### Dependencias
- `@tiptap/vue-3`, `@tiptap/starter-kit`, `@tiptap/pm` — editor rich text
- `marked` — renderizado de markdown

---

## v1.0.0 — MVP Completo (2026-07-30)

### Multi-Tenant
- Sistema multi-tenant con aislamiento por `company_id`
- Tabla `companies` con `business_type` (YOGA, GYM, PILATES, HAIRDRESSER, BARBER, MEDICAL, CUSTOM)
- Tabla `company_settings` con configuración centralizada
- Onboarding: primer usuario crea su empresa (máx 3 por admin)
- RLS policies con función `is_admin_of()` para evitar recursión

### Roles
- `super_admin` — dueño de la plataforma
- `admin` — administrador de empresa
- `professional` — profesional con portal propio
- `customer` — cliente/alumno

### Autenticación
- Login/registro con Supabase Auth
- Primer usuario de cada empresa se auto-asigna como admin
- Registro con selección de rol (admin o cliente)
- Mensaje de confirmación de email
- Página de onboarding para crear empresa

### Servicios — 3 modos de frecuencia
- **Semanal** 🔄 — Clases recurrentes con selección múltiple de días
- **Turnos** ⏰ — Turnos individuales con intervalo configurable
- **Evento** 🎯 — Evento único, fecha específica

### Servicios — Modalidad
- Presencial / Virtual / Híbrida
- Cupos independientes por modalidad

### Reservas
- Crear reserva con validación completa
- Cancelar reserva con devolución de crédito
- Cancelar sesión completa (emergencia)
- Marcar asistencia (asistió/ausente)
- Prevención de duplicados

### Ventana de tiempo
- Configurable por empresa (minutos para reserva y cancelación)
- Modal de advertencia con link de WhatsApp

### Sistema de créditos
- Balance efectivo (excluye expirados)
- Vencimiento: 1 mes + 1 día después de carga
- Advertencia de créditos próximos a vencer
- Consumo FIFO
- Admin agrega/quita créditos con confirmación

### Clientes
- Crear con cuenta (credenciales auto-generadas + copiar)
- Crear sin cuenta (solo nombre y teléfono)
- Crear cuenta después para clientes sin cuenta
- Campos: nombre, email, teléfono, fecha nacimiento, contacto emergencia
- Tipo de acceso: créditos o free pass
- Solo se muestran clientes (no admins ni profesionales)

### Profesionales
- CRUD con credenciales auto-generadas
- Alias (se muestra en lugar del nombre si está activado)
- Campos: email, teléfono, WhatsApp
- Portal propio: dashboard, servicios, reservas, asistencia

### Portal del profesional
- Dashboard con resumen del día
- Lista de servicios asignados
- Reservas con filtro por fecha
- Marcar asistencia (asistió/ausente)
- Botón "📋 Historia" para historia clínica

### Historia clínica
- Configurable por empresa (toggle en configuración)
- Campos predefinidos + texto libre
- El profesional la completa desde el portal

### Modo Gimnasio
- Toggle "Modo Gimnasio" en configuración
- Horario del gimnasio configurable por día
- Free Pass: acceso abierto sin reservar

### Configuración de empresa
- Logo (upload/delete con Supabase Storage)
- Nombre
- Business type selector
- Ventana de tiempo
- WhatsApp del profesional
- Alias de profesionales
- Modo gimnasio (toggle + horario)
- Historia clínica (toggle)
- 16 temas predefinidos con preview visual

### Reportes (7 tipos)
1. Reservas por profesional
2. Ocupación de servicios
3. Consumo de créditos
4. Tasa de asistencia
5. Clientes nuevos
6. Servicios más demandados
7. Cancelaciones

### Exportación
- CSV, Excel (.xlsx), PDF

### Feriados
- Importación de feriados nacionales de Argentina (2025-2027)
- Creación manual
- Toggle activar/desactivar
- Bloqueo de reservas en feriados activos

### UI/UX
- Calendario mensual con indicadores de color
- Toast notifications
- Footer "Asterisk Corp" con año dinámico
- Título del navegador dinámico
- Favicon dinámico
- Logo en todos los layouts
- Temas CSS variables reactivos
- Diseño responsive
