#!/bin/bash

# ============================================================================
# Per-Repository Setup
# ============================================================================
# Run this FROM the root of the repo you want to set up.
# Usage:
#   /path/to/claude-automation-setup/setup-repo.sh
# ============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Directory where this script lives (the setup repo)
SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Current directory (the target repo)
TARGET_DIR="$(pwd)"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Per-Repository Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Setup source: $SETUP_DIR"
echo "Target repo:  $TARGET_DIR"
echo ""

# ----------------------------------------------------------------------------
# Safety check — is this a git repo?
# ----------------------------------------------------------------------------
if [ ! -d "$TARGET_DIR/.git" ]; then
  echo -e "${RED}❌ Current directory is not a git repository.${NC}"
  echo "   Run this from the root of your repo."
  exit 1
fi

# ----------------------------------------------------------------------------
# Detect project type
# ----------------------------------------------------------------------------
if [ -f "$TARGET_DIR/package.json" ]; then
  echo -e "${GREEN}✅ Detected Node.js project (package.json found)${NC}"
  IS_NODE=true
else
  echo -e "${YELLOW}⚠️  No package.json found — this looks like a non-Node project.${NC}"
  echo "   The .js scripts and Husky hooks assume Node. For Python projects,"
  echo "   see docs for the Python adaptation. Continuing with file copy only."
  IS_NODE=false
fi
echo ""

# ----------------------------------------------------------------------------
# 1. Copy scripts
# ----------------------------------------------------------------------------
echo -e "${BLUE}Copying scripts...${NC}"
mkdir -p "$TARGET_DIR/scripts"
cp "$SETUP_DIR"/per-repo/scripts/*.js "$TARGET_DIR/scripts/"
echo -e "${GREEN}✅ Scripts copied to scripts/${NC}"

# ----------------------------------------------------------------------------
# 2. Copy .husky hooks
# ----------------------------------------------------------------------------
echo -e "${BLUE}Copying Husky hooks...${NC}"
mkdir -p "$TARGET_DIR/.husky"
cp "$SETUP_DIR"/per-repo/.husky/pre-commit "$TARGET_DIR/.husky/"
cp "$SETUP_DIR"/per-repo/.husky/prepare-commit-msg "$TARGET_DIR/.husky/"
cp "$SETUP_DIR"/per-repo/.husky/post-merge "$TARGET_DIR/.husky/"
cp "$SETUP_DIR"/per-repo/.husky/pre-tag "$TARGET_DIR/.husky/"
chmod +x "$TARGET_DIR"/.husky/pre-commit
chmod +x "$TARGET_DIR"/.husky/prepare-commit-msg
chmod +x "$TARGET_DIR"/.husky/post-merge
chmod +x "$TARGET_DIR"/.husky/pre-tag
echo -e "${GREEN}✅ Hooks copied to .husky/${NC}"

# ----------------------------------------------------------------------------
# 3. Create .env.local if it doesn't exist
# ----------------------------------------------------------------------------
if [ ! -f "$TARGET_DIR/.env.local" ]; then
  echo -e "${BLUE}Creating .env.local from template...${NC}"
  cp "$SETUP_DIR/.env.example" "$TARGET_DIR/.env.local"
  echo -e "${GREEN}✅ Created .env.local${NC}"
  echo -e "${YELLOW}   ⚠️  EDIT .env.local and fill in your credentials!${NC}"
else
  echo -e "${YELLOW}⚠️  .env.local already exists — left untouched${NC}"
fi

# ----------------------------------------------------------------------------
# 4. Ensure .env.local is gitignored
# ----------------------------------------------------------------------------
if [ ! -f "$TARGET_DIR/.gitignore" ] || ! grep -q ".env.local" "$TARGET_DIR/.gitignore"; then
  echo -e "${BLUE}Adding .env.local to .gitignore...${NC}"
  echo "" >> "$TARGET_DIR/.gitignore"
  echo "# Claude automation secrets" >> "$TARGET_DIR/.gitignore"
  echo ".env.local" >> "$TARGET_DIR/.gitignore"
  echo -e "${GREEN}✅ .gitignore updated${NC}"
fi

# ----------------------------------------------------------------------------
# 5. Node-specific setup
# ----------------------------------------------------------------------------
if [ "$IS_NODE" = true ]; then
  echo ""
  echo -e "${BLUE}Node setup...${NC}"
  echo -e "${YELLOW}Run these manually to finish:${NC}"
  echo "  npm install --save-dev minimist husky"
  echo "  npx husky install"
  echo ""
  echo -e "${YELLOW}Add to package.json scripts:${NC}"
  echo '  "auto-commit": "node scripts/auto-commit.js",'
  echo '  "auto-pr": "node scripts/auto-pr.js",'
  echo '  "auto-jira": "node scripts/auto-jira.js",'
  echo '  "dashboard": "node scripts/dashboard.js",'
  echo '  "prepare": "husky install"'
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Repo setup complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}DON'T FORGET:${NC}"
echo "  1. Edit .env.local with your real credentials"
echo "  2. Run: npm install --save-dev minimist husky"
echo "  3. Add the npm scripts shown above to package.json"
echo "  4. Test: npm run auto-commit -- --help"
echo ""
