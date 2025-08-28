---
inclusion: fileMatch
fileMatchPattern: "*.ex"
---

# Elixir-Specific Development Guidelines

## Ash Framework Patterns

### Resource Definition

```elixir
defmodule Ashfolio.Portfolio.ResourceName do
  use Ash.Resource, data_layer: AshSqlite.DataLayer

  attributes do
    uuid_primary_key :id
    # Define attributes with proper types
    timestamps()
  end

  relationships do
    # Define relationships clearly
  end

  actions do
    defaults [:create, :read, :update, :destroy]
    # Add custom actions as needed
  end
end
```

### Financial Calculations

- Always use `Decimal` for monetary values
- Example: `Decimal.mult(quantity, price)` not `quantity * price`
- Round to appropriate precision: `Decimal.round(value, 2)` for currency

### Error Handling Patterns

```elixir
case SomeModule.operation() do
  {:ok, result} ->
    # Handle success
  {:error, reason} ->
    Logger.error("Operation failed", error: reason)
    # Return user-friendly error
end
```

### GenServer Usage (Minimal)

- Only use for simple coordination (like PriceManager)
- Keep state minimal and focused
- Use `GenServer.call/2` for synchronous operations
- Use `GenServer.cast/2` for fire-and-forget operations

### ETS Cache Patterns

```elixir
# Simple cache operations
:ets.insert(:cache_table, {key, value, timestamp})
:ets.lookup(:cache_table, key)
```

## LiveView Patterns

### Mount Function

```elixir
def mount(_params, _session, socket) do
  # Load initial data
  # Set up subscriptions if needed
  {:ok, assign(socket, key: value)}
end
```

### Handle Events

```elixir
def handle_event("event_name", params, socket) do
  # Process event
  # Update socket assigns
  {:noreply, socket}
end
```

## Testing Patterns

### Ash Resource Tests

```elixir
test "creates resource with valid attributes" do
  assert {:ok, resource} = ResourceName.create(valid_attrs)
  assert resource.attribute == expected_value
end
```

### Mock External APIs

```elixir
# Use Mox or similar for consistent API mocking
# Never make real API calls in tests
```
