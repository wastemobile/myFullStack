---
name: prisma-workflow
description: Prisma schema design, migration workflow, query patterns, transactions, and engine-portability rules for SQLite + PostgreSQL. Use when working with Prisma schemas, migrations, or queries.
---

# Prisma Workflow

## Engine-Portable Schema

Default to types that work on **both SQLite and PostgreSQL** so projects can migrate engines later (see [`AGENTS.md`](../AGENTS.md) §3 for selection criteria).

```prisma
// schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "sqlite"                  // or "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        String   @id @default(cuid())
  email     String   @unique
  name      String?
  role      Role     @default(USER)
  posts     Post[]
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@index([email])
}

model Post {
  id        String   @id @default(cuid())
  title     String
  content   String?
  published Boolean  @default(false)
  author    User     @relation(fields: [authorId], references: [id], onDelete: Cascade)
  authorId  String

  @@index([authorId])
}

enum Role {
  USER
  ADMIN
}
```

### PG-only types — avoid if SQLite is in scope

| Type / feature | Works on SQLite? | Notes |
|---|---|---|
| `String`, `Int`, `Boolean`, `DateTime`, `Float`, `Bytes` | ✅ | Safe |
| `BigInt` | ✅ | Stored as INTEGER |
| `Decimal` | ✅ | Stored as DECIMAL text |
| `Json` | ❌ | PG only — store as `String` and parse if portability matters |
| `String[]` / scalar arrays | ❌ | PG only — model as a related table |
| `@db.Citext`, `@db.JsonB` | ❌ | PG-specific native types |
| `pgvector`, `pg_trgm` extensions | ❌ | PG only — defer until PG commitment |

When committing to PostgreSQL, switch `provider = "postgresql"` and re-run `prisma migrate dev` to pick up PG-native types.

## Migration Workflow

```bash
# 1. Edit schema.prisma
# 2. Generate + apply migration (development)
npx prisma migrate dev --name descriptive_name

# 3. Review the generated SQL in prisma/migrations/<timestamp>_<name>/
# 4. Apply in production (no prompts, no schema drift checks)
npx prisma migrate deploy
```

### Good migration names

```bash
npx prisma migrate dev --name add_user_role
npx prisma migrate dev --name create_posts_table
npx prisma migrate dev --name add_index_on_email
```

### Resetting (dev only)

```bash
npx prisma migrate reset       # drops the DB, replays migrations, runs seed
```

For SQLite this just deletes the `.db` file. For PostgreSQL it drops and recreates the database — **never run in production**.

## Seeding

```typescript
// prisma/seed.ts
import { PrismaClient } from '@prisma/client'
const prisma = new PrismaClient()

async function main() {
  await prisma.user.upsert({
    where: { email: 'admin@example.com' },
    update: {},
    create: { email: 'admin@example.com', role: 'ADMIN' },
  })
}

main().finally(() => prisma.$disconnect())
```

```json
// package.json
"prisma": { "seed": "tsx prisma/seed.ts" }
```

```bash
npx prisma db seed
```

## Query Patterns

### Select specific fields

```typescript
const user = await prisma.user.findUnique({
  where: { id },
  select: { id: true, email: true, name: true },
})
```

### Include relations

```typescript
const user = await prisma.user.findUnique({
  where: { id },
  include: { posts: { where: { published: true } } },
})
```

### Pagination (offset)

```typescript
const users = await prisma.user.findMany({
  skip: (page - 1) * limit,
  take: limit,
  orderBy: { createdAt: 'desc' },
})
```

### Pagination (cursor — preferred for large tables)

```typescript
const users = await prisma.user.findMany({
  take: limit,
  ...(cursor && { skip: 1, cursor: { id: cursor } }),
  orderBy: { id: 'asc' },
})
```

### Transactions

```typescript
await prisma.$transaction([
  prisma.user.update({ where: { id }, data: { balance: { decrement: 100 } } }),
  prisma.order.create({ data: { userId: id, amount: 100 } }),
])
```

For conditional logic inside the transaction, use the interactive form:

```typescript
await prisma.$transaction(async (tx) => {
  const user = await tx.user.findUnique({ where: { id } })
  if (!user || user.balance < 100) throw new Error('insufficient funds')
  await tx.user.update({ where: { id }, data: { balance: { decrement: 100 } } })
  await tx.order.create({ data: { userId: id, amount: 100 } })
})
```

### Batch insert

```typescript
await prisma.user.createMany({
  data: users,
  skipDuplicates: true,    // ⚠ Not supported on SQLite — leave off or guard
})
```

## SQLite-Specific Notes

- Single-writer constraint — enable WAL for higher concurrency:
  ```typescript
  await prisma.$executeRawUnsafe('PRAGMA journal_mode = WAL')
  ```
- `createMany({ skipDuplicates: true })` is **not supported** on SQLite; use upsert or guard with `try/catch`.
- Backups = copy the `.db` file while the app is quiesced (or use `VACUUM INTO 'backup.db'`).

## NestJS Integration

```typescript
@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit {
  async onModuleInit() {
    await this.$connect()
  }
}
```

## Performance Tips

- Always index foreign keys (`@@index([userId])`)
- Use `select` to fetch only needed fields
- Cursor pagination on tables > ~10k rows
- Batch with `createMany` (mind the SQLite caveat above)
- Use `$transaction` for related writes — avoids partial state
