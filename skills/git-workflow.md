---
name: git-workflow
description: Concrete git commands and gh CLI workflows — branch naming, commit messages, PR creation, conflict resolution, useful command reference. Operational counterpart to AGENTS.md §5.
---

# Git Workflow

> Concepts (branching strategy, commit types) live in [`AGENTS.md`](../AGENTS.md) §5.
> This file covers the **commands** — copy-paste-ready operations.

## Branch Naming Examples

```bash
# Pattern: <type>/<short-description>
feature/user-profile-page
feature/export-orders-csv
fix/refresh-token-cookie-samesite
fix/n-plus-one-users-query
chore/upgrade-prisma-6
refactor/extract-payment-service
docs/add-api-endpoints-readme
test/add-auth-integration-tests
release/v2.1.0

# Avoid
johns-branch       # ← no name, no context
fix1               # ← too vague
JIRA-1234          # ← ticket ID alone means nothing later
wip                # ← push to a real branch name
```

## Commit Message Examples

```bash
# Single-line
git commit -m "feat(auth): add JWT refresh token rotation"
git commit -m "fix(users): prevent email enumeration on login"
git commit -m "refactor(orders): extract payment processing to dedicated service"
git commit -m "perf(queries): add index on orders.user_id column"
git commit -m "test(auth): add integration tests for token expiry flow"

# With body (use HEREDOC for clean multiline)
git commit -m "$(cat <<'EOF'
fix(uploads): reject files larger than 5MB

Previously the file size limit was only enforced on the frontend.
An attacker could bypass this by posting directly to the API.
Added multer limits and a guard to enforce 5MB server-side.

Fixes #142
EOF
)"
```

## Create a PR

```bash
# 1. Branch from main
git checkout main
git pull origin main
git checkout -b feature/user-export

# 2. Commit incrementally (stage specific files — avoid `git add .`)
git add src/users/users.service.ts src/users/dto/export.dto.ts
git commit -m "feat(users): add CSV export endpoint"

git add src/users/users.service.spec.ts
git commit -m "test(users): add unit tests for CSV export"

# 3. Push + open PR
git push -u origin feature/user-export
gh pr create --title "feat(users): add CSV export endpoint" --body "$(cat <<'EOF'
## What
Adds GET /users/export.csv returning all users as CSV.

## Why
Requested by ops team for bulk user management. Fixes #89.

## Testing
- [ ] Unit tests added (users.service.spec.ts)
- [ ] Tested locally with 10k users
- [ ] Response headers verified in browser download

## Breaking Changes
None — new endpoint only.
EOF
)"
```

## Keep Branch Updated

```bash
# Rebase onto main (preferred — linear history)
git fetch origin
git rebase origin/main

# On conflict:
#   1. open conflicted files, resolve
#   2. git add <resolved-files>
#   3. git rebase --continue
# Bail out: git rebase --abort

# Alternative: merge main into branch (creates merge commit)
git merge origin/main
```

## Resolve Merge Conflicts

```bash
git status                           # see conflicting files
$EDITOR src/users/users.service.ts   # resolve markers
git add src/users/users.service.ts   # mark resolved
git rebase --continue                # or `git commit` if merging
```

**Conflict marker anatomy:**
```typescript
<<<<<<< HEAD (your branch)
function getUserById(id: string) {
  return this.repo.findOne({ where: { id } })
=======
async function getUserById(id: number) {
  return this.repo.findOne({ where: { id }, relations: ['profile'] })
>>>>>>> origin/main
```

Pick the right version or combine intents — never leave markers in committed code.

## Command Reference

```bash
# Inspect
git status
git diff                       # unstaged changes
git diff --staged              # staged changes
git log --oneline -10          # last 10 commits
git log --graph --oneline      # visual branch tree
git blame <file>               # who changed each line

# Staging
git add <file>                 # stage specific file
git add -p                     # interactive — review hunks
git restore --staged <file>    # unstage

# Commits
git commit -m "message"
git commit --amend             # edit last commit — only if NOT pushed
git commit --fixup <sha>       # mark as fixup for autosquash rebase

# Branches
git branch                     # list local branches
git branch -d feature/done     # delete merged branch
git switch -                   # switch to previous branch
git stash push -m "wip msg"    # stash with label
git stash pop                  # restore stash

# Remote
git fetch origin               # download without merging
git push -u origin <branch>    # push + set upstream
git push --force-with-lease    # safer than --force (fails if upstream moved)

# Undo
git restore <file>             # discard unstaged changes
git reset --soft HEAD~1        # undo last commit, keep changes staged
git reset --mixed HEAD~1       # undo last commit, unstage changes
git revert HEAD                # create a new commit that undoes HEAD
```

## Tagging Releases

```bash
git tag -a v1.2.0 -m "Release v1.2.0 — adds user export feature"
git push origin --tags

gh release create v1.2.0 \
  --title "v1.2.0 — User Export" \
  --notes "$(cat CHANGELOG.md)" \
  --target main
```

## `.gitignore` Essentials

```gitignore
# Node
node_modules/
dist/
build/
.svelte-kit/
.astro/

# Env files
.env
.env.local
.env.*.local
!.env.example     # keep example file in repo

# Local DBs (SQLite)
*.db
*.db-journal
*.db-wal
*.db-shm

# IDE
.vscode/settings.json
.idea/
*.iml

# OS
.DS_Store
Thumbs.db

# Logs
*.log
npm-debug.log*
pnpm-debug.log*

# Tests
coverage/
playwright-report/
test-results/

# Claude Code local state
.claude/settings.local.json
```

## Forbidden Operations (per AGENTS.md §5)

- Never push directly to `main`
- Never force-push to `main` or any shared branch
- Never commit `.env` files
- Never `git add .` without reviewing `git diff --staged` first
- Never amend or rebase commits already pushed to a shared branch
- Never use `--no-verify` to skip hooks — fix the underlying issue
- Never commit generated artifacts (`dist/`, `build/`, `coverage/`)
