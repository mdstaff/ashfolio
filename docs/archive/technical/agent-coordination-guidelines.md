# Agent Coordination Guidelines for Architectural Decisions

2025-08-11
Claude (Architect)
ADR-003, RFC-001, CLAUDE.md

## Purpose

Establish clear guidelines for AI development agents to make consistent architectural decisions, prevent conflicts like the Wallaby incident, and maintain alignment with project principles.

## Core Principles

### 1. Architecture-First Decision Making

- Always understand project philosophy before making changes
- Prefer solutions that support zero-configuration, local-only operation
- Choose boring, proven solutions over exciting new tools
- All architectural choices must be documented and justified

### 2. Incremental Progress

- Make changes that compile and pass tests
- Don't solve multiple architectural issues in single PR
- Prefer changes that can be easily undone if needed

## Decision-Making Framework

### Before Making Any Architectural Decision

1. Stop and Research

   - Read existing ADRs and architectural documentation
   - Find 3 similar implementations in the codebase
   - Understand the problem context and constraints

2. Evaluate Against Project Principles

   ```markdown
   - Does this support local-first architecture?
   - Does this maintain zero-configuration setup?
   - Does this preserve user data ownership?
   - Does this add unnecessary complexity?
   ```

3. Consider Alternatives
   - Can existing dependencies solve this?
   - Is there a simpler approach?
   - What are the maintenance implications?

### Agent Decision Authority Levels

#### Green Light: Autonomous Decisions

You can proceed without approval:

- Using existing dependencies already in mix.exs
- Following established patterns from similar components
- Bug fixes that don't change architecture
- Test improvements using existing framework
- Documentation updates for existing functionality
- Refactoring that maintains identical external behavior

#### Yellow Light: Document and Proceed ⚠️

Proceed but document rationale:

- Minor dependency version updates (patch/minor)
- New internal modules following existing patterns
- Test additions using existing testing approach
- Performance optimizations that don't change APIs
- UI changes following established design patterns

```markdown
## Decision Log

[What you're solving]
[What you implemented]
[What else you considered]
[Why this approach]
```

#### Red Light: Stop and Get Approval ❌

Must request human approval:

- Adding any new dependency to mix.exs
- Changing database schema or data layer approach
- Introducing new testing frameworks or tools
- Adding system dependencies or external services
- Changing build process or deployment approach
- Adding network dependencies or external APIs

```markdown
## Architectural Decision Request

[Clear problem description]
[Your recommended approach]
[2-3 other options with pros/cons]
[How this affects architecture]
[How this supports local-first principles]
```

## Specific Guidelines by Domain

### Dependencies

- Never add system-level dependencies (databases, browsers, native tools)
- Always check if existing dependencies can solve the problem
- Document justification for any new Elixir package
- Prefer standard library solutions over external packages

### Testing

- Use Phoenix LiveViewTest for UI component testing
- Use ExUnit for unit testing business logic
- Avoid browser automation tools (Wallaby, Hound, etc.)
- Write comprehensive tests for any new functionality

### Database & Data

- Stick with SQLite - no PostgreSQL, MySQL, or external databases
- Use Ash Framework patterns for all data modeling
- Maintain single-file database portability
- Preserve zero-configuration setup

### JavaScript & Frontend

- Treat JavaScript as progressive enhancement only
- Ensure functionality works without JavaScript enabled
- Use Phoenix LiveView for primary interactivity
- Keep JavaScript minimal and focused on UX improvements

### External Services

- No external APIs for core functionality
- No cloud dependencies or telemetry
- Optional external integrations must have local fallbacks
- Preserve offline-first functionality

## Common Scenarios and Responses

### Scenario: Need to Add HTTP Client

Need to fetch market data from external API
Add new HTTP client dependency immediately

1. Check if `httpoison` is already in mix.exs (it is)
2. Use existing HTTP client
3. Document data source and API usage
4. Implement graceful offline fallback

### Scenario: Tests Are Failing Due to Missing Tool

Browser tests fail because Chrome is not installed
Add Chrome installation to setup docs

1. Question if browser testing is necessary
2. Check existing ADRs for testing strategy
3. Consider LiveView-based alternative
4. If needed, create ADR for browser testing decision

### Scenario: Performance Issue Needs External Cache

SQLite queries are slow, need Redis caching
Add Redis dependency for performance

1. Profile the actual performance issue
2. Consider SQLite optimization (indexes, queries)
3. Evaluate ETS-based caching
4. Document performance requirements and constraints
5. Only consider external cache as last resort with ADR

### Scenario: Need Complex Data Transformation

Need to process large CSV files efficiently
Add new CSV processing library

1. Check if `nimble_csv` or similar already exists
2. Consider streaming with built-in File functions
3. Profile actual performance needs
4. Choose simplest solution that meets requirements

## Communication Protocols

### When to Create ADR (Architecture Decision Record)

- Any decision affecting multiple components
- Introducing new tools or frameworks
- Changes to core architectural patterns
- Trade-offs between significant alternatives

### When to Request Human Review

- Uncertainty about alignment with project principles
- Multiple viable solutions with unclear trade-offs
- Potential impact on user data or privacy
- Changes affecting deployment or setup process

### Documentation Requirements

#### For All Architectural Decisions

```markdown
## Decision Context

- What problem are you solving?
- What constraints exist?
- What principles apply?

## Solution Analysis

- What options did you consider?
- Why did you choose this approach?
- What are the trade-offs?

## Implementation Plan

- What changes are needed?
- How will you verify success?
- How can this be reversed if needed?
```

#### For Code Changes

- Clear commit messages explaining "why" not just "what"
- Updated documentation for any new patterns
- Test coverage for new functionality
- Performance impact assessment if relevant

## Quality Gates

### Before Implementing Solution

- [ ] Problem clearly understood and documented
- [ ] Existing codebase patterns researched
- [ ] Solution aligns with local-first principles
- [ ] Simplest viable approach identified
- [ ] Impact on complexity assessed

### Before Committing Changes

- [ ] All tests pass
- [ ] No new warnings or errors introduced
- [ ] Documentation updated if needed
- [ ] Decision rationale documented
- [ ] Code follows existing patterns

### Before Creating PR

- [ ] Changes are minimal and focused
- [ ] Architectural decisions explained
- [ ] Alternative approaches documented
- [ ] Impact on setup process assessed

## Emergency Procedures

### Security Issues

- Immediate action permitted for security vulnerability fixes
- Document post-action with rationale and impact assessment
- Follow up with ADR if architectural changes were needed

### Blocking Issues

- Temporary workarounds permitted to unblock development
- Must create follow-up task for proper architectural solution
- Document technical debt and repayment plan

### Production Issues

- Local-first architecture should prevent most production emergencies
- SQLite failures should be rare and recoverable
- Focus on data integrity over feature availability

## Learning and Improvement

### Regular Review Process

- Review decisions made by agents
- Assess alignment with architectural principles
- Update guidelines based on lessons learned

### Knowledge Sharing

- Document patterns that work well
- Share examples of good decision-making
- Create templates for common scenarios
- Build library of architectural solutions

### Continuous Improvement

- Refine guidelines based on real usage
- Add new scenarios as they arise
- Update principles as project evolves
- Improve agent training and context

---

## Quick Reference

Existing patterns, bug fixes, documentation, refactoring
Minor changes, document rationale
New dependencies, system changes, external services

Does this support local-first, zero-configuration, user-owned data?

Stop, document the problem, research alternatives, request review.

---

1.0
2025-11-11
ADR-003, RFC-001, CLAUDE.md
