---
name: fix-bug
description: Use when debugging issues in the reservation platform. Analyzes errors, checks console logs, and provides fixes.
---

# Skill: Fix Bug

Use this skill when the user reports an error, bug, or something isn't working correctly.

## When to use

- "Tengo un error de X"
- "No funciona Y"
- "Me sale Z en la consola"
- "La página no carga"

## Workflow

### 1. Gather information
- Ask for the exact error message
- Ask which page/component is affected
- Ask for console logs (F12 → Console)
- Ask for network errors (F12 → Network)

### 2. Identify the issue
- Check the error type: TypeScript, Vue template, SQL, network
- Check the file location from the error stack
- Check if it's a new issue or regression

### 3. Common issues and fixes

**TypeScript errors:**
- Missing imports → add to file
- Type mismatches → update interfaces
- Missing properties → add to type definition

**Vue template errors:**
- Invalid HTML → check tag closing
- Duplicate attributes → remove duplicates
- Missing computed/ref → add to script

**SQL errors:**
- Table/column not exist → check migration was run
- RLS blocking → check policy conditions
- Function errors → check function signature

**Network errors:**
- 401 Unauthorized → check auth state
- 404 Not Found → check API endpoint
- 500 Internal Server Error → check Supabase logs

### 4. Apply fix
- Make minimal changes to fix the issue
- Don't refactor unrelated code
- Verify the fix with `npm run build-only`

### 5. Document
- Add note to CHANGELOG.md if it's a significant fix
