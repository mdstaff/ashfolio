# MCP Integration Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         MCP Clients                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                  │
│  │ Claude Code  │  │  Claude.app  │  │ Other MCP    │                  │
│  │    CLI       │  │   Desktop    │  │   Clients    │                  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘                  │
└─────────┼─────────────────┼─────────────────┼───────────────────────────┘
          │                 │                 │
          └────────────────┼─────────────────┘
                           │ JSON-RPC over HTTP
                           ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                     Phoenix Application                                  │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                      Router                                         │ │
│  │  forward "/mcp", AshAi.Mcp.Router                                  │ │
│  └─────────────────────────┬──────────────────────────────────────────┘ │
│                            │                                             │
│  ┌─────────────────────────▼──────────────────────────────────────────┐ │
│  │                   AshAi.Mcp.Server                                  │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                 │ │
│  │  │ initialize  │  │ tools/list  │  │ tools/call  │                 │ │
│  │  └─────────────┘  └──────┬──────┘  └──────┬──────┘                 │ │
│  └──────────────────────────┼────────────────┼────────────────────────┘ │
│                             │                │                           │
│  ┌──────────────────────────▼────────────────▼────────────────────────┐ │
│  │                    Ashfolio MCP Layer                               │ │
│  │                                                                      │ │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐  │ │
│  │  │  ModuleRegistry  │  │   ToolSearch     │  │ ToolDefinitions  │  │ │
│  │  │  (dynamic tools) │  │  (deferred load) │  │   (examples)     │  │ │
│  │  └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘  │ │
│  │           │                     │                     │             │ │
│  │  ┌────────▼─────────────────────▼─────────────────────▼─────────┐  │ │
│  │  │                     Privacy Filter                            │  │ │
│  │  │  ┌─────────┐  ┌─────────────┐  ┌──────────┐  ┌──────────┐   │  │ │
│  │  │  │ :strict │  │ :anonymized │  │:standard │  │  :full   │   │  │ │
│  │  │  └─────────┘  └──────┬──────┘  └──────────┘  └──────────┘   │  │ │
│  │  └──────────────────────┼────────────────────────────────────────┘  │ │
│  │                         │                                            │ │
│  │  ┌──────────────────────▼────────────────────────────────────────┐  │ │
│  │  │                     Anonymizer                                 │  │ │
│  │  │  • Names → Letter IDs       • Amounts → Weights               │  │ │
│  │  │  • Net Worth → Tiers        • Symbols → Asset Classes         │  │ │
│  │  │  • Dates → Relative         • Ratios → Pass Through           │  │ │
│  │  └──────────────────────┬────────────────────────────────────────┘  │ │
│  └─────────────────────────┼────────────────────────────────────────────┘ │
│                            │                                             │
│  ┌─────────────────────────▼──────────────────────────────────────────┐ │
│  │                      Ash Domains                                    │ │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐    │ │
│  │  │    Portfolio    │  │   Financial     │  │    Settings     │    │ │
│  │  │    Domain       │  │   Management    │  │    Domain       │    │ │
│  │  │                 │  │                 │  │                 │    │ │
│  │  │ • Account       │  │ • Expense       │  │ • AiConsent     │    │ │
│  │  │ • Transaction   │  │ • Goal          │  │                 │    │ │
│  │  │ • Symbol        │  │ • Category      │  │                 │    │ │
│  │  │ • Holding       │  │                 │  │                 │    │ │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘    │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                      SQLite Database                                │ │
│  └────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

## Component Specifications

### 1. Privacy Filter (`AshfolioWeb.Mcp.PrivacyFilter`)

**Purpose**: Central gatekeeper for all MCP tool results

**Responsibilities**:
- Read privacy mode from configuration
- Route results to appropriate filter
- Enforce consent requirements
- Log filtered access for audit

**Interface**:
```elixir
@spec filter_result(any(), atom(), keyword()) :: any()
@spec current_mode() :: :strict | :anonymized | :standard | :full
@spec mode_allows?(atom(), atom()) :: boolean()
```

**Dependencies**:
- `Anonymizer` for `:anonymized` mode
- `Application.get_env/2` for configuration
- `AiConsent` for consent verification

### 2. Anonymizer (`AshfolioWeb.Mcp.Anonymizer`)

**Purpose**: Transform sensitive financial data into privacy-safe representations

**Responsibilities**:
- Convert account names to letter IDs
- Convert balances to relative weights
- Convert net worth to tier enums
- Convert symbols to asset classes
- Convert dates to relative strings
- Pass through ratios/percentages unchanged

**Interface**:
```elixir
@spec anonymize(any(), atom()) :: map()
@spec anonymize_account(Account.t(), Decimal.t()) :: map()
@spec anonymize_transaction(Transaction.t()) :: map()
@spec value_to_tier(Decimal.t()) :: atom()
```

**Transformation Rules**:

| Input Type | Transformation | Output Type |
|------------|----------------|-------------|
| Account.name | Index to letter | String ("A", "B") |
| Account.balance | balance / total | Float (0.0-1.0) |
| Portfolio total | Tier boundaries | Atom (:six_figures) |
| Symbol.ticker | Sector lookup | Atom (:us_equity) |
| Date | Days ago calculation | String ("3 months ago") |
| Decimal ratio | Pass through | Float |

### 3. Module Registry (`AshfolioWeb.Mcp.ModuleRegistry`)

**Purpose**: Dynamic tool registration from parsing modules

**Responsibilities**:
- Discover modules implementing `Parseable` with MCP callbacks
- Register/unregister tools at runtime
- Track deferred vs always-loaded tools
- Provide tool metadata for search

**Interface**:
```elixir
@spec get_tools(keyword()) :: [tool()]
@spec register_module(module(), keyword()) :: :ok | {:error, reason()}
@spec unregister_module(module()) :: :ok
@spec get_deferred_tools() :: [tool()]
```

**Discovery Process**:
```
1. On application start
2. Scan configured module paths
3. For each module implementing Parseable:
   a. Check mcp_enabled?/0 callback
   b. If true, extract tool metadata
   c. Register with deferred flag if specified
4. Store in ETS for fast lookup
```

### 4. Tool Search (`AshfolioWeb.Mcp.ToolSearch`)

**Purpose**: Enable deferred tool loading via search

**Responsibilities**:
- Index tool names, descriptions, keywords
- Perform fuzzy matching on queries
- Return results at configurable detail levels
- Track search analytics (optional)

**Interface**:
```elixir
@spec search(String.t(), keyword()) :: [tool_result()]
@spec list_categories() :: [String.t()]
@spec tools_in_category(String.t()) :: [tool()]
```

**Search Algorithm**:
1. Normalize query (lowercase, trim)
2. Match against tool.name (exact)
3. Match against tool.description (contains)
4. Match against tool.keywords (any match)
5. Score by match quality
6. Return top N results

### 5. Tool Definitions (`AshfolioWeb.Mcp.ToolDefinitions`)

**Purpose**: Provide usage examples for each tool

**Responsibilities**:
- Store example inputs per tool
- Categorize examples (minimal, partial, full)
- Provide to MCP clients for better tool use

**Interface**:
```elixir
@spec tool_examples() :: %{String.t() => [example()]}
@spec examples_for(String.t()) :: [example()]
@spec validate_examples() :: :ok | {:error, [String.t()]}
```

### 6. AI Consent (`Ashfolio.Settings.AiConsent`)

**Purpose**: Track user consent for third-party AI usage

**Responsibilities**:
- Store consent timestamp and version
- Track provider and privacy mode
- Enable consent revocation
- Support terms version updates

**Schema**:
```elixir
attributes do
  uuid_primary_key :id
  attribute :provider, :atom, allow_nil?: false
  attribute :privacy_mode, :atom, allow_nil?: false
  attribute :consented_at, :utc_datetime, allow_nil?: false
  attribute :consent_version, :string, allow_nil?: false
  attribute :revoked_at, :utc_datetime
  timestamps()
end
```

**Actions**:
- `create` - Record new consent
- `revoke` - Mark consent as revoked
- `current` - Get active consent for provider
- `requires_update?` - Check if terms version changed

## Data Flow

### Tool Invocation Flow

```
1. Client sends tools/call request
   │
2. AshAi.Mcp.Server receives request
   │
3. Server looks up tool by name
   │  ├── Core tools: Direct lookup
   │  └── Module tools: ModuleRegistry.get_tool/1
   │
4. Server executes tool function with arguments
   │
5. Tool returns raw result
   │
6. PrivacyFilter.filter_result/3 called
   │  ├── :strict → Aggregate only
   │  ├── :anonymized → Anonymizer.anonymize/2
   │  ├── :standard → Light filtering
   │  └── :full → Pass through
   │
7. Filtered result returned to client
```

### Consent Flow

```
1. User enables MCP for first time
   │
2. UI checks AiConsent.current/1
   │  └── No consent found
   │
3. UI shows consent modal
   │  ├── Privacy mode selector
   │  ├── Provider terms link
   │  └── Consent checkbox
   │
4. User accepts
   │
5. AiConsent.create/1 called
   │
6. MCP enabled in config
   │
7. Tools available to client
```

## Configuration

### Application Config

```elixir
# config/config.exs
config :ashfolio, :mcp,
  enabled: true,
  privacy_mode: :anonymized,
  rate_limits: %{
    calculate_tax_lots: {5, :minute},
    default: {60, :minute}
  },
  audit_logging: true,
  consent_version: "1.0.0"

# config/runtime.exs (provider-specific)
config :ashfolio, :mcp,
  provider: System.get_env("MCP_PROVIDER", "ollama") |> String.to_atom()
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MCP_ENABLED` | `true` | Enable/disable MCP endpoint |
| `MCP_PRIVACY_MODE` | `anonymized` | Default privacy mode |
| `MCP_PROVIDER` | `ollama` | Default LLM provider |
| `MCP_AUDIT_LOG` | `true` | Enable audit logging |

## Error Handling

### MCP Error Codes

| Code | Meaning | When Used |
|------|---------|-----------|
| -32001 | Privacy restriction | Operation blocked by privacy mode |
| -32002 | Consent required | No consent for provider |
| -32003 | Rate limited | Too many requests |
| -32004 | Not found | Resource doesn't exist |
| -32005 | Invalid parameters | Bad filter/sort/etc |
| -32600 | Invalid request | Malformed JSON-RPC |
| -32601 | Method not found | Unknown MCP method |
| -32602 | Invalid params | Wrong argument types |

### Error Response Format

```json
{
  "jsonrpc": "2.0",
  "id": "request-id",
  "error": {
    "code": -32001,
    "message": "Privacy mode does not allow this operation",
    "data": {
      "current_mode": "strict",
      "required_mode": "standard",
      "tool": "list_transactions"
    }
  }
}
```

## Performance Considerations

### Caching Strategy

| Data | Cache Location | TTL | Invalidation |
|------|---------------|-----|--------------|
| Tool list | ETS | App lifetime | Never |
| Tool examples | ETS | App lifetime | Never |
| Search index | ETS | App lifetime | On module change |
| Rate limit counters | ETS | Per window | Auto-expire |

### Optimization Targets

| Operation | Target | Measurement |
|-----------|--------|-------------|
| Tool list | <10ms | Response time |
| Tool call (simple) | <100ms | Response time |
| Tool call (analytics) | <2s | Response time |
| Privacy filter | <5ms | Processing time |
| Anonymization | <10ms | Processing time |

## Security Model

### Trust Boundaries

```
┌─────────────────────────────────────────────────┐
│ Untrusted: MCP Client                           │
│ (Claude Code, Claude.app, etc.)                 │
└─────────────────────┬───────────────────────────┘
                      │ JSON-RPC (validated)
┌─────────────────────▼───────────────────────────┐
│ Trusted: Ashfolio Application                   │
│ - All input validated by Ash                    │
│ - All output filtered by PrivacyFilter          │
│ - Rate limiting enforced                        │
└─────────────────────┬───────────────────────────┘
                      │ Ash queries
┌─────────────────────▼───────────────────────────┐
│ Trusted: SQLite Database                        │
│ - Single-user, local-first                      │
│ - No network exposure                           │
└─────────────────────────────────────────────────┘
```

### Attack Vectors Mitigated

| Vector | Mitigation |
|--------|------------|
| SQL Injection | Ash parameterized queries |
| Data exfiltration | Privacy filter on all responses |
| Denial of service | Rate limiting |
| Unauthorized access | Single-user model (no auth needed) |
| Sensitive data exposure | Anonymization by default |

---

*Parent: [README.md](README.md) | Spec: [../mcp-integration.md](../mcp-integration.md)*
