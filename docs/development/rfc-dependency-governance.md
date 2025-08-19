# RFC: Dependency Governance Process

**Status**: Proposed
**Date**: 2025-08-11  
**Authors**: Claude (Architect)
**RFC Number**: RFC-001

## Summary

Establish a formal process for managing project dependencies to prevent ad-hoc additions that conflict with architectural principles, create system dependency issues, or compromise the local-first design philosophy.

## Background

### Current Problem

The Wallaby incident revealed gaps in our dependency management:

1. **Ad-hoc Additions**: Wallaby was added without architectural review
2. **System Dependencies**: No process for evaluating system-level requirements  
3. **Philosophy Conflicts**: Dependencies added that conflict with local-first approach
4. **Agent Coordination**: No guidelines for AI agents making dependency decisions

### Project Context

- **Local-First Architecture**: Minimal external dependencies, zero-configuration setup
- **SQLite-Based**: Single file database, no external infrastructure
- **Privacy-First**: User data ownership, no cloud dependencies
- **Development Philosophy**: Boring technology, proven solutions, minimal complexity

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

**Before Adding**:
1. **Justification Document**:
   - What problem does this solve?
   - Why can't it be solved with existing dependencies?
   - How does it align with local-first principles?
   - What are the maintenance implications?

2. **Alternative Analysis**:
   - What alternatives were considered?
   - Why was this option chosen?
   - What's the simplest solution that works?

3. **Impact Assessment**:
   - Does it require system dependencies?
   - Does it add complexity to setup process?
   - Does it impact deployment or distribution?
   - Does it compromise privacy or local-first design?

**Review Criteria**:
- **Necessity**: Is this genuinely needed or just convenient?
- **Alignment**: Does it support local-first architecture?
- **Maintenance**: Can we maintain this long-term?
- **Simplicity**: Is this the simplest solution?
- **Reversibility**: How hard would it be to remove later?

#### For Tier 3 Dependencies

**Automatic Rejection Criteria**:
- Requires external service dependencies
- Requires system-level software installation (except dev tools)
- Compromises single-file data portability
- Adds cloud dependencies or telemetry
- Conflicts with zero-configuration setup

**Exception Process**:
- Must be approved through ADR (Architecture Decision Record)
- Requires documented alternatives analysis
- Must provide local-first workaround
- Needs explicit justification for complexity

### Agent Guidelines

#### For AI Development Agents

**Permitted Without Review**:
- Using existing dependencies already in mix.exs
- Version updates within same major version for security fixes
- Removing dependencies that are unused

**Requires Human Review**:
- Adding any new dependency to mix.exs
- Major version upgrades of existing dependencies
- Using system tools not already documented in setup guides

**Prohibited Actions**:
- Adding Tier 3 dependencies without explicit architecture approval
- Using `--force` flags to bypass dependency conflicts
- Ignoring dependency-related test failures

**Agent Decision Framework**:
1. **Check Existing**: Can I solve this with dependencies already in mix.exs?
2. **Check Documentation**: Is this dependency already approved in docs?
3. **Propose Alternative**: Can I solve this without adding dependencies?
4. **Document Intent**: What problem am I trying to solve and why?

#### Agent Coordination Protocol

**When Uncertain**:
1. **Stop and Document**: Describe what you're trying to achieve
2. **Research Alternatives**: Find 2-3 different approaches
3. **Request Human Review**: Don't proceed with dependency addition
4. **Temporary Workaround**: Implement minimal solution if possible

**Communication Format**:
```markdown
## Dependency Addition Request

**Problem**: [What needs to be solved]
**Proposed Dependency**: [package name and version]
**Alternatives Considered**: [other options and why rejected]
**Architecture Impact**: [how this affects local-first design]
**Maintenance Plan**: [ongoing support considerations]
```

### Implementation Guidelines

#### Dependency Review Checklist

**Technical Assessment**:
- [ ] Does it compile and pass tests?
- [ ] Are version constraints appropriate?
- [ ] Does it conflict with existing dependencies?
- [ ] Is documentation up to date?

**Architecture Assessment**:
- [ ] Aligns with local-first principles
- [ ] Doesn't require external services
- [ ] Maintains data privacy and ownership
- [ ] Supports zero-configuration setup

**Maintenance Assessment**:
- [ ] Active maintenance and community support
- [ ] Reasonable update frequency
- [ ] Clear migration path for future updates
- [ ] Acceptable license terms

#### Documentation Requirements

**For Each Dependency Addition**:
1. Update `DEPENDENCY_GOVERNANCE.md` with rationale
2. Document setup requirements in development guides
3. Add to appropriate testing categories
4. Update troubleshooting guides if needed

**Dependency Registry**:
Maintain a registry of all dependencies with:
- Purpose and justification
- Last review date
- Update policy
- Removal criteria

### Monitoring and Maintenance

#### Regular Dependency Audits

**Monthly Review**:
- Check for security vulnerabilities (`mix deps.audit`)
- Review outdated dependencies (`mix hex.outdated`)
- Assess usage of each dependency
- Identify candidates for removal

**Quarterly Architecture Review**:
- Evaluate alignment with project goals
- Assess maintenance burden
- Review dependency tree complexity
- Plan major version upgrades

#### Dependency Retirement Process

**Retirement Triggers**:
- No longer maintained upstream
- Security issues without fixes
- Superseded by core Elixir/Phoenix features
- Conflicts with architecture evolution

**Retirement Process**:
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

**Scenario**: Agent needs to parse CSV files

**Good Approach**:
1. Check existing: Is `nimble_csv` or similar already in mix.exs?
2. Research: Can I use built-in Elixir `File.stream!/1`?
3. Document: "Need to parse user transaction CSV imports"
4. Request review: If no existing solution works

**Bad Approach**:
1. Add `{:csv, "~> 3.0"}` directly to mix.exs
2. Proceed with implementation
3. Create dependency without architectural consideration

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

**Process Adoption**:
- 100% of new dependencies go through review process
- Zero ad-hoc dependency additions without documentation
- All dependencies have documented justification

**Architecture Alignment**:
- No new system dependencies added
- Maintained zero-configuration setup
- Local-first principles preserved

**Maintenance Quality**:
- Dependency vulnerabilities resolved within 1 week
- Regular audit completion rate > 95%
- Dependency removal success when needed

## Open Questions

1. **Tooling**: Should we add automated dependency policy enforcement?
2. **Exceptions**: What emergency procedures exist for critical security updates?
3. **Community**: How do we handle community contribution dependencies?
4. **Testing**: Should test-only dependencies have different review criteria?

## Decision Timeline

- **Review Period**: 2025-08-11 to 2025-08-18
- **Feedback Deadline**: 2025-08-15
- **Implementation Start**: 2025-08-19
- **Full Process Active**: 2025-08-26

---

**RFC Status**: Proposed → Under Review → Accepted → Implemented
**Next Review**: 2025-11-11 (3 months)
**Related ADRs**: ADR-001 (Local-First Architecture), ADR-003 (Browser Testing Strategy)