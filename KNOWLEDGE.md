# KNOWLEDGE.md — Official AI Entry Points

> Curated list of **official** AI / MCP / agent resources for every major piece of the stack defined in [`AGENTS.md`](./AGENTS.md) §3.
>
> "Official" = published or maintained by the project / vendor itself. Third-party MCP servers and community llms.txt projects are intentionally excluded — they exist for almost everything, but quality and longevity vary.
>
> Last verified: **2026-05**. URLs and capabilities change; re-check before relying.

---

## How to use this file

1. When working on a stack component, follow the entry-point URL to find the **canonical** AI integration (usually an MCP server).
2. Connect your agent to the MCP server with the install command shown. Most accept the `claude mcp add ...` form; equivalent commands exist for Codex, OpenCode, and other agents.
3. If a component is listed as **No official entry**, fall back to the project's regular docs. Do not silently adopt third-party MCP servers — vet them first.

---

## Frontend

### Svelte 5

- **Entry**: <https://svelte.dev/docs/ai/overview>
- **Offers**: MCP server, Instructions (AGENTS.md-style preamble), Skills, Subagents, llms.txt — the most complete official AI package in the stack.
- **Subpages**:
  - MCP: <https://svelte.dev/docs/ai/mcp>
  - Instructions: <https://svelte.dev/docs/ai/instructions>
  - Skills: <https://svelte.dev/docs/ai/skills>
  - Subagents: <https://svelte.dev/docs/ai/subagent>
  - Claude Code plugin: <https://svelte.dev/docs/ai/claude-plugin>
- **Why it matters**: best-in-class — Svelte ships every layer (MCP for live docs, Skills for best practices, Subagents for parallel atomic ops).

#### Pre-configured in this repo

`.mcp.json` at the repo root already declares the remote Svelte MCP server. Claude Code picks it up automatically on first session in this directory — no command needed. Other agents need their own equivalent (below).

#### Install options (if you need to configure manually)

**Remote MCP (HTTP)** — recommended baseline, what `.mcp.json` uses:
```bash
# Claude Code
claude mcp add -t http -s project svelte https://mcp.svelte.dev/mcp
```

**Local MCP (stdio)** — runs the server as a local Node process; works offline:
```bash
# Claude Code
claude mcp add -t stdio -s project svelte -- npx -y @sveltejs/mcp
```

**Claude Code plugin** — richest path: MCP server + Skills + a dedicated Svelte editing subagent in one install. Recommended if you're authoring Svelte heavily:
```
/plugin marketplace add sveltejs/ai-tools
/plugin install svelte
```
(Per-user action; cannot be committed to the repo.)

#### Equivalent for other agents

Most MCP-aware agents accept the same HTTP endpoint via their own config:

| Agent | How to add |
|---|---|
| OpenAI Codex CLI | Add to Codex MCP config: `{ "svelte": { "url": "https://mcp.svelte.dev/mcp" } }` |
| OpenCode (sst) | Add to `opencode.json` under `mcp.servers` with `type: "http"`, same URL |
| Hermes Agent | Same pattern — point its MCP config at `https://mcp.svelte.dev/mcp` |

For the local stdio variant, swap the URL for a command spawning `npx -y @sveltejs/mcp` in the agent's config syntax.

### Astro 5

- **Entry**: <https://docs.astro.build/en/guides/build-with-ai/>
- **MCP server**: `https://mcp.docs.astro.build/mcp`
- **Offers**: hosted MCP server (kapa.ai-backed) for real-time doc access.
- **Note**: Astro removed its `llms.txt` in early 2026 — MCP is the supported path now.

#### Pre-configured in this repo

`.mcp.json` includes `astro-docs` alongside `svelte`. Claude Code auto-loads both; approve on first run.

#### Install options (if you need to configure manually)

```bash
# Claude Code
claude mcp add --transport http astro-docs https://mcp.docs.astro.build/mcp
```

For other agents, point their MCP config at the same URL with HTTP transport:

| Agent | Config snippet |
|---|---|
| OpenAI Codex CLI | `{ "astro-docs": { "url": "https://mcp.docs.astro.build/mcp" } }` |
| OpenCode (sst) | `mcp.servers.astro-docs` with `type: "http"`, same URL |
| Hermes Agent | Same pattern — HTTP transport, same URL |

### Tailwind CSS v4

- **Entry**: No official MCP / llms.txt as of 2026-05.
- **Status**: actively requested — see [tailwindlabs/tailwindcss#18256](https://github.com/tailwindlabs/tailwindcss/discussions/18256) and [#14677](https://github.com/tailwindlabs/tailwindcss/discussions/14677).
- **Workaround**: rely on the model's training + Tailwind's normal docs; avoid third-party MCP servers unless you've reviewed the source.
- **In-repo baseline**: [`skills/tailwind-patterns.md`](./skills/tailwind-patterns.md) — Svelte 5 component variant patterns, v4 `@theme` tokens, dark mode, common recipes.

### TypeScript 5+

- **Entry**: No official llms.txt or MCP from Microsoft for the TypeScript language itself.
- **Workaround**: TypeScript is well-represented in model training; for niche features, consult <https://www.typescriptlang.org/docs/>.
- **In-repo baseline**: [`skills/typescript-patterns.md`](./skills/typescript-patterns.md) — generics, utility types, discriminated unions, type guards.

---

## Backend

### NestJS

- **Entry**: No official AI integration as of 2026-05.
- **Status**: llms.txt proposal open at [nestjs/docs.nestjs.com#3282](https://github.com/nestjs/docs.nestjs.com/issues/3282).
- **Related** (for *building* MCP servers inside NestJS apps, not consuming docs): [`@rekog/mcp-nest`](https://github.com/rekog-labs/MCP-Nest) — community, but the de-facto choice.
- **In-repo baseline**: [`skills/nestjs-patterns.md`](./skills/nestjs-patterns.md) — module structure, DTOs + validation, services, controllers, guards, custom decorators.

### Node.js 24+

- **Entry**: No official MCP from the Node.js project. llms.txt proposal open at [nodejs/doc-kit#226](https://github.com/nodejs/doc-kit/issues/226).
- **Workaround**: official API docs at <https://nodejs.org/api/> are well-structured Markdown and digest cleanly into context.

### BullMQ

- **Entry**: No official AI integration.
- **Workaround**: docs at <https://docs.bullmq.io/>.

### Redis

- **Entry**: <https://redis.io/docs/latest/integrate/redis-mcp/>
- **Repo**: <https://github.com/redis/mcp-redis>
- **Offers**: official MCP server — natural-language interface for hashes, lists, sets, sorted sets, streams; lets agents read/write/query Redis directly.
- **Use case**: only wire this up if the agent *needs* to manipulate live Redis data. For just understanding Redis APIs, this is overkill.

---

## Database

### Prisma 6+

- **Entry**: <https://www.prisma.io/docs/ai>
- **MCP docs**: <https://www.prisma.io/docs/ai/tools/mcp-server>
- **Repo**: <https://github.com/prisma/mcp>
- **llms.txt**: <https://www.prisma.io/docs/llms.txt>
- **Offers**: official MCP server. Can provision Prisma Postgres instances, run migrations, execute SQL, manage backups via natural language. Works with Claude, Codex, Cursor, Warp, ChatGPT.
- **Caveat**: most powerful when using Prisma Postgres; local SQLite workflows mostly use the standard `prisma` CLI.
- **In-repo baseline**: [`skills/prisma-workflow.md`](./skills/prisma-workflow.md) — engine-portable schema, migration commands, query/transaction patterns, SQLite-specific caveats (e.g. `skipDuplicates` unsupported, WAL mode).

### SQLite 3

- **Entry**: Anthropic's reference SQLite MCP server is **archived** (moved to [`modelcontextprotocol/servers-archived`](https://github.com/modelcontextprotocol/servers-archived/tree/main/src/sqlite) in May 2025; a SQL-injection issue was left unpatched).
- **Status**: No actively-maintained official MCP for SQLite as of 2026-05.
- **Workaround**: use Prisma's MCP for schema/migrations; for read-only inspection, accept the trade-offs of the archived server or skip MCP entirely.

### PostgreSQL 16+

- **Entry**: Reference implementation from [`modelcontextprotocol/servers`](https://github.com/modelcontextprotocol/servers) (the same status concerns as SQLite apply — verify it's still active before adopting).
- **Examples directory**: <https://modelcontextprotocol.io/examples>
- **Read-only by default**: schema inspection + read-only queries.
- **For Prisma Postgres**: prefer the Prisma MCP above — it understands your schema.

---

## Testing

### Playwright

- **Entry**: <https://playwright.dev/docs/getting-started-mcp>
- **Repo**: <https://github.com/microsoft/playwright-mcp>
- **Offers**: official MCP server from Microsoft. Gives agents a live browser session with structured accessibility snapshots (not screenshots) — clicks, types, navigates, captures DOM.
- **Use case**: end-to-end test authoring and debugging; visual regression flows.

### Vitest

- **Entry**: No official MCP from the Vitest project.
- **Workaround**: docs at <https://vitest.dev/>.

### Jest

- **Entry**: No official MCP from the Jest project.
- **Workaround**: docs at <https://jestjs.io/>.

---

## Infrastructure

### Docker

- **Entry**: <https://docs.docker.com/ai/mcp-catalog-and-toolkit/>
- **Toolkit guide**: <https://docs.docker.com/ai/mcp-catalog-and-toolkit/toolkit/>
- **Get started**: <https://docs.docker.com/ai/mcp-catalog-and-toolkit/get-started/>
- **Offers**: Docker MCP Toolkit + Catalog — curated, signed MCP server images you can spin up via Docker Desktop, plus an MCP Gateway for orchestrating servers.
- **Use case**: running MCP servers safely (sandboxed in containers) and exposing them to multiple agents through one gateway.
- **In-repo baseline**: [`skills/docker-patterns.md`](./skills/docker-patterns.md) — multi-stage Dockerfiles for Astro + NestJS, docker-compose for SQLite/Postgres + Redis, Caddy 2 reverse proxy with automatic HTTPS.

### Caddy 2

- **Entry**: No official AI integration as of 2026-05.
- **Workaround**: docs at <https://caddyserver.com/docs/>.

### Rocky Linux / Ubuntu

- **Entry**: No official AI integration. Standard distro docs apply.

---

## Aggregated MCP Tooling

Worth knowing when you need to manage many of the above at once:

- **Docker MCP Gateway** (above) — single proxy in front of many MCP servers.
- **MCP reference servers** — <https://modelcontextprotocol.io/examples> (reference implementations; check archive status before adopting).

---

## Quick Adoption Order

If starting fresh with this stack and you want maximum agent leverage with minimum setup:

1. **Svelte MCP + Skills** — biggest win, fully official, multi-layer.
2. **Astro MCP** — one command, hosted, current docs.
3. **Prisma MCP** — only if managing Prisma Postgres.
4. **Playwright MCP** — once you're writing E2E tests.
5. **Docker MCP Toolkit** — if you end up running multiple MCP servers locally.
6. **Redis MCP** — only when the agent genuinely needs to touch Redis data.

Skip the rest until they ship official support — third-party MCPs add maintenance and security surface without clear ownership.
