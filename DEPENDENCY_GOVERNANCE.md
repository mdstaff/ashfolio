# Dependency Governance Policy

## Quick Reference for Agents

### ✅ Pre-Approved Dependencies

Use immediately without approval:

- Phoenix ecosystem (Phoenix 1.8.x, LiveView 1.1.x, Ecto)
- Ash framework and extensions
- Testing: ExUnit, Floki, Mox, Meck
- Business: Decimal, HTTPoison, Finch
- Development tools: Igniter (for Phoenix migrations), Credo
- Custom testing tools: Performance formatters, enhanced failure reporting

### ⚠️ Requires Review

Browser testing, new external services, runtime dependencies

### 🚫 Prohibited

Deprecated packages, cloud-dependent services, complex system dependencies

## Before Using Any Dependency

1. Check mix.exs first: `grep dependency_name mix.exs`
2. Verify compilation: `mix compile`
3. Implement fallbacks: Graceful degradation if dependency missing
4. Test thoroughly: Ensure tests pass with and without dependency

## Browser Testing Decision

APPROVED: Add Wallaby for critical JavaScript interactions only

- Complex UI components (autocomplete, dropdowns)
- Accessibility testing
- Mobile responsiveness
- Critical user workflows

NOT for: Simple rendering, API tests, business logic

## Error Recovery Pattern

```elixir
if Code.ensure_loaded?(ExternalDep) do
  use ExternalDep
  # implementation
else
  @moduletag :skip
  # fallback or skip gracefully
end
```

## Proposal Process

For Tier 2 dependencies, create issue with:

- Package name and version
- Justification and alternatives considered
- Impact assessment (size, complexity, maintenance)
- Fallback strategy
- Test approach

## Testing Architecture

Use existing tag-based system with justfile automation:

- `:unit`, `:integration`, `:liveview`, `:performance` (test categories)
- `:ash_resources`, `:calculations` (architectural layers)
- `:fast`, `:slow` (performance characteristics)
- `:external_deps`, `:browser` (dependency types)

Justfile Commands (see docs/TESTING_STRATEGY.md):

- `just test` - Standard unit test suite
- `just test unit` - Fast unit tests only
- `just test integration` - Integration tests
- `just test performance` - Performance benchmarks
- `just ci unit|integration|e2e|performance` - CI/CD pipeline stages

Priority: Unit > LiveView > Browser tests

## Recent Dependency Changes

### August 2025 Updates

Phoenix LiveView 1.0 → 1.1.4

- Reason: Improved colocated hooks support, better component lifecycle management
- Migration tool: Used igniter for automated migration (`mix igniter.install phoenix_live_view`)
- Breaking changes: Layout architecture updates, @myself parameter handling improvements
- Impact: Enhanced LiveView component reliability, fixed duplicate ID issues
- Status: ✅ Successfully migrated, 125/128 tests passing

Phoenix 1.7 → 1.8.0

- Reason: Compatibility with LiveView 1.1, improved performance
- Migration: Manual upgrade with dependency review
- Breaking changes: Minor template and configuration changes
- Impact: Better LiveView integration, improved error handling
- Status: ✅ Successfully migrated

Igniter 0.6.27 (New)

- Reason: Automated Phoenix migration tooling
- Scope: Development and test environments only
- Purpose: Safe, automated dependency upgrades and code transformations
- Status: ✅ Added as dev dependency for future migrations

### Upgrade Decision Process

1. Security: Check for security vulnerabilities in current versions
2. Compatibility: Ensure new versions work with Ash Framework
3. Breaking Changes: Review changelogs and breaking change documentation
4. Migration Path: Use igniter when available, manual migration otherwise
5. Testing: Full test suite validation before committing changes
6. Rollback Plan: Document rollback steps and maintain working state

### Phoenix Ecosystem Version Policy

- Major versions: Require approval and impact assessment
- Minor versions: Pre-approved within same major version
- Patch versions: Auto-approve for security and bug fixes
- LiveView: Stay within 1-2 minor versions of latest stable
- Phoenix: Stay within latest stable major version (1.8.x currently)
