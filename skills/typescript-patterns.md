---
name: typescript-patterns
description: TypeScript type system patterns — generics, utility types, discriminated unions, type guards, strict-mode practices. Use when writing or reviewing TypeScript anywhere in the stack.
---

# TypeScript Patterns

## Core Rules

- Strict mode always (`"strict": true`, `"noUncheckedIndexedAccess": true`)
- No `any` — use `unknown` for dynamic values
- Explicit return types on all exported functions
- `const` over `let`, never `var`

## Type Definitions

### Interfaces vs Types

```typescript
// Interface for objects/classes (extensible via declaration merging)
interface User {
  id: string
  email: string
  name: string
}

// Type for unions, primitives, computed shapes
type Status = 'active' | 'inactive' | 'pending'
type UserOrAdmin = User | Admin
type ReadonlyUser = Readonly<User>
```

### Generics

```typescript
type ApiResponse<T> = {
  data: T
  error: string | null
  status: number
}

type PaginatedResponse<T> = {
  items: T[]
  total: number
  page: number
  limit: number
}

const findById = <T extends { id: string }>(items: T[], id: string): T | undefined =>
  items.find(item => item.id === id)
```

## Utility Types

```typescript
type UserPreview  = Pick<User, 'id' | 'name'>
type PublicUser   = Omit<User, 'password' | 'salt'>
type UpdateUserDto = Partial<User>
type RequiredUser = Required<User>
type FrozenUser   = Readonly<User>
type ActiveStatus = Extract<Status, 'active' | 'pending'>
type UserMap      = Record<string, User>
```

## Discriminated Unions

```typescript
type Result<T> =
  | { success: true;  data: T }
  | { success: false; error: string }

const processUser = (id: string): Result<User> => {
  try {
    return { success: true, data: fetchUser(id) }
  } catch (e) {
    return { success: false, error: 'User not found' }
  }
}

const result = processUser('123')
if (result.success) {
  console.log(result.data.name)   // narrowed to User
} else {
  console.log(result.error)        // narrowed to string
}
```

## Type Guards

```typescript
// Custom type guard
const isUser = (value: unknown): value is User =>
  typeof value === 'object' &&
  value !== null &&
  'id' in value &&
  'email' in value

// Assertion function
const assertDefined = <T>(value: T | null | undefined): T => {
  if (value == null) throw new Error('Value is null or undefined')
  return value
}
```

## Async Patterns

```typescript
const fetchUser = async (id: string): Promise<User> => {
  const res = await fetch(`/api/users/${id}`)
  if (!res.ok) throw new Error('Failed to fetch user')
  return res.json() as Promise<User>
}

try {
  await fetchUser(id)
} catch (error) {
  if (error instanceof Error) {
    console.error(error.message)
  }
}
```

## Forbidden Patterns

```typescript
// ❌ Never
const data: any = fetchData()
function process(x) { return x }   // implicit any
const obj = {} as User              // unsafe assertion — verify shape instead
// @ts-ignore                       // suppress errors only with a comment + ticket
```
