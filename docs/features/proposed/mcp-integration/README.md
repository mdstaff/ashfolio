# MCP Integration - Spec-Driven Development

## Overview

This directory contains the architecture, design, and task breakdown for implementing MCP integration in Ashfolio following a spec-driven TDD approach.

## Document Hierarchy

```
mcp-integration/
├── README.md                    # This file - navigation & gap analysis
├── ARCHITECTURE.md              # System design & component relationships
├── tasks/
│   ├── phase-1/                 # Core MCP Tools
│   │   ├── 01-router-setup.md
│   │   ├── 02-privacy-filter.md
│   │   ├── 03-anonymizer.md
│   │   ├── 04-core-tools.md
│   │   └── 05-tool-examples.md
│   ├── phase-2/                 # Module Integration
│   │   ├── 01-parseable-mcp.md
│   │   ├── 02-module-registry.md
│   │   └── 03-tool-search.md
│   └── phase-3/                 # Legal & Consent
│       ├── 01-consent-resource.md
│       └── 02-consent-ui.md
└── decisions/                   # ADRs for MCP-specific choices
    └── ADR-MCP-001-privacy-modes.md
```

## Gap Analysis

### Specification Gaps Identified

| Gap | Severity | Description | Resolution |
|-----|----------|-------------|------------|
| **Error Handling** | High | No error response format defined for MCP tools | Define JSON-RPC error codes & messages |
| **Rate Limiting** | Medium | No throttling for expensive operations | Add rate limits for analytics tools |
| **Caching** | Medium | Repeated queries hit DB every time | Add result caching with TTL |
| **Logging/Audit** | Medium | Tool invocations not logged | Add structured logging |
| **Testing with Claude** | Medium | No E2E test strategy for actual Claude interaction | Define manual test protocol |
| **Settings UI** | Low | Privacy mode config via code only | Add settings LiveView |
| **Provider Detection** | Low | Manual provider configuration | Auto-detect from environment |
| **Offline Behavior** | Low | MCP behavior when Ollama unavailable | Define graceful degradation |

### Missing Requirements

#### 1. Error Handling (High Priority)

```elixir
# Not defined in spec - needed
@mcp_error_codes %{
  -32001 => "Privacy mode does not allow this operation",
  -32002 => "Tool requires consent not yet granted",
  -32003 => "Rate limit exceeded",
  -32004 => "Resource not found",
  -32005 => "Invalid filter parameters"
}
```

#### 2. Audit Logging (Medium Priority)

```elixir
# Not defined in spec - needed
defmodule Ashfolio.Audit.McpInvocation do
  use Ash.Resource

  attributes do
    uuid_primary_key :id
    attribute :tool_name, :string
    attribute :privacy_mode, :atom
    attribute :arguments_hash, :string  # Hash only, not actual args
    attribute :result_type, :atom  # :success, :error, :filtered
    attribute :duration_ms, :integer
    attribute :invoked_at, :utc_datetime
  end
end
```

#### 3. Rate Limiting (Medium Priority)

```elixir
# Not defined in spec - needed
@tool_rate_limits %{
  # Expensive analytics - limit per minute
  calculate_tax_lots: {5, :minute},
  analyze_performance: {10, :minute},
  run_retirement_forecast: {3, :minute},
  run_efficient_frontier: {3, :minute},

  # Standard reads - higher limits
  list_accounts: {60, :minute},
  list_transactions: {30, :minute}
}
```

#### 4. Settings LiveView (Low Priority)

```
Route: /settings/ai
Components:
- Privacy mode selector
- Provider configuration
- Consent status display
- Audit log viewer (recent invocations)
```

### Architectural Decisions Needed

| Decision | Options | Recommendation |
|----------|---------|----------------|
| Privacy filter placement | Middleware vs per-tool | Middleware (centralized) |
| Consent storage | Config file vs database | Database (trackable) |
| Caching layer | ETS vs process state | ETS (survives restarts) |
| Rate limit storage | ETS vs database | ETS (ephemeral is fine) |

## TDD Success Criteria

### Phase 1: Core MCP (Definition of Done)

```elixir
# All tests must pass before phase complete

# Router Tests
test "MCP endpoint responds to initialize"
test "MCP endpoint returns tool list"
test "MCP endpoint executes tools"
test "MCP endpoint handles unknown methods"

# Privacy Filter Tests
test "strict mode returns only aggregates"
test "anonymized mode transforms all sensitive fields"
test "standard mode includes account names"
test "full mode returns unfiltered data"
test "default mode is anonymized"

# Anonymizer Tests
test "account names become letter IDs"
test "balances become weights summing to 1.0"
test "net worth becomes tier enum"
test "transactions become patterns not details"
test "ratios pass through unchanged"
test "dates become relative strings"

# Core Tool Tests
test "list_accounts returns accounts filtered by privacy mode"
test "list_transactions supports filter/sort/limit"
test "get_portfolio_summary returns metrics"
test "tool errors return proper JSON-RPC format"

# Integration Tests
test "full MCP flow: initialize -> list tools -> call tool"
test "privacy mode change affects all tool results"
```

### Phase 2: Module Integration (Definition of Done)

```elixir
# Module Registry Tests
test "registers parsing modules as MCP tools"
test "deferred tools not loaded by default"
test "tool search finds tools by keyword"
test "tool search finds tools by description"

# Parseable MCP Extension Tests
test "modules with mcp_enabled?/0 => true are registered"
test "modules without MCP callbacks are skipped"
test "tool_name/0 becomes MCP tool name"
test "parameters_schema/0 becomes input schema"
```

### Phase 3: Consent & Legal (Definition of Done)

```elixir
# Consent Resource Tests
test "consent record created on first enable"
test "consent version tracked for terms updates"
test "provider change requires new consent"
test "privacy mode change logged"

# Consent UI Tests
test "consent modal shown on first MCP setup"
test "checkbox required before enable"
test "privacy policy links work"
test "consent can be revoked"
```

## Implementation Order

### Recommended Sequence

```
Week 1: Foundation
├── Day 1-2: Router setup + basic tests
├── Day 3-4: Privacy filter + anonymizer
└── Day 5: Core tools (list_accounts, list_transactions)

Week 2: Tools & Testing
├── Day 1-2: Remaining core tools
├── Day 3: Tool examples
├── Day 4: Integration tests
└── Day 5: Manual Claude Code testing

Week 3: Polish & Legal
├── Day 1-2: Consent resource + UI
├── Day 3: Audit logging
├── Day 4: Settings LiveView
└── Day 5: Documentation + review
```

## File Creation Checklist

### To Be Created (Implementation)

```
lib/ashfolio_web/mcp/
├── privacy_filter.ex          # Privacy mode filtering
├── anonymizer.ex              # Data anonymization
├── tool_definitions.ex        # Tool examples
├── tool_search.ex             # Deferred loading search
└── module_registry.ex         # Dynamic tool registration

lib/ashfolio/settings/
└── ai_consent.ex              # Consent tracking resource

lib/ashfolio/audit/
└── mcp_invocation.ex          # Audit logging resource

lib/ashfolio_web/live/settings/
└── ai_settings_live.ex        # Settings UI

test/ashfolio_web/mcp/
├── privacy_filter_test.exs
├── anonymizer_test.exs
├── tool_definitions_test.exs
├── tool_search_test.exs
├── module_registry_test.exs
└── server_integration_test.exs

test/ashfolio/settings/
└── ai_consent_test.exs
```

### To Be Modified

```
lib/ashfolio_web/router.ex     # Add MCP forward
lib/ashfolio/portfolio.ex      # Add AshAi extension + tools
config/config.exs              # Add MCP configuration
```

## Next Steps

1. Review this gap analysis
2. Create individual task files with TDD criteria
3. Begin Phase 1 implementation
4. Track progress in IMPLEMENTATION_PLAN.md

---

*Parent spec: [../mcp-integration.md](../mcp-integration.md)*
