# Ashfolio Requirements Document - Simplified Phase 1

## Introduction

This document outlines the requirements for creating Ashfolio Phase 1, a simplified portfolio management application built with Elixir/Phoenix and the Ash Framework. This phase focuses on delivering core portfolio tracking functionality with high confidence and minimal complexity.

**Phase 1 Scope**: Core portfolio tracking with manual price updates and simple calculations
**Future Phases**: Real-time updates, advanced analytics, data import/export, macOS optimizations

The application architecture:

- **Backend**: Phoenix (Elixir) with Ash Framework
- **Frontend**: Phoenix LiveView (simplified UI)
- **Database**: SQLite with basic indexing
- **Cache**: Simple ETS for price caching
- **Market Data**: Yahoo Finance with manual refresh

## Requirements

### Requirement 1: Single User Local Application

**User Story:** As a local user, I want to run the application on my personal machine without complex authentication so that I can manage my portfolio privately and securely.

#### Acceptance Criteria

1. WHEN the application starts THEN it SHALL run as a single-user local application without authentication requirements
2. WHEN a user accesses the application THEN it SHALL be available only on localhost for security
3. WHEN the application initializes THEN it SHALL create a default user profile automatically
4. WHEN data is stored THEN it SHALL be contained within the local SQLite database
5. WHEN the application runs THEN it SHALL not require external authentication services or user management

### Requirement 2: Portfolio and Account Management

**User Story:** As an investor, I want to manage multiple investment accounts and track my portfolio performance so that I can make informed financial decisions.

#### Acceptance Criteria

1. WHEN a user creates an account THEN the system SHALL allow creation of multiple investment accounts with different platforms
2. WHEN a user has accounts THEN the system SHALL support account balance tracking over time
3. WHEN a user manages accounts THEN the system SHALL allow account exclusion from calculations
4. WHEN a user views accounts THEN the system SHALL display account balances, currencies, and associated platforms
5. WHEN a user deletes an account THEN the system SHALL cascade delete related data appropriately

### Requirement 3: Transaction and Order Management

**User Story:** As an investor, I want to record buy/sell transactions, dividends, and fees so that I can track my investment activity accurately.

#### Acceptance Criteria

1. WHEN a user creates a transaction THEN the system SHALL support multiple order types (BUY, SELL, DIVIDEND, FEE, INTEREST)
2. WHEN a user enters a transaction THEN the system SHALL require symbol, quantity, unit price, date, and currency
3. WHEN a user creates a transaction THEN the system SHALL allow optional comments and fee tracking
4. WHEN a user manages transactions THEN the system SHALL support draft transactions for incomplete entries
5. WHEN a user imports data THEN the system SHALL support bulk transaction import from CSV/JSON formats
6. WHEN a user exports data THEN the system SHALL provide transaction export functionality

### Requirement 4: Symbol and Market Data Management

**User Story:** As an investor, I want accurate and up-to-date market data for my investments so that I can track current values and performance.

#### Acceptance Criteria

1. WHEN the system processes symbols THEN it SHALL support multiple data sources (Yahoo Finance, CoinGecko, Manual entry)
2. WHEN market data is needed THEN it SHALL fetch and cache current and historical prices using ETS for real-time data
3. WHEN a symbol is created THEN it SHALL store metadata including asset class, currency, ISIN, sectors, and countries
4. WHEN market data is stale THEN it SHALL display last updated timestamp and provide manual refresh option for user-initiated price updates
5. WHEN a user searches symbols THEN it SHALL provide symbol lookup functionality across data sources
6. WHEN external APIs are unavailable THEN the system SHALL gracefully degrade and allow manual price entry
7. WHEN API failures occur THEN the system SHALL implement circuit breaker patterns with configurable failure thresholds (5 failures = open circuit)
8. WHEN API requests fail THEN the system SHALL retry with exponential backoff (1s, 2s, 4s, 8s) and structured logging

### Requirement 5: Simple Portfolio Performance Tracking

**User Story:** As an investor, I want to see basic portfolio performance metrics so that I can understand my investment returns.

#### Acceptance Criteria

1. WHEN a user views portfolio THEN the system SHALL calculate total portfolio value as sum of all holdings
2. WHEN performance is calculated THEN the system SHALL use simple return formula: (current_value - cost_basis) / cost_basis \* 100
3. WHEN a user views dashboard THEN the system SHALL display total return percentage and dollar amount
4. WHEN displaying holdings THEN the system SHALL show individual position gains/losses
5. WHEN portfolio data changes THEN the system SHALL recalculate values on page refresh

### Requirement 6: Manual Price Updates

**User Story:** As an investor, I want to manually refresh market prices so that I can get current portfolio values when needed.

#### Acceptance Criteria

1. WHEN a user clicks refresh prices THEN the system SHALL fetch current prices from Yahoo Finance
2. WHEN price updates complete THEN the system SHALL update portfolio calculations and display
3. WHEN price fetching fails THEN the system SHALL display an error message and use cached prices
4. WHEN prices are updated THEN the system SHALL show last updated timestamp
5. WHEN the page loads THEN the system SHALL display portfolio values using cached prices

### Requirement 7: Manual Transaction Entry

**User Story:** As an investor, I want to manually enter my transactions so that I can track my investment activity.

#### Acceptance Criteria

1. WHEN a user creates a transaction THEN the system SHALL provide a form with validation
2. WHEN entering transactions THEN the system SHALL support all transaction types (BUY, SELL, DIVIDEND, FEE)
3. WHEN a user submits a transaction THEN the system SHALL validate required fields and save to database
4. WHEN validation fails THEN the system SHALL display specific error messages
5. WHEN transactions are saved THEN the system SHALL update portfolio calculations

### Requirement 8: USD-Only Financial Calculations

**User Story:** As a US-based investor, I want all financial calculations and displays to use USD currency so that I can focus on my domestic portfolio without currency complexity.

#### Acceptance Criteria

1. WHEN financial data is stored THEN it SHALL be stored in USD currency only
2. WHEN amounts are displayed THEN they SHALL be formatted as USD currency ($X,XXX.XX)
3. WHEN calculations occur THEN they SHALL maintain precision for financial calculations using Decimal types
4. WHEN market data is fetched THEN it SHALL request USD prices from data sources
5. WHEN the application interface loads THEN it SHALL display all text in US English

### Requirement 9: Local API Access

**User Story:** As a local user, I want simple API access to my portfolio data so that I can export data or integrate with personal tools.

#### Acceptance Criteria

1. WHEN API access is needed THEN the system SHALL provide a simple REST API for local access
2. WHEN API requests are made THEN they SHALL be accessible without authentication on localhost
3. WHEN API data is requested THEN the system SHALL provide portfolio performance and holdings data in JSON format
4. WHEN API endpoints are accessed THEN they SHALL return data for the single local user
5. WHEN API documentation is needed THEN the system SHALL provide basic endpoint documentation

### Requirement 10: Ash Framework Data Modeling

**User Story:** As a developer, I want to use the Ash framework for data modeling and business logic so that I can leverage its powerful resource management and query capabilities.

#### Acceptance Criteria

1. WHEN data models are defined THEN they SHALL be implemented as Ash resources with proper attributes and relationships
2. WHEN business logic is needed THEN it SHALL be implemented using Ash actions (create, read, update, destroy)
3. WHEN data validation occurs THEN it SHALL use Ash's built-in validation and change management
4. WHEN queries are executed THEN they SHALL leverage Ash's query interface and filtering capabilities
5. WHEN data relationships exist THEN they SHALL be properly defined using Ash's relationship system
6. WHEN authorization is needed THEN it SHALL use Ash's policy system for resource access control
7. WHEN data changes occur THEN they SHALL trigger appropriate Ash notifications and events

### Requirement 11: Basic Application Performance

**User Story:** As a user, I want the application to be responsive and handle my portfolio data efficiently so that I can manage my investments without delays.

#### Acceptance Criteria

1. WHEN the application loads THEN it SHALL start and respond within 5 seconds
2. WHEN database queries execute THEN they SHALL use basic indexing for reasonable performance
3. WHEN the application processes data THEN it SHALL handle portfolios with up to 1,000 transactions efficiently
4. WHEN using ETS caching THEN it SHALL cache price data with simple cleanup
5. WHEN the application runs THEN it SHALL use standard Phoenix configuration without platform-specific optimizations
6. WHEN portfolio calculations are performed THEN the system SHALL use optimized query patterns to eliminate N+1 database queries
7. WHEN displaying holdings data THEN the system SHALL batch fetch symbol metadata to reduce database round trips

### Requirement 12: User Interface and Experience

**User Story:** As a portfolio manager, I want a clean, intuitive, and responsive interface that provides immediate access to my portfolio data so that I can efficiently monitor and manage my investments.

#### Acceptance Criteria

1. WHEN the application loads THEN it SHALL display the portfolio dashboard with total value, daily change, and key metrics visible immediately
2. WHEN market data updates THEN the interface SHALL reflect changes in real-time without requiring page refreshes using Phoenix LiveView
3. WHEN a user interacts with the interface THEN it SHALL provide immediate feedback with optimistic updates and loading states
4. WHEN displaying financial data THEN it SHALL use consistent formatting with proper currency symbols, decimal precision, and color coding for gains/losses
5. WHEN a user navigates between sections THEN the interface SHALL maintain responsive performance with smooth transitions
6. WHEN accessed on different screen sizes THEN the interface SHALL adapt appropriately with desktop-first responsive design
7. WHEN a user performs actions THEN the interface SHALL provide clear success/error feedback and maintain accessibility standards

### Requirement 13: Dashboard and Portfolio Overview

**User Story:** As an investor, I want a comprehensive dashboard that shows my portfolio performance at a glance so that I can quickly assess my investment status.

#### Acceptance Criteria

1. WHEN viewing the dashboard THEN it SHALL display total portfolio value, daily change, and performance metrics prominently
2. WHEN portfolio data changes THEN the dashboard SHALL update values in real-time with smooth animations
3. WHEN displaying holdings THEN it SHALL show current prices, daily changes, and total returns in a sortable table format
4. WHEN showing asset allocation THEN it SHALL provide visual charts (pie/donut) showing distribution by asset class, geography, and sectors
5. WHEN displaying recent activity THEN it SHALL show the latest transactions with quick access to add new transactions

### Requirement 14: Transaction Management Interface

**User Story:** As an investor, I want an efficient interface for entering, editing, and managing my transactions so that I can maintain accurate portfolio records.

#### Acceptance Criteria

1. WHEN adding transactions THEN the interface SHALL provide a form with symbol autocomplete, real-time price lookup, and validation
2. WHEN viewing transactions THEN it SHALL display them in a filterable, sortable table with pagination for large datasets
3. WHEN editing transactions THEN it SHALL support inline editing with immediate validation and feedback
4. WHEN importing data THEN it SHALL provide a CSV import interface with column mapping and error handling
5. WHEN managing bulk operations THEN it SHALL support multi-select actions and batch processing with progress indicators

### Requirement 15: Simple Data Display

**User Story:** As an investor, I want to see my portfolio data in clear tables and basic charts so that I can understand my investments.

#### Acceptance Criteria

1. WHEN viewing portfolio THEN the system SHALL display holdings in a sortable table
2. WHEN showing performance THEN the system SHALL use simple text displays with color coding (green for gains, red for losses)
3. WHEN displaying data THEN the system SHALL use basic HTML tables and simple CSS styling
4. WHEN data loads THEN the system SHALL show loading states during price fetching
5. WHEN errors occur THEN the system SHALL display clear error messages

### Requirement 16: Simple Price Management

**User Story:** As a user, I want simple price updates for my portfolio so that I can see current values without complex background processing.

#### Acceptance Criteria

1. WHEN price updates are needed THEN the system SHALL use a simple GenServer for coordination
2. WHEN fetching prices THEN the system SHALL make direct API calls without complex job queuing
3. WHEN price updates complete THEN the system SHALL update the display immediately
4. WHEN API calls fail THEN the system SHALL log errors and continue with cached prices
5. WHEN the application starts THEN it SHALL initialize the price refresh GenServer

### Requirement 17: Responsive Design and Accessibility

**User Story:** As a user with different devices and accessibility needs, I want the application to be usable across different screen sizes and assistive technologies so that I can access my portfolio information anywhere.

#### Acceptance Criteria

1. WHEN accessing on desktop THEN the interface SHALL provide full functionality with optimal layout and spacing
2. WHEN accessing on tablet THEN the interface SHALL adapt with appropriate touch targets and responsive layouts
3. WHEN using keyboard navigation THEN all interactive elements SHALL be accessible with proper focus management
4. WHEN using screen readers THEN financial data SHALL have appropriate ARIA labels and semantic markup
5. WHEN viewing in different lighting conditions THEN the interface SHALL maintain WCAG AA color contrast standards
6. WHEN the interface loads THEN it SHALL provide progressive enhancement with core functionality available without JavaScript

### Requirement 18: Basic Error Handling

**User Story:** As a user, I want clear error messages when something goes wrong so that I understand what happened and can continue using the application.

#### Acceptance Criteria

1. WHEN system errors occur THEN the application SHALL display user-friendly error messages
2. WHEN API calls fail THEN the system SHALL log the error and show a simple error message
3. WHEN form validation fails THEN the system SHALL highlight invalid fields with specific messages
4. WHEN database errors occur THEN the system SHALL show a generic error message and log details
5. WHEN the application encounters errors THEN it SHALL continue functioning for other operations

### Requirement 19: Documentation and Developer Onboarding

**User Story:** As a developer new to Elixir/Phoenix, I want comprehensive documentation and onboarding materials so that I can understand, contribute to, and maintain the codebase effectively.

#### Acceptance Criteria

1. WHEN setting up the development environment THEN the documentation SHALL provide step-by-step installation instructions for Elixir, Phoenix, and all dependencies specifically optimized for macOS with Apple Silicon (M1 Pro)
2. WHEN learning the codebase THEN it SHALL include architectural overview, code organization, and key concepts explanations
3. WHEN understanding Elixir-specific patterns THEN the documentation SHALL explain OTP concepts, GenServers, supervision trees, and Phoenix LiveView patterns used in the project
4. WHEN working with the Ash Framework THEN it SHALL provide examples and explanations of resource definitions, actions, and policies
5. WHEN contributing code THEN the documentation SHALL include coding standards, testing guidelines, and contribution workflows
6. WHEN troubleshooting THEN it SHALL provide common issues, debugging techniques, and performance optimization guides
7. WHEN deploying or running locally THEN it SHALL include clear setup instructions, configuration options, and operational guidance

### Requirement 19: Testing and Quality Assurance

**User Story:** As a developer, I want comprehensive testing patterns and guidelines so that I can maintain code quality and prevent regressions, especially when working with GenServers and concurrent systems.

#### Acceptance Criteria

1. WHEN testing Ash resources THEN the system SHALL provide reliable test patterns for resource actions, validations, and relationships
2. WHEN testing GenServers THEN the system SHALL handle singleton GenServer testing challenges including shared state, Mox configuration, and race conditions
3. WHEN testing external API integrations THEN the system SHALL use proper mocking with Mox to ensure reliable and fast test execution
4. WHEN testing concurrent behavior THEN the system SHALL focus on functionality over timing-dependent tests to avoid flaky test suites
5. WHEN running the test suite THEN it SHALL achieve 100% pass rate with proper isolation between tests
6. WHEN testing database operations THEN the system SHALL use proper sandbox configuration and handle Ash resource return values correctly
7. WHEN testing shared resources THEN the system SHALL handle persistent state gracefully and provide proper cleanup between tests

#### Technical Requirements

- **GenServer Testing**: Tests must handle singleton GenServers with `async: false` and proper Mox setup using `set_mox_from_context`
- **State Management**: Tests must handle persistent state between runs and not assume clean state
- **Mock Configuration**: External API calls must be mocked with proper expectation counts for shared processes
- **Database Testing**: Must use `Ashfolio.DataCase` with proper sandbox setup and handle list vs single record returns from Ash resources
- **Test Isolation**: Each test must clean up its own state and not interfere with other tests
