# Full Stack HQ — Claude Code Rules

> Global rules for Claude Code. These rules are always active across all projects.
> Optimized for: Astro · Svelte 5 · NestJS · TypeScript · Prisma · Tailwind CSS

---

## 1. Core Principles

### Permission-First Workflow

You are an amplifier, not an autopilot. Every action requires explicit approval.

**NEVER without approval:**
- Execute shell commands
- Create or delete files
- Modify schemas or migrations
- Install packages
- Push to remote
- Create branches

**The only valid approval keywords:**
```
PLAN APPROVED
IMPLEMENTATION APPROVED
PROCEED
DO IT
```

Any variation, implication, or partial approval = **NOT approved**.
When in doubt: *"Please confirm with PLAN APPROVED to proceed."*

### Thinking-First Engineering

Before writing a single line of code:
1. **Who** is the right specialist for this task?
2. **What** is the minimal, reversible change?
3. **How** does this fit the existing architecture?
4. **Why** is this the best approach?

Present your reasoning. Wait for approval. Then execute.

### Plan Mode Usage

For any task involving more than 2 files or 30 minutes of work:
- Enter Plan Mode automatically
- Break into phases with explicit `[APPROVAL NEEDED]` checkpoints
- Each phase must be independently reversible

---

## 2. Agent Roles

Use the appropriate specialist agent for each domain. Never use a generalist when a specialist exists.

| Agent | Trigger | Scope |
|-------|---------|-------|
| `frontend-specialist` | UI, components, pages, styles | Astro, Svelte 5, Tailwind |
| `backend-specialist` | APIs, services, controllers | NestJS, Node.js |
| `database-specialist` | Schema, migrations, queries | Prisma, SQLite, PostgreSQL |
| `code-reviewer` | Post-implementation review | Quality, security, patterns |

For anything outside these four (cross-cutting design, security audit, performance tuning, test strategy, devops) handle it inline in the main conversation — don't spin up another role.

**Invocation pattern:**
```
Use the database-specialist to design a schema for [feature].
```

---

## 3. Tech Stack

### Frontend
- **Framework**: Astro 5+ (Svelte islands for interactivity)
- **UI**: Svelte 5 with runes (`$state`, `$derived`, `$effect`, `$props`)
- **Language**: TypeScript 5+ (strict mode, `noUncheckedIndexedAccess: true`)
- **Styling**: Tailwind CSS v4
- **State**: component-local runes → Svelte stores (when shared across islands)
- **Forms**: Svelte + Zod (validation parsed inside `$derived`)

### Backend
- **Primary**: NestJS with TypeScript
- **Runtime**: Node.js 24+ (LTS)
- **Validation**: class-validator + class-transformer
- **Auth**: Passport.js + JWT (access + refresh token rotation)
- **Queue**: BullMQ (Redis-backed)
- **Cache**: Redis (ioredis)

### Database
- **ORM**: Prisma 6+
- **Migrations**: Prisma Migrate (never manual SQL unless reviewed)
- **Default by project size:**
  - **SQLite 3** — development & test always; production for **micro/small projects** (≤ ~100 active users, ≤ ~1 GB data, single-node deploy)
  - **PostgreSQL 16+** — production for anything larger, multi-node, or needing PG-only features
- **Schema portability**: if SQLite is in play for prod, avoid PG-only types (`Json`, `citext`, arrays, `pgvector`, `pg_trgm`). Only reach for them once committed to PostgreSQL.
- **When to migrate SQLite → PostgreSQL**: concurrent writers > 1, dataset > 1 GB, need for full-text/vector search, or horizontal scaling. Plan the migration before crossing the threshold, not after.

### Infrastructure
- **OS**: Rocky Linux / Ubuntu (LTS)
- **Containerization**: Docker — **prefer Docker Compose** for multi-service local + single-node prod
- **Reverse proxy / TLS**: Caddy 2 (automatic HTTPS)
- **CI**: GitHub Actions
- **Secrets**: Environment variables only — never in code

---

## 4. Code Style

### TypeScript

```typescript
// ✅ CORRECT
const getUserById = async (id: string): Promise<User | null> => {
  return db.user.findUnique({ where: { id } })
}

// ❌ WRONG — any, var, semicolons, double quotes
var getUser = async (id: any) => {
  return await db.user.findUnique({ where: { id } });
}
```

**Rules:**
- No semicolons
- Single quotes
- 2 spaces (no tabs)
- `const` over `let`, never `var`
- Arrow functions preferred
- Explicit return types on all functions
- No `any` — use `unknown` if truly dynamic
- Early returns over nested conditionals
- Barrel exports (`index.ts`) for public APIs

### Astro + Svelte 5

```astro
---
// ✅ src/pages/users.astro — server-rendered by default
import UserCard from '../components/UserCard.svelte'
import { getUsers } from '../lib/users'

const users = await getUsers()
---

<ul>
  {users.map((user) => (
    <li><UserCard user={user} client:visible /></li>
  ))}
</ul>
```

```svelte
<!-- ✅ src/components/UserCard.svelte — Svelte 5 runes -->
<script lang="ts">
  import type { User } from '../lib/types'

  type Props = { user: User, onSelect: (id: string) => void }
  let { user, onSelect }: Props = $props()

  let label = $derived(`Select ${user.name}`)
</script>

<button onclick={() => onSelect(user.id)} aria-label={label}>
  {user.name}
</button>
```

**Rules:**
- Svelte 5 **runes only** — `$state` / `$derived` / `$effect` / `$props`; never the legacy `export let` / reactive `$:` syntax in new code
- Type props with a `Props` type alias, destructured via `$props()`
- Default to Astro server rendering. Add `client:*` directives only on islands that genuinely need interactivity (`client:visible` > `client:load` when possible)
- Named exports only — **except** Astro pages (`src/pages/*.astro`) and layouts, which are file-routed
- No CSS-in-JS — Tailwind only; component-scoped `<style>` blocks allowed for one-off cases Tailwind can't express
- Colocate tests: `UserCard.svelte`, `UserCard.test.ts`

### NestJS

```typescript
// ✅ Module structure
@Module({
  imports: [TypeOrmModule.forFeature([User])],
  controllers: [UserController],
  providers: [UserService, UserRepository],
  exports: [UserService],
})
export class UserModule {}
```

**Rules:**
- One module per domain feature
- Controller → Service → Repository layering (no skipping layers)
- DTOs for all request/response shapes
- Guards for auth, Interceptors for logging/transform
- Never inject repositories directly into controllers

### Prisma

```prisma
// ✅ Always explicit field types, always have createdAt/updatedAt
model User {
  id        String   @id @default(cuid())
  email     String   @unique
  name      String?
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}
```

**Rules:**
- Schema changes require migration plan approval first
- Always run `prisma generate` after schema changes
- Use transactions (`$transaction`) for multi-table writes
- Never use `prisma.$queryRaw` without parameterization
- Soft deletes: add `deletedAt DateTime?` pattern

---

## 5. Git Conventions

### Commit Format (Conventional Commits)

```
type(scope): short description in imperative mood

[optional body]
[optional footer]
```

| Type | When |
|------|------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Restructure without behavior change |
| `perf` | Performance improvement |
| `test` | Tests only |
| `docs` | Documentation only |
| `chore` | Dependencies, tooling |
| `ci` | CI/CD changes |
| `style` | Formatting only |

**Examples:**
```
feat(auth): add JWT refresh token rotation
fix(api): handle null user in profile endpoint
refactor(users): extract UserRepository from UserService
```

### Branch Strategy

```
main          → production, protected, no direct push
dev           → integration branch
feature/<slug> → new features (branch from dev)
fix/<slug>     → bug fixes (branch from dev)
hotfix/<slug>  → urgent production fixes (branch from main)
```

**Agent rule**: Never create branches autonomously. Always propose and wait for approval.

---

## 6. Testing

### Frontend (Vitest + @testing-library/svelte)

```typescript
// ✅ Test behavior, not implementation
import { render, screen } from '@testing-library/svelte'
import userEvent from '@testing-library/user-event'
import LoginForm from './LoginForm.svelte'

it('shows error when email is invalid', async () => {
  render(LoginForm)
  await userEvent.type(screen.getByLabelText('Email'), 'notanemail')
  await userEvent.click(screen.getByRole('button', { name: /login/i }))
  expect(screen.getByText(/invalid email/i)).toBeInTheDocument()
})
```

### Backend (Jest)

```typescript
// ✅ Unit test with mocked dependencies
describe('UserService.create', () => {
  it('throws ConflictException when email exists', async () => {
    mockRepo.findByEmail.mockResolvedValue(existingUser)
    await expect(service.create(dto)).rejects.toThrow(ConflictException)
  })
})
```

### E2E (Playwright)

```typescript
// ✅ Critical user paths only
test('user can complete checkout', async ({ page }) => {
  await page.goto('/cart')
  await page.getByRole('button', { name: 'Checkout' }).click()
  await expect(page.getByText('Order confirmed')).toBeVisible()
})
```

**Philosophy:**
- Test behavior, not implementation
- 80% unit/integration, 20% E2E
- No 100% coverage obsession
- Test the things that break in production

---

## 7. Security

### Mandatory Checks Before Every Commit

- [ ] No hardcoded secrets (`grep -r "api_key\|password\|secret" src/`)
- [ ] All user inputs validated (Zod / class-validator)
- [ ] SQL queries parameterized (no string interpolation)
- [ ] Auth guards on all protected routes
- [ ] Rate limiting on public endpoints
- [ ] CORS configured correctly
- [ ] Error messages don't leak stack traces

### Forbidden Patterns

```typescript
// ❌ NEVER
const query = `SELECT * FROM users WHERE id = ${userId}` // SQL injection
process.env.SECRET_KEY = 'hardcoded'                      // hardcoded secret
app.use(cors({ origin: '*' }))                            // open CORS
console.log('User password:', password)                   // log sensitive data
```

---

## 8. Error Handling Protocol

When you encounter an error:

1. **Report** — What exactly failed?
2. **Analyze** — Root cause, not surface symptom
3. **Impact** — What does this break?
4. **Options** — 2-3 solution paths with trade-offs
5. **Wait** — Which approach should I take?

**Never auto-fix. Always get approval first.**

---

## 9. Claude Code Workflow Commands

Use these slash commands throughout the development workflow:

| Command | When to Use |
|---------|-------------|
| `/plan` | Before starting any feature |
| `/create` | Implementing approved plan |
| `/debug` | Stuck on a bug |
| `/test` | Writing or fixing tests |

---

## 10. Memory & Context

### What to Track in TodoWrite

For every multi-step task, maintain a todo list:
- Current phase and status
- Completed items (with ✅)
- Blocked items (with reason)
- Next action required

### Context Hygiene

- If a conversation exceeds 15 turns without a clear outcome → suggest `/compact` or new session
- If requirements shift mid-implementation → stop, re-plan, get approval
- If context becomes contradictory → ask for clarification, don't assume

---

## 11. Forbidden Patterns (All Languages)

```
❌ any type in TypeScript
❌ console.log in production code
❌ hardcoded secrets or API keys
❌ var keyword
❌ default exports (except Astro pages/layouts)
❌ CSS-in-JS libraries
❌ legacy Svelte syntax (`export let`, reactive `$:`) in new components — use runes
❌ `client:load` on every island (default to server-render; add `client:*` only when needed)
❌ relative imports crossing module boundaries (use path aliases)
❌ direct database access from controllers
❌ unbounded queries (always use pagination)
❌ missing error handling (never silent catch blocks)
❌ TODO comments without ticket reference
```

---

## 12. Quick Reference

| Action | Policy |
|--------|--------|
| Suggest code | ✅ Always (with reasoning) |
| Create files | ⚠️ Approval required |
| Run commands | ⚠️ Approval required |
| Delete files | ⚠️ Approval required |
| Create branches | ⚠️ Approval required |
| Install packages | ⚠️ Approval required |
| Schema migrations | ⚠️ Plan approval + implementation approval |
| Push to remote | ❌ Never autonomously |
| Deploy | ❌ Never autonomously |
| Modify CI/CD | ❌ Never autonomously |
| Access .env files | ❌ Read-only, never modify |
