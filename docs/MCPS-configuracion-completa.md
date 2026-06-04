# 🔌 MCPs: CONFIGURACIÓN COMPLETA

---

## 📋 MCPs REQUERIDOS

```
1. MCP Jira (oficial Atlassian) ✅
2. MCP Git (custom, basado en template Anthropic) ✅
3. MCP GitHub (official, mejorado) ✅
```

---

## 🔧 PASO 1: MCP JIRA (Oficial)

### Instalación

```bash
# Opción A: NPM
npm install -g @atlassian/mcp-server-jira

# Opción B: Si no está disponible en npm, crear custom
# (ver template abajo)
```

### Configuración: claude_desktop_config.json

**Ubicación:** `%USERPROFILE%/AppData/Local/Claude/claude_desktop_config.json` (Windows)
o `~/.claude/claude_desktop_config.json` (Mac/Linux)

```json
{
  "mcpServers": {
    "jira": {
      "command": "node",
      "args": ["/path/to/jira-mcp/index.js"],
      "env": {
        "JIRA_HOST": "yourcompany.atlassian.net",
        "JIRA_EMAIL": "your-email@company.com",
        "JIRA_API_TOKEN": "${JIRA_API_TOKEN}"
      }
    }
  }
}
```

### Variables de Ambiente

```bash
# En .env.local (será sourced antes de iniciar Claude)
export JIRA_HOST=yourcompany.atlassian.net
export JIRA_EMAIL=your-email@company.com
export JIRA_API_TOKEN=<token from https://id.atlassian.com>
```

### Capacidades (Tools)

MCP Jira debe soportar:

```
✅ create_issue - Crear issue
✅ update_issue - Actualizar issue
✅ get_issue - Obtener issue
✅ search_issues - Buscar issues
✅ create_epic - Crear epic
✅ create_story - Crear story
✅ create_task - Crear task
✅ transition_issue - Cambiar estado
✅ add_comment - Agregar comentario
✅ link_issues - Linkear issues
✅ get_issue_metadata - Metadatos
✅ get_transitions - Estados disponibles
```

---

## 🔧 PASO 2: MCP GIT (CUSTOM)

### Instalación

```bash
# Crear carpeta
mkdir -p ~/.claude/mcp-servers/git-mcp
cd ~/.claude/mcp-servers/git-mcp

# Inicializar
npm init -y
npm install @modelcontextprotocol/sdk
```

### Archivo: index.js

```javascript
#!/usr/bin/env node

/**
 * MCP Git Server
 * 
 * Proporciona herramientas para operaciones git automáticas
 * - create_commit
 * - push_branch
 * - create_branch
 * - get_status
 * - get_log
 * - checkout_branch
 */

const { Server } = require('@modelcontextprotocol/sdk/server');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/stdio');
const { execSync } = require('child_process');

const server = new Server({
  name: 'git-mcp',
  version: '1.0.0'
});

// ============================================================================
// TOOL HANDLERS
// ============================================================================

server.setRequestHandler('tools/call', async (request) => {
  const { name, arguments: args } = request;

  try {
    if (name === 'create_commit') {
      return await handle_create_commit(args);
    }
    if (name === 'push_branch') {
      return await handle_push_branch(args);
    }
    if (name === 'create_branch') {
      return await handle_create_branch(args);
    }
    if (name === 'get_status') {
      return await handle_get_status(args);
    }
    if (name === 'get_log') {
      return await handle_get_log(args);
    }
    if (name === 'checkout_branch') {
      return await handle_checkout_branch(args);
    }

    return { error: `Unknown tool: ${name}` };
  } catch (error) {
    return { error: error.message };
  }
});

async function handle_create_commit(args) {
  const { repo_path, message, files, author_name, author_email, sign } = args;

  try {
    const cwd = repo_path || process.cwd();
    
    // Stage files
    const file_args = Array.isArray(files) ? files.join(' ') : files;
    execSync(`git add ${file_args}`, { cwd, stdio: 'pipe' });

    // Build command
    let cmd = `git -c user.name="${author_name}" -c user.email="${author_email}"`;
    
    if (sign && process.env.GPG_KEY_ID) {
      cmd += ` -c user.signingkey="${process.env.GPG_KEY_ID}"`;
    }

    cmd += ` commit`;
    
    if (sign && process.env.GPG_KEY_ID) {
      cmd += ` -S`;
    }

    cmd += ` -m "${message.replace(/"/g, '\\"')}"`;

    // Execute
    execSync(cmd, { cwd, stdio: 'pipe' });

    // Get SHA
    const sha = execSync('git rev-parse HEAD', { 
      cwd, 
      encoding: 'utf-8' 
    }).trim();

    return {
      content: [{
        type: 'text',
        text: `✅ Committed: ${sha.slice(0, 7)}\nMessage: ${message}`
      }],
      success: true,
      sha
    };
  } catch (error) {
    return {
      content: [{ type: 'text', text: `❌ Error: ${error.message}` }],
      success: false,
      error: error.message
    };
  }
}

async function handle_push_branch(args) {
  const { repo_path, branch_name, force } = args;

  try {
    const cwd = repo_path || process.cwd();
    const force_arg = force ? '--force' : '';
    
    execSync(`git push origin ${branch_name} ${force_arg}`, { 
      cwd, 
      stdio: 'pipe' 
    });

    return {
      content: [{ 
        type: 'text', 
        text: `✅ Pushed: ${branch_name}` 
      }],
      success: true
    };
  } catch (error) {
    return {
      content: [{ type: 'text', text: `❌ Error: ${error.message}` }],
      success: false,
      error: error.message
    };
  }
}

async function handle_create_branch(args) {
  const { repo_path, branch_name } = args;

  try {
    const cwd = repo_path || process.cwd();
    execSync(`git checkout -b ${branch_name}`, { cwd, stdio: 'pipe' });

    return {
      content: [{ 
        type: 'text', 
        text: `✅ Created and checked out: ${branch_name}` 
      }],
      success: true,
      branch: branch_name
    };
  } catch (error) {
    return {
      content: [{ type: 'text', text: `❌ Error: ${error.message}` }],
      success: false,
      error: error.message
    };
  }
}

async function handle_get_status(args) {
  const { repo_path } = args;

  try {
    const cwd = repo_path || process.cwd();
    const status = execSync('git status --porcelain', { 
      cwd, 
      encoding: 'utf-8' 
    });

    const files = status.split('\n')
      .filter(Boolean)
      .map(line => ({
        status: line.slice(0, 2),
        file: line.slice(3)
      }));

    return {
      content: [{
        type: 'text',
        text: `Modified files: ${files.length}\n${JSON.stringify(files, null, 2)}`
      }],
      success: true,
      files
    };
  } catch (error) {
    return {
      content: [{ type: 'text', text: `❌ Error: ${error.message}` }],
      success: false,
      error: error.message
    };
  }
}

async function handle_get_log(args) {
  const { repo_path, count = 5, branch = 'HEAD' } = args;

  try {
    const cwd = repo_path || process.cwd();
    const log = execSync(`git log ${branch} --oneline -${count}`, { 
      cwd, 
      encoding: 'utf-8' 
    });

    const commits = log.split('\n')
      .filter(Boolean)
      .map(line => {
        const [sha, ...message] = line.split(' ');
        return { sha: sha.slice(0, 7), message: message.join(' ') };
      });

    return {
      content: [{
        type: 'text',
        text: `Last ${count} commits:\n${JSON.stringify(commits, null, 2)}`
      }],
      success: true,
      commits
    };
  } catch (error) {
    return {
      content: [{ type: 'text', text: `❌ Error: ${error.message}` }],
      success: false,
      error: error.message
    };
  }
}

async function handle_checkout_branch(args) {
  const { repo_path, branch_name } = args;

  try {
    const cwd = repo_path || process.cwd();
    execSync(`git checkout ${branch_name}`, { cwd, stdio: 'pipe' });

    return {
      content: [{ 
        type: 'text', 
        text: `✅ Checked out: ${branch_name}` 
      }],
      success: true,
      branch: branch_name
    };
  } catch (error) {
    return {
      content: [{ type: 'text', text: `❌ Error: ${error.message}` }],
      success: false,
      error: error.message
    };
  }
}

// ============================================================================
// TOOL DEFINITIONS
// ============================================================================

server.setRequestHandler('tools/list', async () => {
  return {
    tools: [
      {
        name: 'create_commit',
        description: 'Create a git commit with staged changes',
        inputSchema: {
          type: 'object',
          properties: {
            repo_path: { type: 'string', description: 'Path to git repo (optional)' },
            message: { type: 'string', description: 'Commit message' },
            files: { 
              oneOf: [
                { type: 'string' },
                { type: 'array', items: { type: 'string' } }
              ],
              description: 'Files to stage'
            },
            author_name: { type: 'string', description: 'Commit author name' },
            author_email: { type: 'string', description: 'Commit author email' },
            sign: { type: 'boolean', description: 'Sign with GPG key' }
          },
          required: ['message', 'files', 'author_name', 'author_email']
        }
      },
      {
        name: 'push_branch',
        description: 'Push branch to origin',
        inputSchema: {
          type: 'object',
          properties: {
            repo_path: { type: 'string' },
            branch_name: { type: 'string' },
            force: { type: 'boolean' }
          },
          required: ['branch_name']
        }
      },
      {
        name: 'create_branch',
        description: 'Create and checkout new branch',
        inputSchema: {
          type: 'object',
          properties: {
            repo_path: { type: 'string' },
            branch_name: { type: 'string' }
          },
          required: ['branch_name']
        }
      },
      {
        name: 'get_status',
        description: 'Get git status',
        inputSchema: {
          type: 'object',
          properties: {
            repo_path: { type: 'string' }
          }
        }
      },
      {
        name: 'get_log',
        description: 'Get recent commits',
        inputSchema: {
          type: 'object',
          properties: {
            repo_path: { type: 'string' },
            count: { type: 'number' },
            branch: { type: 'string' }
          }
        }
      },
      {
        name: 'checkout_branch',
        description: 'Checkout existing branch',
        inputSchema: {
          type: 'object',
          properties: {
            repo_path: { type: 'string' },
            branch_name: { type: 'string' }
          },
          required: ['branch_name']
        }
      }
    ]
  };
});

// ============================================================================
// SERVER STARTUP
// ============================================================================

const transport = new StdioServerTransport();
server.connect(transport).catch(error => {
  console.error('Server error:', error);
  process.exit(1);
});
```

### Configuración: claude_desktop_config.json

```json
{
  "mcpServers": {
    "git": {
      "command": "node",
      "args": ["/path/to/git-mcp/index.js"],
      "env": {
        "GIT_AUTHOR_NAME": "${GIT_AUTHOR_NAME}",
        "GIT_AUTHOR_EMAIL": "${GIT_AUTHOR_EMAIL}",
        "GPG_KEY_ID": "${GPG_KEY_ID}"
      }
    }
  }
}
```

---

## 🔧 PASO 3: MCP GITHUB (Mejorado)

### Instalación

```bash
# Instalar versión latest
npm install -g @modelcontextprotocol/server-github@latest

# Verificar capacidades
npm list @modelcontextprotocol/server-github
```

### Configuración: claude_desktop_config.json

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

### Capacidades Requeridas

```
✅ search_repositories
✅ get_repository
✅ list_issues
✅ get_issue
✅ create_issue
✅ update_issue
✅ list_pull_requests
✅ get_pull_request
✅ create_pull_request
✅ update_pull_request
✅ merge_pull_request
✅ list_commits
✅ get_commit
✅ create_commit
✅ create_ref (para tags)
✅ list_workflows
✅ trigger_workflow
```

Si la versión instalada no tiene todas, crear custom similar a Git MCP.

---

## 📝 PASO 4: CONFIGURAR TODOS LOS MCPs

### Archivo: claude_desktop_config.json (COMPLETO)

**Ubicación:** 
- Windows: `%USERPROFILE%/AppData/Local/Claude/claude_desktop_config.json`
- Mac: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Linux: `~/.config/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "jira": {
      "command": "node",
      "args": ["/path/to/jira-mcp/index.js"],
      "env": {
        "JIRA_HOST": "yourcompany.atlassian.net",
        "JIRA_EMAIL": "${JIRA_EMAIL}",
        "JIRA_API_TOKEN": "${JIRA_API_TOKEN}"
      }
    },
    "git": {
      "command": "node",
      "args": ["/path/to/git-mcp/index.js"],
      "env": {
        "GIT_AUTHOR_NAME": "${GIT_AUTHOR_NAME}",
        "GIT_AUTHOR_EMAIL": "${GIT_AUTHOR_EMAIL}",
        "GPG_KEY_ID": "${GPG_KEY_ID}"
      }
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      }
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/projects"],
      "disabled": false
    }
  }
}
```

### Archivo: .env para MCPs

**Ubicación:** `~/.claude/.env.mcp`

```bash
# Jira
export JIRA_HOST=yourcompany.atlassian.net
export JIRA_EMAIL=your-email@company.com
export JIRA_API_TOKEN=<token>

# GitHub
export GITHUB_TOKEN=ghp_<token>
export GITHUB_OWNER=your-org
export GITHUB_REPO=your-repo

# Git
export GIT_AUTHOR_NAME=Your Name
export GIT_AUTHOR_EMAIL=your-email@company.com
export GPG_KEY_ID=<optional>
```

### Source antes de abrir Claude

```bash
# En tu .bashrc o .zshrc
if [ -f ~/.claude/.env.mcp ]; then
  source ~/.claude/.env.mcp
fi
```

---

## ✅ VERIFICAR INSTALACIÓN

### Test Jira MCP

```bash
# En Claude/Agent
# Usar skill de Jira Integration
# Debería poder crear/actualizar/linkear issues
```

### Test Git MCP

```bash
# En Claude/Agent
# Usar skill de Auto-Commit
# Debería poder hacer commits automáticos
```

### Test GitHub MCP

```bash
# En Claude/Agent
# Usar skill de Auto-PR
# Debería poder crear PRs automáticas
```

---

**Última actualización:** 2026-06-04
**Versión:** 1.0
