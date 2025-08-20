# Symbol Autocomplete Requirements

## Introduction

This feature adds intelligent symbol autocomplete to transaction forms, building on Ashfolio's solid v0.1.0 foundation. The autocomplete will search existing symbols and optionally query external APIs to help users quickly find and select securities.

Built on v0.1.0's production-ready architecture with 383 passing tests and comprehensive Ash Framework implementation.

## Requirements

### Requirement 1: Local Symbol Search

**User Story:** As an investor entering transactions, I want to search my existing symbols so that I can quickly select securities I've previously traded.

#### Acceptance Criteria

1. WHEN a user types 2+ characters in the symbol field THEN the system SHALL search existing Symbol resources by symbol code and company name
2. WHEN search results are found THEN they SHALL display in a dropdown showing symbol, company name, and current price
3. WHEN a user selects a symbol THEN the form SHALL auto-populate the symbol field and display current price information
4. WHEN no matches are found THEN the system SHALL show "No existing symbols found" message
5. WHEN the user clicks outside the dropdown THEN it SHALL close automatically

### Requirement 2: External API Integration (Optional Enhancement)

**User Story:** As an investor, I want to search for new symbols I haven't traded before so that I can easily add new securities to my portfolio.

#### Acceptance Criteria

1. WHEN no local symbols match the search THEN the system SHALL optionally query Yahoo Finance API for symbol suggestions
2. WHEN external API queries are made THEN they SHALL be rate-limited to prevent excessive API calls
3. WHEN external results are returned THEN they SHALL be clearly marked as "New Symbol" in the dropdown
4. WHEN a user selects a new symbol THEN the system SHALL automatically create a Symbol resource
5. WHEN API calls fail THEN the system SHALL gracefully degrade to local-only search

### Requirement 3: Performance and Caching

**User Story:** As a user, I want fast autocomplete responses so that I can efficiently enter transactions without delays.

#### Acceptance Criteria

1. WHEN searching local symbols THEN results SHALL appear within 200ms
2. WHEN external API calls are made THEN they SHALL be cached for 1 hour to improve performance
3. WHEN the same search is performed THEN cached results SHALL be used when available
4. WHEN the autocomplete dropdown is shown THEN it SHALL not block other form interactions
5. WHEN typing rapidly THEN search requests SHALL be debounced to prevent excessive queries

## Technical Requirements

### Integration Points

- Extend with search capabilities
- Reuse existing API integration
- Integrate with existing form components
- Utilize existing caching infrastructure

### Performance Targets

- Local search: < 200ms response time
- External search: < 2s response time with loading indicator
- Cache hit rate: > 80% for repeated searches
- Zero impact on existing form performance
