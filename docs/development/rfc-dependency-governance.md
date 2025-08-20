# RFC: Dependency Governance Process

Proposed
2025-08-11  
 Claude (Architect)
RFC-001

## Summary

Establish a formal process for managing project dependencies to prevent ad-hoc additions that conflict with architectural principles, create system dependency issues, or compromise the local-first design philosophy.

## Background

### Current Problem

The Wallaby incident revealed gaps in our dependency management:

1.  Wallaby was added without architectural review
2.  No process for evaluating system-level requirements
3.  Dependencies added that conflict with local-first approach
4.  No guidelines for AI agents making dependency decisions

### Project Context

- Minimal external dependencies, zero-configuration setup
- Single file database, no external infrastructure
- User data ownership, no cloud dependencies
- Boring technology, proven solutions, minimal complexity

## Proposal

### Dependency Classification

#### Tier 1: Core Dependencies (Pre-approved)

Dependencies that are central to the tech stack and aligned with architecture:

- `{:phoenix, "~> 1.7"}` - Web framework
- `{:ash, "~> 3.0"}` - Domain framework
- `{:ash_sqlite, "~> 0.2"}` - Local database layer
- `{:ecto_sql, "~> 3.10"}` - Database toolkit
- `{:decimal, "~> 2.0"}` - Financial calculations

#### Tier 2: Enhancement Dependencies (Review Required)

Dependencies that add functionality but require architectural review:

- HTTP clients (`httpoison`, `tesla`, `finch`)
- Testing tools (`mox`, `meck`, `credo`)
- UI libraries (`heroicons`, `tailwind`)
- Background processing (`oban`)

#### Tier 3: System Dependencies (Architecture Decision Required)

Dependencies requiring system-level installation or conflicting with local-first approach:

- Browser automation (`wallaby`, `hound`)
- Database systems (`postgresql`, `mysql`)
- External services (Redis, messaging queues)
- Native compiled dependencies

### Dependency Governance Process

#### For Tier 1 Dependencies

- **No approval required** for version updates within same major version
- **Architecture review required** for major version upgrades
- **Documentation update required** for any changes

#### For Tier 2 Dependencies

1.  - What problem does this solve?
    - Why can't it be solved with existing dependencies?
    - How does it align with local-first principles?
    - What are the maintenance implications?

2.  - What alternatives were considered?
    - Why was this option chosen?
    - What's the simplest solution that works?

3.  - Does it require system dependencies?
    - Does it add complexity to setup process?
    - Does it impact deployment or distribution?
    - Does it compromise privacy or local-first design?

- Is this genuinely needed or just convenient?
- Does it support local-first architecture?
- Can we maintain this long-term?
- Is this the simplest solution?
- How hard would it be to remove later?

#### For Tier 3 Dependencies

- Requires external service dependencies
- Requires system-level software installation (except dev tools)
- Compromises single-file data portability
- Adds cloud dependencies or telemetry
- Conflicts with zero-configuration setup

- Must be approved through ADR (Architecture Decision Record)
- Requires documented alternatives analysis
- Must provide local-first workaround
- Needs explicit justification for complexity

### Agent Guidelines

#### For AI Development Agents

- Using existing dependencies already in mix.exs
- Version updates within same major version for security fixes
- Removing dependencies that are unused

- Adding any new dependency to mix.exs
- Major version upgrades of existing dependencies
- Using system tools not already documented in setup guides

- Adding Tier 3 dependencies without explicit architecture approval
- Using `--force` flags to bypass dependency conflicts
- Ignoring dependency-related test failures

1.  Can I solve this with dependencies already in mix.exs?
2.  Is this dependency already approved in docs?
3.  Can I solve this without adding dependencies?
4.  What problem am I trying to solve and why?

#### Agent Coordination Protocol

1.  Describe what you're trying to achieve
2.  Find 2-3 different approaches
3.  Don't proceed with dependency addition
4.  Implement minimal solution if possible

```markdown
## Dependency Addition Request

[What needs to be solved]
[package name and version]
[other options and why rejected]
[how this affects local-first design]
[ongoing support considerations]
```

### Implementation Guidelines

#### Dependency Review Checklist

- [ ] Does it compile and pass tests?
- [ ] Are version constraints appropriate?
- [ ] Does it conflict with existing dependencies?
- [ ] Is documentation up to date?

- [ ] Aligns with local-first principles
- [ ] Doesn't require external services
- [ ] Maintains data privacy and ownership
- [ ] Supports zero-configuration setup

- [ ] Active maintenance and community support
- [ ] Reasonable update frequency
- [ ] Clear migration path for future updates
- [ ] Acceptable license terms

#### Documentation Requirements

1. Update `DEPENDENCY_GOVERNANCE.md` with rationale
2. Document setup requirements in development guides
3. Add to appropriate testing categories
4. Update troubleshooting guides if needed

Maintain a registry of all dependencies with:

- Purpose and justification
- Last review date
- Update policy
- Removal criteria

### Monitoring and Maintenance

#### Regular Dependency Audits

- Check for security vulnerabilities (`mix deps.audit`)
- Review outdated dependencies (`mix hex.outdated`)
- Assess usage of each dependency
- Identify candidates for removal

- Evaluate alignment with project goals
- Assess maintenance burden
- Review dependency tree complexity
- Plan major version upgrades

#### Dependency Retirement Process

- No longer maintained upstream
- Security issues without fixes
- Superseded by core Elixir/Phoenix features
- Conflicts with architecture evolution

1. Create removal plan with timelines
2. Identify replacement approach
3. Update documentation and guides
4. Implement gradual migration
5. Remove from mix.exs

## Examples

### Good Dependency Addition

```elixir
# Adding decimal for financial calculations
{:decimal, "~> 2.0"}

# Justification:
# - Essential for accurate financial math
# - Prevents floating point errors in currency
# - No system dependencies
# - Aligns with financial domain requirements
# - Well-maintained, stable library
```

### Bad Dependency Addition

```elixir
# Adding Redis for caching
{:redix, "~> 1.2"}

# Problems:
# - Requires Redis system installation
# - Violates zero-configuration setup
# - Conflicts with local-first architecture
# - Adds external service dependency
# - ETS/GenServer alternatives exist
```

### Agent Decision Example

Agent needs to parse CSV files

1. Check existing: Is `nimble_csv` or similar already in mix.exs?
2. Research: Can I use built-in Elixir `File.stream!/1`?
3. Document: "Need to parse user transaction CSV imports"
4. Request review: If no existing solution works

5. Add `{:csv, "~> 3.0"}` directly to mix.exs
6. Proceed with implementation
7. Create dependency without architectural consideration

## Migration Plan

### Phase 1: Document Current State (Week 1)

- Audit all existing dependencies
- Classify into tiers
- Document justification for each
- Identify retirement candidates

### Phase 2: Process Implementation (Week 2)

- Create dependency registry
- Update development guides
- Train agents on new process
- Implement review templates

### Phase 3: Monitoring Setup (Week 3)

- Set up automated dependency scanning
- Create review schedules
- Establish metrics and tracking
- Document escalation procedures

## Success Metrics

- 100% of new dependencies go through review process
- Zero ad-hoc dependency additions without documentation
- All dependencies have documented justification

- No new system dependencies added
- Maintained zero-configuration setup
- Local-first principles preserved

- Dependency vulnerabilities resolved within 1 week
- Regular audit completion rate > 95%
- Dependency removal success when needed

## Open Questions

1.  Should we add automated dependency policy enforcement?
2.  What emergency procedures exist for critical security updates?
3.  How do we handle community contribution dependencies?
4.  Should test-only dependencies have different review criteria?

## Decision Timeline

- 2025-08-11 to 2025-08-18
- 2025-08-15
- 2025-08-19
- 2025-08-26

---

Proposed → Under Review → Accepted → Implemented
2025-11-11 (3 months)
ADR-001 (Local-First Architecture), ADR-003 (Browser Testing Strategy)
