# Ash AI Integration Strategy

## Overview
Integrating [Ash AI](https://github.com/ash-project/ash_ai) into Ashfolio aligns perfectly with the project's goals of providing professional-grade tools with a local-first architecture. Ash AI allows us to treat Large Language Models (LLMs) as just another interface to our application, leveraging our existing Ash Resources and strict types.

## Core Opportunities

### 1. Natural Language Interface (Chat with your Finance)
**Feature**: A "Financial Assistant" chat interface.
**Implementation**:
- Use `mix ash_ai.gen.chat` to scaffold the UI.
- **Tools**: Expose existing read actions as tools.
  - `get_net_worth`
  - `list_transactions(filter: ...)`
  - `get_portfolio_performance`
- **User Query**: "What is my current net worth?" -> Calls `NetWorthCalculator` -> Returns exact Decimal value.

### 2. Intelligent Data Entry ("Natural Language Entry")
**Feature**: Paste unstructured text to create transactions.
**Problem**: Manual data entry is high friction.
**Solution**:
- **Action**: `Action :parse_from_text` backed by `Ashfolio.AI.Dispatcher`.
- **Input**: "Bought 10 AAPL at 150 yesterday on Fidelity."
- **Output**: Structured `Transaction` struct with `symbol: "AAPL"`, `qty: 10`, `price: 150`, `date: ~D[2025-11-21]`, `account: "Fidelity"`.
- **Benefit**: Drastically reduces friction for users migrating from notes or emails.
- **Status**: **Implemented (Phase 1)**.

### 3. RAG-Powered Financial Insights
**Feature**: Ask complex questions about financial history.
**Implementation**:
- **Vectorization**: Use Ash AI's `vectorize` macro on `Transaction` descriptions or `JournalEntry` notes.
- **Query**: "Why did my spending spike in March?"
- **Mechanism**: Retrieve relevant transaction records + generate summary.

### 4. Local-First AI (Privacy)
**Constraint**: Ashfolio is privacy-first.
**Strategy**:
- Support local inference (e.g., Ollama) via LangChain/AshAI adapters.
- Allow optional, user-configured API keys for cloud models (OpenAI/Anthropic) with clear "Data leaving device" warnings.

## Proposed Architecture Changes

### New Dependencies
- `ash_ai`
- `langchain`
- `igniter` (for generation)

### New Domain: `Ashfolio.AI`
- **Components**:
  - `Dispatcher`: Central event bus for AI commands.
  - `Handler` Behaviour: Interface for command processors.
  - `Model`: Abstraction for LLM providers (OpenAI, Ollama, etc.).
- **Resources**:
  - `Conversation`: Stores chat history (local SQLite).
  - `Message`: Individual chat messages.


## Implementation Roadmap (Draft)

### Phase 1: Natural Language Entry (Completed)
- Implement `Ashfolio.AI.Dispatcher` and `TransactionParser` handler.
- Add "Natural Language Entry" UI to Transaction Dashboard.
- **Verification**: Unit tests for Dispatcher, manual verification of parsing.


### Phase 2: Read-Only Assistant
- Implement `Ashfolio.AI` domain.
- Expose `NetWorth` and `Portfolio` read actions as tools.
- Add Chat UI to Dashboard.

### Phase 3: Advanced Insights (RAG)
- Vectorize transaction history.
- Implement "Explain this month's performance" feature.

## Recommendation
Start with **Phase 1 (Magic Input)**. It solves a major user pain point (data entry friction) and introduces Ash AI patterns without requiring a full chat UI or complex agent state.
