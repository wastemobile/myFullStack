---
name: create
description: Create new features, components, or modules from scratch. Use when building something new.
command: /create
---

# Create Workflow

## Precondition (Plan-Gate)

Before doing anything else, check whether the **Plan-Gate Rule** (AGENTS.md §1) is satisfied for this request:

- **Does this task create a new file OR modify more than 30 lines in a single existing file?**
  - **Yes** → there MUST be an approved `/plan` in this same session. If there isn't, **refuse**:
    > *"No approved plan in this session. Please run `/plan` first, or confirm this is a single-file ≤ 30-line edit eligible for `IMPLEMENTATION APPROVED`."*
  - **No** (single-file edit ≤ 30 lines) → bypass allowed; proceed with `IMPLEMENTATION APPROVED`.

Only after this check passes do you continue with the steps below.

## Purpose

Systematically create new features, components, or modules following best practices.

## Process

### Step 1: Requirements

- What exactly needs to be created?
- What are the inputs/outputs?
- What are the constraints?

### Step 2: Design

- Choose appropriate patterns
- Define interfaces/types
- Plan file structure

### Step 3: Implementation Plan

- List files to create
- Order by dependencies
- Identify checkpoints

### Step 4: Create

- Implement incrementally
- Follow coding standards
- Add types and documentation

### Step 5: Test

- Write relevant tests
- Verify functionality
- Check edge cases

### Step 6: Review

- Self-review code
- Check for improvements
- Ensure completeness

## Output Format

```markdown
## Creating: [Name]

### Requirements
- ...

### Design

**Type:** Component / Service / Module / API
**Location:** `src/...`

### Files to Create

1. `path/to/file1.ts` - [Purpose]
2. `path/to/file2.ts` - [Purpose]

### Implementation Plan

#### Step 1: [Description]
[Details]

[APPROVAL NEEDED]

#### Step 2: [Description]
...

### Checklist

- [ ] Types defined
- [ ] Implementation complete
- [ ] Tests written
- [ ] Documentation added
```

## When to Use

- New components
- New services/modules
- New API endpoints
- New features
