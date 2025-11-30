# MCP Integration for Ashfolio

## Overview

This specification outlines Model Context Protocol (MCP) integration for Ashfolio, enabling Claude Code and other MCP clients to interact with portfolio data through type-safe Ash actions.

## Strategic Goals

1. **Expose Ash Actions as MCP Tools** - Let Claude query portfolio, transactions, accounts
2. **Integrate with Module System** - Enable dynamic tool discovery/loading
3. **Prepare for Advanced Tool Use** - Document future code execution patterns

## Privacy Model

**IMPORTANT**: MCP tool results become part of the conversation context sent to the LLM provider.

| MCP Client | Tool Execution | Results Sent To | Privacy Level |
|------------|----------------|-----------------|---------------|
| Claude Code CLI | Local | Anthropic API | Medium |
| Claude.app | Local | Anthropic API | Medium |
| Local LLM (Ollama) | Local | Nowhere | Full |

### Privacy Modes

Ashfolio implements a **privacy mode setting** to control data exposure:

```elixir
# config/config.exs
config :ashfolio, :mcp,
  privacy_mode: :anonymized  # :strict | :anonymized | :standard | :full
```

| Mode | Behavior | Use Case |
|------|----------|----------|
| `:strict` | Aggregates only, no structure | Maximum privacy, limited Claude utility |
| `:anonymized` | **Relative data only** - percentages, ratios, tiers | Cloud LLM with full analytical capability |
| `:standard` | Summaries with account names, limited history | Convenience over privacy |
| `:full` | Complete data access | Local LLM only (Ollama) |

### Anonymized Mode (Recommended for Cloud LLMs)

The `:anonymized` mode enables Claude to perform full financial analysis without exposing sensitive data:

#### What Gets Transformed

| Sensitive Data | Anonymized Form | Claude Can Still... |
|----------------|-----------------|---------------------|
| Account names | "Account A", "Account B" | Analyze allocation across accounts |
| Exact balances | Relative weights (35%, 25%) | Evaluate concentration risk |
| Net worth | Tier (:five_figures, :six_figures) | Provide tier-appropriate advice |
| Transaction amounts | Percentile buckets | Identify spending patterns |
| Stock symbols | Sector/asset class | Assess diversification |
| Dates | Relative ("3 months ago") | Analyze timing patterns |
| Ratios/percentages | Pass through unchanged | Full ratio analysis |

#### Example Transformation

**Raw data (never sent):**
```elixir
%{
  accounts: [
    %{name: "Fidelity 401k", balance: Decimal.new("125432.17"), holdings: ["VTI", "VXUS"]},
    %{name: "Vanguard Roth IRA", balance: Decimal.new("45000.00"), holdings: ["VTI"]},
    %{name: "Chase Checking", balance: Decimal.new("8500.00")}
  ]
}
```

**Anonymized (sent to Claude):**
```elixir
%{
  accounts: [
    %{id: "A", type: :retirement_401k, weight: 0.70, asset_classes: %{us_equity: 0.8, intl_equity: 0.2}},
    %{id: "B", type: :retirement_ira, weight: 0.25, asset_classes: %{us_equity: 1.0}},
    %{id: "C", type: :checking, weight: 0.05, asset_classes: %{cash: 1.0}}
  ],
  portfolio: %{
    value_tier: :six_figures,          # $100k-$999k range
    value_percentile: :p50_p75,        # Relative to typical users
    concentration: :high,               # Top account is 70%
    diversification_score: 0.65        # 0-1 scale
  },
  metrics: %{
    # Ratios pass through - not sensitive
    savings_rate: 0.22,
    debt_to_income: 0.15,
    emergency_fund_months: 4.5,
    expense_ratio_weighted: 0.08
  }
}
```

#### What Claude Can Analyze in Anonymized Mode

- "Your portfolio is concentrated - 70% in one account"
- "Savings rate of 22% is above the recommended 20%"
- "4.5 months emergency fund is below the 6-month target"
- "Consider international diversification - currently only 14% of equity"
- "Your expense ratios are reasonable at 0.08% weighted average"

#### What Claude Cannot Determine

- Your actual net worth
- Which brokerages you use
- Specific stock/fund holdings
- Exact transaction amounts
- Account numbers or identifiers

### Privacy Mode Implementation

```elixir
# lib/ashfolio_web/mcp/privacy_filter.ex
defmodule AshfolioWeb.Mcp.PrivacyFilter do
  @moduledoc """
  Filters MCP tool results based on configured privacy mode.
  Prevents accidental exposure of sensitive financial data to cloud LLMs.
  """

  alias AshfolioWeb.Mcp.Anonymizer

  def filter_result(result, tool_name, opts \\ []) do
    mode = Application.get_env(:ashfolio, :mcp)[:privacy_mode] || :anonymized

    case mode do
      :strict -> apply_strict_filter(result, tool_name)
      :anonymized -> Anonymizer.anonymize(result, tool_name)
      :standard -> apply_standard_filter(result, tool_name)
      :full -> result
    end
  end

  # ... strict and standard implementations
end
```

```elixir
# lib/ashfolio_web/mcp/anonymizer.ex
defmodule AshfolioWeb.Mcp.Anonymizer do
  @moduledoc """
  Transforms financial data into anonymized form for cloud LLM analysis.
  Preserves analytical value (ratios, percentages, patterns) while removing
  sensitive identifiers (names, exact amounts, symbols).
  """

  @value_tiers [
    {:under_10k, 0, 10_000},
    {:five_figures, 10_000, 100_000},
    {:six_figures, 100_000, 1_000_000},
    {:seven_figures, 1_000_000, 10_000_000},
    {:eight_figures_plus, 10_000_000, :infinity}
  ]

  @doc """
  Anonymize account data for MCP response.
  """
  def anonymize(accounts, :list_accounts) when is_list(accounts) do
    total = accounts |> Enum.map(& &1.balance) |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

    %{
      accounts: accounts |> Enum.with_index() |> Enum.map(fn {acc, idx} ->
        %{
          id: account_id(idx),
          type: anonymize_account_type(acc.type, acc.name),
          weight: calculate_weight(acc.balance, total),
          asset_classes: anonymize_holdings(acc)
        }
      end),
      portfolio: %{
        value_tier: value_to_tier(total),
        account_count: length(accounts),
        concentration: concentration_level(accounts, total),
        diversification_score: calculate_diversification(accounts)
      }
    }
  end

  def anonymize(transactions, :list_transactions) when is_list(transactions) do
    %{
      summary: %{
        count: length(transactions),
        date_range: relative_date_range(transactions),
        by_type: transactions |> Enum.group_by(& &1.type) |> Map.new(fn {k, v} -> {k, length(v)} end)
      },
      patterns: %{
        avg_transaction_tier: avg_amount_tier(transactions),
        frequency: transaction_frequency(transactions),
        categories: category_breakdown(transactions)
      }
    }
  end

  def anonymize(result, :get_portfolio_summary) do
    %{
      value_tier: value_to_tier(result.total_value),
      allocation: result.allocation,  # Percentages pass through
      metrics: %{
        ytd_return_pct: result.ytd_return,
        diversification_score: result.diversification,
        risk_level: result.risk_level
      },
      # Ratios are not sensitive - pass through
      ratios: Map.take(result, [:savings_rate, :debt_to_income, :expense_ratio])
    }
  end

  # Helper functions

  defp account_id(index), do: <<?A + index>>  # "A", "B", "C", ...

  defp anonymize_account_type(type, name) do
    cond do
      String.contains?(String.downcase(name || ""), "401k") -> :retirement_401k
      String.contains?(String.downcase(name || ""), "ira") -> :retirement_ira
      type in [:brokerage, :investment] -> :taxable_investment
      type == :checking -> :checking
      type == :savings -> :savings
      true -> :other
    end
  end

  defp value_to_tier(amount) do
    amount_float = Decimal.to_float(amount)
    Enum.find_value(@value_tiers, :unknown, fn {tier, min, max} ->
      max_val = if max == :infinity, do: :infinity, else: max
      if amount_float >= min && (max_val == :infinity || amount_float < max_val), do: tier
    end)
  end

  defp calculate_weight(balance, total) do
    if Decimal.compare(total, 0) == :gt do
      balance |> Decimal.div(total) |> Decimal.round(2) |> Decimal.to_float()
    else
      0.0
    end
  end

  defp concentration_level(accounts, total) do
    max_weight = accounts
      |> Enum.map(&calculate_weight(&1.balance, total))
      |> Enum.max(fn -> 0 end)

    cond do
      max_weight > 0.7 -> :very_high
      max_weight > 0.5 -> :high
      max_weight > 0.3 -> :moderate
      true -> :well_distributed
    end
  end

  defp relative_date_range(transactions) do
    dates = Enum.map(transactions, & &1.date)
    min_date = Enum.min(dates, Date)
    max_date = Enum.max(dates, Date)
    days_span = Date.diff(max_date, min_date)

    %{
      span_days: days_span,
      oldest_relative: days_ago(min_date),
      newest_relative: days_ago(max_date)
    }
  end

  defp days_ago(date) do
    diff = Date.diff(Date.utc_today(), date)
    cond do
      diff == 0 -> "today"
      diff == 1 -> "yesterday"
      diff < 7 -> "#{diff} days ago"
      diff < 30 -> "#{div(diff, 7)} weeks ago"
      diff < 365 -> "#{div(diff, 30)} months ago"
      true -> "#{div(diff, 365)} years ago"
    end
  end

  # Additional helper functions...
end
```

### UI Warning

When MCP is enabled with a cloud LLM provider, display a warning:

```
┌─────────────────────────────────────────────────────────────┐
│  ⚠️  MCP Privacy Notice                                     │
│                                                             │
│  MCP tool results are sent to your LLM provider (Anthropic) │
│  as part of the conversation.                               │
│                                                             │
│  Current mode: Standard                                     │
│  [Change to Strict] [Use Local LLM] [Dismiss]              │
└─────────────────────────────────────────────────────────────┘
```

## Cost Model

**Why MCP over API Integration?**

| Approach | Cost | Privacy | Complexity |
|----------|------|---------|------------|
| Embed API calls in app | Pay-per-token ($5-25/M) | Data leaves device | Medium |
| MCP via subscription | Included in Claude Pro/Max | Data stays local* | Low |

*Tool execution is local; results sent to LLM as conversation context.

For users with existing Claude subscriptions, MCP is effectively **zero marginal cost**.

## Architecture

### Current State (v0.8.0)

```
lib/ashfolio/ai/
├── dispatcher.ex          # Routes to handlers
├── handler.ex             # Handler behaviour
├── model.ex               # LLM provider selection
└── handlers/
    └── transaction_parser.ex
```

### Proposed MCP Layer

```
lib/ashfolio_web/
├── router.ex              # Add MCP forward
└── mcp/
    ├── tool_definitions.ex   # Tool metadata & examples
    └── module_registry.ex    # Dynamic tool loading

# Phoenix Router addition:
forward "/mcp", AshAi.Mcp.Router,
  otp_app: :ashfolio,
  tools: [...],
  mcp_name: "Ashfolio Portfolio Manager"
```

## Phase 1: Core MCP Tools

### 1.1 Tool Definitions

Expose these Ash actions as MCP tools:

#### Always Available (Core Tools)

| Tool Name | Resource | Action | Description |
|-----------|----------|--------|-------------|
| `list_accounts` | Account | :read | List all portfolio accounts |
| `get_account` | Account | :read | Get account by ID with holdings |
| `list_transactions` | Transaction | :read | Query transactions with filters |
| `get_portfolio_summary` | (custom) | :action | Overall portfolio metrics |
| `list_symbols` | Symbol | :read | Available securities |

#### Deferred Loading (Advanced Tools)

| Tool Name | Resource | Action | Description |
|-----------|----------|--------|-------------|
| `calculate_tax_lots` | (custom) | :action | FIFO cost basis analysis |
| `analyze_performance` | (custom) | :action | TWR/MWR calculations |
| `calculate_risk_metrics` | (custom) | :action | Volatility, Sharpe, etc. |
| `run_retirement_forecast` | (custom) | :action | Monte Carlo projections |
| `calculate_money_ratios` | (custom) | :action | Financial health assessment |

### 1.2 Implementation in Ash Resources

Add tool declarations to domains:

```elixir
# lib/ashfolio/portfolio.ex
defmodule Ashfolio.Portfolio do
  use Ash.Domain,
    extensions: [AshAi]

  tools do
    tool :list_accounts, Ashfolio.Portfolio.Account, :read,
      description: "List all investment and cash accounts",
      load: [:current_value, :holdings]

    tool :list_transactions, Ashfolio.Portfolio.Transaction, :read,
      description: "Query transactions by account, date, type, or symbol",
      action_parameters: [:filter, :sort, :limit]

    tool :get_portfolio_summary, Ashfolio.Portfolio.PortfolioSummary, :summary,
      description: "Get aggregate portfolio value, allocation, and performance"
  end
end
```

### 1.3 Tool Use Examples (Per Anthropic Best Practices)

Provide 1-5 examples per tool to improve accuracy:

```elixir
# lib/ashfolio_web/mcp/tool_definitions.ex
defmodule AshfolioWeb.Mcp.ToolDefinitions do
  @moduledoc """
  Tool definitions with examples for MCP clients.
  Following Anthropic's advanced tool use patterns.
  """

  def tool_examples do
    %{
      "list_transactions" => [
        # Minimal
        %{
          input: %{},
          description: "List recent transactions"
        },
        # With filter
        %{
          input: %{filter: %{type: "buy"}, limit: 10},
          description: "List last 10 buy transactions"
        },
        # Full specification
        %{
          input: %{
            filter: %{
              account_id: "uuid-here",
              date: %{gte: "2024-01-01", lte: "2024-12-31"}
            },
            sort: [%{field: "date", direction: "desc"}],
            limit: 50
          },
          description: "Get 2024 transactions for specific account"
        }
      ],

      "calculate_tax_lots" => [
        %{
          input: %{symbol: "AAPL", tax_year: 2024},
          description: "Calculate AAPL cost basis for 2024 taxes"
        }
      ]
    }
  end
end
```

### 1.4 Router Configuration

```elixir
# lib/ashfolio_web/router.ex
defmodule AshfolioWeb.Router do
  # ... existing routes ...

  # MCP endpoint for Claude Code / Claude.app integration
  forward "/mcp", AshAi.Mcp.Router,
    otp_app: :ashfolio,
    mcp_name: "Ashfolio Portfolio Manager",
    mcp_server_version: "0.8.0"
end
```

## Phase 2: Module System Integration

### 2.1 Dynamic Tool Registration

Connect MCP to the Smart Parsing Module System:

```elixir
# lib/ashfolio_web/mcp/module_registry.ex
defmodule AshfolioWeb.Mcp.ModuleRegistry do
  @moduledoc """
  Manages dynamic MCP tool registration based on installed modules.
  """

  @doc """
  Get tools based on installed/enabled modules.
  Implements deferred loading pattern from Anthropic's advanced tool use.
  """
  def get_tools(opts \\ []) do
    core_tools = get_core_tools()
    module_tools = get_module_tools(opts)

    # Deferred tools marked for on-demand loading
    deferred = Keyword.get(opts, :include_deferred, false)

    if deferred do
      core_tools ++ module_tools ++ get_deferred_tools()
    else
      core_tools ++ module_tools
    end
  end

  @doc """
  Register a parsing module as an MCP tool.
  """
  def register_module(module, opts) do
    %{
      name: module.tool_name(),
      description: module.tool_description(),
      parameters_schema: module.parameters_schema(),
      function: &module.execute/2,
      metadata: %{
        defer_loading: Keyword.get(opts, :defer_loading, false),
        module_type: :parsing
      }
    }
  end
end
```

### 2.2 Module Metadata for MCP

Extend the `Parseable` behaviour to support MCP:

```elixir
# lib/ashfolio/parsing/behaviours/parseable.ex
defmodule Ashfolio.Parsing.Parseable do
  @moduledoc "Behaviour for parsing modules with MCP support"

  # Existing callbacks
  @callback can_parse?(text :: String.t()) :: boolean()
  @callback parse(text :: String.t()) :: {:ok, result()} | {:error, reason()}
  @callback confidence() :: :high | :medium | :low

  # MCP integration callbacks (optional)
  @callback tool_name() :: String.t()
  @callback tool_description() :: String.t()
  @callback parameters_schema() :: map()
  @callback mcp_enabled?() :: boolean()

  @optional_callbacks [tool_name: 0, tool_description: 0, parameters_schema: 0, mcp_enabled?: 0]
end
```

### 2.3 Example: Expense Parser as MCP Tool

```elixir
# lib/ashfolio/parsing/modules/expense_parser.ex
defmodule Ashfolio.Parsing.Modules.ExpenseParser do
  @behaviour Ashfolio.Parsing.Parseable

  # Parsing implementation...

  # MCP Tool Interface
  def tool_name, do: "parse_expenses"

  def tool_description do
    """
    Parse natural language expense descriptions into structured data.
    Examples: "Netflix, Spotify, $1800 rent" or "I spend $500 on groceries"
    Returns parsed expenses with amounts, categories, and confidence scores.
    """
  end

  def parameters_schema do
    %{
      type: :object,
      properties: %{
        text: %{
          type: :string,
          description: "Natural language expense description"
        },
        include_suggestions: %{
          type: :boolean,
          default: true,
          description: "Include category suggestions for ambiguous items"
        }
      },
      required: ["text"]
    }
  end

  def mcp_enabled?, do: true
end
```

## Phase 3: Tool Search (Deferred Loading)

Implement Anthropic's "Tool Search Tool" pattern for large tool sets:

### 3.1 Tool Search Implementation

```elixir
# lib/ashfolio_web/mcp/tool_search.ex
defmodule AshfolioWeb.Mcp.ToolSearch do
  @moduledoc """
  Implements deferred tool loading via search.
  Reduces token usage by ~85% for large tool sets.
  """

  @doc """
  Search for tools by keyword/description.
  Claude calls this to discover available tools on-demand.
  """
  def search(query, opts \\ []) do
    detail_level = Keyword.get(opts, :detail, :description)

    all_tools()
    |> Enum.filter(&matches?(&1, query))
    |> Enum.map(&format_result(&1, detail_level))
  end

  defp matches?(tool, query) do
    query = String.downcase(query)

    String.contains?(String.downcase(tool.name), query) ||
      String.contains?(String.downcase(tool.description), query) ||
      Enum.any?(tool.keywords || [], &String.contains?(String.downcase(&1), query))
  end

  defp format_result(tool, :name_only), do: tool.name
  defp format_result(tool, :description), do: %{name: tool.name, description: tool.description}
  defp format_result(tool, :full), do: tool
end
```

### 3.2 Tool Categories

Organize tools for efficient discovery:

```elixir
@tool_categories %{
  "portfolio" => [
    :list_accounts, :get_account, :get_portfolio_summary
  ],
  "transactions" => [
    :list_transactions, :create_transaction, :parse_transaction
  ],
  "analytics" => [
    :calculate_performance, :calculate_risk_metrics, :run_efficient_frontier
  ],
  "tax" => [
    :calculate_tax_lots, :analyze_wash_sales, :estimate_capital_gains
  ],
  "planning" => [
    :run_retirement_forecast, :calculate_money_ratios, :analyze_expenses
  ],
  "parsing" => [
    :parse_expenses, :parse_income, :parse_account
  ]
}
```

## Future: Code Execution (v1.0+)

### Prerequisites

Before implementing code execution:

1. **Sandbox Environment** - Isolated execution context
2. **Resource Limits** - CPU, memory, time bounds
3. **Access Controls** - Which tools accessible from code
4. **Audit Logging** - Track executed code for security

### Architecture (Future)

```
┌─────────────────────────────────────────────────────────┐
│                    Claude Code CLI                       │
└─────────────────────┬───────────────────────────────────┘
                      │ MCP Protocol
                      ▼
┌─────────────────────────────────────────────────────────┐
│                  Ashfolio MCP Server                     │
├─────────────────────┬───────────────────────────────────┤
│   Direct Tools      │   Code Execution (Future)         │
│   - list_accounts   │   - sandbox environment           │
│   - list_txns       │   - tool wrappers as TS/Python    │
│   - parse_expense   │   - result filtering              │
│   ...               │   - skill persistence             │
└─────────────────────┴───────────────────────────────────┘
```

### Code Execution Benefits (Deferred)

Per Anthropic's engineering blog:
- **98.7% token reduction** for complex multi-tool operations
- **Data filtering** - Process 10K transactions, return 50 relevant
- **Privacy preservation** - Intermediate data stays in sandbox
- **Skill development** - Save working code as reusable functions

### Roadmap Reference

| Feature | Status | Notes |
|---------|--------|-------|
| Tool Search Tool | Future | >10K tokens in definitions |
| Programmatic Tool Calling | Future | Requires sandbox |
| Skill Persistence | Future | Save working code |
| PII Auto-tokenization | Future | Privacy enhancement |

## Implementation Checklist

### Phase 1: Core MCP (Target: v0.9.0)

- [ ] Add `AshAi.Mcp.Router` to Phoenix router
- [ ] Define tools in Portfolio domain
- [ ] Define tools in FinancialManagement domain
- [ ] Add tool use examples for each tool
- [ ] Test with Claude Code CLI locally
- [ ] Document Claude Code configuration

### Phase 2: Module Integration (Target: v0.10.0)

- [ ] Extend Parseable behaviour with MCP callbacks
- [ ] Implement ModuleRegistry for dynamic tools
- [ ] Connect parsing modules to MCP
- [ ] Add tool search endpoint
- [ ] Implement deferred loading

### Phase 3: Advanced Features (Target: v1.0+)

- [ ] Design sandbox architecture
- [ ] Implement code execution tool
- [ ] Add skill persistence
- [ ] Build audit logging
- [ ] Performance optimization

## Legal & Licensing Considerations

### Third-Party LLM Disclosure Requirements

When users enable cloud LLM features (`:standard` or `:full` privacy modes), Ashfolio must disclose:

#### Required Disclosures

1. **Data Transmission Notice**
   - Financial data will be transmitted to third-party AI providers
   - Specify which provider (Anthropic, OpenAI, etc.)
   - Link to provider's privacy policy and data retention terms

2. **Data Usage Clarity**
   - What data is sent (tool results as conversation context)
   - How data may be used by the provider (training, storage, etc.)
   - User's rights regarding their data

3. **Anonymization Limitations**
   - Even anonymized data reveals financial patterns
   - Aggregated data may still be personally identifiable in context
   - No guarantee of complete privacy with cloud providers

#### Proposed License Addendum

```markdown
## Third-Party AI Services Disclosure

Ashfolio optionally integrates with third-party AI services for enhanced
financial analysis. When enabled, the following applies:

### Data Transmission
- Financial data (filtered by your privacy mode setting) is transmitted
  to your configured AI provider as part of conversation context
- Default mode (:anonymized) sends only relative percentages, ratios,
  and categorical data - not actual account names or dollar amounts
- Full mode sends complete financial data to the AI provider

### Supported Providers & Their Terms
- **Anthropic (Claude)**: [Privacy Policy](https://www.anthropic.com/privacy)
- **OpenAI**: [Privacy Policy](https://openai.com/privacy)
- **Ollama (Local)**: No data transmission - runs entirely on your device

### Your Choices
- Use :strict or :anonymized mode to limit data exposure
- Use Ollama for complete local processing with no cloud transmission
- Disable MCP integration entirely to prevent any AI data access

### No Warranty
Ashfolio makes no representations about third-party AI providers' data
handling practices. Users are responsible for reviewing provider terms
before enabling cloud AI features.

By enabling cloud AI features, you acknowledge that financial data
(as filtered by your privacy setting) will be transmitted to your
selected AI provider.
```

#### UI Consent Flow

First-time MCP setup with cloud provider:

```
┌─────────────────────────────────────────────────────────────────┐
│  Enable Claude Integration                                       │
│                                                                  │
│  This will allow Claude to analyze your portfolio data.          │
│                                                                  │
│  ⚠️  Data Disclosure                                             │
│                                                                  │
│  Your financial data (filtered by privacy mode) will be sent     │
│  to Anthropic as part of your conversation with Claude.          │
│                                                                  │
│  Privacy Mode: [Anonymized ▼]                                    │
│                                                                  │
│  • Anonymized (recommended): Percentages and ratios only         │
│  • Standard: Account names and summaries                         │
│  • Full: Complete data (use with Ollama only)                    │
│                                                                  │
│  📄 View Anthropic's Privacy Policy                              │
│  📄 View full data disclosure terms                              │
│                                                                  │
│  ☐ I understand that my financial data will be transmitted       │
│    to Anthropic when using Claude integration                    │
│                                                                  │
│  [Cancel]                              [Enable Integration]      │
└─────────────────────────────────────────────────────────────────┘
```

#### Configuration Persistence

```elixir
# Store user consent in database
defmodule Ashfolio.Settings.AiConsent do
  use Ash.Resource

  attributes do
    uuid_primary_key :id
    attribute :provider, :atom  # :anthropic, :openai, :ollama
    attribute :privacy_mode, :atom  # :strict, :anonymized, :standard, :full
    attribute :consented_at, :utc_datetime
    attribute :consent_version, :string  # Track terms version
    attribute :ip_hash, :string  # For audit trail (hashed)
  end
end
```

### Future Legal Considerations

| Item | Status | Notes |
|------|--------|-------|
| GDPR compliance | Future | Data portability, right to deletion |
| CCPA compliance | Future | California privacy requirements |
| Financial data regulations | Research | May vary by jurisdiction |
| Provider agreement updates | Ongoing | Monitor for terms changes |

### Recommendation

Before v1.0 release with MCP features:
- [ ] Legal review of disclosure language
- [ ] Confirm compliance with Anthropic/OpenAI terms of service
- [ ] Determine if financial data has special regulatory status
- [ ] Establish process for updating disclosures when provider terms change

## Security Considerations

### Data Privacy (Critical)

**Tool results are sent to the LLM provider as conversation context.**

Mitigations:
- **Privacy mode setting**: `:strict`, `:anonymized`, `:standard`, or `:full`
- **Default to `:anonymized`**: Full analytical capability without exposing sensitive data
- **Anonymizer transforms**: Converts amounts to percentages, names to IDs, values to tiers
- **Require `:full` mode opt-in**: User must explicitly enable for complete data access
- **UI warning**: Display notice when cloud LLM is configured
- **Local LLM recommendation**: Suggest Ollama for maximum privacy

### MCP Endpoint Security

- **Local-first**: MCP server only accessible locally by default
- **No authentication required**: Single-user, database-as-user model
- **Read-heavy**: Most operations are queries, not mutations
- **Audit trail**: Log all tool invocations
- **Privacy filter**: All results pass through `PrivacyFilter` before returning

### Future Code Execution Security

When implemented:
- Sandboxed execution environment (WASM, Docker, or similar)
- Time limits on execution (30s max)
- Memory limits (256MB max)
- No filesystem access outside sandbox
- No network access from sandbox
- Allowlist of callable tools

## Testing Strategy

### Unit Tests

```elixir
# test/ashfolio_web/mcp/tool_definitions_test.exs
describe "tool examples" do
  test "all tools have at least one example" do
    for {tool_name, examples} <- ToolDefinitions.tool_examples() do
      assert length(examples) >= 1, "#{tool_name} needs examples"
    end
  end

  test "examples include minimal, partial, and full patterns" do
    examples = ToolDefinitions.tool_examples()["list_transactions"]
    assert Enum.any?(examples, &(map_size(&1.input) == 0))  # minimal
    assert Enum.any?(examples, &(map_size(&1.input) > 2))   # full
  end
end
```

### Integration Tests

```elixir
# test/ashfolio_web/mcp/server_test.exs
describe "MCP server" do
  test "initializes with correct capabilities" do
    {:ok, response} = send_mcp_request("initialize", %{})
    assert response["capabilities"]["tools"]
  end

  test "lists available tools" do
    {:ok, response} = send_mcp_request("tools/list", %{})
    tool_names = Enum.map(response["tools"], & &1["name"])
    assert "list_accounts" in tool_names
    assert "list_transactions" in tool_names
  end

  test "executes tool and returns results" do
    {:ok, response} = send_mcp_request("tools/call", %{
      "name" => "list_accounts",
      "arguments" => %{}
    })
    assert response["result"]["content"]
  end
end
```

## References

- [Anthropic: Advanced Tool Use](https://www.anthropic.com/engineering/advanced-tool-use)
- [Anthropic: Code Execution with MCP](https://www.anthropic.com/engineering/code-execution-with-mcp)
- [MCP Specification](https://modelcontextprotocol.io/)
- [Ash AI Documentation](https://hexdocs.pm/ash_ai/)

---

*Last Updated: November 2025 | Target: v0.9.0 - v1.0+*
