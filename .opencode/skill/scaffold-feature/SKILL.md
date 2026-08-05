---
name: scaffold-feature
description: Use when creating new features for the reservation platform. Creates types, services, pages, routes, and SQL migrations following the project's patterns.
---

# Skill: Scaffold Feature

Use this skill when the user asks to create a new feature, functionality, or module for the reservation platform.

## When to use

- "Creame la funcionalidad de X"
- "Agregame la página de X"
- "Necesito un nuevo CRUD para X"
- "Implementá el módulo de X"

## Workflow

### 1. Analyze the request
- Read SPEC.md to understand if the feature is defined
- Identify what tables, types, services, and pages are needed
- Determine if SQL migration is required

### 2. Create TypeScript types
- Add interfaces to `src/types/index.ts`
- Follow existing naming conventions (PascalCase, descriptive names)

### 3. Create SQL migration (if needed)
- Create file in `supabase/migration-{feature-name}.sql`
- Use `IF NOT EXISTS` / `IF EXISTS` for idempotency
- Include RLS policies following the `is_admin_of()` pattern
- Add to `MIGRACIONES.md`

### 4. Create service
- Create `src/services/{FeatureName}Service.ts`
- Follow existing patterns: async methods, error handling, Supabase queries
- Export as named constant

### 5. Create pages
- Admin page: `src/pages/admin/Admin{FeatureName}Page.vue`
- Customer page (if needed): `src/pages/{FeatureName}Page.vue`
- Follow existing patterns: forms, tables, loading states, error handling

### 6. Update router
- Add routes to `src/router/index.ts`
- Use appropriate meta: `requiresAuth`, `requiresAdmin`, `requiresProfessional`, `layout`

### 7. Update layouts (if needed)
- Add navigation items to `AdminLayout.vue` sidebar

### 8. Verify build
- Run `npm run build-only` to check for errors

## Patterns to follow

- Use CSS variables for theming: `var(--color-primary)`, `var(--color-surface)`, etc.
- Use `is_admin_of()` for RLS policies
- Use `auth.uid()` for user-specific queries
- Use `signUp()` instead of `admin.createUser()`
- All SQL functions should have `SET search_path = public, pg_temp`
