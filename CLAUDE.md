# CLAUDE.md | Development Guidelines

## Philosophy

### Core Beliefs

- Incremental progress over big bangs - Small changes that compile and pass tests
- Learning from existing code - Study and plan before implementing
- Pragmatic over dogmatic - Adapt to project reality
- Clear intent over clever code - Be boring and obvious

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

1. Understand - Study existing patterns in codebase
2. Test - Write test first (red)
3. Implement - Minimal code to pass (green)
4. Refactor - Clean up with tests passing
5. Commit - With clear message linking to plan

### 3. When Stuck (After 3 Attempts)

Maximum 3 attempts per issue, then STOP.

1. Document the problem:

   - What you tried
   - Specific error messages
   - Why you think it failed

2. Research existing solutions:

   - Find 2-3 similar implementations
   - Note different approaches used

3. Question assumptions:

   - Is this the right abstraction level?
   - Can this be split into smaller problems?
   - Is there a simpler approach entirely?

4. Consider alternatives:
   - Different library/framework feature?
   - Different architectural pattern?
   - Remove abstraction instead of adding?

## Technical Standards

### Architecture Principles

- Composition over inheritance - Use dependency injection
- Interfaces over singletons - Enable testing and flexibility
- Explicit over implicit - Clear data flow and dependencies
- Test-driven when possible - Never disable tests, fix them

### Code Quality

- Minimum requirements:

  - Compile successfully
  - Pass all existing tests
  - Include tests for new functionality
  - Follow project formatting/linting
  - Include proper documentation for public APIs

- Before committing:
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

1. Testability - Can I easily test this?
2. Readability - Will someone understand this in 6 months?
3. Consistency - Does this match project patterns?
4. Simplicity - Is this the simplest solution that works?
5. Reversibility - How hard to change later?

## Project Integration

### Learning the Codebase

- Find 3 similar features/components
- Identify common patterns and conventions
- Use same libraries/utilities when possible
- Follow existing test patterns

### Tooling

- Use project's existing build system (see @justfile)
- Use project's test framework and justfile commands (see @docs/TESTING_STRATEGY.md)

## Phoenix/HEEx Development Rules

### HEEx Template Variable Guidelines

CRITICAL: All data accessed in HEEx templates must be in `assigns` and prefixed with `@`.

#### ❌ NEVER DO THIS

```elixir
def render_component(assigns) do
  scenarios = [:pessimistic, :realistic, :optimistic]
  colors = ["#red", "#blue", "#green"]

  ~H"""
  <%= for {scenario, color} <- Enum.zip(scenarios, colors) do %>
    <div style={"color: #{color}"}><%= scenario %></div>
  <% end %>
  """
end
```

#### ✅ ALWAYS DO THIS

```elixir
def render_component(assigns) do
  scenarios = [:pessimistic, :realistic, :optimistic]
  colors = ["#red", "#blue", "#green"]

  assigns = assign(assigns, :scenario_data, Enum.zip(scenarios, colors))

  ~H"""
  <%= for {scenario, color} <- @scenario_data do %>
    <div style={"color: #{color}"}><%= scenario %></div>
  <% end %>
  """
end
```

### HEEx Template Rules

1. Variable Access: Only `@variable` syntax allowed in templates
2. No Local Variables: Never reference function-local variables in `~H`
3. Empty Templates: Use `~H"""<!-- content -->"""` not `~H""`
4. Assigns Map: All template data must flow through `assigns` parameter

### Pre-Development Checklist

Before creating any Phoenix component or LiveView:

- [ ] Plan all template variables to be passed via `assigns`
- [ ] Never use local variables directly in `~H` templates
- [ ] Test template rendering with `rendered_to_string/1`
- [ ] Verify compilation with `mix compile --warnings-as-errors`

### Frequent Warning Checks (Required)

MANDATORY: Run these checks frequently during development:

```bash
# Check for compilation warnings every 30 minutes
mix compile --warnings-as-errors

# Check for HEEx template issues specifically
grep -r "~H\"\"\"" lib/ --include="*.ex" | head -5

# Verify Code GPS can run (disabled templates break it)
mix code_gps --dry-run
```

When to Run Warning Checks:

- After implementing any HEEx template
- Before every commit
- After adding 50+ lines of code
- When switching between files/components
- At end of every development session

### Code Formatting and Style Issues

**IMPORTANT**: Always use `mix format` to automatically fix style issues instead of manually editing:

```bash
# Fix ALL whitespace and formatting issues automatically
mix format

# Format specific files
mix format path/to/file.ex

# This project uses Styler plugin which handles:
# - Trailing whitespace removal
# - Consistent indentation
# - Line ending normalization
# - Code organization and style consistency
```

**DO NOT** manually fix these Credo issues - let the formatter handle them:
- Trailing whitespace
- Line length (in most cases)
- Indentation issues
- Import/alias ordering

Run `mix format` BEFORE running `mix credo` to avoid seeing issues that can be auto-fixed.

### Additional HEEx Patterns (Validated)

The following patterns are also valid and commonly used:

1. **Helper Function Calls in Templates**: Direct function calls are acceptable
   ```elixir
   <span class={money_ratios_status_color(@status)}>
   ```

2. **Computed Assigns Pattern**: Pre-compute complex data before template
   ```elixir
   assigns = assign(assigns, :processed_data, process_calculation(assigns.raw_data))
   ```

3. **Attribute Spreading**: Use `{@rest}` for passing through attributes
   ```elixir
   <div {@rest}>
   ```

## Quality Gates

### Definition of Done

- [ ] Tests written and passing
- [ ] Code follows project conventions
- [ ] HEEx templates compile without warnings
- [ ] All template variables accessed via @assigns
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

DO NOT:

- Use `--no-verify` to bypass commit hooks
- Disable tests instead of fixing them
- Commit code that doesn't compile
- Make assumptions - verify with existing code

DO:

- Commit working code incrementally
- Update plan documentation as you go
- Learn from existing implementations
- Stop after 3 failed attempts and reassess

# AI Agent Instructions

## MANDATORY: Code GPS First

Before starting ANY development work, ALWAYS:

1. Run `mix code_gps` to generate latest codebase analysis
2. Read `.code-gps.yaml` to understand current architecture
3. Use the integration opportunities and patterns listed

The Code GPS manifest contains:

- LiveView detection (Note: Currently detects only direct :live_view usage, not all LiveView modules)
- Key components with usage counts and attributes
- Existing patterns to follow
- Specific integration opportunities with priorities

### Known Code GPS Limitations

- LiveView count may be undercounted (detects ~3 instead of actual ~20+)
- Focus on component patterns and test analysis which are accurate
- Use `find lib/ashfolio_web/live -name "*.ex"` for complete LiveView inventory

## Development Commands

```bash
# Generate Code GPS manifest (run first, always)
mix code_gps

# Run tests by category
just test        # Standard suite (excludes slow/performance)
just test unit   # Unit tests only (~230 tests, <1s each)
just test smoke  # Critical paths (~11 tests, <2s)
just test live   # LiveView tests (~36 tests, 5-15s)
just test perf   # Performance tests (~14 tests, 30-60s)
just test failed # Re-run failed tests

# Start development server
just dev         # Foreground mode
just dev bg      # Background mode
just server stop # Stop background server

# Code quality
mix format       # ALWAYS run before credo
mix credo        # Static analysis (non-blocking warnings)
just check       # Format + compile + credo + smoke tests
just fix         # Auto-fix common issues
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
