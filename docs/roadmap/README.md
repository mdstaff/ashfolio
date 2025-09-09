# Ashfolio Roadmap Documentation

This directory contains Ashfolio's strategic planning and architectural decision documentation.

## Current Documents

### Active Development

- **[Financial Expansion Roadmap](financial-expansion-roadmap.md)** - Future feature planning for v0.6.0 and beyond
- **[UI/UX Improvements](ui-ux-improvements.md)** - Ongoing user interface enhancements
- **[QA Automation Roadmap](qa-automation-roadmap.md)** - Testing and quality assurance improvements

### [Architectural Decision Record](../architecture/adr-001-local-first-architecture.md)

Professional ADR documenting our commitment to local-first, single-user SQLite architecture with complete rationale, alternatives considered, and consequences.

## Completed Versions Archive

### [v0.1.0 - v0.5.0 Consolidated Archive](../archive/v0.1-v0.5-consolidated-archive.md)

Complete development history from inception through v0.5.0, documenting the evolution from basic portfolio tracker to comprehensive financial management platform with 1,680+ tests.

**Archived Specifications:**
- [v0.2-v0.5 Roadmap](../archive/v0.2-v0.5-roadmap.md) - Original roadmap (completed)
- [v0.5.0 Specification](../archive/v0.5.0-specification.md) - Final v0.5 planning document
- [v0.4.x Specification](../archive/v0.4.x-specification.md) - Financial planning features
- [v0.3.x Specifications](../archive/) - Analytics and expense tracking

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

## Current Status: v0.5.0 Complete ✅

**v0.5.0 has been successfully completed**, delivering a comprehensive financial management platform with:
- 1,680+ comprehensive tests passing
- Money Ratios assessment system (Charles Farrell methodology)
- Advanced tax planning with FIFO calculations
- Complete retirement planning features
- Production-ready performance (<100ms portfolio calculations)

## Next Phase: v0.6.0 Planning

The next development phase will focus on advanced portfolio management and optimization features. See the [Financial Expansion Roadmap](financial-expansion-roadmap.md) for detailed planning of:

1. Advanced portfolio optimization
2. Risk analysis and management
3. Alternative investment tracking
4. Enhanced reporting capabilities

## Contributing to Roadmap

Feature suggestions should:

1. Align with our architectural decisions
2. Avoid duplicating existing specifications
3. Include clear user story and technical approach
4. Consider implementation complexity and maintenance impact

For questions about roadmap priorities, review the current version roadmap and architectural decisions documentation.
