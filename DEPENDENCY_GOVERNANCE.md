# Dependency Governance Policy

## Quick Reference for Agents

### ✅ Pre-Approved Dependencies
Use immediately without approval:
- Phoenix ecosystem (Phoenix, LiveView, Ecto)
- Ash framework and extensions
- Testing: ExUnit, Floki, Mox, Meck
- Business: Decimal, HTTPoison, Finch

### ⚠️ Requires Review
Browser testing, new external services, runtime dependencies

### 🚫 Prohibited
Deprecated packages, cloud-dependent services, complex system dependencies

## Before Using Any Dependency

1. **Check mix.exs first**: `grep dependency_name mix.exs`
2. **Verify compilation**: `mix compile`
3. **Implement fallbacks**: Graceful degradation if dependency missing
4. **Test thoroughly**: Ensure tests pass with and without dependency

## Browser Testing Decision

**APPROVED**: Add Wallaby for critical JavaScript interactions only
- Complex UI components (autocomplete, dropdowns)
- Accessibility testing
- Mobile responsiveness
- Critical user workflows

**NOT for**: Simple rendering, API tests, business logic

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

Use existing tag-based system:
- `:ash_resources`, `:liveview`, `:calculations` (architectural layers)
- `:fast`, `:slow`, `:integration` (performance)
- `:external_deps`, `:browser` (dependency types)

Priority: Unit > LiveView > Browser tests