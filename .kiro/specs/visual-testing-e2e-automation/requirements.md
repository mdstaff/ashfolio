# Requirements Document

## Introduction

This feature introduces comprehensive visual testing and end-to-end (E2E) automation capabilities to Ashfolio, building upon the existing robust test foundation of 383 passing tests. The enhancement will integrate Playwright MCP (Model Context Protocol) server capabilities with Claude Desktop to enable natural language test generation, visual regression testing, and comprehensive browser automation while maintaining compatibility with Ashfolio's SQLite local-first architecture.

The implementation will create a hybrid testing strategy that preserves the existing Phoenix LiveView test suite while adding browser-based validation, visual consistency checks, and AI-assisted test creation capabilities.

## Requirements

### Requirement 1

User Story: As a developer, I want to use natural language to generate and execute browser-based tests, so that I can efficiently create comprehensive E2E test coverage without writing complex automation code.

#### Acceptance Criteria

1. WHEN I describe a test scenario in natural language to Claude THEN the system SHALL generate and execute corresponding Playwright browser automation
2. WHEN I request "Navigate to dashboard, add a new transaction for AAPL, verify portfolio value updates" THEN the system SHALL perform these actions automatically and provide validation results
3. WHEN I use the Playwright MCP integration THEN the system SHALL work seamlessly with Ashfolio's SQLite local-first architecture
4. WHEN I generate tests through Claude THEN the system SHALL integrate with the existing SQLiteHelpers patterns for data setup
5. WHEN I create browser tests THEN the system SHALL support both Microsoft's official MCP server and ExecuteAutomation's enhanced MCP server options

### Requirement 2

User Story: As a developer, I want automated visual regression testing through Playwright MCP, so that I can detect unintended UI changes and maintain visual consistency across updates.

#### Acceptance Criteria

1. WHEN I run visual regression tests THEN the system SHALL capture screenshots of key application states using Playwright MCP
2. WHEN visual changes are detected THEN the system SHALL provide clear diff comparisons between baseline and current screenshots
3. WHEN I update the UI intentionally THEN the system SHALL allow me to update baseline screenshots through a simple command
4. WHEN visual tests run THEN the system SHALL integrate with the existing test architecture using SQLite patterns
5. WHEN I capture screenshots THEN the system SHALL use Playwright's built-in screenshot capabilities with consistent viewport settings

### Requirement 3

User Story: As a developer, I want E2E tests that validate complete user workflows, so that I can ensure the application works correctly from a user's perspective across all critical paths.

#### Acceptance Criteria

1. WHEN I run E2E tests THEN the system SHALL validate complete user workflows from start to finish
2. WHEN E2E tests execute THEN the system SHALL test real-time price updates and portfolio calculations in the browser
3. WHEN I test user interactions THEN the system SHALL validate JavaScript functionality and LiveView real-time updates
4. WHEN E2E tests run THEN the system SHALL work with the single-user SQLite architecture without external dependencies
5. WHEN I execute browser tests THEN the system SHALL provide accessibility tree analysis to bypass visual interpretation needs

### Requirement 4

User Story: As a developer, I want the new testing capabilities to integrate seamlessly with existing development workflows, so that I can maintain productivity while gaining enhanced testing coverage.

#### Acceptance Criteria

- WHEN I use the justfile commands THEN the system SHALL provide new commands for visual and E2E testing (test-visual, test-e2e, test-visual-update)
- WHEN I set up test data THEN the system SHALL use established SQLiteHelpers patterns for consistency
- WHEN I run different test types THEN the system SHALL organize tests into clear layers (Phoenix LiveView, Playwright MCP Browser, Visual Regression)
- WHEN I configure the system THEN the system SHALL integrate with Claude Desktop through MCP server configuration

### Requirement 5

User Story: As a developer, I want comprehensive test coverage for critical Ashfolio workflows, so that I can ensure reliability of core portfolio management functionality.

#### Acceptance Criteria

1. WHEN I test portfolio workflows THEN the system SHALL validate account creation, transaction entry, portfolio viewing, and price refresh workflows
2. WHEN I test dashboard functionality THEN the system SHALL verify portfolio calculations, holdings display, and real-time updates
3. WHEN I test transaction management THEN the system SHALL validate all transaction types (buy, sell, dividend, fee) with proper error handling
4. WHEN I test account management THEN the system SHALL verify CRUD operations, exclusion toggles, and account relationships
5. WHEN I test market data integration THEN the system SHALL validate Yahoo Finance integration, price caching, and error handling scenarios

### Requirement 6

User Story: As a developer, I want streamlined visual testing through Playwright MCP, so that I can maintain visual consistency with a single, integrated toolchain.

#### Acceptance Criteria

1. WHEN I run visual tests THEN the system SHALL use Playwright's built-in screenshot and comparison capabilities
2. WHEN I need cross-browser testing THEN the system SHALL support multiple browser engines through Playwright
3. WHEN I integrate with CI/CD THEN the system SHALL support pipeline integration for automated visual validation
4. WHEN I manage visual baselines THEN the system SHALL provide clear workflows for updating and maintaining reference images through simple commands
5. WHEN I compare screenshots THEN the system SHALL use Playwright's native image comparison with configurable thresholds

### Requirement 7

User Story: As a developer, I want the testing enhancements to support Ashfolio's local-first architecture, so that testing remains fast, reliable, and independent of external services.

#### Acceptance Criteria

1. WHEN I run tests THEN the system SHALL work with SQLite database without requiring external database services
2. WHEN I test locally THEN the system SHALL support the single-user architecture without authentication complexity
3. WHEN I execute browser tests THEN the system SHALL work with localhost deployment and local file storage
4. WHEN I use MCP integration THEN the system SHALL maintain compatibility with the existing ETS caching system
5. WHEN I run comprehensive tests THEN the system SHALL preserve the fast execution characteristics of the current test suite
