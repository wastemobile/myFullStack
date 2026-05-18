#!/usr/bin/env bash
# template-mirror — PostToolUse hook
#
# Two responsibilities, dispatched by the file path written:
#
# A. Skill twin sync:
#    bootstrap/use-mystack.md → ~/.claude/commands/use-mystack.md
#
# B. Template mirror (source files):
#    AGENTS.md, CLAUDE.md, KNOWLEDGE.md, .mcp.json, .gitignore,
#    skills/**, .claude/agents/**
#    → ~/.claude/templates/fullStack/
#
# Excluded from the mirror (dev-only / repo-only):
#   README.md, .git/, .DS_Store, bootstrap/, bootstrap.sh,
#   .claude/commands/, .claude/hooks/, .claude/settings*.json

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")
[ -z "$FILE_PATH" ] && exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/projects/myFullStack}"
TEMPLATE_DIR="$HOME/.claude/templates/fullStack"
SKILL_LOCAL="$HOME/.claude/commands/use-mystack.md"

# Only fire for files inside this project
case "$FILE_PATH" in
  "$PROJECT_DIR"/*) ;;
  *) exit 0 ;;
esac

# A. Skill twin sync — fires regardless of template dir presence.
if [ "$FILE_PATH" = "$PROJECT_DIR/bootstrap/use-mystack.md" ]; then
  mkdir -p "$(dirname "$SKILL_LOCAL")"
  cp "$FILE_PATH" "$SKILL_LOCAL"
  echo "[template-mirror] synced bootstrap/use-mystack.md → ~/.claude/commands/use-mystack.md" >&2
  exit 0
fi

# B. Template mirror — silently no-op if template dir doesn't exist (third-party clone).
[ -d "$TEMPLATE_DIR" ] || exit 0

case "$FILE_PATH" in
  "$PROJECT_DIR"/AGENTS.md|\
  "$PROJECT_DIR"/CLAUDE.md|\
  "$PROJECT_DIR"/KNOWLEDGE.md|\
  "$PROJECT_DIR"/.mcp.json|\
  "$PROJECT_DIR"/.gitignore|\
  "$PROJECT_DIR"/skills/*|\
  "$PROJECT_DIR"/.claude/agents/*)
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
      "$PROJECT_DIR/" "$TEMPLATE_DIR/"
    echo "[template-mirror] synced $(basename "$FILE_PATH") → ~/.claude/templates/fullStack/" >&2
    ;;
esac

exit 0
