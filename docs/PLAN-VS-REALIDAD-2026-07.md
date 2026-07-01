# Reporte comparativo: Plan de Cursor vs. estado real del repo

_Generado: 2026-07-01_

## 1. Alcance del plan de Cursor

El archivo `claude-cursor_monorepo_split_1b1edd71.plan.md` proponía una reestructuración con **codegen explícito** para lograr paridad Claude/Cursor:

- **Nueva jerarquía**: `shared/` (artefactos tool-agnostic) + `tools/claude/` (SSOT canónico de Claude) + `tools/cursor/` (**generado y comiteado**) + `scripts/transformers/`.
- **Motivación declarada**: las rules ya divergían entre `.md` (Claude) y `.mdc` (Cursor) por edición manual duplicada; faltaban artefactos (`block-secrets.sh`, `dependency-and-secrets-audit/SKILL.md`); no había paridad para subagentes/skills/hooks de Cursor.
- **Pasos clave (Fases A-D)**:
  1. Mover `global/` y `per-repo/` a `shared/`/`tools/claude/`.
  2. Construir transformadores Node (`agent-to-cursor.js`, `rule-to-mdc.js`, `hooks-to-cursor.js`, `index.js` con modo `--check`).
  3. Generar y **comitear** `tools/cursor/` (agentes Cursor, `.mdc`, `hooks.json`).
  4. Nuevos scripts de instalación (`install-cursor.sh`, `setup-portability.ps1` para Windows) y un `package.json` raíz con `generate:cursor` / `generate:cursor:check`.
  5. Portar los 12 subagentes a `~/.cursor/agents/` y agregar CI que falle si `tools/cursor/` queda "stale".

## 2. Estado real — qué se hizo, qué no, y qué se hizo diferente

**Se ejecutó (con `git status` confirmado):**
- Migración de carpetas: `global/agents/*` → `tools/claude/global/agents/*` (12 archivos), `global/skills/*` → `shared/skills/*` (12 skills + README), `per-repo/.claude/rules/*` → `tools/claude/per-repo/rules/*`, `per-repo/.claude/hooks/*` → `tools/claude/per-repo/hooks/*`, `per-repo/.claude/settings.json` → `tools/claude/per-repo/settings.json`, `per-repo/scripts/*.js` → `shared/scripts/*.js`, `per-repo/.husky/*` → `shared/husky/*`, `per-repo/.github/workflows/*` → `shared/github/workflows/*`, `per-repo/AGENTS.md` → `shared/templates/AGENTS.md`, `per-repo/.mcp.json` → `shared/templates/.mcp.json`, `per-repo/setup-portability.sh` → `shared/templates/setup-portability.sh`.
- `install.sh` y `setup-repo.sh` actualizados a las nuevas rutas (verificado leyendo ambos archivos completos — no quedan referencias rotas a `global/` o `per-repo/`).
- Docs actualizados: `README.md`, `USAGE.md`, `docs/GITHUB-ACTIONS-SETUP.md`, `docs/tool-compatibility.md`, `shared/skills/README.md`, y una nota "Estado: mayormente ejecutado" agregada al inicio de `plan.md` original.
- Se verificó directamente en disco que `tools/claude/per-repo/hooks/pre-tool-use/block-secrets.sh` y `shared/skills/dependency-and-secrets-audit/SKILL.md` **ya existían** antes de la migración — la premisa del plan de Cursor de que faltaban era **fácticamente incorrecta** (confirmado tanto por el `find` del filesystem como por `docs/RESTRUCTURE-2026-06.md`).

**Hecho DIFERENTE a lo planeado (decisión consciente, no omisión accidental):**
- `docs/RESTRUCTURE-2026-06.md` (archivo untracked nuevo) documenta explícitamente que el plan de Cursor fue **evaluado y rechazado en sus partes de codegen**. La justificación registrada: "contradecía una decisión ya documentada en `docs/tool-compatibility.md`: los subagentes y hooks se quedan intencionalmente exclusivos de Claude Code" — y el plan tenía errores fácticos sobre archivos "faltantes".
- **No existe `tools/cursor/`** (verificado: no hay tal carpeta en disco). En vez de comitear un árbol generado, `setup-repo.sh` incorporó una función bash `generate_cursor_rule()` (líneas 61-75) que genera `.cursor/rules/*.mdc` **al vuelo, en el repo destino**, cada vez que se corre el script (paso 2f, líneas 169-178) — nunca se versiona el `.mdc` en este repo.
- **No existen** `scripts/transformers/`, `package.json` raíz, `install-cursor.sh`, ni `setup-portability.ps1`. No hay dependencia de Node/`gray-matter` para parsear frontmatter; el reemplazo `paths:`→`globs:` se hace con `grep`/`sed`/`awk` puros en `setup-repo.sh`.
- Los 12 subagentes **no** se portan a `~/.cursor/agents/` ni a `.cursor/agents/` — se mantienen exclusivos de Claude Code (tabla de paridad en `README.md` línea 65: "Agentes | ✅ | ❌ | ❌ | ❌ | ❌").
- Los hooks (`block-secrets.sh`, `lint-after-write.sh`) **no** se registran para Cursor (`.cursor/hooks.json` nunca se creó); siguen siendo Claude-only, consistente con `docs/tool-compatibility.md`.

**Lo que falta respecto al plan original** (pero por decisión, no por trabajo pendiente): transformadores Node, CI de drift-check (`generate:cursor:check`), paridad de subagentes/hooks en Cursor. Ninguno de estos aparece como "pendiente" en el repo — `docs/RESTRUCTURE-2026-06.md` los lista en una tabla "Lo que se descartó del plan de Cursor original" con motivo explícito para cada ítem.

## 3. Riesgos y cabos sueltos

- **`per-repo/.cursor/rules/*.mdc` borrados sin reemplazo versionado** (los 5 `D` en `git status`: backend, design, frontend, security, testing) — esto es **intencional**, no una pérdida accidental: el reemplazo es la generación en tiempo de ejecución vía `generate_cursor_rule()` en `setup-repo.sh`. Riesgo residual: si alguien clona el repo y espera ver `.mdc` versionados (como antes), puede sorprenderse; está documentado en `README.md` línea 40 y en `docs/RESTRUCTURE-2026-06.md`, pero no hay mención de esto en `USAGE.md`.
- **Ninguna referencia rota encontrada**: grep exhaustivo de `global/agents`, `global/skills`, `per-repo/.claude`, `per-repo/.cursor`, `per-repo/scripts`, `per-repo/.husky`, `per-repo/.github` en todo el árbol (excluyendo los dos archivos de plan, que son historial intencional) solo arroja coincidencias legítimas tipo `tools/claude/global/agents/` (falso positivo del regex, no ruta rota). `install.sh` (líneas 56-57) y `setup-repo.sh` (múltiples secciones) apuntan correctamente a `shared/` y `tools/claude/`.
- **`claude-cursor_monorepo_split_1b1edd71.plan.md` queda suelto en la raíz del repo, sin trackear** — no está en `.gitignore` ni referenciado desde ningún doc salvo este análisis. Si no se va a comitear como registro histórico, conviene decidir explícitamente si se descarta o se mueve a `docs/` (junto a `docs/RESTRUCTURE-2026-06.md`, que sí lo referencia por nombre en su primera línea).
- **`plan.md` original mantiene ~15 referencias a rutas viejas** (`global/skills/`, `per-repo/.claude/rules/`, etc., líneas 213-416) como parte de su contenido histórico — esto es intencional según la nota agregada al inicio ("se mantiene como registro histórico, no se reescribió"), pero vale la pena que quede explícito para cualquiera que lo lea sin contexto.
- **Conteos verificados correctos**: 12 agentes (`tools/claude/global/agents/*.md`) y 12 skills (`shared/skills/*/`) coinciden con lo que dicen `README.md` y `USAGE.md`.

## 4. Recomendación de próximos pasos

1. Decidir el destino de `claude-cursor_monorepo_split_1b1edd71.plan.md`: si se conserva como evidencia histórica de la decisión de arquitectura, moverlo a `docs/` (p. ej. `docs/claude-cursor-plan-original.md`) y enlazarlo desde `docs/RESTRUCTURE-2026-06.md`; si no aporta valor a futuro, se puede descartar sin comitear.
2. Agregar en `USAGE.md` una sección breve (o un enlace a `docs/RESTRUCTURE-2026-06.md`) que explique el mecanismo de generación de `.cursor/rules/*.mdc` en tiempo de `setup-repo.sh`, para que un usuario nuevo no busque esos `.mdc` como archivos versionados.
3. Confirmar que `docs/RESTRUCTURE-2026-06.md` se quiere comitear tal cual (actualmente untracked) — es, de hecho, el documento que mejor resuelve la comparación pedida en esta tarea; vale la pena que quede en el historial de commits, no solo en el working directory.
4. Correr `bash setup-repo.sh` en un repo de prueba (o revisar manualmente) para confirmar en runtime que `generate_cursor_rule()` produce `.mdc` idénticos a los `.md` fuente (la afirmación de "verificado byte a byte" en `docs/RESTRUCTURE-2026-06.md` línea 48 no fue revalidada en esta sesión de solo lectura).
5. Ninguna acción urgente de "reparación" es necesaria — el split está funcionalmente completo y consistente; el "plan de Cursor" fue una propuesta evaluada y conscientemente simplificada, no un plan abandonado a medias.

## Archivos revisados

- `claude-cursor_monorepo_split_1b1edd71.plan.md`
- `docs/RESTRUCTURE-2026-06.md`
- `plan.md`
- `install.sh`
- `setup-repo.sh`
- `README.md`
- `USAGE.md`
- `docs/tool-compatibility.md`
- `docs/GITHUB-ACTIONS-SETUP.md`
- `shared/skills/README.md`
- `tools/claude/` (árbol completo, 12 agentes + rules + hooks + settings.json)
- `shared/` (árbol completo)
