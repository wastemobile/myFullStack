#!/usr/bin/env bash
# bootstrap.sh — set up Full Stack HQ on a new machine.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/wastemobile/myFullStack/main/bootstrap.sh | bash
#
# What it does:
#   1. Clone github.com/wastemobile/myFullStack into ~/projects/myFullStack
#      (or pull if it already exists)
#   2. rsync the repo into ~/.claude/templates/fullStack/  (install source)
#   3. Copy bootstrap/use-mystack.md into ~/.claude/commands/  (the skill)
#
# Idempotent — safe to re-run.

set -euo pipefail

REPO_URL="${FULLSTACK_HQ_URL:-https://github.com/wastemobile/myFullStack.git}"
REPO_DIR="${FULLSTACK_HQ_ROOT:-$HOME/projects/myFullStack}"
TEMPLATE_DIR="$HOME/.claude/templates/fullStack"
SKILL_DIR="$HOME/.claude/commands"

echo "▶ Full Stack HQ bootstrap"
echo "  repo:     $REPO_DIR"
echo "  template: $TEMPLATE_DIR"
echo "  skill:    $SKILL_DIR/use-mystack.md"
echo ""

# 1. Clone or update repo
if [ ! -d "$REPO_DIR/.git" ]; then
  mkdir -p "$(dirname "$REPO_DIR")"
  echo "→ cloning $REPO_URL"
  git clone "$REPO_URL" "$REPO_DIR"
else
  echo "→ repo already present, running git pull --ff-only --tags"
  git -C "$REPO_DIR" pull --ff-only --tags
fi

VERSION=$(git -C "$REPO_DIR" describe --tags --abbrev=0 HEAD 2>/dev/null || echo "untagged")
echo "  version:  $VERSION"

# 2. Sync template (same excludes as template-mirror hook + /sync-template skill)
echo "→ syncing template"
mkdir -p "$TEMPLATE_DIR"
rsync -a --delete \
  --exclude='/.git/' \
  --exclude='/README.md' \
  --exclude='/.DS_Store' \
  --exclude='/.claude/commands/' \
  --exclude='/.claude/hooks/' \
  --exclude='/.claude/settings.json' \
  --exclude='/.claude/settings.local.json' \
  --exclude='/bootstrap/' \
  --exclude='/bootstrap.sh' \
  "$REPO_DIR/" "$TEMPLATE_DIR/"

# 3. Install /use-mystack skill
echo "→ installing /use-mystack skill"
mkdir -p "$SKILL_DIR"
cp "$REPO_DIR/bootstrap/use-mystack.md" "$SKILL_DIR/use-mystack.md"

echo ""
echo "✓ bootstrap complete (installed $VERSION)."
echo ""
echo "Next:"
echo "  1. Restart Claude Code (or /reload-plugins)."
echo "  2. cd into any project."
echo "  3. Run /use-mystack — it will check for upstream updates and install."
echo ""
echo "Release notes: https://github.com/wastemobile/myFullStack/releases"
