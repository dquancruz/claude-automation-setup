# PLAN.md — Migración a un Setup Portable Multi-Herramienta

> **Para:** Claude Code
> **Repo:** `claude-automation-setup`
> **Objetivo:** Evolucionar el setup actual (11 agentes + 6 skills + scripts + hooks) hacia la arquitectura estándar 2026 — **sin perder portabilidad** entre Claude Code, Cursor, GitHub Copilot, Gemini CLI y Codex — y añadir dos capacidades nuevas: **diseño con presets** (Fase 9) y **seguridad / AppSec** (Fase 10). Los 11 agentes se **mantienen separados** (Fase 5), pasando a 12 con el de seguridad.

---

## 0. Contexto y principio rector

El setup actual es sólido en agentes/skills/scripts, pero le falta la capa de **contexto persistente** y está acoplado a Claude Code. La meta NO es atarse más a Claude Code, sino lo contrario: construir un setup tan portable que si mañana cambias (o trabajas en equipo con gente que usa Cursor o Copilot), todo viaje contigo.

**Principio rector:** `AGENTS.md` es el **Single Source of Truth (SSOT)**. Todos los demás archivos de instrucciones específicos de cada herramienta son **symlinks** que apuntan a él. Escribes las reglas una vez, las leen todas las herramientas.

### Ranking de portabilidad por capa (de más a menos portable)

| Capa | Estándar / formato | Portabilidad | Estrategia |
|------|--------------------|--------------|------------|
| Instrucciones | `AGENTS.md` | ✅ Universal | SSOT + symlinks |
| Skills | `SKILL.md` (Agent Skills) | ✅ Alta | Carpeta portable + frontmatter |
| MCP servers | `.mcp.json` | ✅ Alta | Schema estándar, env vars |
| Rules (path-scoped) | varía por tool | 🟡 Media | `.claude/rules/` + `.cursor/rules/` |
| Hooks | varía por tool | 🟠 Baja | Mantener específico de Claude |
| Subagentes | concepto de Claude Code | 🟠 Baja | Documentar workflow en AGENTS.md |

> Las capas portables (instrucciones, skills, MCP) llevan el 80% del valor y funcionan en todas las herramientas. Las no portables (hooks, subagentes) se mantienen específicas de Claude Code pero se documentan en AGENTS.md como "workflow esperado" para que otra herramienta pueda replicarlo a mano.

---

## 1. Estructura objetivo del repositorio

Al terminar el plan, la estructura `per-repo/` (lo que se copia dentro de cada proyecto) debe quedar así:

```
<proyecto>/
├── AGENTS.md                      # ⭐ SSOT — instrucciones del proyecto
├── CLAUDE.md                      # → symlink a AGENTS.md
├── GEMINI.md                      # → symlink a AGENTS.md
├── .github/
│   └── copilot-instructions.md    # → symlink a ../AGENTS.md
├── .mcp.json                      # MCP servers (Claude Code, schema estándar)
├── .cursor/
│   ├── mcp.json                   # → symlink a ../.mcp.json (mismo schema)
│   └── rules/                     # Rules en formato Cursor (.mdc)
├── .claude/
│   ├── rules/                     # Rules path-scoped (Claude Code)
│   │   ├── backend.md
│   │   ├── frontend.md
│   │   ├── testing.md
│   │   ├── design.md              # preset de diseño del cliente (Fase 9)
│   │   └── security.md            # reglas de seguridad path-scoped (Fase 10)
│   └── hooks/                     # Hooks específicos de Claude Code
│       ├── pre-tool-use/
│       └── post-tool-use/
├── .husky/                        # Git hooks (ya existe)
├── scripts/                       # Scripts de automatización (ya existe)
└── .env.local                     # Secretos (gitignored, ya existe)
```

Y la carpeta `global/` (lo que se instala a `~/.claude/`) se mantiene, pero las skills se actualizan al formato portable.

---

## 2. FASE 1 — Crear `AGENTS.md` como SSOT + symlinks cross-tool

**Esta es la fase más importante. Hace todo lo demás portable.**

### Tareas

- [ ] Crear `per-repo/AGENTS.md` con el template de abajo.
- [ ] Crear el script `per-repo/setup-portability.sh` que genere los symlinks.
- [ ] Mantenerlo **bajo ~150 líneas** (presupuesto de contexto; los modelos siguen ~150-200 instrucciones y el system prompt ya gasta ~50).

### Template: `per-repo/AGENTS.md`

```markdown
# <Nombre del Proyecto>

> Una línea: qué es este repo.

## Tech Stack
- Runtime: <Node.js 20 / Python 3.12>
- Framework: <Next.js 15 / FastAPI>
- Base de datos: <MongoDB / PostgreSQL>
- Testing: <Jest / pytest>
- Infra: <AWS + CDK>

## Comandos (invocaciones exactas)
- Build:  `npm run build`
- Test:   `npm test`        # preferir tests individuales: `npm test -- <archivo>`
- Lint:   `npm run lint`
- Deploy: `npm run deploy`
- Auto-commit: `npm run auto-commit -- --help`

## Arquitectura (apuntar a archivos, no describir en prosa)
- `src/api/`        → endpoints y lógica de backend
- `src/components/` → componentes de UI
- `scripts/`        → automatización (commit, PR, release)
- Ver `docs/` para arquitectura detallada.

## Convenciones del proyecto
- <Server components por defecto; 'use client' solo cuando sea necesario>
- <Soft deletes en la tabla X — no borrar físicamente>
- Commits: Conventional Commits (ver skill semantic-versioning).

## Workflow de agentes (Claude Code)
Estos subagentes existen en `~/.claude/agents/`. En otras herramientas,
replicar el flujo manualmente:
- Arquitectura/diseño → `solutions-expert`
- Backend (API)       → `backend-expert`
- Frontend            → `frontend-expert`
- Infra (AWS/CDK)     → `infrastructure-expert`
- PRs                 → `pr-manager`
- Review + seguridad  → `code-reviewer`

Pipeline típico: solutions-expert → (backend|frontend) → code-reviewer → pr-manager.

## Reglas críticas (YOU MUST)
- NUNCA hacer push directo a `main`.
- NUNCA commitear `.env.local` ni secretos.
- SIEMPRE correr lint + tests antes de un PR.
- Scope acotado: no leer cientos de archivos; usar un subagente de investigación.
```

> **Por qué este formato:** lidera con comandos (la sección de mayor ROI), apunta a archivos en vez de describirlos, e incluye el "por qué" de las reglas no obvias. No duplica lo que ya hace el linter.

### Script: `per-repo/setup-portability.sh`

```bash
#!/usr/bin/env bash
# Genera los symlinks que apuntan al SSOT (AGENTS.md).
# Ejecutar desde la raíz del repo destino.
set -euo pipefail

[ -f AGENTS.md ] || { echo "❌ Falta AGENTS.md (el SSOT). Créalo primero."; exit 1; }

# Claude Code
ln -sf AGENTS.md CLAUDE.md
# Gemini CLI
ln -sf AGENTS.md GEMINI.md
# GitHub Copilot (busca en .github/)
mkdir -p .github
ln -sf ../AGENTS.md .github/copilot-instructions.md
# Cursor lee AGENTS.md de forma nativa — no requiere symlink de instrucciones.

echo "✅ Symlinks creados: CLAUDE.md, GEMINI.md, .github/copilot-instructions.md → AGENTS.md"
echo "ℹ️  Cursor y Codex leen AGENTS.md directamente."
```

### Verificación Fase 1
- [ ] `cat CLAUDE.md` muestra el contenido de AGENTS.md.
- [ ] `ls -la` muestra los symlinks (`->`) y no copias.
- [ ] Editar AGENTS.md → el cambio se refleja en todos los symlinks.

---

## 3. FASE 2 — MCP portable (`.mcp.json`)

Hoy los MCP (Jira, Git, GitHub) se configuran a mano en Claude. Centralizarlos en `.mcp.json` (schema estándar) los hace versionables y reutilizables por Cursor.

### Tareas
- [ ] Crear `per-repo/.mcp.json` (template abajo).
- [ ] Crear symlink `.cursor/mcp.json` → `../.mcp.json` (Cursor usa el mismo schema).
- [ ] Usar **interpolación de variables de entorno** para los secretos (nunca tokens en claro).
- [ ] Confirmar contra `docs/MCPS-configuracion-completa.md` los paquetes/URLs exactos.

### Template: `per-repo/.mcp.json`

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": { "GITHUB_TOKEN": "${GITHUB_TOKEN}" }
    },
    "git": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-git", "--repository", "."]
    },
    "jira": {
      "command": "npx",
      "args": ["-y", "<paquete-mcp-jira-de-tus-docs>"],
      "env": {
        "JIRA_URL": "${JIRA_URL}",
        "JIRA_TOKEN": "${JIRA_TOKEN}"
      }
    }
  }
}
```

### Symlink Cursor
```bash
mkdir -p .cursor
ln -sf ../.mcp.json .cursor/mcp.json
```

### Verificación Fase 2
- [ ] `.mcp.json` no contiene ningún secreto en claro (solo `${VAR}`).
- [ ] Las variables (`GITHUB_TOKEN`, `JIRA_URL`, etc.) están en `.env.example` y `.env.local`.
- [ ] Claude Code detecta los 3 MCP al iniciar en un repo de prueba.

---

## 4. FASE 3 — Skills portables (formato Agent Skills)

Las 6 skills actuales deben migrar al estándar `SKILL.md` con frontmatter para que: (a) Claude las auto-descubra vía progressive disclosure, y (b) Cursor/Codex/Gemini puedan leerlas apuntando a la carpeta.

### Tareas
- [ ] Para cada skill en `global/skills/`, crear estructura `<nombre>/SKILL.md`.
- [ ] Añadir frontmatter (`name`, `description`, `argument-hint`, `tools`) a cada una.
- [ ] La `description` debe ser específica — es lo que dispara la carga de la skill.
- [ ] (Opcional) Crear `global/skills/README.md` que documente cómo apuntar Cursor/Gemini a esta carpeta para portabilidad.

### Formato de cada `SKILL.md`

```markdown
---
name: auto-commit
description: Genera mensajes de commit semánticos (Conventional Commits). Usar
  cuando el usuario quiera commitear cambios o pida "auto-commit". Dispara con
  cambios staged listos para commit.
argument-hint: --message "feat: add auth" --scope api
tools: [git, bash]
---

# Auto-Commit Best Practices

1. Analizar `git diff --staged`.
2. Determinar tipo: feat | fix | chore | docs | refactor | test.
3. Generar mensaje en formato Conventional Commits.
4. ...
```

Mapeo de las 6 skills actuales:
- [ ] `iot-backend/SKILL.md` ← IoT Backend Best Practices
- [ ] `pr-formatter/SKILL.md` ← PR Description Formatter
- [ ] `semantic-versioning/SKILL.md` ← Semantic Versioning Control
- [ ] `auto-commit/SKILL.md` ← Auto-Commit Best Practices
- [ ] `auto-pr/SKILL.md` ← Auto-PR Creation Guide
- [ ] `jira-integration/SKILL.md` ← Jira Integration Patterns

### Verificación Fase 3
- [ ] Cada skill tiene frontmatter válido con `name` y `description`.
- [ ] Las descriptions son accionables (dicen *cuándo* usar la skill).
- [ ] `README.md` explica el comando para que Cursor/Gemini lean la carpeta.

---

## 5. FASE 4 — Rules con path scoping

Las rules se cargan **solo** cuando Claude trabaja en directorios que hacen match, manteniendo el contexto limpio. Replicar para Cursor con `.cursor/rules/*.mdc`.

### Tareas
- [ ] Crear `per-repo/.claude/rules/` con archivos por dominio + frontmatter `paths`.
- [ ] Crear el equivalente Cursor en `per-repo/.cursor/rules/` (formato `.mdc` con `globs`).

### Ejemplo Claude: `.claude/rules/backend.md`
```markdown
---
paths: ["src/api/**", "src/services/**"]
---
# Convenciones Backend
- Validar input con <Zod / Pydantic> en cada endpoint.
- Errores tipados, nunca `throw` genérico.
- ...
```

### Ejemplo Cursor: `.cursor/rules/backend.mdc`
```markdown
---
description: Convenciones de backend
globs: ["src/api/**", "src/services/**"]
alwaysApply: false
---
- Validar input con <Zod / Pydantic> en cada endpoint.
- ...
```

Crear al menos: `backend`, `frontend`, `testing`.

### Verificación Fase 4
- [ ] Editar un archivo en `src/api/` activa `backend` y NO `frontend`.
- [ ] El contenido de las rules NO duplica lo que ya está en AGENTS.md (evitar redundancia de contexto).

---

## 6. FASE 5 — Mantener los 11 agentes separados (+ árbol de decisión)

**Decisión tomada:** se conservan los 11 agentes como entidades **separadas**, para que puedan trabajar en paralelo en tareas distintas sin pisarse. **NO se consolidan.** Con el agente de seguridad (Fase 10), el set pasa a **12**.

El único riesgo de tener muchos agentes es de contexto (confusión sobre cuál usar). Se mitiga con un **árbol de decisión claro**, no fusionándolos.

### Tareas
- [ ] NO fusionar agentes. Mantener los 11 actuales tal cual.
- [ ] En `AGENTS.md`, escribir un árbol de decisión "cuándo usar cuál" que cubra los 12 agentes (los 11 + `security-expert`), para que la elección sea inequívoca.
- [ ] Para cada agente, declarar explícitamente en su frontmatter las `skills` y `tools` que puede usar (los subagentes **no heredan skills automáticamente**).
- [ ] Asegurar que cada agente tenga una `description` accionable (dice CUÁNDO invocarlo) — así Claude Code elige el correcto por sí solo.

### Árbol de decisión (plantilla para AGENTS.md)
```
¿Qué necesitas?
- Diseñar arquitectura / decidir el enfoque   → solutions-expert
- Generar jerarquía de tickets Jira           → ticket-orchestrator
- Backend API (NestJS/FastAPI/Mongo)          → backend-expert
- Backend IoT (Raspberry Pi/GPIO/edge)        → iot-backend-expert
- Frontend (React/Next/Astro + a11y)          → frontend-expert
- Arquitectura AWS                            → aws-architect
- Infra as Code (CDK)                         → cdk-expert
- Crear PR (formato TELUS)                    → pr-manager
- Review general + scanning ligero            → code-reviewer-pro
- Seguridad profunda (AppSec)                 → security-expert   [Fase 10]
- Docs + versionado + releases                → documentation-generator
- Orquestar varios de los anteriores          → agent-orchestrator
```

### Verificación Fase 5
- [ ] Los 12 agentes existen en `~/.claude/agents/` con `description` accionable.
- [ ] Cada agente declara sus `skills`/`tools` en frontmatter.
- [ ] El árbol de decisión en AGENTS.md cubre los 12 sin ambigüedad.

---

## 7. FASE 6 — Hooks de Claude Code (PreToolUse / PostToolUse)

Husky cubre git, pero faltan los hooks de Claude que actúan **antes** de escribir en disco. Estos son específicos de Claude Code (no portables), pero su intención se documenta en AGENTS.md.

### Tareas
- [ ] Crear `per-repo/.claude/hooks/pre-tool-use/block-secrets.sh` (bloquea escrituras que contengan patrones de secretos / `.env`).
- [ ] Crear `per-repo/.claude/hooks/post-tool-use/lint-after-write.sh` (corre linter tras editar y devuelve feedback no bloqueante).
- [ ] Registrar los hooks en `.claude/settings.json`.
- [ ] **No** bloquear escrituras a mitad de un plan multi-paso (rompe el razonamiento secuencial).

### Verificación Fase 6
- [ ] Un intento de escribir un token dispara el block-secret.
- [ ] Tras editar un archivo, el lint corre automáticamente.

---

## 8. FASE 7 — Documentar el presupuesto de contexto

### Tareas
- [ ] Crear `docs/context-budget.md` con la guía de manejo de contexto.

### Contenido sugerido
```markdown
# Manejo de Contexto

## Presupuesto por sesión (aprox.)
- AGENTS.md:        ~100 tokens (siempre cargado)
- Rules:            ~200 tokens (filtradas por path)
- Skills:           ~50 tokens c/u (bajo demanda)
- Definiciones MCP: ~500+ tokens
- Presupuesto útil: ~1.5-2k tokens antes de empezar a trabajar.

## Prácticas
- Una tarea por conversación. `/clear` entre tareas no relacionadas.
- Investigaciones >50 archivos → spawn de subagente, no en el contexto principal.
- Si el modelo se equivoca dos veces, `/clear` y reiniciar con mejor prompt.
- Nunca volcar el repo entero al contexto.
```

---

## 9. FASE 8 — Actualizar scripts de instalación

### Tareas
- [ ] `setup-repo.sh`: además de copiar scripts/hooks, debe:
  - Copiar `AGENTS.md` (template), `.mcp.json`, `.claude/rules/`, `.claude/hooks/`, `.cursor/rules/`.
  - Ejecutar `setup-portability.sh` para generar los symlinks.
  - Crear symlink `.cursor/mcp.json` → `../.mcp.json`.
  - Añadir `.env.local` al `.gitignore` (ya lo hace) y verificar que los symlinks no rompan nada.
- [ ] `install.sh`: añadir en el output una nota sobre cómo apuntar Cursor/Gemini/Codex a `~/.claude/skills/` para reutilizar las skills.
- [ ] Actualizar `README.md` del repo con la nueva arquitectura portable y la tabla de "qué es portable vs tool-specific".

### Verificación Fase 8
- [ ] Correr `setup-repo.sh` en un repo limpio deja la estructura completa de la sección 1.
- [ ] Todos los symlinks resuelven correctamente.

---

## 10. FASE 9 — Skills de diseño (presets + 3D)

Añade la capacidad de diseño: un **registro de presets** invocables por palabra-clave y una skill de **3D**, más la dirección de diseño en el `frontend-expert`. Contenido base ya redactado en los archivos `design-system-SKILL.md` e `immersive-3d-SKILL.md` (usar como punto de partida; ajustar al gusto).

### Tareas
- [ ] Crear `global/skills/design-system/SKILL.md` — registro de presets. Debe contener: (a) cómo se invoca un preset (en el prompt, o vía `Design preset:` en las rules del repo), (b) principios universales + anti-patrones + quality floor, (c) los presets `velocity`, `vice`, `quiet` con sus tokens (color/tipo/escala/motion/signature), (d) el encuadre **"los presets son punto de partida, no ley"** — adaptable: hex/fuentes/escalas; firme: anti-patrones + accesibilidad.
- [ ] Crear `global/skills/immersive-3d/SKILL.md` — técnica 3D/WebGL. Debe cubrir: 3D por preset (`velocity` = objeto real-time + scroll-camera; `vice` = atmósfera cinematográfica con video + WebGL ambiente; `quiet` = sin 3D), el **caveat de assets** (el agent integra modelos, NO los genera; alternativa procedural por código), stack (R3F + drei + three + Lenis/GSAP + postprocessing; **Rive** como 2.5D ligero), presupuesto de performance y fallbacks (lazy-load del canvas, degradar en mobile, respetar `reduced-motion`).
- [ ] Editar `global/agents/frontend-expert.md`: añadir el bloque **"Dirección de diseño"** — filosofía (hero como tesis, tipografía con personalidad, gastar la audacia en el signature) + **lógica de selección de preset** (1: el nombrado en el prompt; 2: `Design preset:` en rules/AGENTS.md; 3: default `quiet` y avisar) + cargar SIEMPRE `design-system` (y `immersive-3d` si hay 3D) antes de codear.
- [ ] Añadir el override por proyecto: en `per-repo/.claude/rules/` crear `design.md` con la línea `Design preset: <keyword>` + los tokens reales del cliente; equivalente Cursor en `.cursor/rules/design.mdc`.

### Verificación Fase 9
- [ ] El `frontend-expert` carga `design-system` al hacer UI y respeta el preset activo.
- [ ] Decir "usa el preset `vice`" cambia los tokens; declararlo en rules lo fija para todo el repo.
- [ ] Las skills tienen frontmatter válido y son legibles por Cursor/Codex/Gemini.

---

## 11. FASE 10 — Capa de seguridad (AppSec)

Hoy **no hay nada enfocado en seguridad**. Se añade un agente especialista profundo en AppSec + sus skills. Contenido base del agente ya redactado en `security-expert-agent.md` (usar como punto de partida).

> **Relación con `code-reviewer-pro`:** ese agente ya hace review general con scanning ligero. `security-expert` es el escalamiento **profundo**: se invoca cuando un cambio toca **auth, datos sensibles, criptografía, secretos, superficie de red o IaC**. Documentar este límite en AGENTS.md para que no se solapen.

### Tareas
- [ ] Crear `global/agents/security-expert.md` (agente). Frontmatter con `model`, `description` accionable y las `skills` listadas (los subagentes **no heredan skills**). Debe definir: modos de operación (threat model / review / auditoría deps / review cloud), **formato fijo de hallazgos** (severidad + qué + dónde + impacto + fix concreto), y reglas YOU MUST (nunca debilitar seguridad, menor privilegio, defensa en profundidad, **rol defensivo** — sin generar exploits).
- [ ] Crear las 4 skills en `global/skills/`:
  - [ ] `threat-modeling/SKILL.md` — STRIDE, límites de confianza, flujo de datos, superficie de ataque, abuse cases. Se corre en **diseño** (con `solutions-expert`). Salida: modelo de amenazas con riesgos rankeados + mitigaciones. Notas para API, frontend, IoT/edge y cloud.
  - [ ] `secure-coding/SKILL.md` — OWASP Top 10 mapeado al stack: validación de input (Zod/Pydantic), inyección (**incl. NoSQL/Mongo**), XSS/encoding, CSRF, SSRF, auth (errores comunes de JWT, hashing **argon2id/bcrypt**, sesiones), authz (RBAC, **IDOR**), secretos en código, cripto (no inventar la propia), errores seguros (no filtrar stack traces al cliente), security headers (CSP/HSTS), rate limiting. Notas por framework: **NestJS** (guards/pipes/`ValidationPipe`), **FastAPI** (Pydantic, dependencies), **Next.js** (exposición `NEXT_PUBLIC_`, server actions, route handlers).
  - [ ] `dependency-and-secrets-audit/SKILL.md` — SCA (`npm/pnpm audit`, `pip-audit`, `osv-scanner`), escaneo de secretos (gitleaks/trufflehog), SBOM (syft/cyclonedx), chequeo de licencias, pinning + lockfiles, Dependabot/Renovate, integración en CI.
  - [ ] `cloud-iac-security/SKILL.md` — IAM de **menor privilegio** (sin wildcards), cifrado en reposo (S3/RDS/EBS) y en tránsito (TLS), nada de S3 público ni security groups `0.0.0.0/0`, secretos en **Secrets Manager/SSM** (no en env), segmentación VPC, logging CloudTrail, **`cdk-nag`** para chequeos automáticos, roles Lambda de menor privilegio. Pareja con `aws-architect`/`cdk-expert`.
- [ ] Añadir `security-expert` al árbol de decisión de agentes en AGENTS.md (Fase 5).
- [ ] Crear `per-repo/.claude/rules/security.md` con `paths` a zonas sensibles (`src/api/**`, `src/auth/**`, `infra/**`) recordando las reglas críticas de seguridad.
- [ ] Aprovechar el hook `block-secrets` (Fase 6) como refuerzo en disco.

### Verificación Fase 10
- [ ] `security-expert` existe con sus 4 skills declaradas en frontmatter.
- [ ] Pedir un "security review" produce hallazgos con **severidad + fix concreto**.
- [ ] AGENTS.md deja claro cuándo usar `code-reviewer-pro` vs `security-expert`.
- [ ] Las 4 skills son legibles por Cursor/Codex/Gemini (portables).

---

## 12. Checklist de verificación final

- [ ] Existe `AGENTS.md` y `CLAUDE.md`/`GEMINI.md`/`copilot-instructions.md` son symlinks a él.
- [ ] AGENTS.md está bajo ~150 líneas, lidera con comandos, apunta a archivos.
- [ ] `.mcp.json` existe, sin secretos en claro, con `.cursor/mcp.json` symlinkeado.
- [ ] Las 6 skills migradas + `design-system` + `immersive-3d` + las 4 de seguridad tienen frontmatter `name`/`description` válido.
- [ ] Hay rules path-scoped para Claude (`.claude/rules/`) y Cursor (`.cursor/rules/`), incluyendo `design.md` y `security.md`.
- [ ] Los **12 agentes** (11 + `security-expert`) están separados, con árbol de decisión en AGENTS.md y `skills`/`tools` declaradas en frontmatter.
- [ ] El `frontend-expert` carga `design-system` y respeta el preset activo (`velocity`/`vice`/`quiet`).
- [ ] `security-expert` existe con sus 4 skills; AGENTS.md define el límite con `code-reviewer-pro`.
- [ ] Hooks PreToolUse/PostToolUse registrados en `.claude/settings.json`.
- [ ] `docs/context-budget.md` existe.
- [ ] Scripts de instalación actualizados y probados en un repo limpio.
- [ ] `README.md` documenta la arquitectura portable.

---

## 13. Resumen: qué es portable vs específico de cada herramienta

| Elemento | Archivo | Claude Code | Cursor | Copilot | Gemini CLI | Codex |
|----------|---------|:-----------:|:------:|:-------:|:----------:|:-----:|
| Instrucciones | `AGENTS.md` | ✅ (symlink) | ✅ nativo | ✅ (symlink) | ✅ (symlink) | ✅ nativo |
| Skills | `SKILL.md` | ✅ | ✅ apuntando | 🟡 | ✅ apuntando | ✅ |
| MCP | `.mcp.json` | ✅ | ✅ (`.cursor/mcp.json`) | 🟡 | 🟡 | 🟡 |
| Rules | `.claude/rules` + `.cursor/rules` | ✅ | ✅ (`.mdc`) | 🟡 | 🟡 | 🟡 |
| Hooks | `.claude/hooks` | ✅ | ❌ | ❌ | ❌ | ❌ |
| Subagentes | `~/.claude/agents` | ✅ | ❌ (concepto distinto) | ❌ | ❌ | ❌ |

**Regla práctica:** lo que viaja en el repo (AGENTS.md, .mcp.json, skills, rules) hace que **cualquier compañero de equipo con cualquier herramienta** sea productivo al clonar. Lo específico de Claude Code (hooks, subagentes) se documenta como "workflow esperado" en AGENTS.md para que sea replicable a mano.

---

## Orden de ejecución recomendado

Por impacto/leverage:

1. **Fase 1** (AGENTS.md + symlinks) — desbloquea todo lo demás.
2. **Fase 2** (.mcp.json) — elimina configuración manual repetida.
3. **Fase 3** (skills portables) — auto-discovery + cross-tool.
4. **Fase 5** (árbol de decisión de los 12 agentes) — claridad sin fusionar.
5. **Fase 10** (capa de seguridad) — el hueco más crítico hoy; agente + skills AppSec.
6. **Fase 9** (skills de diseño) — presets + 3D para el `frontend-expert`.
7. **Fase 4** (rules) — eficiencia de contexto, incluye `design.md` y `security.md`.
8. **Fase 6, 7, 8** (hooks, docs, scripts) — refinamiento y empaquetado.

> Tratar cada archivo de config como código: versionarlo, revisarlo en PR, y verificar en una sesión limpia que el comportamiento del agente realmente cambia antes de hacer merge.