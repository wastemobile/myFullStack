---
description: Preview and explicitly mirror this repo to ~/.claude/templates/fullStack/ for /use-mystack consumption. Complement to the PostToolUse template-mirror hook.
---

# /sync-template

Manually mirror `~/projects/myFullStack/` → `~/.claude/templates/fullStack/`.

Use when:
- You batched several edits and want a single explicit sync
- The `template-mirror` PostToolUse hook is disabled or you want to confirm sync state
- You want a diff preview before any files change

## What gets synced

Everything in the project, **except**:
- `README.md`
- `.git/`
- `.DS_Store`
- `.claude/commands/`, `.claude/hooks/`
- `.claude/settings.json`, `.claude/settings.local.json`

The mirror is destructive on the destination side (`rsync --delete`): files removed from the project are also removed from the template.

## Flow

### Step 1 — preview

Run dry-run rsync with itemized output:

```bash
rsync -a --delete --itemize-changes --dry-run \
  --exclude='/.git/' \
  --exclude='/README.md' \
  --exclude='/.DS_Store' \
  --exclude='/.claude/commands/' \
  --exclude='/.claude/hooks/' \
  --exclude='/.claude/settings.json' \
  --exclude='/.claude/settings.local.json' \
  "$HOME/projects/myFullStack/" "$HOME/.claude/templates/fullStack/"
```

Show the user the itemized output. Each line begins with a code:
- `>f.....` create new file
- `>f.s.t.` update file (size/time changed)
- `*deleting` remove file from template

If the output is empty → report "Already in sync." and stop.

### Step 2 — confirm

If there are pending changes, ask the user to confirm with `PROCEED`. Show a short summary like:
```
3 files will change:
  + skills/redis-patterns.md
  ~ AGENTS.md
  - skills/old-thing.md

Reply PROCEED to apply, or cancel.
```

### Step 3 — apply

On `PROCEED`, re-run rsync **without** `--dry-run`:

```bash
rsync -a --delete --itemize-changes \
  --exclude='/.git/' \
  --exclude='/README.md' \
  --exclude='/.DS_Store' \
  --exclude='/.claude/commands/' \
  --exclude='/.claude/hooks/' \
  --exclude='/.claude/settings.json' \
  --exclude='/.claude/settings.local.json' \
  "$HOME/projects/myFullStack/" "$HOME/.claude/templates/fullStack/"
```

Report success with a one-line summary.

## Relationship to the hook

`.claude/hooks/template-mirror.sh` (PostToolUse) runs the **same rsync** automatically after edits to source files. This skill exists as the manual / batch / preview path. They are deliberately redundant — both must use identical excludes to stay coherent. If you change the excludes, update both.
