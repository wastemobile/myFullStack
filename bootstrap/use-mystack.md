---
description: Install the Full Stack HQ tech-stack reference (Astro/Svelte 5/NestJS/Prisma/Tailwind). Self-updates from GitHub before installing. Smart-merges with existing AGENTS.md/CLAUDE.md.
---

# /use-mystack

Install the **Full Stack HQ tech-stack reference guide** into `$PWD`. Self-updating: each run checks GitHub for newer versions of the repo and this skill before installing.

## Sources

```
GitHub (wastemobile/myFullStack)
        │ git fetch / pull
        ▼
~/projects/myFullStack/         ← local git checkout
        │ rsync (this skill or template-mirror hook)
        ▼
~/.claude/templates/fullStack/  ← install source
        │ /use-mystack
        ▼
$PWD                             ← target project
```

The canonical version of this file lives at `~/projects/myFullStack/bootstrap/use-mystack.md`. The `template-mirror` PostToolUse hook mirrors edits there to `~/.claude/commands/use-mystack.md` (this file).

## Arguments

| flag | meaning |
|---|---|
| *(none)* | smart install with preflight self-update |
| `--refresh` | replace the existing BEGIN/END block in target AGENTS.md |
| `--dry-run` | preview only |
| `--skip-update` | skip Step 0; use cached template as-is |

## Step 0 — preflight self-update

Run unless `--skip-update`.

Variables:
```bash
REPO_DIR="$HOME/projects/myFullStack"
TEMPLATE_DIR="$HOME/.claude/templates/fullStack"
SKILL_LOCAL="$HOME/.claude/commands/use-mystack.md"
SKILL_REPO="$REPO_DIR/bootstrap/use-mystack.md"
```

### 0.1 — repo present?

If `$REPO_DIR/.git` does not exist, print:
```
⚠ Local repo missing at ~/projects/myFullStack.
  To enable self-update, run bootstrap once:
    curl -fsSL https://raw.githubusercontent.com/wastemobile/myFullStack/main/bootstrap.sh | bash
  Proceeding with cached template (no version check)...
```
Then skip to Step 1.

### 0.2 — fetch + compare

```bash
git -C "$REPO_DIR" fetch --quiet origin main 2>/dev/null || OFFLINE=1
```

If `OFFLINE` → warn `⚠ git fetch failed (offline?). Using cached template.` and skip to Step 1.

Otherwise:
```bash
LOCAL=$(git -C "$REPO_DIR" rev-parse HEAD)
REMOTE=$(git -C "$REPO_DIR" rev-parse origin/main)
BEHIND=$(git -C "$REPO_DIR" rev-list --count HEAD..origin/main)
```

- If `LOCAL == REMOTE` → print `✓ Repo up to date.` Continue.
- Otherwise show the user the new commits and ask:

```
Local repo is $BEHIND commit(s) behind origin/main:

<output of: git -C "$REPO_DIR" log --oneline HEAD..origin/main>

Pull and re-sync template? (PROCEED to pull, or "skip")
```

On `PROCEED`:
```bash
git -C "$REPO_DIR" pull --ff-only
rsync -a --delete \
  --exclude='/.git/' --exclude='/README.md' --exclude='/.DS_Store' \
  --exclude='/.claude/commands/' --exclude='/.claude/hooks/' \
  --exclude='/.claude/settings.json' --exclude='/.claude/settings.local.json' \
  --exclude='/bootstrap/' --exclude='/bootstrap.sh' \
  "$REPO_DIR/" "$TEMPLATE_DIR/"
```

### 0.3 — skill twin drift check

```bash
diff -q "$SKILL_LOCAL" "$SKILL_REPO" >/dev/null 2>&1 || SKILL_DRIFT=1
```

If `SKILL_DRIFT`, ask:
```
The /use-mystack skill has updates in the repo. Update it now?
(PROCEED to copy bootstrap/use-mystack.md → ~/.claude/commands/use-mystack.md, or "skip")
```

On `PROCEED`:
```bash
cp "$SKILL_REPO" "$SKILL_LOCAL"
```
Warn: `Skill updated. The new logic applies on next /use-mystack call.`

## Step 1 — install preflight

```bash
SRC="$TEMPLATE_DIR"
DST="$PWD"
test -d "$SRC" || { echo "✗ template missing — run bootstrap.sh"; exit 1; }

COMMIT_SHA=$(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")
INSTALL_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
```

If `--dry-run`, prefix every write/copy with `echo` (do not execute real ops).

## Step 2 — root files (copy-if-missing)

```bash
for f in KNOWLEDGE.md .mcp.json .gitignore; do
  if [ -e "$DST/$f" ]; then
    record "skipped: $f"
  else
    cp "$SRC/$f" "$DST/$f"
    record "created: $f"
  fi
done
```

## Step 3 — `.claude/agents/` (rsync, no overwrite)

```bash
mkdir -p "$DST/.claude/agents"
rsync -a --ignore-existing "$SRC/.claude/agents/" "$DST/.claude/agents/"
```

## Step 4 — `skills/` (rsync, no overwrite)

```bash
rsync -a --ignore-existing "$SRC/skills/" "$DST/skills/"
```

## Step 5 — AGENTS.md (smart merge)

Marker format (commit metadata embedded for drift detection):

```
<!-- BEGIN: full-stack-hq stack preferences (managed by /use-mystack; commit COMMIT_SHA @ INSTALL_DATE) -->

{template AGENTS.md contents}

<!-- END: full-stack-hq stack preferences -->
```

Decision tree:

**1. `$DST/AGENTS.md` does not exist.**
→ `cp "$SRC/AGENTS.md" "$DST/AGENTS.md"`. Record `created: AGENTS.md`.

**2. Exists, no BEGIN marker.**
→ Append the delimited block to the end of the file, using the BEGIN line with current `$COMMIT_SHA` and `$INSTALL_DATE`. Record `appended: AGENTS.md`.

**3. Exists, has BEGIN marker, no `--refresh`.**
Parse installed SHA from the existing marker:
```bash
INSTALLED_SHA=$(grep -m1 'BEGIN: full-stack-hq' "$DST/AGENTS.md" | sed -E 's/.*commit ([a-f0-9]+) @.*/\1/')
```
- If `INSTALLED_SHA == $COMMIT_SHA` → record `up to date: AGENTS.md`.
- Else compute drift:
  ```bash
  DRIFT=$(git -C "$REPO_DIR" rev-list --count "$INSTALLED_SHA..HEAD" 2>/dev/null || echo "?")
  ```
  Record:
  ```
  ⚠ AGENTS.md drift: installed at $INSTALLED_SHA, template at $COMMIT_SHA ($DRIFT commits behind).
    Run /use-mystack --refresh to update.
  ```

**4. Exists, has BEGIN marker, with `--refresh`.**
Replace the entire region from `<!-- BEGIN:` through `<!-- END:` (inclusive) with a freshly-stamped block using current `$COMMIT_SHA` and `$INSTALL_DATE`. Record `refreshed: AGENTS.md ($INSTALLED_SHA → $COMMIT_SHA)`.

## Step 6 — CLAUDE.md (`@AGENTS.md` reference)

1. `$DST/CLAUDE.md` does not exist → `cp "$SRC/CLAUDE.md" "$DST/CLAUDE.md"`. Record `created`.
2. Exists, already contains `@AGENTS.md` → record `skipped`.
3. Exists, missing `@AGENTS.md` → append `@AGENTS.md` on a new line. Record `appended (@AGENTS.md added)`.

Check via:
```bash
grep -qF '@AGENTS.md' "$DST/CLAUDE.md"
```

## Step 7 — report

```
/use-mystack — install complete

Preflight:
  Repo:   <up to date | pulled $BEHIND commits | offline | repo missing>
  Skill:  <up to date | refreshed | skipped>

Install:
  Created:    <files>
  Appended:   <files>
  Refreshed:  <files>
  Skipped:    <files>
  Drift:      <files needing --refresh>

Next:
  - Review AGENTS.md to confirm stack preferences fit this project.
  - If this is a new repo: git init && git add -A && git commit -m "chore: install full-stack-hq preferences"
```

If `--dry-run`, prefix heading with `[DRY RUN] ` and clarify nothing was written.

## Idempotency contract

Running `/use-mystack` twice produces no further changes the second time:
- Step 0 reports `up to date`.
- Step 5 case 3 detects matching SHA → `up to date: AGENTS.md`.
- All other steps already skip-if-existing.

The BEGIN/END markers + embedded commit SHA are the idempotency contract. Don't hand-edit them.

## Permissions

Invoking `/use-mystack` authorizes writes to `$PWD`. The following actions require an explicit `PROCEED` reply from the user:
- Pulling new commits from GitHub (Step 0.2)
- Refreshing the skill itself (Step 0.3)
- `--refresh` rewriting an existing AGENTS.md block (Step 5 case 4)
