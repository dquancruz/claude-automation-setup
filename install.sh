#!/bin/bash

# ============================================================================
# Claude Automation Setup — Installer
# ============================================================================
# Installs agents and skills globally to ~/.claude/
# Per-repo files (scripts, hooks, .env) are handled separately — see README.
# ============================================================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Claude Automation Setup — Installer${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# ----------------------------------------------------------------------------
# 1. Verify ~/.claude exists
# ----------------------------------------------------------------------------
CLAUDE_DIR="$HOME/.claude"

if [ ! -d "$CLAUDE_DIR" ]; then
  echo -e "${YELLOW}Creating $CLAUDE_DIR ...${NC}"
  mkdir -p "$CLAUDE_DIR"
fi

mkdir -p "$CLAUDE_DIR/agents"
mkdir -p "$CLAUDE_DIR/skills"

# ----------------------------------------------------------------------------
# 2. Backup existing agents/skills (safety)
# ----------------------------------------------------------------------------
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

if [ "$(ls -A $CLAUDE_DIR/agents 2>/dev/null)" ]; then
  echo -e "${YELLOW}Backing up existing agents to agents-backup-$TIMESTAMP ...${NC}"
  cp -r "$CLAUDE_DIR/agents" "$CLAUDE_DIR/agents-backup-$TIMESTAMP"
fi

if [ "$(ls -A $CLAUDE_DIR/skills 2>/dev/null)" ]; then
  echo -e "${YELLOW}Backing up existing skills to skills-backup-$TIMESTAMP ...${NC}"
  cp -r "$CLAUDE_DIR/skills" "$CLAUDE_DIR/skills-backup-$TIMESTAMP"
fi

# ----------------------------------------------------------------------------
# 3. Install agents (11)
# ----------------------------------------------------------------------------
echo ""
echo -e "${BLUE}Installing agents...${NC}"
cp global/agents/*.md "$CLAUDE_DIR/agents/"
AGENT_COUNT=$(ls global/agents/*.md | wc -l)
echo -e "${GREEN}✅ Installed $AGENT_COUNT agents${NC}"

# ----------------------------------------------------------------------------
# 4. Install skills (6)
# ----------------------------------------------------------------------------
echo ""
echo -e "${BLUE}Installing skills...${NC}"
cp global/skills/*.md "$CLAUDE_DIR/skills/"
SKILL_COUNT=$(ls global/skills/*.md | wc -l)
echo -e "${GREEN}✅ Installed $SKILL_COUNT skills${NC}"

# ----------------------------------------------------------------------------
# Done
# ----------------------------------------------------------------------------
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Global install complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Installed to: $CLAUDE_DIR"
echo "  - $AGENT_COUNT agents"
echo "  - $SKILL_COUNT skills"
echo ""
echo -e "${YELLOW}NEXT — per-repo setup (run in each project):${NC}"
echo "  See README.md → 'Per-Repository Setup'"
echo "  1. Copy per-repo/scripts/ to your repo"
echo "  2. Copy per-repo/.husky/ to your repo"
echo "  3. cp .env.example <your-repo>/.env.local and fill it in"
echo "  4. Add npm scripts to package.json"
echo ""
