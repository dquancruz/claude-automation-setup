# Skills — Guía de Portabilidad

Las skills están en formato `<nombre>/SKILL.md` con frontmatter estándar (Agent Skills).

## Estructura

```
global/skills/
├── auto-commit/SKILL.md
├── pr-formatter/SKILL.md
├── semantic-versioning/SKILL.md
├── iot-backend/SKILL.md
├── auto-pr/SKILL.md
├── jira-integration/SKILL.md
├── design-system/SKILL.md
├── immersive-3d/SKILL.md
├── threat-modeling/SKILL.md
├── secure-coding/SKILL.md
├── dependency-and-secrets-audit/SKILL.md
└── cloud-iac-security/SKILL.md
```

## Instalación (Claude Code)
```bash
./install.sh
# Copia global/skills/*/ → ~/.claude/skills/
```

## Portabilidad cross-tool

### Cursor
En el system prompt de Cursor, apuntar a `~/.claude/skills/`:
```
Refer to the skill files in ~/.claude/skills/ for domain-specific conventions.
```

### Gemini CLI
Las skills se referencian por nombre en el workflow de agentes documentado en `AGENTS.md` (symlinkeado como `GEMINI.md`).

### GitHub Copilot
Copiar el contenido relevante de la skill al `.github/copilot-instructions.md` para el contexto más crítico.

### Codex
Apuntar el system prompt a `~/.claude/skills/` como contexto adicional.
