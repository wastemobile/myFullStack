---
name: tailwind-patterns
description: Tailwind CSS v4 patterns — utility-first composition, design tokens via @theme, responsive + dark mode, common component recipes (button / card / form / skeleton). Use when styling Svelte / Astro components or reviewing CSS.
---

# Tailwind Patterns

## Core Approach

- **Utility-first** — compose classes, do not write custom CSS unless a utility truly cannot express it
- **Extract Svelte components, not classes** — never use `@apply` to build button/card variants; make a `<Button>` component instead
- **Tokens via `@theme`** (v4) — CSS variables drive the system; reference via utility names

## Component Variant Pattern (Svelte 5)

```svelte
<!-- src/components/Button.svelte -->
<script lang="ts">
  type Variant = 'primary' | 'secondary' | 'danger' | 'ghost'
  type Size = 'sm' | 'md' | 'lg'

  type Props = {
    variant?: Variant
    size?: Size
    children: import('svelte').Snippet
    onclick?: (e: MouseEvent) => void
  }

  let { variant = 'primary', size = 'md', children, onclick }: Props = $props()

  const variants: Record<Variant, string> = {
    primary:   'bg-blue-600 hover:bg-blue-700 text-white',
    secondary: 'bg-gray-100 hover:bg-gray-200 text-gray-900',
    danger:    'bg-red-600  hover:bg-red-700  text-white',
    ghost:     'hover:bg-gray-100 text-gray-700',
  }

  const sizes: Record<Size, string> = {
    sm: 'px-3 py-1.5 text-sm',
    md: 'px-4 py-2',
    lg: 'px-6 py-3 text-lg',
  }
</script>

<button
  class="{variants[variant]} {sizes[size]} rounded-lg font-medium transition-colors"
  {onclick}
>
  {@render children()}
</button>
```

## Responsive Design (mobile-first)

```svelte
<div class="
  flex flex-col            // mobile: stack
  md:flex-row              // tablet: row
  lg:grid lg:grid-cols-3   // desktop: 3 columns
  gap-4
">
  …
</div>
```

## Dark Mode

```svelte
<div class="bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100">
  <p class="text-gray-600 dark:text-gray-400">Secondary text</p>
</div>
```

## Design Tokens (Tailwind v4)

```css
/* src/app.css */
@import "tailwindcss";

@theme {
  --color-primary: oklch(0.6 0.2 250);
  --color-primary-foreground: oklch(1 0 0);
  --spacing-page: 1.5rem;
  --radius-card: 0.75rem;
}
```

```svelte
<!-- consume tokens directly as utilities -->
<div class="bg-primary text-primary-foreground p-page rounded-card">…</div>
```

## Common Recipes

### Card

```svelte
<div class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-800 dark:bg-gray-900">
  …
</div>
```

### Form Input

```svelte
<input
  type="email"
  class="w-full rounded-lg border border-gray-300 bg-white px-4 py-2.5 text-sm
         focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20
         dark:border-gray-700 dark:bg-gray-900"
/>
```

### Skeleton Loader

```svelte
<div class="animate-pulse rounded-lg bg-gray-200 dark:bg-gray-700 h-4 w-3/4" />
```

### Stacked Inputs with Labels

```svelte
<label class="block">
  <span class="block mb-1 text-sm font-medium text-gray-700 dark:text-gray-300">Email</span>
  <input type="email" class="w-full rounded-lg border border-gray-300 px-3 py-2 ..." />
</label>
```

## Class Composition with `clsx`-style helpers

When variants get conditional, prefer a tiny helper over template-string juggling:

```svelte
<script lang="ts">
  const cx = (...c: (string | false | undefined)[]) => c.filter(Boolean).join(' ')

  let { active = false } = $props()
</script>

<div class={cx(
  'rounded-lg px-4 py-2 transition-colors',
  active ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-700',
)}>…</div>
```

## Forbidden Patterns

```svelte
<!-- ❌ @apply for component styling — extract a Svelte component instead -->
<style>
  .btn { @apply px-4 py-2 bg-blue-600; }
</style>

<!-- ❌ Arbitrary value when a token / scale value exists -->
<div class="text-[#3b82f6]"></div>          <!-- use text-blue-500 -->
<div class="mt-[13px]"></div>                <!-- use mt-3 / mt-3.5 -->

<!-- ❌ Inline style overrides -->
<div style="color: blue" class="…"></div>

<!-- ❌ client:load on a presentational island just to apply a class -->
<Card client:load />                          <!-- omit the directive -->
```
