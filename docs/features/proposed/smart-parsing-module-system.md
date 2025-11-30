# Smart Parsing Module System Roadmap

## Overview

This roadmap outlines the development of a **local-first, rule-based parsing system** for Ashfolio that enables intelligent data entry without requiring external AI services. The module system provides fast, private, offline-capable parsing for onboarding and ongoing data entry.

## Strategic Vision

Transform the initial onboarding experience from manual form-filling to **conversational data entry** while maintaining Ashfolio's core principles:

- **Privacy First**: All parsing happens locally, no data leaves the user's machine
- **Offline Capable**: Works without internet after initial install
- **Fast Response**: Sub-millisecond parsing vs 1-10 seconds for LLM calls
- **Predictable Results**: Deterministic rule-based matching vs probabilistic AI
- **Zero Dependencies**: No API keys, no external services, no usage costs

## Current State (v0.8.0)

### AI-Powered Parsing (Existing)

- `Ashfolio.AI.Dispatcher` routes text to handlers
- `Ashfolio.AI.Handlers.TransactionParser` parses via LLM
- Requires Ollama (local) or OpenAI (cloud) configuration
- 1-10 second response time depending on provider

### Limitations of Current Approach

- Requires AI infrastructure setup (Ollama or API key)
- Latency impacts user experience for simple inputs
- Overkill for structured, predictable input patterns
- Privacy concerns when using cloud providers

## Module System Architecture

### Design Principles

1. **Tiered Parsing**: Rule-based first, AI fallback optional
2. **Composable Modules**: Each parser handles one domain
3. **Extensible Patterns**: Easy to add new parsing rules
4. **Confidence Scoring**: Indicate certainty of parsed values
5. **Graceful Degradation**: Always provide partial results

### Proposed Directory Structure

```
lib/ashfolio/parsing/
├── parser.ex                    # Main entry point & router
├── behaviours/
│   └── parseable.ex             # Behaviour for all parsers
├── modules/
│   ├── expense_parser.ex        # Monthly expense extraction
│   ├── income_parser.ex         # Salary/income parsing
│   ├── account_parser.ex        # Account setup parsing
│   ├── subscription_parser.ex   # Known subscription lookup
│   └── amount_parser.ex         # Shared currency/number utilities
├── patterns/
│   ├── expense_patterns.ex      # Expense regex + keywords
│   ├── income_patterns.ex       # Income/salary patterns
│   ├── date_patterns.ex         # Relative date parsing
│   └── category_keywords.ex     # Category classification rules
├── data/
│   ├── subscription_database.ex # Known services & prices
│   └── category_mappings.ex     # Keyword → category mappings
└── enhancers/
    └── ai_fallback.ex           # Optional LLM enhancement
```

## Phase 1: Foundation (v0.9.0)

### Goals

- Establish parsing behaviour and router
- Implement expense parsing module
- Create shared amount/currency utilities
- Build subscription lookup database

### Deliverables

#### 1.1 Parsing Behaviour & Router

```elixir
defmodule Ashfolio.Parsing.Parseable do
  @moduledoc "Behaviour for all parsing modules"

  @callback can_parse?(text :: String.t()) :: boolean()
  @callback parse(text :: String.t()) :: {:ok, result()} | {:error, reason()}
  @callback confidence() :: :high | :medium | :low
end

defmodule Ashfolio.Parsing.Parser do
  @moduledoc "Routes text to appropriate parsing modules"

  def parse(text, opts \\ [])
  def parse_expenses(text)
  def parse_income(text)
  def parse_account(text)
end
```

#### 1.2 Expense Parser Module

Handles patterns like:
- "I spend $1800 on rent"
- "$500/month for groceries"
- "Netflix, Spotify, gym membership"
- "About 4k monthly on bills"

Features:
- Explicit amount extraction with category inference
- Bulk expense parsing from comma-separated lists
- Subscription service lookup with known prices
- Category classification via keyword matching

#### 1.3 Subscription Database

Built-in knowledge of common subscription services:

| Service | Default Price | Category |
|---------|--------------|----------|
| Netflix | $15.99 | Entertainment |
| Spotify | $10.99 | Entertainment |
| Amazon Prime | $14.99 | Shopping |
| Gym/Planet Fitness | $25-50 | Health & Fitness |
| Phone/Mobile | $50-100 | Utilities |

Extensible via user configuration.

#### 1.4 Amount Parser Utilities

Shared utilities for parsing monetary values:
- Currency symbol handling ($, €, £)
- Thousand separators (1,000 vs 1000)
- K/M abbreviations (85k = 85,000)
- Range parsing ("50-100" → midpoint or range)

### Success Metrics

- Parse 80% of common expense descriptions correctly
- Sub-5ms response time for all parsing operations
- Zero external dependencies required
- 95% test coverage on parsing modules

## Phase 2: Income & Accounts (v0.10.0)

### Goals

- Implement income/salary parsing
- Add account setup parsing
- Build date pattern recognition
- Create onboarding UI integration

### Deliverables

#### 2.1 Income Parser Module

Handles patterns like:
- "I make 85k a year"
- "Salary is $7,000/month"
- "$45/hour, 40 hours/week"
- "About 100k annually"

Features:
- Period normalization (hourly → annual)
- K abbreviation expansion
- Implicit period detection ("85k" assumes annual)
- Monthly/annual calculation

#### 2.2 Account Parser Module

Handles patterns like:
- "Fidelity 401k with 50k"
- "Vanguard Roth IRA, mostly VTI"
- "Chase checking, about 5k balance"
- "Savings account at 4.5% APY"

Features:
- Institution name extraction
- Account type inference (401k, IRA, checking, savings)
- Balance extraction with confidence scoring
- Symbol/holding mention detection

#### 2.3 Date Pattern Recognition

Handles relative dates:
- "yesterday", "today", "last week"
- "last month", "3 months ago"
- "beginning of the year"
- "Q1 2024", "January"

#### 2.4 Onboarding UI Integration

LiveView component for guided data entry:

```
┌─────────────────────────────────────────────────────────┐
│  Tell me about your monthly expenses:                   │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Netflix, Spotify, $1800 rent, about $500 food   │   │
│  └─────────────────────────────────────────────────┘   │
│                                         [Parse →]       │
│                                                         │
│  Parsed Results:                          ⚡ <1ms       │
│  ┌─────────────────────────────────────────────────┐   │
│  │ ✅ Netflix      $15.99/mo   Entertainment       │   │
│  │ ✅ Spotify      $10.99/mo   Entertainment       │   │
│  │ ✅ Rent         $1,800/mo   Housing             │   │
│  │ ✅ Food         $500/mo     Food & Dining       │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  [✓ Save All]  [Edit Amounts]  [Add More]              │
└─────────────────────────────────────────────────────────┘
```

### Success Metrics

- Parse 85% of income descriptions correctly
- Account setup success rate > 80%
- Onboarding completion time < 5 minutes
- User satisfaction with parsed accuracy > 90%

## Phase 3: Intelligence & Learning (v0.11.0)

### Goals

- Add user correction learning
- Implement context-aware parsing
- Build confidence calibration
- Create AI fallback integration

### Deliverables

#### 3.1 User Correction Learning

// Nice To Have - Low Value
When users correct parsed values, learn from corrections:
- Store correction patterns locally? (SQLite)
- Adjust confidence scores based on accuracy history
- Suggest corrections based on past user behavior

```elixir
defmodule Ashfolio.Parsing.Learning do
  def record_correction(original, corrected)
  def apply_learned_patterns(parsed_result)
  def get_accuracy_stats()
end
```

#### 3.2 Context-Aware Parsing

Use existing user data to improve parsing:
- Match account names to existing accounts
- Suggest categories based on past categorizations
- Infer symbols from portfolio holdings
- Use expense history for amount validation

#### 3.3 Confidence Calibration

Track actual vs predicted accuracy:
- Calibrate confidence scores over time
- Surface low-confidence results for review
- Provide confidence explanations

#### 3.4 AI Fallback Integration

Optional enhancement for ambiguous cases:
- Route low-confidence results to AI
- Use AI for natural language that defies patterns
- Maintain privacy by default (opt-in only)

```elixir
defmodule Ashfolio.Parsing.Parser do
  def parse(text, opts \\ []) do
    case try_rule_based(text) do
      {:ok, result} when result.confidence in [:high, :medium] ->
        {:ok, result}

      {:ok, result} when opts[:allow_ai] ->
        enhance_with_ai(text, result)

      {:error, _} when opts[:allow_ai] ->
        try_ai_fallback(text)

      other ->
        other
    end
  end
end
```

### Success Metrics

- Parsing accuracy improves 5% after 100 corrections
- Context-aware suggestions used in 30% of parses
- AI fallback needed for < 10% of inputs
- User trust in parsed results > 95%

## Phase 4: Advanced Features (v0.12.0+)

### Goals

- Multi-language support (stretch)
- Voice input parsing
- Bulk import enhancement
- API for third-party integration

### Potential Deliverables

#### 4.1 Internationalization

- Currency-aware parsing (EUR, GBP, etc.)
- Localized number formats (1.000,00 vs 1,000.00)
- Regional subscription databases
- Multi-language keyword dictionaries

#### 4.2 Voice Input

- Speech-to-text integration
- Acoustic similarity matching
- Confirmation before saving

#### 4.3 Bulk Import Enhancement

- CSV/QFX parsing with smart column detection
- Pattern learning from imported data
- Duplicate detection and merging

#### 4.4 External API

- REST endpoint for parsing requests
- Webhook integration for automation
- CLI tool for batch processing

## Technical Implementation Details

### Pattern Matching Strategy

```elixir
# Expense patterns with named captures
@expense_patterns [
  # "I spend $X on Y"
  ~r/(?:spend|pay|paid)\s+\$?(?<amount>[\d,]+(?:\.\d{2})?)\s+(?:on|for)\s+(?<description>.+)/i,

  # "$X/month for Y" or "$X monthly on Y"
  ~r/\$?(?<amount>[\d,]+(?:\.\d{2})?)\s*(?:\/|per|a)?\s*(?:month|mo)\w*\s+(?:for|on)\s+(?<description>.+)/i,

  # "Y costs $X"
  ~r/(?<description>.+?)\s+(?:costs?|is)\s+\$?(?<amount>[\d,]+(?:\.\d{2})?)/i
]
```

### Category Classification

```elixir
@category_keywords %{
  "Housing" => ~w(rent mortgage hoa property tax landlord apartment lease home),
  "Transportation" => ~w(car gas fuel uber lyft parking insurance auto vehicle),
  "Food & Dining" => ~w(food grocery groceries restaurant dinner lunch coffee),
  "Utilities" => ~w(electric electricity gas water internet phone mobile cable wifi),
  "Entertainment" => ~w(netflix spotify hulu disney movie theater concert music game),
  "Health & Fitness" => ~w(gym doctor medical prescription health dental fitness yoga),
  "Shopping" => ~w(amazon clothes clothing shopping target walmart),
  "Insurance" => ~w(insurance life health auto home renters),
  "Subscriptions" => ~w(subscription membership premium service)
}
```

### Confidence Scoring

```elixir
defmodule Ashfolio.Parsing.Confidence do
  @doc """
  Calculate confidence based on parsing method and match quality.
  """
  def score(parsed_result) do
    base_score = case parsed_result.source do
      :explicit_amount -> 0.95    # "I spend $1800 on rent"
      :subscription_lookup -> 0.90 # "Netflix" → known price
      :bulk_pattern -> 0.75       # "$1800 rent, $500 food"
      :keyword_only -> 0.50       # "rent" without amount
      :ai_fallback -> 0.85        # AI parsed
    end

    # Adjust based on specificity
    adjustments = [
      if(parsed_result.amount, do: 0.05, else: -0.10),
      if(parsed_result.category != "Uncategorized", do: 0.05, else: 0),
      if(parsed_result.recurring != nil, do: 0.02, else: 0)
    ]

    min(1.0, base_score + Enum.sum(adjustments))
  end
end
```

## Integration with Existing AI System

The module system complements (not replaces) the existing AI infrastructure:

```
User Input
    │
    ▼
┌──────────────────┐
│  Parsing.Parser  │ ◄── Primary path (fast, local)
└────────┬─────────┘
         │
         ▼
    ┌────────────┐
    │ Confidence │
    │   Check    │
    └─────┬──────┘
          │
    ┌─────┴─────┐
    │           │
High/Medium    Low (+ allow_ai: true)
    │           │
    ▼           ▼
  Return    ┌──────────────────┐
  Result    │ AI.Dispatcher    │ ◄── Fallback path
            └────────┬─────────┘
                     │
                     ▼
               AI-Enhanced
                 Result
```

## Testing Strategy

### Unit Tests

- Pattern matching accuracy for each regex
- Category classification correctness
- Amount parsing edge cases
- Confidence score calculations

### Integration Tests

- Multi-pattern input handling
- Parser routing correctness
- UI component rendering
- Database persistence

### Property-Based Tests

```elixir
# Generate random expense descriptions
property "parses valid expense amounts" do
  check all amount <- positive_float(),
            category <- member_of(@categories) do
    text = "I spend $#{:erlang.float_to_binary(amount, decimals: 2)} on #{category}"
    assert {:ok, result} = ExpenseParser.parse(text)
    assert_decimal_equal(result.amount, Decimal.from_float(amount))
  end
end
```

### Accuracy Benchmarks

Track parsing accuracy over time:
- Maintain test corpus of 500+ real-world examples
- Measure precision and recall per category
- Regression alerts when accuracy drops

## Migration Path

### For New Users

- Module system is the default parsing method
- AI features available as opt-in enhancement
- No configuration required for basic functionality

### For Existing v0.8.0 Users

- Existing AI configuration continues to work
- Module system available as faster alternative
- Gradual migration recommended

### Configuration

```elixir
# config/config.exs

# Default: Rule-based parsing only (fastest, most private)
config :ashfolio, :parsing,
  method: :rule_based

# Optional: Enable AI fallback for ambiguous cases
config :ashfolio, :parsing,
  method: :hybrid,
  ai_fallback: true,
  ai_confidence_threshold: 0.60
```

## Success Criteria

### Phase 1 Complete When

- [ ] Expense parser handles 10+ common patterns
- [ ] Subscription database includes 50+ services
- [ ] Amount parser handles all currency formats
- [ ] 100+ unit tests passing
- [ ] Documentation complete

### Phase 2 Complete When

- [ ] Income parser handles salary/hourly/annual
- [ ] Account parser creates valid accounts
- [ ] Onboarding UI integrated with parsing
- [ ] User testing shows 80%+ satisfaction

### Phase 3 Complete When

- [ ] Learning system improves accuracy over time
- [ ] Context-aware parsing uses portfolio data
- [ ] AI fallback seamlessly integrated
- [ ] Confidence calibration validated

## Resource Requirements

### Phase 1 (Foundation)

- Development: 2-3 weeks
- Testing: 1 week
- Documentation: 2-3 days

### Phase 2 (Income & Accounts)

- Development: 2-3 weeks
- UI Integration: 1 week
- User Testing: 1 week

### Phase 3 (Intelligence)

- Development: 3-4 weeks
- ML/Learning: 2 weeks
- Calibration: 1 week

## Risks & Mitigations

### Pattern Brittleness

**Risk**: Regex patterns fail on unexpected input formats
**Mitigation**: Layered parsing with multiple pattern attempts, extensive test corpus

### Subscription Database Staleness

**Risk**: Service prices change, new services emerge
**Mitigation**: User-editable database, community contributions, periodic updates

### Over-Confidence

**Risk**: Parser reports high confidence on incorrect parses
**Mitigation**: Calibration system, user correction tracking, conservative scoring

### Feature Creep

**Risk**: Adding too many patterns creates maintenance burden
**Mitigation**: Focus on 80/20 patterns, prioritize common cases

## Conclusion

The Smart Parsing Module System provides a privacy-first, fast, offline-capable alternative to LLM-based parsing. By handling common patterns locally and reserving AI for truly ambiguous cases, Ashfolio can deliver an excellent onboarding experience while maintaining its local-first principles.

This system is **complementary** to the existing AI infrastructure, not a replacement. Users who prefer AI-powered parsing can continue using it, while users who prioritize privacy and speed can rely on the module system.

---

*Last Updated: November 2025 | Target: v0.9.0 - v0.12.0*
