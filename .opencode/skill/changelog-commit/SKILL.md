---
name: changelog-commit
description: Use when the user wants to save changes, update the changelog, and create a git commit. Detects modified files, categorizes changes, generates commit name, and updates CHANGELOG.md and ChangelogPage.vue.
---

# Skill: Changelog & Commit

Use this skill when the user says something like:
- "Guardá los cambios"
- "Guardá en el changelog"
- "Subilo al changelog"
- "Hacé el commit"
- "¿Qué cambios hay?"
- "¿Qué puedo subir?"

## Workflow

### 1. Detectar cambios

Ejecutar comandos git para ver qué archivos cambiaron:

```bash
git status --porcelain
git diff --stat
```

### 2. Categorizar cambios

Mapear archivos modificados a categorías del CHANGELOG:

| Archivos | Categoría |
|----------|-----------|
| `src/services/*` | Según el servicio (Reservas, Créditos, etc.) |
| `src/pages/admin/*` | Según el módulo (Clientes, Profesionales, etc.) |
| `src/pages/ServicesPage.vue` | Servicios |
| `src/pages/GuestBookingPage.vue` | Reservas Guest |
| `src/components/*` | UI/UX |
| `supabase/migration-*` | Migraciones DB |
| `src/types/*` | Modelo de datos |
| `src/router/*` | Navegación |

### 3. Preguntar al usuario

Presentar los cambios detectados y preguntar:

```
Detecté los siguientes cambios:

1. feat: Agregado toggle de modo gimnasio en configuración
2. feat: Nuevo horario configurable del gimnasio
3. fix: Corregido error de login con email no confirmado

¿Querés agregar estos cambios al changelog?
```

### 4. Si el usuario dice que sí

#### 4a. Preguntar versión

```
¿Qué versión querés asignar?
- v1.1.0 (minor - nueva funcionalidad)
- v1.0.1 (patch - corrección)
- v2.0.0 (major - cambio grande)
```

#### 4b. Generar nombre del commit

Formato: `{tipo}: {descripción corta en español}`

| Tipo | Cuándo usar |
|------|-------------|
| `feat:` | Nueva funcionalidad |
| `fix:` | Corrección de bug |
| `refactor:` | Reestructuración |
| `docs:` | Documentación |
| `chore:` | Mantenimiento |

Ejemplos:
- `feat: agregar modo gimnasio con free pass`
- `fix: corrección de login con email no confirmado`
- `feat: reservas guest con link compartible`

### 5. Actualizar CHANGELOG.md

Prepender nueva entrada al inicio del archivo:

```markdown
## v1.1.0 — Modo Gimnasio (2026-08-01)

### Modo Gimnasio
- Toggle para activar modo gimnasio
- Horario configurable por día de la semana
- Free Pass: acceso abierto sin reservar

### Fix
- Corregido error de login con email no confirmado
```

### 6. Actualizar ChangelogPage.vue

Agregar entrada al array `entries` con el formato:

```typescript
{
  version: 'v1.1.0',
  date: '2026-08-01',
  changes: [
    { category: 'Modo Gimnasio', items: ['Toggle para activar...', ...] },
    { category: 'Fix', items: ['Corregido error de login...'] },
  ]
}
```

### 7. Ejecutar commit

```bash
git add .
git commit -m "{tipo}: {descripción}"
```

### 8. Confirmar

Mostrar al usuario:
- Nombre del commit
- Archivos modificados
- Entrada del changelog

---

## Formato del commit

```
{tipo}: {descripción corta en español}
```

Ejemplos:
- `feat: agregar modo gimnasio con free pass`
- `fix: corrección de login con email no confirmado`
- `feat: reservas guest con link compartible`
- `refactor: renombrar tablas a formato SaaS`
- `docs: actualizar changelog v1.1.0`

---

## Formato del CHANGELOG

```markdown
## v{VERSION} — {TÍTULO} ({YYYY-MM-DD})

### {Categoría}
- {Descripción del cambio}
- {Otro cambio}

### {Otra Categoría}
- {Descripción}
```

---

## Referencias

- `CHANGELOG.md` — fuente de verdad del historial
- `src/pages/ChangelogPage.vue` — vista en la app
- `SPEC.md` — especificación del proyecto
