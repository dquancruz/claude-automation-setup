# Compatibilidad entre herramientas

Este repo está pensado para que **Claude Code, Cursor, GitHub Copilot, Antigravity y Codex** puedan trabajar sobre el mismo proyecto con el mismo contexto. Pero no todas las capas se "habilitan" igual en cada herramienta — este documento explica exactamente qué obtiene cada una al clonar el repo y correr `setup-repo.sh`.

**Regla general:** lo que vive en archivos estándar (instrucciones, MCP, skills, rules) es portable. Lo que es un *mecanismo interno* de Claude Code (hooks, subagentes) no tiene equivalente 1:1 en las demás — su conocimiento sí viaja (vía AGENTS.md/skills), pero el orquestador no.

---

## Tabla de compatibilidad

| Capa | Archivo | Cursor | Codex | Antigravity | GitHub Copilot | Claude Code |
|---|---|:---:|:---:|:---:|:---:|:---:|
| Instrucciones del proyecto | `AGENTS.md` | ✅ nativo | ✅ nativo | ✅ nativo | ✅ (symlink) | ✅ (symlink) |
| MCP servers | `.mcp.json` | ✅ nativo (`.cursor/mcp.json`) | ✅ nativo | ✅ nativo | 🟡 parcial | ✅ nativo |
| Skills (conocimiento) | `SKILL.md` | 🟡 si se referencian | 🟡 si se referencian | 🟡 si se referencian | ❌ | ✅ auto-discovery |
| Rules path-scoped | `.claude/rules` / `.cursor/rules` | ✅ (`.mdc`) | 🟡 vía AGENTS.md | 🟡 vía AGENTS.md | ❌ | ✅ nativo |
| Hooks (Pre/PostToolUse) | `.claude/hooks` | ❌ | ❌ | ❌ | ❌ | ✅ nativo |
| Git hooks (Husky) | `.husky/` | ✅ | ✅ | ✅ | ✅ | ✅ |
| Subagentes (los 12 especializados) | `~/.claude/agents` | ❌ concepto distinto | ❌ | ❌ propio sistema | ❌ | ✅ nativo |

✅ funciona igual · 🟡 funciona con fricción o requiere referenciarlo a mano · ❌ sin equivalente

---

## Qué significa esto en la práctica

### Si alguien clona el repo y abre **Cursor**
Lee `AGENTS.md` automáticamente (mismas convenciones, comandos, arquitectura). Conecta los mismos MCP servers vía `.cursor/mcp.json`. Sus `.cursor/rules/*.mdc` se activan por path igual que en Claude Code. Las skills (`design-system`, `secure-coding`, etc.) **no se auto-disparan** — hay que mencionarlas o que el modo activo de Cursor las referencie explícitamente. No tiene los 12 subagentes; el trabajo equivalente lo hace una sola sesión de Cursor leyendo el mismo contexto.

### Si alguien usa **Codex** o **Antigravity**
Mismo trato: instrucciones y MCP funcionan nativo. Rules y skills funcionan si la herramienta las lee como contexto adicional (vía AGENTS.md o referencia manual), pero sin la divulgación progresiva automática de Claude Code.

### Si alguien usa **GitHub Copilot**
El más limitado de los cinco: lee `copilot-instructions.md` (symlink a AGENTS.md), y MCP solo parcialmente según el cliente (VS Code vs otros). No tiene concepto de skills ni rules — todo lo que necesite debe estar resumido dentro de AGENTS.md.

### Lo único exclusivo de **Claude Code**
- **Hooks** `PreToolUse`/`PostToolUse` (ej. bloqueo de secretos antes de escribir a disco).
- **Los 12 subagentes** trabajando en paralelo con contexto aislado cada uno (`solutions-expert`, `backend-expert`, `security-expert`, etc.) y el auto-discovery de skills por divulgación progresiva.

Esto es intencional: Claude Code sigue siendo la herramienta "completa" del setup. Las demás obtienen el **contexto y conocimiento** del proyecto (que es el 80% del valor), pero no el **orquestador**.

---

## Implicación práctica para el equipo

- **Trabajo en paralelo / multi-agente real** → usar Claude Code.
- **Edición rápida con el mismo contexto del proyecto** → Cursor, Codex o Antigravity funcionan bien; el repo ya les da AGENTS.md + MCP + rules.
- **Copilot** → tratarlo como el caso mínimo; si una convención es crítica, debe estar en AGENTS.md explícitamente, no asumida desde una skill o un hook.
- Si una skill resulta crítica para que **cualquier** herramienta la siga (no solo Claude Code), considera promoverla a una sección corta dentro de `AGENTS.md` en vez de dejarla solo como skill — así no depende del auto-discovery.