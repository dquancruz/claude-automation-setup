# 🚀 SETUP COMPLETO: NIVEL 3 AUTOMATIZACIÓN TOTAL

---

## 📋 RESUMEN DE ARCHIVOS A INSTALAR

```
SKILLS (6 archivos .md) → ~/.claude/skills/
SCRIPTS (4 archivos .js) → repo/scripts/
AGENTES (5 archivos .md) → ~/.claude/agents/
MCPs (configuración) → claude_desktop_config.json
HOOKS (4 scripts) → .husky/
CONFIGURACIÓN (3 archivos) → repo root
```

---

## 🔧 INSTALACIÓN PASO A PASO

### FASE 1: SKILLS (10 minutos)

```bash
# 1. Copiar skills a ~/.claude/skills/
cp 01-IoT-Backend-Best-Practices.md ~/.claude/skills/
cp 02-PR-Description-Formatter.md ~/.claude/skills/
cp 03-Semantic-Versioning-Control.md ~/.claude/skills/
cp 04-Auto-Commit-Best-Practices.md ~/.claude/skills/
cp 05-Auto-PR-Creation-Guide.md ~/.claude/skills/
cp 06-Jira-Integration-Patterns.md ~/.claude/skills/

# 2. Verificar
ls -la ~/.claude/skills/
# Deberías ver 6 archivos .md
```

---

### FASE 2: AGENTES (15 minutos)

```bash
# 1. Renombrar y copiar
cp AGENTE-1-agent-orchestrator.md ~/.claude/agents/agent-orchestrator.md
# (Los otros 4 están en AGENTES-2-5-modificados.md, crear archivos individuales)

# Para los otros 4 agentes:
# - Extraer código de AGENTES-2-5-modificados.md
# - Crear archivos individuales:
#   ~/.claude/agents/backend-expert.md (MODIFICADO)
#   ~/.claude/agents/frontend-expert.md (MODIFICADO)
#   ~/.claude/agents/pr-manager.md (MODIFICADO)
#   ~/.claude/agents/documentation-generator.md (MODIFICADO)

# 2. Verificar
ls -la ~/.claude/agents/
# Deberías ver: agent-orchestrator.md + 4 más (si ya existían)
```

---

### FASE 3: SCRIPTS (15 minutos)

```bash
cd ~/mi-repo

# 1. Renombrar scripts
# (En outputs, los archivos tienen prefijo "scripts-" para evitar conflictos)
cp ~/outputs/scripts-auto-commit.js scripts/auto-commit.js
cp ~/outputs/scripts-auto-pr.js scripts/auto-pr.js
cp ~/outputs/scripts-auto-jira.js scripts/auto-jira.js
cp ~/outputs/scripts-dashboard.js scripts/dashboard.js

# 2. Dar permisos
chmod +x scripts/*.js

# 3. Instalar dependencia
npm install --save-dev minimist

# 4. Agregar scripts a package.json
# Editar package.json y agregar:
cat >> package.json << 'EOF'
{
  "scripts": {
    "auto-commit": "node scripts/auto-commit.js",
    "auto-pr": "node scripts/auto-pr.js",
    "auto-jira": "node scripts/auto-jira.js",
    "dashboard": "node scripts/dashboard.js"
  }
}
EOF

# 5. Verificar
ls -la scripts/
npm run auto-commit -- --help
```

---

### FASE 4: CONFIGURACIÓN (20 minutos)

```bash
cd ~/mi-repo

# 1. Crear .env.local (NUNCA COMMITTER)
cat > .env.local << 'EOF'
# Jira
JIRA_HOST=yourcompany.atlassian.net
JIRA_EMAIL=your-email@company.com
JIRA_API_TOKEN=<paste from https://id.atlassian.com/manage-profile/security/api-tokens>
JIRA_PROJECT_KEY=PROJ

# GitHub
GITHUB_TOKEN=ghp_<paste from https://github.com/settings/tokens>
GITHUB_OWNER=your-org
GITHUB_REPO=your-repo

# Git
GIT_AUTHOR_NAME=Your Name
GIT_AUTHOR_EMAIL=your-email@company.com
GPG_KEY_ID=<optional, get from gpg --list-keys>
EOF

# 2. Agregar .env.local a .gitignore
echo ".env.local" >> .gitignore
echo ".env.*.local" >> .gitignore

# 3. Verificar
ls -la .env.local
grep ".env.local" .gitignore
```

---

### FASE 5: MCPs (25 minutos)

#### 5A. MCP Jira

```bash
# Opción A: Si está disponible en npm (recomendado)
npm install -g @atlassian/mcp-server-jira

# Opción B: Si no, crear custom (ver MCPS-configuracion-completa.md)
# mkdir -p ~/.claude/mcp-servers/jira-mcp
# cd ~/.claude/mcp-servers/jira-mcp
# npm init -y
# npm install @modelcontextprotocol/sdk
# (Copiar código del archivo)
```

#### 5B. MCP Git

```bash
# Crear custom Git MCP
mkdir -p ~/.claude/mcp-servers/git-mcp
cd ~/.claude/mcp-servers/git-mcp

# Inicializar
npm init -y
npm install @modelcontextprotocol/sdk

# Copiar código de MCPS-configuracion-completa.md
# (El archivo index.js completo)

# Verificar
ls -la index.js
```

#### 5C. MCP GitHub

```bash
# Instalar oficial
npm install -g @modelcontextprotocol/server-github@latest

# Verificar
which mcp-github
# O si está en local:
npm list @modelcontextprotocol/server-github
```

#### 5D. Configurar claude_desktop_config.json

```bash
# Ubicación correcta según SO:
# Windows: %USERPROFILE%/AppData/Local/Claude/claude_desktop_config.json
# Mac: ~/Library/Application Support/Claude/claude_desktop_config.json
# Linux: ~/.config/Claude/claude_desktop_config.json

# Copiar el contenido de MCPS-configuracion-completa.md (sección "Completo")
# Actualizar paths a:
# - /path/to/jira-mcp/index.js
# - /path/to/git-mcp/index.js

# Verificar JSON válido
cat claude_desktop_config.json | jq .
```

---

### FASE 6: HOOKS (20 minutos)

```bash
cd ~/mi-repo

# 1. Instalar Husky
npm install husky --save-dev

# 2. Inicializar
npx husky install

# 3. Crear hooks
# Copiar código de HOOKS-husky-complete.md

cat > .husky/pre-commit << 'EOF'
#!/bin/sh
# (Copiar contenido completo de HOOKS-husky-complete.md)
EOF

cat > .husky/prepare-commit-msg << 'EOF'
#!/bin/sh
# (Copiar contenido)
EOF

cat > .husky/post-merge << 'EOF'
#!/bin/sh
# (Copiar contenido)
EOF

cat > .husky/pre-tag << 'EOF'
#!/bin/sh
# (Copiar contenido)
EOF

# 4. Dar permisos
chmod +x .husky/*

# 5. Agregar "prepare" script a package.json
# En la sección "scripts", agregar:
# "prepare": "husky install"

# 6. Verificar
ls -la .husky/
npx husky list
```

---

## ✅ VERIFICACIÓN DE INSTALACIÓN

### Paso 1: Verificar Skills

```bash
ls -la ~/.claude/skills/
# Deberías ver 6 archivos .md

# Verificar que agent-orchestrator pueda leerlas
# (cuando uses Claude Code, debería mostrar available skills)
```

### Paso 2: Verificar Agentes

```bash
ls -la ~/.claude/agents/
# Deberías ver: agent-orchestrator.md + otros

# Verificar contenido
grep "auto-commit" ~/.claude/agents/agent-orchestrator.md
# Debería encontrar referencias a scripts
```

### Paso 3: Verificar Scripts

```bash
cd ~/mi-repo

# Test auto-commit
npm run auto-commit -- --help
# Debería mostrar: "Auto-Commit Script"

# Test auto-pr
npm run auto-pr -- --help
# Debería mostrar: "Auto-PR Script"

# Test auto-jira
npm run auto-jira -- --help
# Debería mostrar: "Auto-Jira Script"

# Test dashboard
npm run dashboard -- --help
# Debería mostrar: "Dashboard Script"
```

### Paso 4: Verificar Configuración

```bash
cd ~/mi-repo

# Verificar .env.local
[ -f .env.local ] && echo "✅ .env.local existe" || echo "❌ .env.local no existe"

# Verificar variables
grep JIRA_HOST .env.local
grep GITHUB_TOKEN .env.local
grep GIT_AUTHOR_NAME .env.local

# Verificar .gitignore
grep ".env.local" .gitignore
```

### Paso 5: Verificar MCPs

```bash
# Verificar Jira MCP
which jira-mcp 2>/dev/null || echo "Jira MCP no en PATH (OK si es custom)"

# Verificar Git MCP
ls -la ~/.claude/mcp-servers/git-mcp/index.js

# Verificar GitHub MCP
npm list @modelcontextprotocol/server-github -g

# Verificar claude_desktop_config.json
cat claude_desktop_config.json | jq .mcpServers
# Debería mostrar jira, git, github, filesystem
```

### Paso 6: Verificar Hooks

```bash
cd ~/mi-repo

# Verificar husky instalado
npm list husky

# Verificar hooks creados
ls -la .husky/
# Deberías ver: _, pre-commit, prepare-commit-msg, post-merge, pre-tag

# Verificar permisos
[ -x .husky/pre-commit ] && echo "✅ pre-commit ejecutable" || echo "❌ No ejecutable"

# Probar hook (sin hacer commit real)
.husky/pre-commit --dry-run || true
```

---

## 🧪 TESTE FINAL: FLUJO COMPLETO

```bash
cd ~/mi-repo

# 1. Crear rama de test
git checkout -b test/level3-automation

# 2. Hacer cambio
echo "// Test feature" > src/test-feature.ts

# 3. Intentar commit
git add src/test-feature.ts
git commit -m "feat(test): test level 3 automation"

# Debería ejecutarse:
# ✅ Pre-commit hook
#    - Tests running...
#    - Linter running...
#    - Type check...
#    - Secrets check...
# ✅ Prepare-commit-msg hook
#    - Auto-detect branch
#    - Auto-add Jira ref (si aplica)
# ✅ Commit creado con [JIRA-XXX] si rama lo tiene

# Verificar
git log -1 --oneline
# Debería mostrar: feat(test): test level 3 automation [JIRA-XXX]

# 4. Crear PR (prueba manual)
npm run auto-pr -- \
  --title "🧪 Test | Level 3 Automation" \
  --branch test/level3-automation \
  --labels "test"

# Debería mostrar:
# ✅ PR created: #XXX
# ✅ URL: https://github.com/...

# 5. Ver dashboard
npm run dashboard -- --watch

# Debería mostrar:
# 📊 Dashboard
# - Recent commits
# - PRs
# - Tests status
# - Coverage
```

---

## 📊 CHECKLIST FINAL

```markdown
## SKILLS
- [ ] 6 skills copiadas a ~/.claude/skills/
- [ ] Agent-orchestrator puede acceder a skills
- [ ] Cada skill es legible y bien formateada

## AGENTES
- [ ] 5 agentes en ~/.claude/agents/
- [ ] agent-orchestrator.md tiene auto-commit references
- [ ] backend-expert.md tiene auto-commit section
- [ ] frontend-expert.md tiene auto-commit section
- [ ] pr-manager.md tiene auto-pr section
- [ ] documentation-generator.md tiene versioning section

## SCRIPTS
- [ ] 4 scripts en repo/scripts/
- [ ] scripts tienen permisos ejecutables (chmod +x)
- [ ] minimist instalado (npm list minimist)
- [ ] npm scripts agregados a package.json
- [ ] Cada script responde a --help

## CONFIGURACIÓN
- [ ] .env.local creado con credenciales
- [ ] .env.local en .gitignore
- [ ] JIRA_HOST, EMAIL, TOKEN configurados
- [ ] GITHUB_TOKEN configurado
- [ ] GIT_AUTHOR_NAME, EMAIL configurados
- [ ] Variables verifiable en terminal

## MCPs
- [ ] Jira MCP instalado o custom creado
- [ ] Git MCP custom creado en ~/.claude/mcp-servers/git-mcp
- [ ] GitHub MCP instalado
- [ ] claude_desktop_config.json actualizado
- [ ] Todos los MCPs tienen correct paths
- [ ] JSON válido (jq validated)

## HOOKS
- [ ] Husky instalado (npm list husky)
- [ ] Husky inicializado (npx husky install)
- [ ] 4 hooks creados en .husky/
- [ ] Todos los hooks tienen permisos ejecutables
- [ ] "prepare" script en package.json
- [ ] Pre-commit hook ejecuta sin errores
- [ ] Prepare-commit-msg agrega Jira refs
- [ ] Post-merge hook corre sin errores
- [ ] Pre-tag hook valida formato

## TESTING
- [ ] npm run auto-commit -- --help funciona
- [ ] npm run auto-pr -- --help funciona
- [ ] npm run auto-jira -- --help funciona
- [ ] npm run dashboard -- --help funciona
- [ ] Test commit local (test/automation branch)
- [ ] Test pre-commit validations
- [ ] Test prepare-commit-msg auto-reference
- [ ] Test dashboard showing info

## FINAL
- [ ] Todo commiteado al repo (excepto .env.local)
- [ ] README actualizado con instrucciones
- [ ] Team notificado del nuevo setup
- [ ] Primeros features probados exitosamente
- [ ] Dashboard mostrando progreso
```

---

## 🎯 PRIMEROS PASOS PARA PROBAR

Una vez todo instalado:

```
OPCIÓN 1: Crear feature desde cero
└─ TÚ: @agent-orchestrator "Feature: Agregar X"
   └─ Automático: Jira epic → commits → PR → merge → release

OPCIÓN 2: Trabajar ticket existente
└─ TÚ: @agent-orchestrator "Trabaja PROJ-123"
   └─ Automático: Fetch ticket → implement → commit → PR → merge

OPCIÓN 3: Verificar feature implementada
└─ TÚ: @agent-orchestrator "¿Está hecho PROJ-123?"
   └─ Automático: Verifica acceptance criteria

OPCIÓN 4: Ver progreso en tiempo real
└─ npm run dashboard -- --epic PROJ-120 --watch
   └─ Dashboard mostrando todo en tiempo real
```

---

## 🆘 TROUBLESHOOTING RÁPIDO

| Problema | Solución |
|----------|----------|
| JIRA_TOKEN no funciona | Verificar en https://id.atlassian.com/manage-profile/security/api-tokens |
| GITHUB_TOKEN no funciona | Verificar token tiene scopes: repo, workflow, gist |
| Scripts no ejecutan | Verificar: chmod +x scripts/*.js |
| Hooks no se disparan | Verificar: npx husky list |
| MCPs no conectan | Verificar: paths en claude_desktop_config.json |
| Pre-commit bloquea | Revisar: tests, lint, types están OK |
| Auto-commit falla | Revisar: GIT_AUTHOR_NAME/EMAIL configurados |
| Auto-PR falla | Verificar: rama existe, no tiene conflictos con main |

---

**Última actualización:** 2026-06-04
**¡ESTÁS LISTO PARA EMPEZAR! 🚀**
