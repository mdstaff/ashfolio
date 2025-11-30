# Ashfolio Features

This directory contains feature specifications and documentation.

## Structure

```
features/
├── implemented/     # Shipped features with user documentation
├── proposed/        # Features under consideration (not on active roadmap)
└── README.md
```

## Implemented Features

Features that have shipped and are available in the current version.

- **[AI Natural Language Entry](implemented/ai-natural-language-entry.md)** (v0.8.0)
  - Parse transactions from natural language: "Bought 10 AAPL at 150"
  - Supports Ollama (local) and OpenAI (cloud) providers

## Proposed Features

Features under consideration for future development. These are **not committed** to the roadmap but represent well-documented ideas that could be picked up.

- **[MCP Integration](proposed/mcp-integration.md)**
  - Model Context Protocol server for Claude Code/Claude.app
  - Expose Ash actions as MCP tools (zero API cost via subscription)
  - Integrates with Module System for dynamic tool discovery
  - References Anthropic's advanced tool use patterns

- **[Smart Parsing Module System](proposed/smart-parsing-module-system.md)**
  - Rule-based parsing without AI dependencies
  - Subscription database, expense/income parsing
  - Potential for child agent implementation

- **[Demo Mode & Interactive Tutorial](proposed/demo-mode/)**
  - Synthetic portfolio personas for exploration
  - Tutorial overlay system with tooltips
  - Feature discovery and progressive disclosure

## Feature Lifecycle

```
Proposed → Roadmap → Implementation → Implemented
    │                                      │
    └──── Archived (if declined) ──────────┘
```

### Proposing a Feature

1. Create a markdown file in `proposed/`
2. Include: problem statement, proposed solution, technical approach
3. Discuss feasibility and priority
4. If approved, move to active roadmap

### After Implementation

1. Move documentation to `implemented/`
2. Update for user-facing documentation style
3. Add to CHANGELOG.md
