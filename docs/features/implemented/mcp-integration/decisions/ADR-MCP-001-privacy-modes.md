# ADR-MCP-001: Privacy Modes for MCP Tool Results

## Status

Proposed

## Date

2024-11-26

## Context

Ashfolio is implementing MCP (Model Context Protocol) integration to allow Claude to help users analyze their portfolios. A critical design decision is how to handle the privacy of financial data when tool results are sent to Anthropic's servers as part of the conversation context.

### Problem Statement

When a user asks Claude "What's my portfolio allocation?", the MCP tool `list_accounts` executes locally and returns account data. This data is then sent to Anthropic as part of the conversation, enabling Claude to formulate a response. However, this means sensitive financial information (account names, balances, holdings) is transmitted to and processed by a third-party cloud service.

### Constraints

1. **Single-user model**: Ashfolio is a personal finance app with no authentication
2. **Local-first philosophy**: User data is stored locally in SQLite
3. **Regulatory considerations**: GDPR, CCPA, and financial data privacy expectations
4. **Utility vs. Privacy trade-off**: More data enables better analysis, but increases exposure

### Requirements

- User must have control over what data is shared
- Default must be privacy-preserving (privacy by design)
- Claude must still be useful for financial analysis
- Consent must be informed and revocable

## Decision

Implement a four-tier privacy mode system that filters MCP tool results before they are sent to Anthropic:

### Privacy Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| **Strict** | Aggregate only | Users who want AI help with general questions but minimal data exposure |
| **Anonymized** | Relative values, no identifiers | Default. Enables useful analysis while protecting specifics |
| **Standard** | Names visible, amounts hidden | Users who want Claude to reference specific accounts |
| **Full** | All data unfiltered | Power users who accept the privacy trade-off |

### Anonymization Strategy (Default Mode)

| Data Type | Original | Anonymized |
|-----------|----------|------------|
| Account names | "Fidelity 401k" | "A" |
| Account IDs | UUID | "A", "B", "C" |
| Balances | $125,432.17 | 0.65 (weight) |
| Net worth | $193,127.00 | "six_figures" (tier) |
| Symbols | VTI, VXUS | "US Equity ETF", "Intl Equity ETF" |
| Transaction amounts | $2,500.00 | 0.02 (relative) |
| Dates | 2024-06-15 | "6 months ago" |
| **Ratios** | 0.22 | 0.22 (pass-through) |

The key insight is that **ratios and percentages preserve analytical utility without exposing absolute values**. Claude can still tell the user "Your savings rate of 22% is above the recommended 20% threshold" without knowing their actual income or savings amounts.

### Value Tiers

Instead of exact net worth, we use categorical tiers:

```elixir
@value_tiers [
  {:under_10k, 0, 10_000},
  {:five_figures, 10_000, 100_000},
  {:six_figures, 100_000, 1_000_000},
  {:seven_figures, 1_000_000, 10_000_000},
  {:eight_figures_plus, 10_000_000, :infinity}
]
```

This allows Claude to provide tier-appropriate advice (e.g., "With a six-figure portfolio, you should consider...") without knowing exact amounts.

### Implementation Architecture

```
User Request → MCP Tool Execution (Local) → Privacy Filter → Anthropic
                                                  ↓
                                            [Anonymizer]
                                                  ↓
                                          Filtered Result
```

The privacy filter sits between local tool execution and the MCP response, ensuring no unfiltered data reaches the cloud.

## Consequences

### Positive

1. **Privacy by default**: New users are protected without action
2. **Utility preserved**: Anonymized mode still enables useful financial analysis
3. **User control**: Four modes cover different comfort levels
4. **Regulatory compliance**: Consent tracking supports GDPR/CCPA
5. **Reversible**: Users can change modes at any time
6. **Auditable**: All tool invocations are logged

### Negative

1. **Complexity**: Four modes to test and maintain
2. **UX friction**: Users must understand and choose modes
3. **Feature limitations**: Strict mode reduces Claude's usefulness
4. **Mapping maintenance**: Asset class mappings need updates

### Risks

1. **Information leakage**: Careful testing needed to ensure no sensitive data leaks
2. **Correlation attacks**: Relative weights could theoretically be used to estimate values if portfolio is public
3. **Mode confusion**: Users may not understand implications of each mode

## Alternatives Considered

### Alternative 1: Binary On/Off

Simple enable/disable for all AI features.

**Rejected because**: Too coarse. Users lose all AI functionality if privacy-concerned.

### Alternative 2: Per-Tool Permissions

Users configure which tools are enabled individually.

**Rejected because**: Too complex for most users. Cognitive overhead too high.

### Alternative 3: Query-Based Consent

Ask for permission on each tool invocation.

**Rejected because**: Extremely disruptive UX. Consent fatigue would make the feature unusable.

### Alternative 4: Local-Only LLM

Run an LLM locally (e.g., Ollama) to avoid cloud transmission.

**Considered for future**: Good option but requires significant compute resources. Not rejected, but deferred to future iteration as opt-in alternative.

## Implementation Plan

1. **Phase 1**: Implement privacy filter with all four modes
2. **Phase 1**: Default to `:anonymized` mode
3. **Phase 3**: Add consent UI with mode selection
4. **Phase 3**: Add settings page for mode changes
5. **Future**: Consider local LLM as fifth option

## Related Decisions

- ADR-MCP-002: Consent Resource Design (pending)
- ADR-MCP-003: Audit Logging Strategy (pending)

## References

- [Anthropic MCP Specification](https://modelcontextprotocol.io/)
- [GDPR Article 7: Conditions for consent](https://gdpr-info.eu/art-7-gdpr/)
- [CCPA Consumer Rights](https://oag.ca.gov/privacy/ccpa)
- [Privacy by Design Principles](https://www.ipc.on.ca/wp-content/uploads/Resources/7foundationalprinciples.pdf)

---

## Appendix: Example Transformations

### List Accounts - Anonymized Mode

**Input (from database):**
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Fidelity 401k",
    "account_type": "investment",
    "balance": "125432.17",
    "institution": "Fidelity"
  },
  {
    "id": "6ba7b810-9dad-11d1-80b4-00c04fd430c8",
    "name": "Chase Checking",
    "account_type": "checking",
    "balance": "8500.00",
    "institution": "Chase"
  }
]
```

**Output (to Claude):**
```json
{
  "accounts": [
    {
      "id": "A",
      "type": "investment",
      "weight": 0.94
    },
    {
      "id": "B",
      "type": "checking",
      "weight": 0.06
    }
  ],
  "portfolio": {
    "account_count": 2,
    "value_tier": "six_figures",
    "allocation": {
      "investment": 0.94,
      "checking": 0.06
    }
  }
}
```

### Portfolio Summary - Anonymized Mode

**Input:**
```json
{
  "total_value": "133932.17",
  "savings_rate": 0.22,
  "debt_to_income": 0.15,
  "expense_ratio": 0.12,
  "accounts": [...]
}
```

**Output:**
```json
{
  "value_tier": "six_figures",
  "ratios": {
    "savings_rate": 0.22,
    "debt_to_income": 0.15,
    "expense_ratio": 0.12
  },
  "allocation": {
    "investment": 0.94,
    "cash": 0.06
  },
  "metrics": {
    "diversification_score": 0.75,
    "risk_level": "moderate"
  }
}
```

This transformation preserves all the ratios and metrics Claude needs for analysis while removing any absolute dollar amounts.
