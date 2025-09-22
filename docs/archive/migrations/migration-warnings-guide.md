# Migration Generation Warnings Guide

## Overview

When running `mix ash_sqlite.generate_migrations`, it's common to see warnings while still achieving a successful migration generation. This guide explains what warnings are expected vs. concerning.

## Expected Warning Patterns

### 1. Domain Configuration Warnings

```
Domain Ashfolio.FinancialManagement is not present in config :ashfolio, ash_domains: [Ashfolio.Portfolio].
```

Expected during development
Add new domain to `config/config.exs`
Migration still generates successfully

### 2. Missing Relationship Field Warnings

```
invalid association `transactions` in schema: associated schema does not have field `category_id`
```

Expected during incremental development
Forward references to fields that will be added in subsequent tasks
Migration generates for current resource, relationship will be completed later

### 3. Atomic Action Warnings

```
`destroy_if_not_system` cannot be done atomically, because the changes cannot be done atomically
```

Expected for custom validations
Add `require_atomic?(false)` to the action
Migration generates, action works correctly

## Pre-existing Warnings (Safe to Ignore)

These warnings existed before your changes and don't affect migration generation:

```
warning: function fetch_individually/1 is unused
warning: undefined attribute "data-testid" for component
warning: Ashfolio.Portfolio.User.get_by_id/1 is undefined or private
```

## Success Indicators

Even with warnings, migration generation is successful when you see:

```
Generated ashfolio app
* creating _build/dev/lib/ashfolio/priv/repo/migrations/[timestamp]_[name].exs
* creating _build/dev/lib/ashfolio/priv/resource_snapshots/repo/[resource]/[timestamp].json
```

## Key Principle

Elixir/Phoenix development commonly shows warnings during incremental development. The migration system is designed to handle forward references and incomplete relationships during the development process.

## When to Be Concerned

Only be concerned if you see:

- Compilation errors (not warnings)
- No migration file generated
- Database migration failures when running `mix ecto.migrate`

## Best Practice

1. Generate migration - Accept expected warnings
2. Run migration - `mix ecto.migrate`
3. Address warnings - Fix configuration and atomic issues
4. Continue development - Forward references will be resolved in subsequent tasks

This incremental approach allows for test-driven development while building complex, interconnected resources.
