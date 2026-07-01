---
name: auto-commit
description: Genera mensajes de commit semánticos siguiendo Conventional Commits. Usar cuando el usuario quiera commitear cambios, pida "auto-commit", o cuando backend-expert/frontend-expert hayan validado código listo para commit.
argument-hint: --message "feat: add auth" --scope api --jira PROJ-123
tools: [Bash, Read]
---

# Auto-Commit Best Practices

## Formato: Conventional Commits

```
<type>(<scope>): <subject> [<ticket>]

<body opcional>

<footer opcional>
```

## Tipos
- `feat` — nueva funcionalidad
- `fix` — bug fix
- `refactor` — ni feature ni fix
- `perf` — mejora de rendimiento
- `test` — tests
- `docs` — solo documentación
- `style` — formato (no lógica)
- `chore` — deps, build, CI

## Reglas del subject
- Imperativo: "add" no "adds" ni "added"
- Sin mayúscula inicial, sin punto final
- Máx 50 caracteres

## Validaciones pre-commit (SIEMPRE)
1. `npm test` — todos los tests deben pasar
2. `npx tsc --noEmit` — sin errores de tipos
3. `npm run lint` — sin errores de lint
4. Sin `console.log`, `.only()`, `.skip()`, secretos hardcodeados

## Comando
```bash
npm run auto-commit -- \
  --message "feat(api): add date filter [PROJ-123]" \
  --files src/api/reports.ts \
  --push
```

## Anti-patrones
- ❌ `git commit -m "fix stuff"` → ✅ `fix(api): handle null dates`
- ❌ Subject en pasado → ✅ imperativo
- ❌ Sin ticket en features → ✅ `[PROJ-123]`
