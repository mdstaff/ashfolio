# Ashfolio Coding Standards

## Project Context
- This is Ashfolio Phase 1: a simplified single-user local portfolio management app
- Built with Elixir/Phoenix and Ash Framework
- Focus on simplicity and high development confidence (80-90% success rate per task)

## Core Development Principles

### Simplicity First
- Avoid complex patterns or premature optimizations
- Use standard Phoenix/Elixir conventions
- Prefer explicit over clever code
- Each task should build incrementally on previous work

### Ash Framework Usage
- All business logic must be implemented as Ash resources
- Use Ash actions for create/read/update/destroy operations
- Define relationships using Ash's relationship system
- Leverage Ash validations and change management
- No direct Ecto usage - everything through Ash
- Always register new resources in the Portfolio domain
- Use `installed_extensions/0` function in Repo for AshSqlite compatibility
- Generate migrations with `mix ash_sqlite.generate_migrations`
- Use proper Ecto.Adapters.SQL.Sandbox setup for tests

### Financial Data Handling
- Use Decimal types for all monetary calculations
- All amounts stored and calculated in USD only
- Format currency as $X,XXX.XX in UI
- Simple return calculation: (current_value - cost_basis) / cost_basis * 100

### Error Handling
- Use `Ashfolio.ErrorHandler` for centralized error processing
- Use Logger for error logging with appropriate levels (debug, info, warning, error)
- Display user-friendly error messages in UI using `ErrorHelpers.put_error_flash/3`
- Use `Ashfolio.Validation` module for form and data validation
- Graceful degradation for API failures (use cached data)
- Never crash the application - handle errors gracefully
- Format changeset errors for user-friendly display

### Testing Requirements
- Write unit tests for all Ash resources and actions
- Mock external APIs (Yahoo Finance, CoinGecko) in tests
- Test both success and failure scenarios
- Include basic LiveView tests for user interactions
- Use `Ecto.Adapters.SQL.Sandbox.checkout/1` in test setup for database isolation
- Test Ash error structures with `error.field` pattern, not tuple destructuring
- Use `%{}` syntax for Ash.create/update parameters, not keyword lists
- Test both code interface functions and direct Ash actions

## Phase 1 Scope Boundaries

### DO Include
- Manual price refresh (user-initiated)
- Basic portfolio calculations
- Simple transaction entry and management
- Account CRUD operations
- Holdings display with gains/losses
- USD-only financial calculations

### DO NOT Include
- Real-time price updates or background jobs
- Advanced analytics (ROAI, time-weighted returns)
- CSV import/export functionality
- Multi-currency support
- Complex charting or visualizations
- Authentication or user management

## Code Organization
- Business logic in `lib/ashfolio/` (Ash resources)
- Web layer in `lib/ashfolio_web/` (LiveView components)
- Database files in `data/` directory
- Tests mirror the lib/ structure

## Common Patterns to Follow
- Use GenServer only for simple coordination (like PriceManager)
- ETS for basic price caching with simple cleanup
- Phoenix LiveView for all UI interactions
- HTTPoison for external API calls with basic error handling