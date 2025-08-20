# Comprehensive Financial Management v0.2.0 Requirements

## Introduction

This document outlines the requirements for Ashfolio v0.2.0, which expands from portfolio-only investment tracking to comprehensive personal financial management. This addresses user needs for replacing spreadsheet-based financial workflows while maintaining our local-first, SQLite-based architecture.

Portfolio-only investment tracking → Comprehensive financial management (investments + cash + net worth)

Individual currently using spreadsheet-based approach requiring 45+ minutes monthly for financial updates. Focus on practical net worth tracking without complex cash transaction management or tax-irrelevant transfer tracking.

## Requirements

### Requirement 1: Cash Account Management

**User Story:** As someone managing comprehensive finances, I want to track cash accounts alongside my investment accounts so that I can see my complete financial picture in one application.

#### Acceptance Criteria

1. WHEN creating accounts THEN the system SHALL support cash account types (checking, savings, money market, CD) in addition to existing investment accounts
2. WHEN viewing accounts THEN cash and investment accounts SHALL be displayed in a unified listing with clear type indicators
3. WHEN managing cash accounts THEN the system SHALL support basic account metadata (interest rates, minimum balances) without sensitive banking information
4. WHEN using existing features THEN all current investment account functionality SHALL remain unchanged

### Requirement 2: Simple Cash Balance Management

**User Story:** As someone managing cash accounts, I want to manually adjust cash balances when needed so that I can maintain accurate net worth calculations without detailed transaction tracking.

#### Acceptance Criteria

1. WHEN managing cash accounts THEN the system SHALL allow manual balance adjustments with optional notes
2. WHEN updating cash balances THEN the system SHALL record the change with timestamp for audit purposes
3. WHEN cash balances change THEN net worth calculations SHALL update automatically
4. WHEN viewing cash accounts THEN current balances SHALL be clearly displayed

### Requirement 3: Net Worth Calculation

**User Story:** As someone tracking wealth accumulation, I want real-time net worth calculation across all my accounts so that I can monitor my financial progress.

#### Acceptance Criteria

1. WHEN viewing the dashboard THEN it SHALL display current net worth as the sum of all investment and cash account values
2. WHEN account balances change THEN net worth SHALL recalculate automatically and update in real-time
3. WHEN displaying net worth THEN the system SHALL show breakdown by account type (Investment vs Cash)
4. WHEN calculating net worth THEN it SHALL use current market values for investments and actual balances for cash accounts

### Requirement 4: Symbol Autocomplete

**User Story:** As an investor entering transactions, I want intelligent symbol search so that I can quickly find securities without typing full symbol names.

#### Acceptance Criteria

1. WHEN typing in symbol fields THEN the system SHALL provide autocomplete with local symbol search
2. WHEN typing 2+ characters THEN search results SHALL appear within 200ms showing symbol, company name, and current price
3. WHEN no local matches exist THEN the system SHALL optionally query Yahoo Finance API for new symbols
4. WHEN external symbols are selected THEN the system SHALL automatically create Symbol resources

### Requirement 5: Transaction Categories (Investment Focus)

**User Story:** As an investor managing transactions, I want to assign categories to my investment transactions so that I can organize and filter my investment activity.

#### Acceptance Criteria

1. WHEN creating investment transactions THEN the system SHALL allow optional category assignment from predefined categories (Growth, Income, Speculative, Index)
2. WHEN managing categories THEN the system SHALL support custom category creation with color coding
3. WHEN viewing transactions THEN categories SHALL be displayed as colored tags with filtering capabilities
4. WHEN categories are applied THEN they SHALL focus primarily on investment transaction organization

## Technical Requirements

### Architecture

- Extend existing Portfolio.Account resource for cash account types
- Create FinancialManagement domain for net worth and cash-specific features
- Maintain 100% backward compatibility with existing investment functionality

### Performance Targets

- Symbol autocomplete: < 200ms for local search
- Dashboard load: Maintain existing v0.1.0 performance
- Net worth calculation: Real-time updates without noticeable delay
