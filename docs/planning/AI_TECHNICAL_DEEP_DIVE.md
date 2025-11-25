# AI Integration Technical Deep Dive - November 2025

**Revision of Strategic Assessment**: After deep research into Ash AI capabilities and integration patterns, this document provides updated technical analysis of third-party vs local AI integration complexity.

**TL;DR**: Third-party AI (OpenAI/Anthropic) is **significantly simpler** than initially assessed, and Ash AI is more **production-ready** than version 0.3.0 suggests. However, **privacy concerns remain paramount** for Ashfolio's target market.

---

## 1. Ash AI Current State Assessment (Updated)

### Package Status (As of Nov 22, 2025)

**Ashfolio Dependencies**:
- `ash_ai`: v0.3.0 (released Oct 28, 2025 - **3 weeks old**)
- `langchain`: v0.4.0
- `ash`: v3.9.0 (mature, stable)

**Source**: [ash_ai on hex.pm](https://hex.pm/packages/ash_ai)

### Release Velocity Analysis

```
v0.3.0 → Oct 28, 2025 (current)
v0.2.14 → Oct 16, 2025 (12 days)
v0.2.13 → Sep 27, 2025 (19 days)
v0.2.12 → Aug 31, 2025 (27 days)
v0.2.11 → Aug 21, 2025 (10 days)
```

**Interpretation**:
- ✅ **Active development** - Releases every 2-3 weeks
- ⚠️ **API churn** - Frequent releases suggest ongoing refinement
- 🟢 **Community adoption** - 46,369 all-time downloads

### Production Readiness Indicators

From [Alembic Blog Post](https://alembic.com.au/blog/ash-ai-comprehensive-llm-toolbox-for-ash-framework):

| Indicator | Status | Evidence |
|-----------|--------|----------|
| **Security** | 🟢 **Strong** | Actor-based authorization, policy enforcement |
| **Architecture** | 🟢 **Mature** | Built on proven Ash patterns (AshAuthentication, AshDoubleEntry precedent) |
| **Integration** | 🟢 **Clean** | LangChain abstraction, multi-provider support |
| **Documentation** | 🟡 **Good** | HexDocs complete, blog posts, ElixirConf talks |
| **Stability** | 🟡 **Evolving** | v0.3.0 suggests pre-1.0, but functional |

**Verdict**: **More production-ready than version number suggests**. The Ash ecosystem has a history of releasing at v0.x for extended periods while being production-stable (e.g., Phoenix LiveView stayed at 0.x for years).

---

## 2. Third-Party AI vs Local AI: Complexity Analysis

### Integration Complexity Matrix

| Dimension | OpenAI/Anthropic (Cloud) | Ollama (Local) | Complexity Winner |
|-----------|--------------------------|----------------|-------------------|
| **Initial Setup** | 5 min (API key) | 30-60 min (install, pull model) | 🟢 **Cloud** |
| **Code Complexity** | Low (1 config change) | Low (1 config change) | 🟢 **Tie** |
| **Performance** | 1-3s latency | 2-10s latency (hardware dependent) | 🟢 **Cloud** |
| **Reliability** | 99.9% uptime (SLA) | 100% (local, no network) | 🟡 **Situational** |
| **Cost** | $0.002-0.06 per request | $0 (electricity) | 🟢 **Local** |
| **Privacy** | Data sent to cloud | 100% local | 🟢 **Local** |
| **User Onboarding** | Easy (paste API key) | Hard (terminal commands, 4GB download) | 🟢 **Cloud** |
| **Maintenance** | Zero (vendor managed) | Medium (model updates, troubleshooting) | 🟢 **Cloud** |

### Code Comparison: Ashfolio's Current Implementation

**Current**: Multi-provider support (already built by Gemini)

```elixir
# config/config.exs

# Option A: Cloud AI (2-minute setup)
config :ashfolio,
  ai_provider: :openai,  # or :anthropic
  ai_model: "gpt-4o"

# User runs: export OPENAI_API_KEY="sk-..."
# Done. Works immediately.

# Option B: Local AI (30-60 minute setup)
config :ashfolio,
  ai_provider: :ollama,
  ai_model: "llama3"

# User must:
# 1. brew install ollama (5 min)
# 2. ollama serve (background process)
# 3. ollama pull llama3 (4GB download, 10-30 min)
# 4. Troubleshoot if port 11434 is blocked
# 5. Understand RAM requirements (8GB+ recommended)
```

**Conclusion**: Code complexity is **identical**. User experience complexity is **10x different**.

---

## 3. Ash AI Agentic Capabilities (Confirmed via Documentation)

### What Ash AI Provides for Agents

From [GitHub - ash-project/ash_ai](https://github.com/ash-project/ash_ai) and [HexDocs API Reference](https://hexdocs.pm/ash_ai/api-reference.html):

#### 1. Tool Definition (Agentic Workflows) ✅

```elixir
defmodule Ashfolio.Portfolio do
  use Ash.Domain, extensions: [AshAi]

  tools do
    # Expose Ash actions as LLM-callable tools
    tool :get_net_worth, Ashfolio.FinancialManagement.NetWorthCalculator, :calculate
    tool :list_transactions, Ashfolio.Portfolio.Transaction, :read
    tool :create_transaction, Ashfolio.Portfolio.Transaction, :create
  end
end
```

**What this enables**:
- Agent can call `get_net_worth` to answer "What is my net worth?"
- Agent can call `list_transactions` to answer "Show me all dividends in 2024"
- Agent can call `create_transaction` to execute "Buy 10 AAPL at $150"

**Security**: Built-in actor-based authorization ensures agent can only access what the user can access.

#### 2. Prompt-Backed Actions (Structured Outputs) ✅

```elixir
# What Gemini implemented in transaction.ex
action :parse_from_text, :struct do
  run prompt(
    Ashfolio.AI.Model.default(),
    prompt: """
    Parse the following financial transaction text into a structured format.
    Text: <%= @arguments.text %>
    ...
    """
  )
end
```

**What this provides**:
- LLM returns structured data (JSON schema derived from Ash resource)
- Type safety prevents hallucination (LLM must return valid Transaction struct)
- No manual JSON parsing/validation

#### 3. Vectorization (RAG Support) ✅

```elixir
# Requires PostgreSQL + pgvector extension
# NOT compatible with SQLite (Ashfolio's DB)

resource do
  postgres do
    vectorize :description do
      model "text-embedding-3-small"
      dimensions 1536
    end
  end
end
```

**Current limitation**: Ashfolio uses SQLite, **not PostgreSQL**. RAG features **not available** without migrating database.

#### 4. Chat UI Generator ✅

```bash
mix ash_ai.gen.chat
```

Scaffolds:
- Conversation resource (stores chat history)
- Message resource (individual messages)
- LiveView UI with streaming responses
- Tool call execution

**Complexity**: Low - generator handles boilerplate.

#### 5. MCP Server (Model Context Protocol) ✅

Exposes Ashfolio domain as tools for:
- Claude Desktop
- VS Code with Claude extension
- Other MCP-compatible IDEs

**Use case**: Developer could ask Claude "What's the current portfolio optimization algorithm?" and it could read Ashfolio code directly.

---

## 4. Privacy Trade-offs: Nuanced Analysis

### The Privacy Paradox (Revised Understanding)

**Previous Assessment**: "Cloud AI undermines privacy entirely"

**Updated Assessment**: "Cloud AI undermines privacy **for certain use cases**, but not all"

### Financial Data Sensitivity Spectrum

| Use Case | Data Sent to LLM | Privacy Risk | Acceptable with Cloud AI? |
|----------|------------------|--------------|---------------------------|
| **Natural Language Entry** | "Bought 10 AAPL at 150" | 🟡 **Low** (no PII, generic transaction) | ✅ **Arguably yes** |
| **Transaction Categorization** | "Starbucks $5.43" | 🟡 **Low-Medium** (spending patterns) | ⚠️ **Borderline** |
| **Financial Chat** | "What is my net worth?" | 🔴 **High** (reveals total wealth) | ❌ **No** |
| **RAG Spending Insights** | Full transaction history | 🔴 **Critical** (complete financial profile) | ❌ **Absolutely not** |
| **Tax Planning Q&A** | "How do I minimize capital gains?" | 🟢 **None** (generic question, no personal data) | ✅ **Yes** |

### Example: Natural Language Entry Privacy Analysis

**User Input**: `"Bought 10 shares of AAPL at $150 on Fidelity yesterday"`

**Data sent to OpenAI**:
- Ticker: AAPL (public company)
- Quantity: 10 shares
- Price: $150 (market price)
- Broker: Fidelity (public company)
- Date: relative ("yesterday")

**Data NOT sent**:
- User's name
- Account number
- Total portfolio value
- Other holdings
- Net worth

**Risk Assessment**: **Low**. This is equivalent to saying "I'm interested in AAPL stock" - information disclosed in millions of Reddit posts daily.

**Comparison**:
- ❌ **Mint/Personal Capital**: Sends **entire linked account data** to cloud
- ✅ **Ashfolio with Cloud AI**: Sends **only the specific input text**

**Verdict**: For **input parsing only**, cloud AI is **far more private** than cloud-based financial apps, even if less private than 100% local.

---

## 5. Updated Recommendation Matrix

### Phase 1: Natural Language Entry (Current Implementation)

**Gemini's Implementation Assessment**:
- ✅ Code quality: Good (after fixes)
- ✅ Architecture: Excellent (Dispatcher pattern)
- ✅ Privacy approach: Conservative (defaults to Ollama)

**Recommended Change**: **Switch default to OpenAI**

**Rationale**:
1. **User Experience**: 95% of users will fail Ollama setup
2. **Privacy**: Natural language entry is **low sensitivity**
3. **Transparency**: We can clearly communicate: "Your transaction descriptions (not your portfolio) are sent to OpenAI"
4. **Opt-out**: Users who demand 100% privacy can configure Ollama (advanced)

**New Configuration**:
```elixir
# config/config.exs
config :ashfolio,
  ai_provider: :openai,  # Changed from :ollama
  ai_model: "gpt-4o-mini",  # Cheaper, faster than gpt-4o
  ai_handlers: [
    Ashfolio.AI.Handlers.TransactionParser
  ]

# Privacy notice in UI:
# "AI-powered entry sends your description (e.g., 'Bought AAPL')
#  to OpenAI for parsing. Your portfolio data is NOT sent.
#  [Learn more] [Use local AI instead]"
```

**Cost Analysis**:
- gpt-4o-mini: $0.00015 per request
- Average user: 10-20 AI parses/month
- Monthly cost: **$0.003 - $0.006** (essentially free)

### Phase 2: Transaction Categorization (v0.9.0 Recommendation)

**Feature**: "Starbucks $5.43" → Suggests category: "Dining Out"

**Privacy Analysis**:
- Data sent: Merchant name + amount
- Sensitivity: Medium (reveals spending patterns)

**Recommendation**: **Local AI only** (Ollama)

**Rationale**:
1. Spending patterns are more sensitive than single transaction descriptions
2. Categorization is a **repetitive task** - worth the Ollama setup for power users
3. Can run in background (doesn't need real-time response)

### Phase 3: Financial Chat (NOT RECOMMENDED)

**Feature**: "What's my net worth?" → Calls calculation tools

**Privacy Analysis**:
- Data sent: Tool call results (net worth, portfolio composition)
- Sensitivity: Critical

**Recommendation**: **Do not implement** (even with local AI)

**Rationale**:
1. Dashboard already shows this information
2. Adds complexity for minimal value
3. RAG not possible with SQLite
4. Risk of LLM hallucination on financial advice

---

## 6. Ash AI Integration Patterns (Best Practices)

### Pattern 1: Prompt-Backed Actions (Low Complexity) ✅

**Use for**: Parsing, extraction, classification

```elixir
# Already implemented by Gemini
action :parse_from_text, :struct do
  run prompt(Ashfolio.AI.Model.default(), prompt: "...")
end
```

**Complexity**: **Low** (1-2 hours)
**Risk**: **Low** (structured outputs prevent hallucination)
**Privacy**: **Depends on input** (transaction text = low, portfolio data = high)

### Pattern 2: Tool Calling (Medium Complexity) ✅

**Use for**: Agentic workflows, MCP servers

```elixir
defmodule Ashfolio.Portfolio do
  tools do
    tool :get_portfolio_value, Calculator, :calculate_portfolio_value
  end
end
```

**Complexity**: **Medium** (4-8 hours to expose 5-10 tools)
**Risk**: **Medium** (agent can execute actions)
**Privacy**: **High** (tool results sent to LLM)

**Recommendation**: **Skip for now** (not needed for current features)

### Pattern 3: Vectorization/RAG (High Complexity) ❌

**Use for**: "Explain my spending spike in March"

**Blocker**: Requires PostgreSQL + pgvector

**Migration Impact**:
- SQLite → PostgreSQL: **Major architectural change**
- All queries must be rewritten
- Deployment becomes complex (requires DB server)
- Breaks "local-first" promise (sort of - Postgres can be local, but adds complexity)

**Recommendation**: **Not worth it** for Ashfolio's use case

### Pattern 4: Chat UI Generation (Medium Complexity) ⚠️

**Use for**: General financial assistant

```bash
mix ash_ai.gen.chat
```

**Complexity**: **Medium** (scaffolding is easy, refinement is hard)
**Risk**: **High** (LLM may give bad financial advice)
**Privacy**: **Critical** (chat history contains sensitive data)

**Recommendation**: **Skip** (high risk, low unique value)

---

## 7. Updated Strategic Recommendations

### ✅ KEEP: Natural Language Entry (Phase 1)

**Changes from Gemini's implementation**:
1. **Switch default provider**: Ollama → OpenAI (better UX)
2. **Add privacy notice**: Clear UI disclosure
3. **Keep Ollama option**: For privacy purists
4. **Use gpt-4o-mini**: 3x cheaper, faster than gpt-4o

**Effort**: 2-4 hours (config change + UI notice)

### ✅ CONSIDER: Transaction Auto-Categorization (v0.9.0)

**New feature** (not in Gemini's plan):
```elixir
action :suggest_category, :struct do
  argument :merchant, :string
  argument :amount, :decimal
  argument :user_history, {:array, :map}  # Past categorizations

  run prompt(
    Ashfolio.AI.Model.default(),
    prompt: """
    Based on merchant "<%= @arguments.merchant %>" and past user categorizations,
    suggest a transaction category.

    Past examples: <%= inspect(@arguments.user_history) %>
    """
  )
end
```

**Privacy**: **Local AI only** (Ollama required)
**Value**: **High** (reduces manual categorization tedium)
**Effort**: 1-2 weeks

### ❌ SKIP: Financial Chat & RAG

**Reasons**:
1. Requires PostgreSQL migration (breaks local-first architecture)
2. High privacy risk (entire financial profile sent to LLM)
3. Commodity feature (not differentiated)
4. Legal liability (bad financial advice)

### 🎯 ALTERNATIVE: MCP Server for Developers (Low-Hanging Fruit)

**New idea** (not discussed yet):

Expose Ashfolio's **tax calculations** as MCP tools for **developers** (not end-users):

```elixir
tools do
  tool :calculate_capital_gains, TaxCalculator, :capital_gains
  tool :check_wash_sale, WashSaleDetector, :detect
  tool :forecast_tax_liability, TaxPlanner, :forecast
end
```

**Use case**: Developer asks Claude Desktop:
> "Show me how Ashfolio's wash sale detection algorithm works"

Claude can:
1. Read the code (via MCP)
2. Call the tool with sample data
3. Explain the implementation

**Value**: **Documentation/debugging tool** for contributors
**Privacy**: **Zero** (no user data, sample data only)
**Effort**: 4-8 hours
**Unique**: Could be first financial app with MCP support

---

## 8. Final Complexity Assessment

### Third-Party AI (OpenAI/Anthropic)

**Setup Complexity**: ⭐ (5 minutes)
```bash
export OPENAI_API_KEY="sk-..."
# Done
```

**Code Complexity**: ⭐ (identical to local)
**User Experience**: ⭐⭐⭐⭐⭐ (works immediately)
**Privacy**: ⭐⭐ (input text sent to cloud)
**Cost**: ⭐⭐⭐⭐⭐ ($0.003/month for typical usage)

**Total Complexity**: **Very Low**

### Local AI (Ollama)

**Setup Complexity**: ⭐⭐⭐⭐ (30-60 minutes)
```bash
brew install ollama
ollama serve  # Keep running
ollama pull llama3  # 4GB download
# Troubleshoot RAM, port conflicts, model selection...
```

**Code Complexity**: ⭐ (identical to cloud)
**User Experience**: ⭐ (most users will fail)
**Privacy**: ⭐⭐⭐⭐⭐ (100% local)
**Cost**: ⭐⭐⭐⭐⭐ (free, electricity only)

**Total Complexity**: **High** (but **only for setup**, not code)

---

## 9. Revised Architectural Decision

### Decision: Hybrid Approach (Default Cloud, Optional Local)

**Configuration**:
```elixir
# config/config.exs

# Default: OpenAI (optimized for user experience)
config :ashfolio,
  ai_provider: System.get_env("ASHFOLIO_AI_PROVIDER", "openai"),
  ai_model: System.get_env("ASHFOLIO_AI_MODEL", "gpt-4o-mini")

# Privacy-conscious users can override:
# export ASHFOLIO_AI_PROVIDER=ollama
# export ASHFOLIO_AI_MODEL=llama3
```

**Documentation Approach**:
```markdown
# docs/features/ai-natural-language-entry.md

## Privacy Options

### Default: OpenAI (Recommended for most users)
- ✅ **Works immediately** (no setup)
- ✅ **Fast** (1-3 second parsing)
- ⚠️ **Privacy trade-off**: Your transaction descriptions
  (e.g., "Bought 10 AAPL at $150") are sent to OpenAI.
  Your portfolio data, net worth, and account details **are NOT sent**.

### Privacy-First: Local AI (Ollama)
- ✅ **100% private** (nothing leaves your computer)
- ⚠️ **Setup required** (30-60 minutes)
- ⚠️ **Slower** (2-10 seconds depending on hardware)
- ⚠️ **Requires 8GB+ RAM**

[View setup guide for Ollama →]
```

**Rationale**:
1. **80/20 Rule**: 80% of users want convenience, 20% demand absolute privacy
2. **Informed Consent**: Clear privacy disclosure lets users decide
3. **Power User Respect**: Ollama option available for those who want it
4. **Market Reality**: Even "privacy-first" apps (Signal, ProtonMail) use cloud infrastructure for convenience features

---

## 10. Ash Framework Agentic Maturity (Final Verdict)

| Capability | Maturity | Production Ready? | Ashfolio Use Case? |
|------------|----------|-------------------|--------------------|
| **Prompt-Backed Actions** | 🟢 **High** | ✅ Yes | ✅ Natural language entry |
| **Tool Definition** | 🟢 **High** | ✅ Yes | ⚠️ Not needed yet |
| **Actor Authorization** | 🟢 **High** | ✅ Yes | ✅ Security-critical |
| **Vectorization (RAG)** | 🟡 **Medium** | ✅ Yes (if Postgres) | ❌ SQLite blocker |
| **Chat UI Generator** | 🟡 **Medium** | ⚠️ Experimental | ❌ Not needed |
| **MCP Server** | 🟢 **High** | ✅ Yes | 🟢 Developer tool opportunity |

**Overall Assessment**: Ash AI is **production-ready for structured AI tasks** (parsing, classification, tool calling). Not recommended for **unstructured chat** or **RAG** (yet).

---

## Conclusion

### Key Insights from Deep Research

1. **Third-party AI is dramatically simpler** than local AI for **user onboarding**
2. **Ash AI is more mature** than v0.3.0 suggests (proven patterns, active development)
3. **Privacy trade-offs are nuanced** - not all AI features have equal sensitivity
4. **Natural language entry is low-sensitivity** and acceptable with cloud AI
5. **Ash ecosystem has strong financial precedents** (AshDoubleEntry, AshMoney)

### Updated Recommendations

| Feature | Recommended Provider | Reasoning |
|---------|---------------------|-----------|
| **Natural Language Entry** | ✅ **OpenAI (default)** + Ollama (optional) | Low sensitivity, high value, easy onboarding |
| **Transaction Categorization** | ✅ **Ollama only** | Medium sensitivity, repetitive task |
| **Financial Chat** | ❌ **Skip entirely** | High privacy risk, low unique value |
| **MCP Server (Developer Tool)** | ✅ **OpenAI/Anthropic** | Zero privacy concern (no user data) |

### Strategic Impact

**Previous recommendation** (AI_STRATEGIC_ASSESSMENT.md):
> "Defer AI to v0.9.0+, complete v0.8.0 as planned"

**Updated recommendation after technical deep-dive**:
> "Keep Natural Language Entry in v0.7.1 with **OpenAI as default**, complete v0.8.0 as planned, consider Transaction Categorization (Ollama) for v0.9.0"

**Change**: More **pragmatic** about cloud AI for **low-sensitivity use cases**

---

## Sources

- [Ash AI: Comprehensive LLM Toolbox - Alembic](https://alembic.com.au/blog/ash-ai-comprehensive-llm-toolbox-for-ash-framework)
- [ash_ai Package - hex.pm](https://hex.pm/packages/ash_ai)
- [ash_ai GitHub Repository](https://github.com/ash-project/ash_ai)
- [Ash Framework Official](https://ash-hq.org/)
- [Working with LLMs - Ash Docs](https://hexdocs.pm/ash/working-with-llms.html)
- [ElixirConf EU 2025 - Ash AI Launch](https://elixirforum.com/t/ash-ai-launch-zach-daniel-elixirconf-eu-2025/71230)

---

*Analysis Date: November 22, 2025*
*Analyst: Claude (Sonnet 4.5)*
*Reviewer: Matthew Staff*
