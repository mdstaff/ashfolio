# MCP Integration Task Index

## Overview

This index tracks all implementation tasks for MCP integration, organized by phase with TDD success criteria.

## Task Summary

| ID | Task | Phase | Priority | Est. Hours | Status |
|----|------|-------|----------|------------|--------|
| P1-01 | [Router Setup](phase-1/01-router-setup.md) | 1 | P0 | 2-4 | Complete |
| P1-02 | [Privacy Filter](phase-1/02-privacy-filter.md) | 1 | P0 | 4-6 | Complete |
| P1-03 | [Anonymizer](phase-1/03-anonymizer.md) | 1 | P0 | 4-6 | Complete |
| P1-04 | [Core Tools](phase-1/04-core-tools.md) | 1 | P1 | 6-8 | Complete |
| P1-05 | [Tool Examples](phase-1/05-tool-examples.md) | 1 | P2 | 2-3 | Deferred (Partial) |
| P1-06 | [Integration Tests](phase-1/06-integration-tests.md) | 1 | P1 | 3-4 | Complete |
| P2-01 | [Parseable MCP Extension](phase-2/01-parseable-mcp.md) | 2 | P1 | 3-4 | Not Started |
| P2-02 | [Module Registry](phase-2/02-module-registry.md) | 2 | P1 | 4-6 | Not Started |
| P2-03 | [Tool Search](phase-2/03-tool-search.md) | 2 | P2 | 3-4 | Not Started |
| P3-01 | [Consent Resource](phase-3/01-consent-resource.md) | 3 | P1 | 4-6 | Not Started |
| P3-02 | [Consent UI](phase-3/02-consent-ui.md) | 3 | P1 | 4-6 | Not Started |
| P3-03 | [Audit Logging](phase-3/03-audit-logging.md) | 3 | P2 | 3-4 | Not Started |
| P3-04 | [Settings LiveView](phase-3/04-settings-liveview.md) | 3 | P2 | 4-6 | Not Started |

**Total Estimated Hours**: 42-61 hours

## Phase 1: Core MCP Tools (v0.9.0)

**Goal**: Basic MCP functionality with privacy protection

### Critical Path
```
P1-01 Router Setup
    │
    ├──► P1-02 Privacy Filter
    │        │
    │        └──► P1-03 Anonymizer
    │
    └──► P1-04 Core Tools ◄── P1-02, P1-03
             │
             └──► P1-05 Tool Examples
                      │
                      └──► P1-06 Integration Tests
```

### Test Coverage Targets

| Module | Unit Tests | Integration | Coverage |
|--------|------------|-------------|----------|
| Router | 6 | 2 | 90% |
| Privacy Filter | 15 | 3 | 95% |
| Anonymizer | 12 | 2 | 95% |
| Core Tools | 10 | 5 | 85% |
| Tool Examples | 4 | 1 | 80% |

### Definition of Done - Phase 1

- [ ] All P1 tasks complete
- [ ] 40+ tests passing
- [ ] Manual Claude Code test successful
- [ ] Privacy modes verified with real data
- [ ] No sensitive data leakage in anonymized mode
- [ ] Documentation updated

## Phase 2: Module Integration (v0.10.0)

**Goal**: Dynamic tool registration from parsing modules

### Dependencies
- Phase 1 complete
- Smart Parsing Module System (partial)

### Tasks

| ID | Task | Description |
|----|------|-------------|
| P2-01 | Parseable MCP Extension | Add optional MCP callbacks to Parseable behaviour |
| P2-02 | Module Registry | Dynamic tool registration/discovery |
| P2-03 | Tool Search | Deferred loading via search |

### Definition of Done - Phase 2

- [ ] Parsing modules can expose MCP tools
- [ ] Tool search reduces token usage
- [ ] Deferred loading functional
- [ ] 20+ additional tests passing

## Phase 3: Legal & Consent (Pre-v1.0)

**Goal**: Compliance and user protection

### Tasks

| ID | Task | Description |
|----|------|-------------|
| P3-01 | Consent Resource | Track user consent in database |
| P3-02 | Consent UI | Modal for first-time setup |
| P3-03 | Audit Logging | Track tool invocations |
| P3-04 | Settings LiveView | Privacy mode configuration UI |

### Definition of Done - Phase 3

- [ ] Consent required before cloud LLM use
- [ ] Consent versioning for terms updates
- [ ] Audit trail for tool invocations
- [ ] Settings UI for privacy mode

## Test Commands

```bash
# Run all MCP tests
mix test test/ashfolio_web/mcp/

# Run specific phase tests
mix test test/ashfolio_web/mcp/ --only phase1
mix test test/ashfolio_web/mcp/ --only phase2

# Run with coverage
mix test test/ashfolio_web/mcp/ --cover

# Run integration tests only
mix test test/ashfolio_web/mcp/ --only integration
```

## Progress Tracking

Update status as tasks complete:

```
Not Started → In Progress → Testing → Complete
```

When a task moves to "Complete":
1. Update status in this index
2. Update status in task file
3. Update IMPLEMENTATION_PLAN.md if exists
4. Run full test suite to verify no regressions

## Architecture Decision Records

| ADR | Title | Status |
|-----|-------|--------|
| [ADR-MCP-001](../decisions/ADR-MCP-001-privacy-modes.md) | Privacy Modes for MCP Tool Results | Proposed |
| [ADR-MCP-002](../decisions/ADR-MCP-002-holdings-architecture.md) | Holdings Architecture for MCP Tools | Accepted |

---

*Parent: [../README.md](../README.md)*
