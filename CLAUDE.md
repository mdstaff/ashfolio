# CLAUDE.md | Development Guidelines

## Philosophy

### Core Beliefs

- **Incremental progress over big bangs** - Small changes that compile and pass tests
- **Learning from existing code** - Study and plan before implementing
- **Pragmatic over dogmatic** - Adapt to project reality
- **Clear intent over clever code** - Be boring and obvious

### Simplicity Means

- Single responsibility per function/class
- Avoid premature abstractions
- No clever tricks - choose the boring solution
- If you need to explain it, it's too complex

## Process

### 1. Planning & Staging

Break complex work into 3-5 stages. Document in `IMPLEMENTATION_PLAN.md`:

```markdown
## Stage N: [Name]

[Specific deliverable]
[Testable outcomes]
[Specific test cases]
[Not Started|In Progress|Complete]
```

- Update status as you progress
- Remove file when all stages are done

### 2. Implementation Flow

1. **Understand** - Study existing patterns in codebase
2. **Test** - Write test first (red)
3. **Implement** - Minimal code to pass (green)
4. **Refactor** - Clean up with tests passing
5. **Commit** - With clear message linking to plan

### 3. When Stuck (After 3 Attempts)

Maximum 3 attempts per issue, then STOP.

1. **Document the problem**:
   - What you tried
   - Specific error messages
   - Why you think it failed

2. **Research existing solutions**:
   - Find 2-3 similar implementations
   - Note different approaches used

3. **Question assumptions**:
   - Is this the right abstraction level?
   - Can this be split into smaller problems?
   - Is there a simpler approach entirely?

4. **Consider alternatives**:
   - Different library/framework feature?
   - Different architectural pattern?
   - Remove abstraction instead of adding?

## Technical Standards

### Architecture Principles

- **Composition over inheritance** - Use dependency injection
- **Interfaces over singletons** - Enable testing and flexibility
- **Explicit over implicit** - Clear data flow and dependencies
- **Test-driven when possible** - Never disable tests, fix them

### Code Quality

- **Minimum requirements**:
  - Compile successfully
  - Pass all existing tests
  - Include tests for new functionality
  - Follow project formatting/linting
  - Include proper documentation for public APIs

- **Before committing**:
  - Run formatters/linters
  - Self-review changes
  - Ensure commit message explains "why"
  - Verify documentation follows style guide

### Error Handling

- Fail fast with descriptive messages
- Include context for debugging
- Handle errors at appropriate level
- Never silently swallow exceptions

## Decision Framework

When multiple valid approaches exist, choose based on:

1. **Testability** - Can I easily test this?
2. **Readability** - Will someone understand this in 6 months?
3. **Consistency** - Does this match project patterns?
4. **Simplicity** - Is this the simplest solution that works?
5. **Reversibility** - How hard to change later?

## Project Integration

### Learning the Codebase

- Find 3 similar features/components
- Identify common patterns and conventions
- Use same libraries/utilities when possible
- Follow existing test patterns

### Tooling

- Use project's existing build system (see @justfile)
- Use project's test framework and justfile commands (see @docs/TESTING_STRATEGY.md)

## Quality Gates

### Definition of Done

- [ ] Tests written and passing
- [ ] Code follows project conventions
- [ ] No linter/formatter warnings
- [ ] Documentation follows style guide (see docs/development/documentation-style-guide.md)
- [ ] Commit messages are clear
- [ ] Implementation matches plan
- [ ] No TODOs without issue numbers

### Test Guidelines

- Test behavior, not implementation
- One assertion per test when possible
- Clear test names describing scenario
- Use existing test utilities/helpers
- Tests should be deterministic
- Follow testing strategy and organization (see docs/TESTING_STRATEGY.md)

## Important Reminders

**DO NOT**:
- Use `--no-verify` to bypass commit hooks
- Disable tests instead of fixing them
- Commit code that doesn't compile
- Make assumptions - verify with existing code

**DO**:
- Commit working code incrementally
- Update plan documentation as you go
- Learn from existing implementations
- Stop after 3 failed attempts and reassess

# AI Agent Instructions

## MANDATORY: Code GPS First

**Before starting ANY development work, ALWAYS:**

1. Run `mix code_gps` to generate latest codebase analysis
2. Read `.code-gps.yaml` to understand current architecture
3. Use the integration opportunities and patterns listed

**The Code GPS manifest contains:**
- All LiveViews with events and subscriptions
- Key components with usage counts and attributes
- Existing patterns to follow
- Specific integration opportunities with priorities

## Development Commands

```bash
# Generate Code GPS manifest
mix code_gps

# Run tests
just test

# Start development server
just work

# Format and lint
mix format && mix credo
```

## Key Files to Reference

- `.code-gps.yaml` - Current codebase structure
- `IMPLEMENTATION_PLAN.md` - Active development stages
- `docs/TESTING_STRATEGY.md` - Test organization
- `justfile` - Available commands

## Phoenix/Elixir Patterns

This codebase uses:
- Phoenix LiveView for interactive UI
- Ash framework for domain logic
- Decimal for financial calculations
- Standard Phoenix components in `core_components.ex`
- PubSub for real-time updates

## Current Focus: v0.3.1

Building frontend dashboard widgets with:
- Expense tracking integration
- Net worth visualization
- Manual snapshot functionality
- Contex chart components

Always check the Code GPS for latest component patterns and integration points.