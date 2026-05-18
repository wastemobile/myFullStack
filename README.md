# Full Stack HQ

> Opinionated AI coding configuration for a TypeScript-first full-stack workflow.
> One canonical rule set (`AGENTS.md`), readable by any modern coding agent.

Inspired by [sabahattink/antigravity-fullstack-hq](https://github.com/sabahattink/antigravity-fullstack-hq) — adapted for Claude Code, retargeted at the Astro/Svelte/SQLite stack, and trimmed for lower complexity.

---

## Tech Stack

- **Frontend** — Astro 5+, Svelte 5 (runes), Tailwind CSS v4, TypeScript 5+
- **Backend** — NestJS, Node.js 24+, BullMQ, Redis
- **Database** — SQLite 3 (dev/test + micro/small prod), PostgreSQL 16+ (larger prod), Prisma 6+
- **Auth** — JWT with refresh token rotation
- **Testing** — Vitest, Jest, Playwright
- **Infra** — Rocky Linux / Ubuntu, Docker (prefer Docker Compose), Caddy 2

Engine selection criteria (active users, data volume, deploy topology) are documented in `AGENTS.md` §3.

---

## For AI Agents

If you are an AI coding agent and you've been pointed at this repository:

1. **Read [`AGENTS.md`](./AGENTS.md) first** — the canonical rule set (permission workflow, code style, stack-specific rules).
2. **Then [`KNOWLEDGE.md`](./KNOWLEDGE.md)** — curated list of *official* AI / MCP / agent entry points for every major piece of the stack (Svelte, Astro, Prisma, Playwright, Redis, Docker, ...). Use it to wire up MCP servers and skills, not to chase third-party plugins.
3. **Then [`skills/`](./skills/)** — concrete operational know-how for tools without (or before reaching for) official MCP: TypeScript patterns, Tailwind, Prisma workflow, Docker, git commands, NestJS scaffolding. Designed to give different agents and different model tiers a shared baseline.

Tool-specific entry points all resolve to the same content:

| Agent | Entry point | How it resolves |
|---|---|---|
| Claude Code | `CLAUDE.md` | One-line file: `@AGENTS.md` (Claude Code include syntax) |
| OpenAI Codex | `AGENTS.md` | Read directly |
| OpenCode (sst) | `AGENTS.md` | Read directly |
| Hermes Agent | `AGENTS.md` | Read directly |
| Other [agents.md](https://agents.md)-compatible tools | `AGENTS.md` | Read directly |

**Do not duplicate or fork rules into per-agent files.** Update `AGENTS.md` only.

---

## Repository Layout

```
.
├── AGENTS.md              # Canonical tech-stack & style preferences — start here
├── KNOWLEDGE.md           # Official AI/MCP entry points for stack components
├── skills/                # Operational know-how (TS, Tailwind, Prisma, Docker, ...)
├── CLAUDE.md              # Claude Code entry point (includes AGENTS.md)
├── .mcp.json              # Project-scoped MCP servers (auto-loaded by Claude Code)
├── README.md              # This file
└── .claude/               # Claude Code-specific extras (optional for other agents)
    └── agents/            # Subagent definitions
        ├── frontend-specialist.md
        ├── backend-specialist.md
        ├── database-specialist.md
        └── code-reviewer.md
```

`.claude/agents/` is a Claude Code convention. Other agents can read these files as plain-Markdown role descriptions.

**Workflows are not bundled.** Planning, debugging, testing, etc. come from each agent's own commands (e.g. Claude Code's built-in `/plan`) or from skills installed separately. This repo only describes *what* stack and conventions to use — not *how* to drive your workflow.

---

## Bootstrap Into a New Project

There is **no install script**. Copy the files manually so you understand what lands where.

```bash
# From the project where you want these rules to apply:
PROJECT_DIR="$(pwd)"
TMP_DIR="$(mktemp -d)"

git clone --depth 1 git@github.com:wastemobile/myFullStack.git "$TMP_DIR/fullStack"

cp "$TMP_DIR/fullStack/AGENTS.md"    "$PROJECT_DIR/AGENTS.md"
cp "$TMP_DIR/fullStack/KNOWLEDGE.md" "$PROJECT_DIR/KNOWLEDGE.md"
cp "$TMP_DIR/fullStack/CLAUDE.md"    "$PROJECT_DIR/CLAUDE.md"
cp "$TMP_DIR/fullStack/.mcp.json"    "$PROJECT_DIR/.mcp.json"
cp -r "$TMP_DIR/fullStack/skills"    "$PROJECT_DIR/skills"
cp -r "$TMP_DIR/fullStack/.claude"   "$PROJECT_DIR/.claude"

rm -rf "$TMP_DIR"
```

Then commit:

```bash
git add AGENTS.md KNOWLEDGE.md CLAUDE.md .mcp.json skills/ .claude/
git commit -m "chore: adopt Full Stack HQ agent rules"
```

### Add `.gitignore` entry

`.claude/settings.local.json` is per-machine permission state and should not be committed:

```
.claude/settings.local.json
```

### Verify

Open a new agent session and ask it to **summarize the rules in three bullet points**. A correctly configured agent should mention permission-first workflow, the Astro/Svelte/SQLite stack, and approval keywords (`PLAN APPROVED`, `IMPLEMENTATION APPROVED`, `PROCEED`, `DO IT`).

For Claude Code, also check the MCP server loaded:

```
/mcp
```

You should see `svelte` and `astro-docs` connected. Approve the prompt to trust the project-scoped servers on first run.

For agents other than Claude Code (Codex, OpenCode, Hermes), see [`KNOWLEDGE.md`](./KNOWLEDGE.md#equivalent-for-other-agents) for the equivalent MCP install command in their config format.

---

## Personal Local Shortcut (author's setup, not shipped)

The author keeps a `/use-mystack` Claude Code skill that installs this repo's contents into any project. **Not part of this repo** — the skill and the template both live in `$HOME`. To replicate:

```bash
# 1. Template directory (clean copy of this repo, no .git / README / local state)
mkdir -p ~/.claude/templates/fullStack
rsync -a --delete \
  --exclude='README.md' --exclude='.git/' --exclude='.claude/settings.local.json' \
  ~/projects/myFullStack/ ~/.claude/templates/fullStack/

# 2. Skill at ~/.claude/commands/use-mystack.md that orchestrates the install.
#    All logic lives in the skill — no shell wrapper. It reads the template,
#    detects existing files in $PWD, and either copies fresh or smart-merges:
#      - AGENTS.md (existing) → appends a delimited stack-preferences block
#      - CLAUDE.md (existing) → ensures @AGENTS.md is referenced
#      - skills/, agents/, .mcp.json → rsync --ignore-existing
```

Run `/use-mystack` in any project — empty or existing. The append uses a
`<!-- BEGIN: full-stack-hq stack preferences -->` marker so re-running is a
no-op (idempotent). Pass `--refresh` to update the marked section, `--dry-run`
to preview.

**Re-sync after `git pull` of this repo** — re-run step 1's `rsync`. The
`--delete` flag is mandatory: without it, files removed upstream would linger
in the local template and keep getting installed into new projects.

---

## Quickstart: Starting a New Project

After bootstrap above, the config files are present but **nothing is scaffolded yet**. To kick off:

1. Open the directory in your agent (`claude`, `codex`, `opencode`, ...). It will auto-load `AGENTS.md` (and `CLAUDE.md → @AGENTS.md` for Claude Code). For Claude Code, approve the project-scoped MCP prompt on first run.

2. **Paste this as your first message** (agent-agnostic):

   > I want to build **[一句話描述, e.g. a personal expense tracker for myself, single user, local only]**. Please follow this repo's stack baseline.
   >
   > First, output your Session Start Check per AGENTS.md §0. Then propose a scaffolding plan: directory structure, init commands (`astro create`, `nest new`, `prisma init`, etc.), and any deviations from the baseline you'd recommend for this use case (e.g. SQLite vs PostgreSQL based on AGENTS.md §3 criteria). Wait for `PLAN APPROVED` before running anything.

3. The agent should respond with the `[Session Start Check]` block, then a scaffolding plan. Review, adjust, and reply `PLAN APPROVED` when satisfied — only then does it run init commands.

4. From this point on, every feature follows the same loop: describe → `[Session Start Check]` (if it's a fresh session) → planning step (use your agent's own `/plan` command or skill, or just propose a plan conversationally) → `PLAN APPROVED` → implementation → review. Single-file edits ≤ 30 lines can go straight to `IMPLEMENTATION APPROVED`.

### Why this works

- **AGENTS.md §0** forces the agent to declare its understanding before acting — catches stack-mismatch and skipped-skill problems early.
- **AGENTS.md §1 Permission-First** prevents the agent from leaping into multi-file scaffolding off a one-line request without an explicit approval keyword.
- **`.mcp.json`** auto-connects Svelte/Astro live docs so the agent isn't guessing from training memory.

If the agent skips the Session Start Check or starts writing without `PLAN APPROVED`, that's a regression — re-prompt with: *"Please follow AGENTS.md §0 and §1 strictly."*

---

## Customizing

- **Different stack?** Edit `AGENTS.md` §3 (Tech Stack) and §4 (Code Style), then refresh `KNOWLEDGE.md` with the new components' official AI entry points and replace/remove affected files in `skills/`.
- **Want more or fewer subagents?** Add/remove files in `.claude/agents/`. The `AGENTS.md` §2 table should reflect what exists.
- **Need a new operational skill?** Add a file to `skills/` with the YAML frontmatter (`name`, `description`) and list it in `AGENTS.md` §11.
- **Want slash commands or workflow automation?** Install them via your agent's own mechanism (Claude Code skills/commands, Codex prompts, etc.) — this repo deliberately stays workflow-agnostic so the same rules ship to every agent.
- **New official MCP / Skill / Subagent appears upstream?** Add it to `KNOWLEDGE.md` and bump the "Last verified" date.

Sources of truth:
- `AGENTS.md` — rules
- `KNOWLEDGE.md` — external AI integrations
- `skills/` — operational know-how (tools / libraries / languages)

---

## License

Inherits the spirit of the upstream MIT license. Use freely.
