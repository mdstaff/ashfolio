# Session Recap: AI Integration & Magic Input

## Work Completed

### 1. Magic Input Feature (Phase 1)
- **UI**: Implemented "Natural Language Entry" on the Transactions page.
- **Backend**: Added `Transaction.parse_from_text/1` using `AshAi`.
- **Status**: **Ready for Review**. See [AI Integration Strategy](ai_integration_strategy.md) for details.

### 2. Extensible Architecture
- **Dispatcher**: Refactored the direct call into `Ashfolio.AI.Dispatcher`.
- **Handlers**: Created `Ashfolio.AI.Handler` behaviour and `TransactionParser` handler.
- **Benefit**: Allows future extensions (e.g., "Show Net Worth") without modifying core transaction logic.

### 3. Multi-Provider Support
- **Abstraction**: Created `Ashfolio.AI.Model` to abstract the LLM provider.
- **Config**: Added configuration to switch between OpenAI, Anthropic, etc.

## Current Status & Blockers

### 🚧 Dependency Issue
We encountered a runtime crash when invoking the AI action:
- **Error**: `UndefinedFunctionError` in `AshJsonApi.OpenApi.resource_write_attribute_type/3`.
- **Cause**: Incompatibility between `ash_ai` (0.1.11) and `ash_json_api` (1.5.x/1.4.x).
- **Attempted Fix**: Downgraded `ash_json_api` to `1.4.27`, but the issue persists or requires a specific version combination.
- **Impact**: The "Natural Language Entry" feature will crash if used currently.

### 🔄 Local-First Transition
- **Goal**: Switch from OpenAI to Ollama.
- **Status**: Dependencies updated, but configuration not yet applied due to the blocking crash.

## Key Learnings
- **Ash Ecosystem**: The ecosystem is evolving rapidly. `ash_ai` relies on internal details of `ash_json_api` that seem to have changed.
- **Architecture**: The Dispatcher pattern proved valuable immediately, allowing us to isolate the AI logic from the LiveView.

## Remaining TODOs
1.  **Fix Dependency Crash**: Investigate the exact version matrix for `ash_ai` 0.1.11 or wait for a patch.
2.  **Configure Ollama**: Once the crash is resolved, configure `Ashfolio.AI.Model` to use `LangChain.ChatModels.ChatOllama`.
3.  **Verify Local Model**: Test the parsing quality with a local model (e.g., Llama 3).

## Potential Tasks for Delegation
- "Debug and fix `ash_ai` / `ash_json_api` version incompatibility."
- "Implement Ollama provider configuration and test with local LLM."
