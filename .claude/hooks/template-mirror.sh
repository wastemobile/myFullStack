#!/usr/bin/env bash
# template-mirror — PostToolUse hook
#
# After Claude writes/edits a "source" file in this repo, mirror the repo to
# ~/.claude/templates/fullStack/ so /use-mystack always installs the latest.
#
# Source files (whitelist):
#   AGENTS.md, CLAUDE.md, KNOWLEDGE.md, .mcp.json, .gitignore,
#   skills/**, .claude/agents/**
#
# Excluded from the mirror (dev-only / repo-only):
#   README.md, .git/, .DS_Store, .claude/commands/, .claude/hooks/,
#   .claude/settings*.json

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")
[ -z "$FILE_PATH" ] && exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/projects/myFullStack}"
TEMPLATE_DIR="$HOME/.claude/templates/fullStack"

# Only fire for files inside this project
case "$FILE_PATH" in
  "$PROJECT_DIR"/*) ;;
  *) exit 0 ;;
esac

# Silently no-op if template dir doesn't exist (third-party clone)
[ -d "$TEMPLATE_DIR" ] || exit 0

# Source-file whitelist — anything else: no mirror
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
      "$PROJECT_DIR/" "$TEMPLATE_DIR/"
    echo "[template-mirror] synced $(basename "$FILE_PATH") → ~/.claude/templates/fullStack/" >&2
    ;;
esac

exit 0
