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

If you are an AI coding agent and you've been pointed at this repository, **read [`AGENTS.md`](./AGENTS.md) first**. It is the canonical rule set.

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
├── AGENTS.md              # Canonical rules — start here
├── CLAUDE.md              # Claude Code entry point (includes AGENTS.md)
├── README.md              # This file
└── .claude/               # Claude Code-specific extras (optional for other agents)
    ├── agents/            # Subagent definitions
    │   ├── frontend-specialist.md
    │   ├── backend-specialist.md
    │   ├── database-specialist.md
    │   └── code-reviewer.md
    └── commands/          # Slash command workflows
        ├── plan.md
        ├── create.md
        ├── debug.md
        └── test.md
```

`.claude/agents/` and `.claude/commands/` are Claude Code conventions. Agents that don't recognize them can still follow the playbooks inside — each file is plain Markdown describing the role or workflow.

---

## Bootstrap Into a New Project

There is **no install script**. Copy the files manually so you understand what lands where.

```bash
# From the project where you want these rules to apply:
PROJECT_DIR="$(pwd)"
TMP_DIR="$(mktemp -d)"

git clone --depth 1 git@github.com:wastemobile/myFullStack.git "$TMP_DIR/fullStack"

cp "$TMP_DIR/fullStack/AGENTS.md"  "$PROJECT_DIR/AGENTS.md"
cp "$TMP_DIR/fullStack/CLAUDE.md"  "$PROJECT_DIR/CLAUDE.md"
cp -r "$TMP_DIR/fullStack/.claude" "$PROJECT_DIR/.claude"

rm -rf "$TMP_DIR"
```

Then commit:

```bash
git add AGENTS.md CLAUDE.md .claude/
git commit -m "chore: adopt Full Stack HQ agent rules"
```

### Add `.gitignore` entry

`.claude/settings.local.json` is per-machine permission state and should not be committed:

```
.claude/settings.local.json
```

### Verify

Open a new agent session and ask it to **summarize the rules in three bullet points**. A correctly configured agent should mention permission-first workflow, the Astro/Svelte/SQLite stack, and approval keywords (`PLAN APPROVED`, `IMPLEMENTATION APPROVED`, `PROCEED`, `DO IT`).

---

## Customizing

- **Different stack?** Edit `AGENTS.md` §3 (Tech Stack) and §4 (Code Style). All agents will pick up the change on next session.
- **Want more or fewer subagents?** Add/remove files in `.claude/agents/`. The `AGENTS.md` §2 table should reflect what exists.
- **Want more slash commands?** Add files in `.claude/commands/`. Update `AGENTS.md` §9.

Keep one source of truth: `AGENTS.md`.

---

## License

Inherits the spirit of the upstream MIT license. Use freely.
