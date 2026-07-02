# AI-SETUP-PLAN-v2 — Arquitectura Multi-Tool Extensible

> **Estado:** EN EJECUCIÓN — Fases 1-4 de la sección 8 ya están implementadas y commiteadas (ver estado por fase ahí). Fases 5-6 pendientes. El plan se considera aprobado por la ejecución continuada de sus fases en orden; este documento ya no es solo diseño especulativo.
> **Para:** revisión humana → luego, si se aprueba, ejecución por Claude Code en fases (sección 8).
> **Reemplaza en intención (no en archivo) a:** el intento de reestructuración `shared/` + `tools/claude/` + `tools/cursor/` con codegen documentado en `docs/RESTRUCTURE-2026-06.md` y evaluado en `docs/PLAN-VS-REALIDAD-2026-07.md`. Este plan retoma la idea de fondo (SSOT + adaptadores) pero corrige los motivos concretos de rechazo (ver sección 7).

---

## 0. Resumen del problema y principio rector

Hoy el setup es **Claude-only funcional**: 12 agentes + 12 skills + hooks + scripts viven en `global/` (→ `~/.claude/`) y `per-repo/` (→ cada proyecto). Cursor recibe una fracción — `AGENTS.md`, `.mcp.json`, `.cursor/rules/*.mdc` mantenidos **a mano en paralelo** a `.claude/rules/*.md` — y ya mostraron drift real (`docs/RESTRUCTURE-2026-06.md`, ejemplo `backend.md` vs `backend.mdc`).

El pedido ahora es explícito: no se trata solo de "agregar Cursor", sino de dejar el setup listo para que **agregar la próxima herramienta (Windsurf, Copilot, Codex CLI, Gemini CLI, la que sea)** sea una tarea de bajo costo, sin duplicar contenido y sin rehacer la arquitectura cada vez.

**Principio rector: separar CONOCIMIENTO de PRESENTACIÓN.**

- El **conocimiento** (qué hace cada agente, qué sabe cada skill, qué reglas rigen `src/api/`, qué hace el hook de bloqueo de secretos) se escribe **una sola vez**, en un formato tool-agnostic, en un `registry/` central.
- La **presentación** (¿el archivo se llama `.claude/rules/backend.md` o `.cursor/rules/backend.mdc`? ¿el agente es un subagente real o un párrafo condensado dentro de `AGENTS.md`?) es responsabilidad de un **adaptador por herramienta**, pequeño y aislado, que declara sus capacidades y renderiza el conocimiento al formato que esa herramienta entiende — **en el momento de habilitar un repo, no antes, y nunca comiteado como árbol generado en este repo.**

Esto es la misma lección que ya dejó `docs/RESTRUCTURE-2026-06.md` (generar `.mdc` al vuelo, no versionarlo) — este plan la generaliza a **todos** los artefactos (agentes, skills, rules, hooks, MCP) y a **cualquier** herramienta futura, no solo a las rules de Cursor.

---

## 1. Estructura de directorios propuesta

```
claude-automation-setup/
│
├── registry/                        # SSOT — conocimiento, tool-agnostic, se edita UNA vez
│   ├── agents/                      # 12 agentes canónicos (ver sección 2)
│   │   ├── backend-expert.md
│   │   ├── security-expert.md
│   │   └── ...
│   ├── skills/                      # 12 skills — YA son portables hoy, se mantienen igual
│   │   ├── auto-commit/SKILL.md
│   │   └── ...
│   ├── rules/                       # Rules canónicas, un solo archivo por dominio
│   │   ├── backend.md               # frontmatter: paths: [...]
│   │   ├── frontend.md
│   │   ├── testing.md
│   │   ├── design.md
│   │   └── security.md
│   ├── hooks/                       # Lógica de hooks, tool-agnostic (ver sección 4)
│   │   ├── pre-write/block-secrets.sh
│   │   └── post-write/lint-after-write.sh
│   ├── templates/                   # AGENTS.md template, .mcp.json template, .env.example
│   └── scripts/                     # auto-commit.js, auto-pr.js, auto-jira.js, dashboard.js
│                                     # (ya tool-agnostic hoy — no cambian de contenido, solo de carpeta)
│
├── tools/                           # Un adaptador por herramienta de IA soportada
│   ├── claude/
│   │   ├── capabilities.yaml        # qué soporta nativamente (ver sección 5)
│   │   └── enable.sh                # cómo instalar/renderizar para esta herramienta
│   ├── cursor/
│   │   ├── capabilities.yaml
│   │   ├── enable.sh
│   │   └── adapt/
│   │       ├── rule-to-mdc.sh       # generaliza generate_cursor_rule() ya validado
│   │       └── agent-to-mode.sh     # agente canónico → Cursor Custom Mode
│   ├── copilot/
│   │   ├── capabilities.yaml
│   │   └── enable.sh                # usa lib/condense.mjs (sección 6)
│   └── _template/                   # scaffold para agregar una herramienta nueva
│       ├── capabilities.yaml.example
│       └── enable.sh.example
│
├── lib/                              # Motor de render compartido — evita reimplementar por tool
│   ├── frontmatter.sh                # parseo de frontmatter YAML mínimo (sin deps pesadas)
│   ├── condense.mjs                  # colapsa N agentes/skills a resumen de bajo presupuesto
│   └── render.mjs                    # aplica capabilities.yaml + registry/* → salida por tool
│
├── bin/
│   ├── install-global.sh             # reemplaza install.sh — recorre tools/*/enable.sh --scope=global
│   └── enable-repo.sh                # reemplaza setup-repo.sh — el "habilitar repo" (sección 5)
│
├── docs/
│   ├── tool-compatibility.md         # tabla derivada 1:1 de tools/*/capabilities.yaml
│   ├── context-budget.md             # ya existe — se extiende con tabla de tiers (sección 6)
│   ├── AI-SETUP-PLAN-v2.md           # este documento
│   └── RESTRUCTURE-2026-06.md        # se conserva como registro histórico
│
└── plan.md                           # se conserva como registro histórico (ya tiene nota de "superseded")
```

**Qué NO existe en este árbol y por qué:** no hay `tools/cursor/global/agents/` ni ningún otro subárbol **generado y comiteado** dentro de `claude-automation-setup`. Todo lo que un adaptador produce (un `.mdc`, un Custom Mode de Cursor, un `AGENTS.md` condensado para Copilot) se escribe **directamente en el repo destino** (o en `~/.cursor/`, `~/.claude/`, etc. para el scope global) cuando corre `enable-repo.sh` / `install-global.sh`. Nunca hay un artefacto generado que viva en este repo esperando quedar stale. Esto es exactamente la lección de `docs/RESTRUCTURE-2026-06.md`, generalizada.

---

## 2. Paridad de agentes entre herramientas con distintas capacidades

Los mismos 12 agentes existen para todas las herramientas — lo que cambia es **cómo se materializan**, según lo que cada tool puede ejecutar. Se define un frontmatter canónico ampliado y tres **tiers de renderizado**:

### 2.1 Formato canónico (`registry/agents/<nombre>.md`)

```markdown
---
name: backend-expert
description: Backend implementation specialist for NestJS, FastAPI, MongoDB...
model: sonnet                 # solo relevante para tools con model routing (Claude)
tools: Read, Write, Edit, Bash, Glob, Grep   # solo relevante para tools con permisos por herramienta
skills: [iot-backend, auto-commit]
tier: core                    # core | extended → orden de prioridad al condensar (sección 6)
---

## Essence                    # NUEVO — 3-5 bullets, para tiers que no pueden cargar el body completo
- Implementa APIs NestJS/FastAPI/MongoDB con TDD-first.
- Auto-commitea solo tras validar tests + lint.
- Coordina contratos compartidos con frontend-expert.
- Nunca hace push directo a main.

# Backend Expert
<body completo igual al actual global/agents/backend-expert.md>
```

El único contenido **nuevo** que hay que redactar por agente es el bloque `## Essence` (3-5 bullets) — el resto es el mismo body que ya existe hoy en `global/agents/*.md`. Esta sección es la pieza que permite condensar sin duplicar prosa: se escribe una vez junto al agente y la reutiliza cualquier tool de tier C, presente o futura.

### 2.2 Los tres tiers de renderizado

| Tier | Qué soporta la tool | Cómo se materializa el agente | Ejemplo hoy |
|------|---------------------|-------------------------------|-------------|
| **A — Subagente nativo** | Contexto aislado por agente, invocación automática/paralela | Copia verbatim a la carpeta de agentes de la tool | Claude Code (`~/.claude/agents/`) |
| **B — Modo/persona nativo, sin aislamiento de contexto** | El usuario puede definir "modos" o "personas" con instrucciones propias, pero sin orquestación automática ni contexto aislado | `agent-to-mode.sh` renderiza el body completo a **un archivo por agente** en el formato nativo de esa tool (ej. Cursor Custom Mode) — mismo contenido, invocación manual | Cursor (Custom Modes) |
| **C — Un solo archivo de instrucciones, sin concepto de agente** | Todo vive en un único documento siempre cargado | `condense.mjs` colapsa los 12 agentes a un **roster condensado** (nombre + primera frase de `description` + `## Essence`) dentro de `AGENTS.md`/`copilot-instructions.md` | GitHub Copilot |

Regla explícita: **el roster (los 12 nombres + su especialidad) es idéntico en las tres tiers.** Lo que se pierde al bajar de tier no es "qué agentes existen" sino la **mecánica de invocación** (automática y paralela en A, manual en B, "actúa como X" instruido por el usuario en C). Esa pérdida se documenta explícitamente en `AGENTS.md` (sección "Cómo se invoca cada agente según tu herramienta"), nunca se finge paridad que no existe — mismo criterio que ya usaba el plan de Cursor rechazado ("no fake parity"), que sí era correcto en ese punto.

### 2.3 Por qué esto reconsidera (parcialmente) la decisión de `tool-compatibility.md`

La decisión previa decía "los 12 subagentes son intencionalmente exclusivos de Claude Code". Se mantiene correcta para la **orquestación** (contexto aislado + paralelismo + selección automática por `description`) — eso sigue siendo un mecanismo interno de Claude Code sin equivalente real. Pero el **contenido** de cada agente (su expertise, sus reglas, su rol) sí puede — y debe — viajar a cualquier tool vía tiers B/C. Antes esto no se hacía porque la única alternativa contemplada era "portar subagentes reales a `~/.cursor/agents/`", que si Cursor no tiene ese concepto exacto, es una analogía forzada. Custom Modes sí es una analogía razonable (persona + instrucciones propias, invocación manual) — de ahí que se reconsidere para tier B, sin tocar la conclusión sobre orquestación.

---

## 3. Evitar duplicación — mecanismo concreto

**Un solo lugar de verdad por tipo de conocimiento**, más un **motor de render genérico** en vez de una función de transformación por cada combinación (artefacto × tool):

| Tipo de conocimiento | SSOT | Se duplica hoy porque... | Cómo deja de duplicarse |
|---|---|---|---|
| Agentes | `registry/agents/*.md` | No existía condensación → se pensaba "portar" o "no portar", nada intermedio | `lib/render.mjs` aplica el tier declarado en `capabilities.yaml` de la tool destino |
| Skills | `registry/skills/*/SKILL.md` | Ya no se duplican hoy (correcto) | Se mantiene igual — solo cambia de carpeta (`global/skills` → `registry/skills`) |
| Rules | `registry/rules/*.md` | `.claude/rules/*.md` y `.cursor/rules/*.mdc` se mantenían a mano en paralelo | `tools/cursor/adapt/rule-to-mdc.sh` genera el `.mdc` en el repo destino en cada `enable-repo.sh`, nunca se edita a mano ni se comitea aquí |
| Hooks (lógica) | `registry/hooks/*.sh` | N/A hoy (Claude-only) — pero al agregar tools con hooks, el riesgo es reescribir la lógica por tool | Los scripts leen ambos esquemas de stdin (`tool`/`tool_name`, `file_path`/`path`) — la MISMA lógica sirve para cualquier tool que dispare hooks; solo cambia el archivo de *registro* (`.claude/settings.json` vs el equivalente de la tool nueva) |
| MCP | `registry/templates/.mcp.json` | Ya centralizado hoy (correcto) | Se mantiene igual — cada tool symlinkea o copia a su ruta esperada |
| Instrucciones del proyecto | `registry/templates/AGENTS.md` | Ya centralizado hoy vía symlinks (correcto) | Se mantiene igual, generalizando el loop de symlinks a cualquier tool declarada en `tools/*/capabilities.yaml` |

**¿Por qué el motor de render (`lib/render.mjs` + `lib/condense.mjs`) sí se justifica esta vez, si la vez pasada se rechazó el codegen?**

Diferencia concreta con lo rechazado en `docs/RESTRUCTURE-2026-06.md`:

1. **No genera y comitea un árbol en este repo.** Genera directo en el repo/máquina destino, en cada ejecución de `enable-repo.sh`/`install-global.sh` — no hay nada que pueda quedar "stale" porque no hay copia persistente comparándose contra el SSOT; se regenera siempre desde cero (idempotente, sobrescribe limpio, igual que ya hace `generate_cursor_rule()` hoy).
2. **No agrega dependencias pesadas.** `lib/frontmatter.sh` sigue el mismo criterio que ya se usó para rechazar `gray-matter`: parseo de frontmatter con `grep`/`sed`/`awk` o, si se usa Node, sin dependencias externas (regex simple, ya es el estilo de `per-repo/scripts/*.js`).
3. **No agrega CI de "drift-check".** No hace falta: si nada generado se comitea, no hay drift posible por definición — se elimina la clase de problema en vez de vigilarla.
4. **Es un único motor genérico, no N transformadores ad-hoc.** La vez pasada se propusieron `agent-to-cursor.js`, `rule-to-mdc.js`, `hooks-to-cursor.js` como scripts separados y crecientes por combinación tool×artefacto. Acá `render.mjs` toma `capabilities.yaml` como dato — agregar una tool nueva es **declarar capacidades**, no escribir un transformador nuevo desde cero (salvo casos de formato realmente distinto, como `.mdc`, que sí quedan como adaptadores pequeños y explícitos en `tools/<tool>/adapt/`).

---

## 4. Hooks — lógica compartida, registro por tool

Hoy solo Claude Code soporta hooks (`PreToolUse`/`PostToolUse`). Eso puede seguir siendo cierto para Copilot/Codex actuales, pero no hay que asumir que ninguna tool futura tendrá hooks — el diseño debe estar listo sin sobre-construir hoy.

- `registry/hooks/pre-write/block-secrets.sh` y `registry/hooks/post-write/lint-after-write.sh` contienen la lógica pura, **agnóstica de qué tool los invoca**: leen el path del archivo y el contenido desde variables de entorno o stdin JSON, aceptando ambos esquemas de nombres de campo conocidos hasta hoy (`tool_name`/`tool`, `file_path`/`path`), tal como ya proponía correctamente el plan rechazado en este punto puntual.
- El **registro** (qué evento dispara qué script, con qué matcher) es lo único específico de cada tool: `tools/claude/enable.sh` escribe `.claude/settings.json` apuntando a `registry/hooks/...` (copiado o symlinkeado al repo destino). Una tool futura con hooks aporta su propio `tools/<tool>/adapt/hooks-registration.*` sin tocar la lógica en `registry/hooks/`.
- Tools sin soporte de hooks (Cursor, Copilot hoy): `capabilities.yaml` declara `hooks: none` y `enable.sh` simplemente no escribe nada — se documenta en `docs/tool-compatibility.md` como límite real, no se simula.

---

## 5. Mecanismo de "habilitar repo" por herramienta

### 5.1 `capabilities.yaml` — el contrato que hace todo esto extensible

Cada tool declara, en un archivo de ~15 líneas, qué soporta:

```yaml
# tools/cursor/capabilities.yaml
name: cursor
instructions:
  mechanism: native            # native | symlink | inline
  filename: AGENTS.md          # Cursor lee AGENTS.md nativamente, sin symlink
  global_scope: unsupported    # Cursor no tiene AGENTS.md/CLAUDE.md global — solo por repo
agents:
  mechanism: custom-mode        # native | custom-mode | condensed | none
  path: ".cursor/modes.json"    # repo-local; ver 5.3 — no existe equivalente global
  global_scope: unsupported
skills:
  mechanism: reference          # native-autodiscovery | reference | condensed | none
  path: ".cursor/skills/"
  global_scope: unsupported     # confirmado: Cursor no tiene directorio personal/global de skills
rules:
  mechanism: native-mdc         # native | native-mdc | condensed | none
  path: ".cursor/rules/"
  global_scope: manual-only     # existe "User Rules" en Settings → Rules → User, pero vive en
                                 # el storage interno de la app, no en un archivo plano editable
                                 # por script de forma soportada — no se automatiza
hooks:
  mechanism: none                # native | none
  global_scope: unsupported
mcp:
  mechanism: native
  path: ".cursor/mcp.json"
  global_scope: supported        # ~/.cursor/mcp.json (%USERPROFILE%\.cursor\mcp.json en Windows)
                                  # es un archivo real — project-level gana si hay conflicto de server
context_tier: B                  # A | B | C — usado por lib/condense.mjs
max_instructions_lines: 300
```

Nuevo campo `global_scope` por artefacto (`supported | unsupported | manual-only`): existe porque, a diferencia de Claude Code, **no todos los artefactos de Cursor tienen equivalente a nivel de máquina** — ver tabla completa en 5.3.

### 5.2 `bin/enable-repo.sh` — entrypoint único

```bash
enable-repo.sh --tools claude,cursor,copilot   # default: all
```

Por cada tool solicitada:

1. Lee `tools/<tool>/capabilities.yaml`.
2. Instala lo **tool-agnóstico** una sola vez por repo, sin importar cuántas tools se habiliten (scripts de automatización, Husky, GitHub Actions, `.env.local`, `.mcp.json` base) — esto ya no se repite por tool.
3. Para lo que sí varía por tool, invoca `lib/render.mjs` con el `capabilities.yaml` correspondiente:
   - `instructions.mechanism` → symlink (`CLAUDE.md`, `GEMINI.md`, `.github/copilot-instructions.md`) o nativo (Cursor no necesita symlink, ya lee `AGENTS.md`).
   - `agents.mechanism` → copia verbatim (native), corre `tools/<tool>/adapt/agent-to-mode.sh` (custom-mode), o condensa dentro de instructions (condensed).
   - `rules.mechanism` → copia verbatim, corre `rule-to-mdc.sh`, o condensa.
   - `skills.mechanism` → copia carpeta completa, deja solo referencia (nombre + ruta), o condensa resumen.
   - `hooks.mechanism` → registra si `native`, omite si `none`.
   - `mcp.mechanism` → symlink/copia a `path`.
4. Imprime un resumen explícito: qué se habilitó, qué se omitió y por qué (leyendo directo de `capabilities.yaml`), para que el gap de paridad sea visible, no silencioso.

### 5.3 `bin/install-global.sh` — qué significa "global" tool por tool

**Esta sección estaba subespecificada en la versión anterior del plan** (asumía "agentes y skills a `~/.claude/`, `~/.cursor/`, etc." como si el mecanismo fuera simétrico entre tools). No lo es. Investigado el comportamiento real de cada tool antes de asumir nada — mismo criterio que ya obligó `docs/RESTRUCTURE-2026-06.md` ("no asumir que faltan artefactos sin verificar el filesystem primero"), aplicado ahora a "no asumir que existe un scope global sin verificar la tool primero":

| Artefacto | Claude Code | Cursor |
|---|---|---|
| **Agentes** | `~/.claude/agents/*.md` — directorio global real, ya usado hoy por `install.sh`. `tools/claude/enable.sh --scope=global` sigue haciendo `cp registry/agents/*.md ~/.claude/agents/`, sin cambio de comportamiento. | **No existe scope global.** Los Custom Modes de Cursor viven en `.cursor/modes.json`, un archivo **por proyecto** — no hay un `~/.cursor/modes.json` que aplique a todos los repos. `install-global.sh` **no instala agentes para Cursor**; los 12 agentes solo llegan a un repo Cursor cuando corre `enable-repo.sh` sobre ESE repo. |
| **Skills** | `~/.claude/skills/<nombre>/SKILL.md` — igual, directorio global real, sin cambio de comportamiento. | **No existe directorio personal/global de skills en Cursor** (a diferencia de Claude Code) — todas las skills de Cursor son project-scoped, en `.cursor/skills/`. Mismo caso que agentes: `install-global.sh` no hace nada para Cursor aquí; solo `enable-repo.sh` por repo. |
| **Rules** | No aplica scope global hoy (las rules ya son por-repo vía path-matching); se mantiene igual. | Cursor sí tiene "User Rules" (Settings → Rules → User) que aplican a toda la máquina — pero viven en el storage interno de la app (no un archivo plano documentado como estable para escribir por script). Se marca `global_scope: manual-only`: el plan **no** intenta automatizar esto: en su lugar, `install-global.sh` imprime instrucciones para que el usuario las pegue manualmente en Settings, generadas desde `registry/rules/*.md`. |
| **MCP** | Sin cambio — ya centralizado hoy. | `~/.cursor/mcp.json` (`%USERPROFILE%\.cursor\mcp.json` en Windows) es un archivo real y documentado — **sí soportado**. `install-global.sh` puede escribirlo/mergearlo con seguridad. Si el mismo server está definido también en `.cursor/mcp.json` del repo, Cursor prioriza el project-level (documentado por Cursor, no asumido). |
| **Hooks** | Global no aplica (hooks son por-repo hoy). | Cursor no tiene hooks — `global_scope: unsupported`, igual que a nivel repo. |

**Consecuencia para el diseño de `install-global.sh`:** no es "el mismo motor aplicado a otra ruta" como decía la versión anterior — es el mismo motor, pero que **lee `global_scope` de cada `capabilities.yaml` y omite explícitamente** lo que no tiene equivalente de máquina, en vez de intentar forzar una ruta que no existe. Para Cursor, el resultado real de correr `install-global.sh --tools cursor` hoy es: instala MCP global, imprime instrucciones para pegar rules manualmente en Settings, y dice explícitamente "agentes y skills de Cursor no tienen scope global — se instalan al habilitar cada repo con `enable-repo.sh`" — igual que ya hace el punto 4 de `enable-repo.sh` (sección 5.2) al imprimir qué se omitió y por qué, pero a nivel global.

**Para una tool futura:** el mismo campo `global_scope` en su `capabilities.yaml` es lo único que hay que declarar (`supported`, `unsupported`, o `manual-only` con instrucciones) — no hace falta tocar `install-global.sh`, que ya recorre `tools/*/capabilities.yaml` genéricamente (sección 5.4).

*Fuentes usadas para verificar el comportamiento real de Cursor (no asumido): [Cursor Docs — Rules](https://cursor.com/docs/rules), [Cursor Docs — CLI Configuration](https://cursor.com/docs/cli/reference/configuration), [Cursor Docs — Customizing Agents](https://cursor.com/learn/customizing-agents), [Where Cursor Stores Skills](https://www.agensi.io/learn/where-are-cursor-skills-stored), [Cursor Forum — Workspace/profile-scoped config request](https://forum.cursor.com/t/workspace-or-profile-scoped-cursor-config-rules-skills-subagents-mcp/153068).*

### 5.4 Agregar una herramienta nueva (ej. Windsurf) — costo esperado

1. Copiar `tools/_template/` a `tools/windsurf/`.
2. Rellenar `capabilities.yaml` (~15 líneas, investigando qué soporta Windsurf hoy: instructions nativas, ¿tiene Cascades como concepto de agente? ¿tiene rules propias? ¿MCP? ¿hooks?).
3. Si algún mecanismo requiere un formato de archivo realmente distinto (no cubierto por los mecanismos genéricos ya soportados: `native`, `symlink`, `custom-mode`, `condensed`, `native-mdc`, `none`), agregar el adaptador puntual en `tools/windsurf/adapt/`. Si encaja en un mecanismo existente, **no se escribe código nuevo**, solo se declara.
4. `enable-repo.sh` y `install-global.sh` ya la reconocen automáticamente (recorren `tools/*/` en runtime) — no requieren editarse.

No se rearma `registry/`, no se tocan otras tools, no hay migración de contenido. Este es el costo bajo que pide el requisito 1.

---

## 6. Presupuesto de contexto/tokens por tool

Se extiende `docs/context-budget.md` (ya existente) con una tabla de **tiers de render**, que es lo que realmente controla cuánto contenido "siempre cargado" recibe cada tool:

| Tier | Tools (hoy) | Qué se carga siempre | Qué se carga bajo demanda | Presupuesto ambient |
|------|-------------|----------------------|----------------------------|----------------------|
| **A** | Claude Code | `AGENTS.md` (~100 tokens) + rules por path-match (~200) | Agente completo solo si se invoca; skill completa solo si se auto-descubre | ~300 tokens ambient — el resto es progressive disclosure real |
| **B** | Cursor | `AGENTS.md` nativo + rules por glob-match (`.mdc`) | Custom Mode completo solo si el usuario lo activa; skill completa solo si se referencia explícitamente | ~300-400 tokens ambient — similar a A, pierde el auto-discovery de skills pero no el path-scoping de rules |
| **C** | Copilot (hoy) | Todo el `copilot-instructions.md` — no hay carga condicional | Nada — todo lo que no está inline no existe para la tool | `max_instructions_lines` en `capabilities.yaml` (ej. 300) fuerza a `condense.mjs` a recortar: roster de agentes → nombre + 1 frase; skills → nombre + 1 frase; rules → resumen de convenciones por área en vez de archivos separados |

Regla de `condense.mjs` para tier C (determinística, no depende de que un LLM resuma — evita variabilidad):

1. Ordenar por `tier: core` antes que `extended` (frontmatter ya definido en agentes/skills).
2. Por cada item: `nombre` + primera oración de `description` + (si es agente) las bullets de `## Essence`.
3. Si el total supera `max_instructions_lines`, recortar primero los `extended`, dejando un ítem-resumen ("también disponibles: X, Y — ver `registry/agents/`").
4. Nunca omitir las reglas críticas (`YOU MUST`) — esas tienen prioridad fija sobre roster/skills al recortar.

Esto responde directamente al requisito 5: ninguna tool recibe el contenido completo de las 12 skills + 12 agentes si no puede aprovecharlo vía carga condicional — la única que sí lo recibe completo es la que realmente lo carga bajo demanda (A y, en su mayoría, B).

---

## 7. Qué se descarta explícitamente (y por qué)

Aprendiendo de `docs/RESTRUCTURE-2026-06.md`:

| Se descarta | Por qué |
|---|---|
| Comitear un árbol generado por tool dentro de este repo (`tools/cursor/global/agents/`, `tools/cursor/per-repo/rules/*.mdc`, etc.) | Es la causa raíz del riesgo de drift detectado la vez pasada. Se genera solo en destino, en cada `enable-repo.sh`. |
| CI de "drift-check" (`generate:cursor:check`) | Innecesario si no hay artefacto comiteado que comparar — se elimina la clase de bug en vez de monitorearla. |
| `package.json` raíz + dependencias como `gray-matter` solo para parsear frontmatter | Sobre-ingeniería para archivos de <100 líneas; `grep`/`sed`/`awk` o regex simple en Node sin deps alcanza, como ya se demostró con `generate_cursor_rule()`. |
| Portar los 12 subagentes tal cual a `~/.cursor/agents/` asumiendo equivalencia 1:1 con Claude Code | Cursor no tiene orquestación automática ni contexto aislado por agente — forzar esa analogía finge una paridad que no existe. Se usa Custom Modes (tier B) en su lugar, con la diferencia documentada. |
| Crear carpetas `tools/<tool>/` vacías "por simetría" antes de tener contenido real | Mismo argumento ya usado para no crear `tools/cursor/` vacío la vez pasada — se aplica ahora como regla general para cualquier tool futura: se crea cuando hay `capabilities.yaml` + `enable.sh` reales. |
| Asumir que faltan artefactos sin verificar el filesystem primero | El plan de Cursor original afirmó erróneamente que faltaban `block-secrets.sh` y `dependency-and-secrets-audit/SKILL.md` cuando ya existían — cualquier fase de este plan que toque esos archivos debe primero confirmar su estado real en disco antes de "arreglarlos". |
| Asumir que `install-global.sh` es simétrico entre tools ("agentes y skills a `~/.claude/`, `~/.cursor/`, etc.") sin verificar cada tool | Cursor no tiene directorio global de agentes (Custom Modes viven en `.cursor/modes.json` por repo) ni de skills (siempre project-scoped) — confirmado contra la documentación oficial de Cursor, no asumido. El campo `global_scope` (`supported`/`unsupported`/`manual-only`) en `capabilities.yaml` reemplaza la suposición por una declaración verificada (sección 5.3). |
| Reescribir `plan.md` original | Se mantiene como registro histórico con su nota de "superseded", igual que ya se decidió. |

---

## 8. Plan de migración por fases (sin romper lo que funciona)

Cada fase deja el repo en estado funcional y verificable — el pipeline Claude-only actual **no se degrada en ningún punto intermedio**.

### Fase 1 — Reorganizar a `registry/` (mover, no reescribir)
**Estado: ✅ Hecho** (commit `25476d0`, más `tier: core|extended` agregado después en el commit `f049a32` de la Fase 4 — el frontmatter de tiers estaba especificado aquí pero se implementó junto con `condense.mjs`, su primer consumidor real).
- Mover `global/agents/` → `registry/agents/` (agregar `## Essence` a cada uno — único contenido nuevo).
- Mover `global/skills/` → `registry/skills/` (sin cambios de contenido).
- Mover las partes tool-agnósticas de `per-repo/` (`scripts/`, `.husky/`, `.github/workflows/`, `AGENTS.md`, `.mcp.json`, `setup-portability.sh`) → `registry/templates/` y `registry/scripts/`.
- Mover `per-repo/.claude/rules/*.md` → `registry/rules/` (una sola copia, ya no dos).
- Mover `per-repo/.claude/hooks/*` → `registry/hooks/` (mismo contenido, normalizar lectura de ambos esquemas de stdin).
- Actualizar `install.sh`/`setup-repo.sh` a las nuevas rutas — comportamiento idéntico al actual, cero cambio funcional.
- **Verificación:** correr el `setup-repo.sh` actualizado en un repo de prueba y confirmar que el resultado es idéntico al de hoy.

### Fase 2 — Adaptador Claude explícito
**Estado: ✅ Hecho** (commit `1f271f9`).
- Crear `tools/claude/capabilities.yaml` (documenta lo que Claude Code ya hace hoy — no cambia comportamiento).
- Crear `tools/claude/enable.sh` como envoltorio delgado de la lógica que hoy vive en `install.sh`/`setup-repo.sh`.
- **Verificación:** `tools/claude/enable.sh` produce exactamente el mismo árbol que `setup-repo.sh` hoy.

### Fase 3 — Adaptador Cursor con tiers reales
**Estado: ✅ Hecho** (commit `1f271f9`). Verificado end-to-end en repo de prueba: `.cursor/rules/*.mdc` byte a byte idéntico al `.md` fuente (frontmatter + body), sin overlap de `globs` entre dominios (`src/api/**` no matchea `frontend`).
- Crear `tools/cursor/capabilities.yaml` (agents: custom-mode, rules: native-mdc, skills: reference, hooks: none, mcp: native).
- Crear `tools/cursor/adapt/rule-to-mdc.sh` (generaliza la función bash ya validada en el intento anterior — sin nuevas dependencias).
- Crear `tools/cursor/adapt/agent-to-mode.sh` (agente canónico completo → Custom Mode de Cursor, un archivo por agente).
- **Verificación:** habilitar un repo de prueba solo con `--tools cursor` y confirmar que `.cursor/rules/*.mdc` coincide byte a byte con el `.md` fuente (mismo criterio de verificación que ya se usó en `docs/RESTRUCTURE-2026-06.md`), y que los 12 Custom Modes existen con contenido completo.

### Fase 4 — Motor de condensación + primer tool tier C (Copilot)
**Estado: ✅ Hecho** (commits `f049a32` tier frontmatter, `aef123b` motor + adaptador). Verificado end-to-end en repo de prueba: salida real de 119 líneas para el `registry/` de este repo (bajo el presupuesto de 200, sin necesidad de recorte), los 12 nombres de agentes y 11 de skills presentes, las 4 reglas críticas de `registry/templates/AGENTS.md` copiadas byte a byte, y degradación correcta del cascade de recorte probada con un presupuesto artificial de 40 líneas (colapsa a resumen pero nunca omite un nombre).
- Implementar `lib/condense.mjs` con el algoritmo determinístico de la sección 6.
- Crear `tools/copilot/capabilities.yaml` (agents: condensed, skills: condensed, rules: condensed, hooks: none, mcp: partial).
- **Verificación:** `copilot-instructions.md` generado respeta `max_instructions_lines`, incluye el roster de 12 agentes condensado y no omite ninguna regla `YOU MUST`.

### Fase 5 — Generalizar `enable-repo.sh` / `install-global.sh`
**Estado: ⬜ Pendiente.**
- Reemplazar cualquier lógica hardcodeada por tool con un loop genérico sobre `tools/*/capabilities.yaml`.
- Agregar `tools/_template/` con instrucciones inline de cómo agregar una tool nueva.
- **Prueba de extensibilidad:** agregar una tool más (real o simulada, ej. Gemini CLI) usando solo el template, sin tocar `registry/`, `lib/`, ni otros adaptadores, para validar el costo bajo prometido en el requisito 1.

### Fase 6 — Documentación y cierre
**Estado: ⬜ Pendiente.**
- Regenerar `docs/tool-compatibility.md` para que sea 1:1 con `tools/*/capabilities.yaml` (evita que vuelva a divergir de la realidad, como pasó con el `.mdc` vs `.md`).
- Extender `docs/context-budget.md` con la tabla de tiers (sección 6).
- Actualizar `README.md`/`USAGE.md` con la nueva estructura y el comando único `enable-repo.sh`.
- Marcar `plan.md` original y `docs/RESTRUCTURE-2026-06.md` como contexto histórico, enlazados desde este documento (ya lo están).

---

## 9. Checklist de verificación final

- [x] `registry/` es la única fuente de conocimiento — cero contenido duplicado entre agentes/skills/rules/hooks. (Se encontró y corrigió una duplicación puntual en `registry/templates/AGENTS.md` vs `registry/rules/{frontend,backend}.md` — commit `6b5b847`.)
- [x] Ningún artefacto generado por tool está comiteado en este repo — todo se genera en destino vía `enable-repo.sh`/`install-global.sh`. (Verificado: no hay `.mdc` ni `copilot-instructions.md` trackeados en git; solo `capabilities.yaml`/`enable.sh`/adaptadores, que son código, no salida generada.)
- [x] Los 12 agentes tienen `## Essence` y existen en las tres formas (verbatim, custom-mode, condensado) según la tool habilitada. (Verbatim: `tools/claude/enable.sh`. Custom-mode: `tools/cursor/adapt/agent-to-mode.sh`. Condensado: `lib/condense.mjs` vía `tools/copilot/enable.sh`.)
- [ ] `docs/tool-compatibility.md` se deriva de `tools/*/capabilities.yaml`, no se mantiene a mano. (Fase 6.)
- [ ] Agregar una tool nueva no requiere tocar `registry/`, `lib/`, ni otros adaptadores — solo `tools/<nueva>/`. (Fase 5 — `enable-repo.sh` aún no generaliza el loop sobre `tools/*/capabilities.yaml`; hoy cada adaptador se invoca por separado.)
- [x] El pipeline Claude-only actual sigue funcionando igual en cada fase (sin regresión). (Verificado en la Fase 3: `.claude/rules/*.md` generado por `setup-repo.sh` idéntico al de antes de la migración a `registry/`.)
- [ ] `docs/context-budget.md` documenta los 3 tiers y el criterio de recorte determinístico. (Fase 6.)
- [x] `plan.md` y `docs/RESTRUCTURE-2026-06.md` quedan como registro histórico, no se borran.
