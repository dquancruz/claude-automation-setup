---
name: semantic-versioning
description: Detecta el bump de versión correcto (MAJOR/MINOR/PATCH) a partir de los commits, actualiza package.json, genera el CHANGELOG, crea el git tag y publica el GitHub Release. Usar cuando se va a hacer un release o cuando documentation-generator pide bump de versión.
argument-hint: --dry-run
tools: [Bash, Read, Edit]
---

# Semantic Versioning Control

## SemVer: MAJOR.MINOR.PATCH

- **MAJOR** — breaking changes (`feat!:`, `BREAKING CHANGE:`)
- **MINOR** — nueva funcionalidad compatible (`feat:`)
- **PATCH** — bug fixes (`fix:`, `perf:`, `refactor:`)

## Detección automática desde commits
```bash
# Ver commits desde último tag
git log $(git describe --tags --abbrev=0)..HEAD --oneline

# Si hay feat!: o BREAKING CHANGE → MAJOR
# Si hay feat: → MINOR
# Si solo hay fix:/chore:/docs: → PATCH
```

## Flujo de release
1. `npm version <major|minor|patch>` — bump en package.json + tag
2. Actualizar `CHANGELOG.md` con cambios del período
3. `git push && git push --tags`
4. Crear GitHub Release con las notas del CHANGELOG

## CHANGELOG formato
```markdown
## [1.2.0] - 2026-06-29
### Added
- Descripción del feat

### Fixed
- Descripción del fix
```

## Anti-patrones
- ❌ Nunca saltar versiones (de 1.0 a 2.0 sin 1.x intermedio)
- ❌ Nunca bajar versión
- ❌ Tag en main sin pasar por PR
