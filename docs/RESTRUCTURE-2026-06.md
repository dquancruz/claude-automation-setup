# Restructure — antes vs. después (2026-06)

Comparación de lo que cambió al reorganizar el repo hacia `shared/` + `tools/claude/`. Contexto completo del porqué en `plan.md` (nota al inicio) y en el historial de commits; este documento es solo la foto antes/después.

## Motivación

El pedido original era hacer el setup más universal a medida que aparezcan nuevas herramientas de IA, sin perder la automatización ya construida. Se evaluó un plan generado por Cursor que proponía una arquitectura con codegen (`scripts/transformers/`, `package.json`, `tools/cursor/` comiteado, CI de drift-check) y portar los 12 subagentes a `~/.cursor/agents/`. Ese plan tenía errores fácticos (afirmaba que faltaban `block-secrets.sh` y `dependency-and-secrets-audit/SKILL.md`, cuando ya existían) y contradecía una decisión ya documentada en `docs/tool-compatibility.md`: los subagentes y hooks se quedan **intencionalmente** exclusivos de Claude Code. Se optó por una versión más ligera del mismo objetivo.

## Estructura de carpetas

| Antes | Después | Motivo |
|---|---|---|
| `global/agents/*.md` | `tools/claude/global/agents/*.md` | Exclusivo de Claude Code — se agrupa bajo `tools/claude/` en vez de una carpeta genérica `global/` |
| `global/skills/*/SKILL.md` | `shared/skills/*/SKILL.md` | Las skills son tool-agnostic (mismo `SKILL.md` sirve para cualquier herramienta) — se mueven a `shared/` |
| `per-repo/.claude/rules/*.md` | `tools/claude/per-repo/rules/*.md` | Pasan a ser la fuente **canónica** que alimenta la generación de rules de Cursor |
| `per-repo/.claude/hooks/*` | `tools/claude/per-repo/hooks/*` | Sin cambio de contenido, solo de ubicación (exclusivo Claude Code) |
| `per-repo/.claude/settings.json` | `tools/claude/per-repo/settings.json` | Igual — solo ubicación |
| `per-repo/.cursor/rules/*.mdc` | **Eliminado del repo** | Ver sección "Rules de Cursor" abajo — ya no se versionan a mano |
| `per-repo/scripts/*.js` | `shared/scripts/*.js` | Tool-agnostic (Node scripts consumidos vía `npm run`, no dependen de Claude) |
| `per-repo/.husky/*` | `shared/husky/*` | Tool-agnostic (git hooks) |
| `per-repo/.github/workflows/*` | `shared/github/workflows/*` | Tool-agnostic (CI) |
| `per-repo/AGENTS.md` | `shared/templates/AGENTS.md` | Tool-agnostic (lo leen Claude, Cursor, Gemini, Codex nativamente o vía symlink) |
| `per-repo/.mcp.json` | `shared/templates/.mcp.json` | Tool-agnostic (mismo schema MCP para todas las herramientas) |
| `per-repo/setup-portability.sh` | `shared/templates/setup-portability.sh` | Tool-agnostic |
| *(no existía)* | `tools/cursor/` | **No se creó.** Ver sección siguiente. |

## Por qué no hay `tools/cursor/`

Con subagentes y hooks quedándose Claude-only, y las rules de Cursor generadas al vuelo (no comiteadas), Cursor termina sin ningún artefacto propio que valga la pena versionar en este repo: todo lo que necesita ya es `shared/` (skills, MCP, AGENTS.md) o se genera directo en el repo destino. Crear una carpeta `tools/cursor/` vacía solo por simetría con `tools/claude/` habría sido una abstracción sin contenido. Si en el futuro una herramienta (Gemini CLI, Copilot, etc.) gana artefactos realmente exclusivos, se le crea su propio `tools/<nombre>/` siguiendo el mismo patrón.

## Rules de Cursor: de comiteadas a generadas

**Antes:** `per-repo/.cursor/rules/*.mdc` se escribían y mantenían a mano, en paralelo a `per-repo/.claude/rules/*.md`. Ya habían empezado a divergir — ejemplo real encontrado en `backend.md` vs `backend.mdc`:

```diff
- Validar todo input con Zod (TS) o Pydantic (Python) — nunca confiar en datos externos sin schema.
+ Validar input con Zod (TS) o Pydantic (Python).
```

El `.mdc` era una paráfrasis resumida y desactualizada del `.md`, sin que nada lo marcara como stale.

**Después:** `setup-repo.sh` genera `.cursor/rules/*.mdc` en cada corrida a partir de `tools/claude/per-repo/rules/*.md` (fuente única), vía la función bash `generate_cursor_rule()`:
- `paths:` → `globs:` (mismo valor)
- añade `description:` (tomada del primer `# Heading` del `.md`)
- añade `alwaysApply: false`
- el cuerpo se copia **verbatim**, sin resumir

No se comitea ningún `.mdc` en este repo — nunca puede quedar desactualizado porque no existe como archivo independiente hasta que `setup-repo.sh` lo escribe en el repo destino. Verificado: el cuerpo generado es idéntico byte a byte al `.md` fuente, y volver a correr el script sobreescribe limpio (sin duplicados).

## Lo que se descartó del plan de Cursor original

| Propuesta de Cursor | Decisión | Motivo |
|---|---|---|
| Portar los 12 agentes a `~/.cursor/agents/` (`agent-to-cursor.js`) | Descartado | Contradice `docs/tool-compatibility.md`, que ya declara los agentes "intencionalmente" exclusivos de Claude Code |
| `scripts/transformers/` + `package.json` + `gray-matter` | Descartado | Sobre-ingeniería para 5 archivos de rules; una función bash de ~15 líneas alcanza |
| Comitear `tools/cursor/` generado + CI de drift-check | Descartado | Innecesario si se genera al momento — elimina la posibilidad de drift en vez de detectarlo después |
| `hooks-to-cursor.js` / `.cursor/hooks.json` | Descartado | Hooks se quedan Claude-only (ya decidido) |
| Implementar `block-secrets.sh` y `dependency-and-secrets-audit/SKILL.md` "porque faltaban" | Descartado | Ya existían en el repo — el plan de Cursor tenía esa premisa equivocada |
| Rename `global/` → `tools/claude/global/`, `per-repo/` → estructura por herramienta | **Adoptado** | Es la parte del plan que sí tenía mérito, ejecutada en versión más simple (sin `tools/cursor/`) |

## Scripts modificados

- **`install.sh`** — mismas 3 secciones (verificar `~/.claude`, backup, instalar), rutas actualizadas: `tools/claude/global/agents/` y `shared/skills/`.
- **`setup-repo.sh`** — mismas secciones de copia, rutas actualizadas a `shared/` y `tools/claude/per-repo/`; se agregó la función `generate_cursor_rule()` y el paso que reemplaza el antiguo `cp .../.cursor/rules/*.mdc`.

## Docs actualizados

`README.md`, `USAGE.md`, `docs/tool-compatibility.md`, `docs/GITHUB-ACTIONS-SETUP.md`, `shared/skills/README.md` y una nota de "superseded" agregada al inicio de `plan.md` (se mantiene como registro histórico, no se reescribió).
