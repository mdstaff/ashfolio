# Ashfolio Roadmap Documentation

This directory contains Ashfolio's strategic planning and architectural decision documentation.

## Current Documents

### [v0.2-v0.5 Roadmap](v0.2-v0.5-roadmap.md)

Active roadmap for near-term feature development, organized by version with clear priorities and architectural alignment.

### [Architectural Decision Record](../architecture/adr-001-local-first-architecture.md)

Professional ADR documenting our commitment to local-first, single-user SQLite architecture with complete rationale, alternatives considered, and consequences.

## Archive

### [Ghostfolio-Inspired Comprehensive Features](../archive/ghostfolio-inspired-comprehensive-features.md)

Complete feature list inspired by the Ghostfolio project. Not a development roadmap - serves as long-term inspiration while understanding most features require architectural changes incompatible with our local-first approach.

## Roadmap Development Process

### Feature Evaluation Framework

Before any feature enters the roadmap, it must pass these criteria:

1. **Architectural Alignment**
   - Works with SQLite local-first design
   - No external service dependencies
   - Compatible with single-user model
   - Maintains privacy and offline capability

2. **User Value Assessment**
   - Significantly improves portfolio management workflow
   - Addresses real user pain points
   - Provides measurable benefit over manual alternatives

3. **Technical Feasibility**
   - Implementable with current Phoenix/Ash/SQLite stack
   - Reasonable complexity for maintenance
   - Can be thoroughly tested

4. **Project Scope Alignment**
   - Fits incremental development approach
   - Maintains focus on personal portfolio management

### Version Planning Strategy

- 3-5 new features every 2-3 months
- Bug fixes and small improvements as needed
- Prioritized by user value and implementation complexity
- Every feature must align with local-first SQLite approach

### Documentation Standards

Each roadmap feature requires:
- Clear description of user benefit
- How it integrates with existing architecture
- Implementation complexity estimate
- Dependencies and prerequisites
- Success criteria

## Current Focus: v0.5.0

Active development phase focused on consolidating and refining existing features for production stability.

Following the successful completion of v0.4.x (AER standardization, financial calculations, and test improvements), v0.5.0 emphasizes:

1. Production readiness improvements
2. User experience refinements
3. Performance optimizations
4. Documentation completion

Target completion aligns with ongoing development priorities and architectural stability goals.

## Contributing to Roadmap

Feature suggestions should:

1. Align with our architectural decisions
2. Avoid duplicating existing specifications
3. Include clear user story and technical approach
4. Consider implementation complexity and maintenance impact

For questions about roadmap priorities, review the current version roadmap and architectural decisions documentation.
