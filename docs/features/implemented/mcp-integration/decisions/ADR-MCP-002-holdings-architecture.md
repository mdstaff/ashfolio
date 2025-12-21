# ADR-MCP-002: Holdings Architecture for MCP Tools

## Status

Accepted

## Date

2024-11-26

## Context

During MCP integration development, a code review identified that test specifications assumed an `Ashfolio.Portfolio.Holding` Ash resource exists. In reality, holdings are **calculated dynamically** from transaction history via `HoldingsCalculator`.

This raised an architectural question: Should we introduce a `Holding` resource to simplify MCP tool implementation?

## Decision

**Keep the current calculated holdings architecture.** MCP tools will use `HoldingsCalculator.get_holdings_summary()` rather than a dedicated Holding resource.

### Rationale

| Factor | Holding Resource | Calculated (Current) |
|--------|------------------|---------------------|
| Query Performance | O(1) table lookup | O(n) transaction scan |
| Data Consistency | Must sync on every transaction | Always accurate |
| FIFO Cost Basis | Still needs transaction history | Native to calculation |
| Storage Overhead | Additional table | None |
| Implementation Complexity | Sync logic required | Already implemented |

For a single-user personal finance app with typical transaction volumes (hundreds to low thousands), the performance difference is negligible. The calculation approach is simpler and eliminates sync bugs.

## Consequences

### Positive

1. **No sync complexity**: Holdings are always consistent with transactions
2. **Simpler schema**: No additional table or migration
3. **FIFO accuracy**: Cost basis calculations use the same transaction data
4. **Already implemented**: `HoldingsCalculator` exists and is tested

### Negative

1. **MCP tool complexity**: Tools must call calculator instead of simple Ash read
2. **No Ash relationships**: Can't use `load: [:holdings]` on Account
3. **Repeated calculation**: Each request recalculates (mitigated by caching)

### Risks

1. **Performance at scale**: If transaction volume grows significantly, calculations may slow down

## Future Considerations

**If performance becomes an issue, introduce a `HoldingSnapshot` resource:**

```elixir
defmodule Ashfolio.Portfolio.HoldingSnapshot do
  @moduledoc """
  Materialized view of current holdings, updated on transaction changes.
  """

  use Ash.Resource,
    domain: Ashfolio.Portfolio,
    data_layer: AshSqlite.DataLayer

  attributes do
    uuid_primary_key :id
    attribute :account_id, :uuid
    attribute :symbol_id, :uuid
    attribute :quantity, :decimal
    attribute :cost_basis, :decimal
    attribute :current_value, :decimal
    attribute :calculated_at, :utc_datetime
  end

  # Refresh via Ash Reactor or PubSub on transaction create/update/delete
end
```

This would provide O(1) lookups while maintaining accuracy through event-driven updates. Implementation criteria:

- **Trigger**: When MCP tool response times exceed 100ms consistently
- **Approach**: Add as read-through cache, not replacement for calculator
- **Validation**: Snapshot values must match calculator output (property-based testing)

## Related Decisions

- ADR-MCP-001: Privacy Modes for MCP Tool Results

---

*Parent: [../TASK_INDEX.md](../tasks/TASK_INDEX.md)*
