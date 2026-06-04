# Claude Automation Setup

Level 3 automation setup for Claude Code: 11 agents, 6 skills, 4 scripts, and 4 git hooks that turn feature descriptions into Jira tickets, commits, PRs, and releases.

## What's Inside

```
claude-automation-setup/
├── install.sh              # Installs agents + skills globally to ~/.claude/
├── setup-repo.sh           # Sets up an individual repo (scripts, hooks, .env)
├── .env.example            # Credentials template (copy to .env.local)
├── .gitignore              # Blocks secrets from being committed
├── global/                 # Goes to ~/.claude/ (once, all repos)
│   ├── agents/             # 11 agents
│   └── skills/             # 6 skills
├── per-repo/               # Goes into each repo that uses the tools
│   ├── scripts/            # 4 executable scripts
│   └── .husky/             # 4 git hooks
└── docs/                   # Setup guides and reference
```

## Two Levels of Installation

This is the key concept: **some things are global, some are per-repo.**

### Global (install once, works everywhere)

Agents and skills live in `~/.claude/` and apply to every repo automatically.

```bash
./install.sh
```

This copies:
- `global/agents/*` → `~/.claude/agents/`
- `global/skills/*` → `~/.claude/skills/`

(It backs up any existing agents/skills first.)

### Per-Repository (run in each project)

Scripts, hooks, and credentials live **inside each repo** — they are project
tooling, not Claude config, so they do NOT go in `.claude/`.

From the root of a repo you want to set up:

```bash
/path/to/claude-automation-setup/setup-repo.sh
```

This copies:
- `per-repo/scripts/*` → `<repo>/scripts/`
- `per-repo/.husky/*` → `<repo>/.husky/`
- `.env.example` → `<repo>/.env.local` (then you fill it in)
- Adds `.env.local` to the repo's `.gitignore`

## Where Things Go (Important)

| File | Location | Why |
|------|----------|-----|
| agents/ | `~/.claude/agents/` | Claude config, global |
| skills/ | `~/.claude/skills/` | Claude config, global |
| scripts/ | `<repo>/scripts/` | Run by npm, project tooling |
| .husky/ | `<repo>/.husky/` | Where git/husky looks for hooks |
| .env.local | `<repo>/.env.local` | Where dotenv reads secrets |

**Agents and skills do NOT need to be duplicated per repo.** Once in `~/.claude/`
they work everywhere. Only put an agent in `<repo>/.claude/agents/` if you want a
version specific to that one project — Claude Code merges global + project agents.

## Quick Start

```bash
# 1. Clone this repo
git clone <your-repo-url> claude-automation-setup
cd claude-automation-setup

# 2. Install agents + skills globally
chmod +x install.sh setup-repo.sh
./install.sh

# 3. For each project, set it up
cd ~/your-project
/path/to/claude-automation-setup/setup-repo.sh

# 4. Fill in credentials
#    Edit your-project/.env.local

# 5. (Node projects) finish setup
npm install --save-dev minimist husky
npx husky install
# Add the npm scripts to package.json (see setup-repo.sh output)

# 6. Test
npm run auto-commit -- --help
```

## The 11 Agents

| Agent | Role |
|-------|------|
| agent-orchestrator | Master orchestrator, single entry point |
| solutions-expert | Master system designer |
| ticket-orchestrator | Generates Jira Epic/Story/Task hierarchy |
| backend-expert | NestJS / FastAPI / MongoDB |
| frontend-expert | React / Next.js / Astro + a11y |
| iot-backend-expert | Raspberry Pi / GPIO / edge FastAPI |
| pr-manager | Creates PRs (TELUS format) |
| code-reviewer-pro | Automated review + security scanning |
| aws-architect | AWS cloud architecture |
| cdk-expert | Infrastructure as Code (CDK) |
| documentation-generator | Docs + versioning + releases |

## The 6 Skills

1. IoT Backend Best Practices
2. PR Description Formatter
3. Semantic Versioning Control
4. Auto-Commit Best Practices
5. Auto-PR Creation Guide
6. Jira Integration Patterns

## Security

**Never commit `.env.local`.** It contains your Jira and GitHub tokens.
The `.gitignore` here blocks it, and `setup-repo.sh` adds it to each repo's
`.gitignore` automatically. Use `.env.example` as the shareable template.

## MCPs

Level 3 needs three MCP servers (Jira, Git, GitHub). See
`docs/MCPS-configuracion-completa.md` for setup. These are configured once in
your Claude Code config, not per-repo.

## Node vs Python Projects

The scripts (`.js`) and Husky hooks assume a Node.js project. For Python
projects (like a FastAPI service), you'll need to adapt:
- Replace npm scripts with direct `node scripts/x.js` calls or Python equivalents
- Use Python's `pre-commit` framework instead of Husky, or call the hooks directly

See `docs/` for details.

## License

Internal use. Keep this repository private if it contains organization-specific
conventions.
