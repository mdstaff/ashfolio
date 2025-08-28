# Phoenix LiveView Layout Architecture

## Overview

This document explains the correct layout configuration for Phoenix LiveView applications and documents a critical architectural issue we discovered during the Phoenix LiveView 1.1 upgrade.

## The Issue: Duplicate Layout Rendering

### Problem Discovered

When upgrading to Phoenix LiveView 1.1, we encountered widespread test failures due to duplicate ID errors. Phoenix LiveView 1.1 introduced stricter duplicate ID validation that exposed a fundamental architectural misconfiguration.

60+ test failures due to duplicate IDs in layout components (topbar, flash messages, navigation).

### Root Cause

The issue was in `lib/ashfolio_web.ex` where LiveViews were configured to use the `:root` layout:

```elixir
# ❌ INCORRECT CONFIGURATION
def live_view do
  quote do
    use Phoenix.LiveView,
      layout: {AshfolioWeb.Layouts, :root}  # WRONG!
  end
end
```

Combined with the router configuration:

```elixir
# This part is correct
plug :put_root_layout, html: {AshfolioWeb.Layouts, :root}
```

This caused the

1. Router applies `:root` layout as the outer shell
2. LiveView applies `:root` layout again as inner content
3. Result: Every ID appears twice (flash-group, mobile-menu, etc.)

## The Solution

### Correct Configuration

```elixir
#  CORRECT CONFIGURATION
# In lib/ashfolio_web.ex
def live_view do
  quote do
    use Phoenix.LiveView,
      layout: {AshfolioWeb.Layouts, :app}  # CORRECT!
  end
end

# In lib/ashfolio_web/router.ex (unchanged - this was correct)
plug :put_root_layout, html: {AshfolioWeb.Layouts, :root}
```

### Layout Architecture

```
Request → Router → LiveView → Response

┌─────────────────────────────────────────────┐
│ Router applies :root layout                 │
│ ┌─────────────────────────────────────────┐ │
│ │ Root Layout (:root)                     │ │
│ │ • <html>, <head>, <body>                │ │
│ │ • TopBar component                      │ │
│ │ • Flash components                      │ │
│ │ • Global navigation                     │ │
│ │ ┌─────────────────────────────────────┐ │ │
│ │ │ LiveView applies :app layout        │ │ │
│ │ │ App Layout (:app)                   │ │ │
│ │ │ • {@inner_content}                  │ │ │ ← LiveView content
│ │ └─────────────────────────────────────┘ │ │
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

## Layout Files

### Root Layout (`root.html.heex`)

Outer shell with complete HTML structure

- `<html>`, `<head>`, `<body>` tags
- CSS and JavaScript imports
- TopBar navigation component
- Flash message components
- Global application shell

- Complete HTML document structure
- Applied by router to all requests
- Contains `{@inner_content}` where app layout renders

### App Layout (`app.html.heex`)

Inner content wrapper for LiveViews

- Minimal structure
- Only `{@inner_content}` for LiveView content
- NO HTML structure (that's root layout's job)
- NO duplicate components

- Minimal wrapper
- Applied by LiveView configuration
- Renders inside root layout's `{@inner_content}`

## Phoenix Framework Patterns

### Standard Phoenix Layout Hierarchy

1.  Sets root layout with `put_root_layout`
2.  Sets inner layout (usually `:app`)
3.  Renders actual content

This creates a nesting pattern: `root → app → content`

### Why This Matters

- Shell vs content
- Different controllers can use different inner layouts
- Avoids duplicating shell components
- Prevents duplicate HTML IDs

## Impact of the Fix

### Before Fix

- 71+ failures due to duplicate IDs
- Potential DOM conflicts in production
- Strict validation errors

### After Fix

- 125/128 tests passing (97.7% success rate)
- No duplicate ID warnings
- Follows Phoenix conventions

## Prevention: Regression Tests

### Configuration Test

File: `test/ashfolio_web/layout_configuration_test.exs`

Verifies:

- LiveView uses `:app` layout (not `:root`)
- Layout files exist and have correct structure
- No architectural regression

### Integration Test

File: `test/ashfolio_web/layout_duplication_detection_test.exs`

Verifies:

- No duplicate IDs in rendered HTML
- Layout components appear exactly once
- All major routes render cleanly

## Best Practices

### DO

- Use `:root` layout for router configuration
- Use `:app` layout for LiveView configuration
- Keep app layout minimal (just `{@inner_content}`)
- Put shell components in root layout only
- Run regression tests after layout changes

### ❌ DON'T

- Configure LiveView to use `:root` layout
- Duplicate shell components in app layout
- Put HTML structure tags in app layout
- Ignore duplicate ID warnings from Phoenix LiveView 1.1+

## Key Insight

Phoenix LiveView 1.1's stricter duplicate ID validation is a feature, not a bug.

It helped us identify a fundamental architectural problem that was:

- Degrading user experience in production
- Creating potential DOM conflicts
- Violating Phoenix framework conventions
- Hidden from view until strict validation exposed it

This demonstrates the value of framework upgrades that include improved validation and error detection.
