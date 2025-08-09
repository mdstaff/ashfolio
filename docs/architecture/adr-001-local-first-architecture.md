# ADR-001: Local-First Portfolio Management Architecture

## Status

**Accepted** - 2025-08-09

## Metadata

- **Replaces**: None
- **Amended by**: None
- **Related to**: None
- **Participants**: Development Team
- **Version**: v0.1.0

## Problem Statement

**Question**: What architectural approach should Ashfolio adopt for data persistence, user management, and system dependencies?

**Context**: Personal portfolio management applications face competing pressures between feature richness (requiring external integrations and complex infrastructure) and simplicity (favoring local-first approaches). Users desire privacy and control over their financial data while avoiding complex setup procedures. The market offers comprehensive cloud solutions but lacks simple, privacy-focused alternatives for personal use.

**Constraints**:

- Target audience: Individual investors managing personal portfolios
- Primary use case: Single-user portfolio tracking and analysis
- Key requirements: Privacy, simplicity, offline capability

## Decision Summary

Ashfolio adopts a **local-first, single-user architecture** using SQLite as the primary database, explicitly avoiding the complexity and external dependencies common in modern web applications.

**Core Philosophy**: Local-first architecture prioritizes user data ownership, privacy, and offline reliability by storing data locally rather than in external cloud services.

## Alternatives Considered

### Option 1: Traditional Multi-User SaaS Architecture

- **Description**: PostgreSQL database, user authentication, cloud deployment, real-time integrations
- **Pros**: Industry standard, scalable, comprehensive feature integrations possible, familiar to developers
- **Cons**: Complex setup, external dependencies, privacy concerns, GDPR compliance burden, ongoing operational costs
- **Decision**: **Rejected** - Overengineering for target use case of personal portfolio management

### Option 2: Local-First SQLite Architecture (Selected)

- **Description**: SQLite database, single-user application, no authentication layer, minimal external dependencies
- **Pros**: Simple setup, complete privacy, offline capability, zero operational dependencies, fast development cycle
- **Cons**: Limited to single user, manual data entry required, no real-time integrations
- **Decision**: **Selected** - Aligns with project philosophy and user privacy requirements

### Option 3: Hybrid Cloud-Local Architecture

- **Description**: Local SQLite with optional cloud sync, user choice between local and cloud storage
- **Pros**: Flexibility for users, potential for device synchronization
- **Cons**: Significantly increases complexity, doubles maintenance burden, unclear value proposition
- **Decision**: **Rejected** - Violates simplicity principle and doubles architectural complexity

## Decision Rationale

### Technical Rationale

**SQLite Selection**:

- Proven performance for single-user financial data volumes (1000+ positions tested)
- ACID transactions ensure data integrity for financial calculations
- Zero configuration - embedded database with no external setup required
- Single-file storage enables simple backup/restore procedures

**Single-User Design**:

- Eliminates authentication/authorization complexity (~30% reduction in codebase)
- Removes need for user management, session handling, and security policies
- Enables faster development and testing cycles
- Reduces attack surface for financial data

**Phoenix LiveView + Ash Framework**:

- Real-time UI updates without complex JavaScript
- Type-safe business logic with Ash Resources
- Excellent testing capabilities with embedded database
- Strong Elixir ecosystem for financial calculations

## Consequences

### Positive Consequences

**Operational Simplicity**

- Zero-dependency installation (`just dev` starts entire application)
- Single-file backups (copy SQLite database file)
- No external service monitoring, maintenance, or operational costs
- Simplified deployment (single Elixir application)

**User Privacy & Control**

- Complete data ownership and privacy protection
- No cloud accounts or external data sharing required
- Offline capability for all core portfolio management functions
- No external APIs required for basic functionality

**Development Velocity**

- Faster test execution using in-memory SQLite database
- Reduced complexity by eliminating authentication/authorization layer
- Clear architectural boundaries with Ash Framework resources
- Simplified debugging with local data storage

**Performance Characteristics**

- Sub-millisecond query performance for typical portfolio sizes
- Real-time UI updates through Phoenix LiveView
- Efficient ETS caching for frequently accessed calculations

### Negative Consequences

**Scalability Limitations**

- Cannot serve multiple users without fundamental rearchitecture
- Portfolio size practically limited to approximately 1000 positions
- No built-in data synchronization across multiple devices
- Manual scaling only (user manages their own data)

**Feature Constraints**

- Manual data entry increases user workload compared to automated integrations
- No real-time market data streaming (manual refresh only)
- Limited to basic asset types initially (stocks, ETFs)
- Single currency support (USD) to avoid forex complexity

**Maintenance Trade-offs**

- Users responsible for their own data backups
- Application updates require user action
- No centralized monitoring of user issues or usage patterns
- Limited ability to provide user support without access to user data

**Integration Limitations**

- No brokerage API integrations (manual transaction entry)
- No external service integrations for enhanced features
- Limited to data sources that work without authentication

## Implementation Guidance

### Development Standards

- **Database Operations**: All database operations must use Ash Framework resources (no direct Ecto usage)
- **Financial Precision**: Always use `Decimal` types for monetary values, maintain USD-only calculations
- **Caching Strategy**: Implement ETS caching for frequently accessed portfolio calculations
- **External APIs**: Manual price refresh via Yahoo Finance only (no authentication required)
- **Error Handling**: Use centralized `ErrorHandler` for consistent user feedback

### Testing Requirements

- **Database Testing**: All database operations must be testable with in-memory SQLite
- **Performance Validation**: Tests must verify performance with 1000+ position portfolios
- **Offline Capability**: Integration tests must verify core functionality without internet
- **Data Integrity**: Comprehensive tests for financial calculations and FIFO cost basis
- **Concurrency**: SQLite concurrency patterns using established project helpers

### Architecture Constraints

- **No Real-Time Streams**: Avoid features requiring continuous external connections
- **Manual Data Entry**: Design UI for efficient manual transaction entry
- **Single-User Assumptions**: All features designed for single concurrent user
- **Local Storage**: All persistent data must be stored in SQLite database

## Regulatory Considerations

**Data Privacy**: Local-first architecture inherently complies with privacy regulations (GDPR, CCPA) by maintaining data under user control with no external sharing.

**Financial Regulations**: Application does not provide investment advice or execute trades, significantly reducing regulatory complexity and compliance requirements.

**Security Model**: No user authentication reduces external attack surface; users maintain responsibility for local file system security and backup procedures.

## Reversibility Assessment

**Migration Complexity**: **High** - Moving from SQLite single-user to multi-user architecture would require fundamental application redesign including authentication, data isolation, and external database migration.

**Data Portability**: **High** - SQLite data is easily exportable to CSV, JSON, or other standard formats, ensuring user data is never locked in proprietary formats.

**Rollback Strategy**: **Not Applicable** - Architectural decisions are foundational design choices that cannot be easily reversed without complete application rewrite.

## Decision Review Process

### Criteria for Reconsidering

**Performance Limitations**: If SQLite performance becomes insufficient for typical use cases (>1000 positions)

**User Demand**: Significant user demand for multi-user features with clear value proposition

**Maintenance Burden**: If simplicity goals are not reducing maintenance complexity as expected

### Change Impact Assessment Process

Any proposed architectural change must evaluate:

1. **Complexity Impact**: Quantify additional complexity introduced
2. **Dependency Analysis**: Document new external dependencies required
3. **User Value**: Demonstrate significant improvement in user workflow
4. **Migration Path**: Define clear migration strategy for existing users
5. **Rollback Plan**: Document rollback procedures if change fails

### Amendment Process

1. **Document Pain Points**: Specific problems requiring architectural change
2. **Prototype Alternative**: Build minimal proof-of-concept for proposed approach
3. **Community Review**: Gather user and contributor feedback on proposed changes
4. **Impact Analysis**: Complete assessment of migration complexity and user impact
5. **Staged Implementation**: If approved, implement with backward compatibility

## Decision History

**August 2025**: Initial architectural decisions documented (ADR-001)

- **Selected**: SQLite database, single-user architecture, local-first approach
- **Status**: Validated with v0.1.0 release achieving 383+ passing tests
- **Performance**: Confirmed support for portfolios up to 1000+ positions
- **Dependencies**: Zero external dependencies achieved for core functionality

---

_This ADR serves as the foundational architectural guidance for Ashfolio development through v1.0 and beyond, ensuring consistency with the local-first, privacy-focused philosophy that defines the project._
