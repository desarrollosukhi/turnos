---
name: create-migration
description: Use when creating SQL migrations for the reservation platform. Creates idempotent migration files with proper RLS policies.
---

# Skill: Create Migration

Use this skill when the user asks to create a database migration, add new tables, modify existing tables, or create SQL functions.

## When to use

- "Creá una migración para X"
- "Agregá una tabla de X"
- "Necesito un campo nuevo en X"
- "Creá una función SQL para X"

## Workflow

### 1. Understand the change
- Read the current schema in `supabase/schema.sql`
- Identify what tables/columns/functions are affected
- Determine if it's additive (new) or destructive (modify/delete)

### 2. Create migration file
- Create `supabase/migration-{feature-name}.sql`
- Use `IF NOT EXISTS` / `IF EXISTS` for idempotency
- Use `DO $$ BEGIN ... EXCEPTION WHEN ... THEN NULL; END $$` blocks

### 3. Follow security patterns
- All functions: `SET search_path = public, pg_temp`
- RLS policies: use `is_admin_of(company_id)` for admin checks
- Use `auth.uid()` for user-specific checks
- Never use `auth.jwt()` in policies (causes recursion)

### 4. Update documentation
- Add entry to `supabase/MIGRACIONES.md`
- Include: file name, description, when to run

### 5. Update types
- Add new interfaces to `src/types/index.ts`
- Follow existing naming conventions

## Idempotency patterns

```sql
-- Safe column add
ALTER TABLE IF EXISTS table_name ADD COLUMN IF NOT EXISTS col_name TYPE;

-- Safe policy creation
DO $$ BEGIN
  CREATE POLICY "policy_name" ON table_name ...;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Safe type creation
DO $$ BEGIN
  CREATE TYPE type_name AS ENUM (...);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
```

## RLS patterns

```sql
-- Admin check (uses SECURITY DEFINER function)
CREATE POLICY "table_admin_all" ON table_name
  FOR ALL USING (is_admin_of(company_id));

-- User own data
CREATE POLICY "table_select_own" ON table_name
  FOR SELECT USING (auth.uid() = user_id);

-- Professional access
CREATE POLICY "table_select_professional" ON table_name
  FOR SELECT USING (
    professional_id IN (
      SELECT id FROM professionals WHERE user_id = auth.uid()
    )
  );
```
