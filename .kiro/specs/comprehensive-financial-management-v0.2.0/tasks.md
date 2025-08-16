# Implementation Plan

Convert the feature design into a series of prompts for an AI Agent like Claude Sonnet that will implement each step in a test-driven manner. Prioritize best practices, incremental progress, and early testing, ensuring no big jumps in complexity at any stage. Make sure that each prompt builds on the previous prompts, and ends with wiring things together. There should be no hanging or orphaned code that isn't integrated into a previous step. Focus ONLY on tasks that involve writing, modifying, or testing code.

- [x] 1. Enhance Account resource for cash account types

  - Extend existing `Ashfolio.Portfolio.Account` resource with new attributes: `account_type` (atom with constraints), `interest_rate` (decimal), `minimum_balance` (decimal)
  - Add new read actions: `by_type`, `cash_accounts`, `investment_accounts`
  - Update validations to handle cash account specific rules
  - Generate and run database migration for new account attributes
  - Write comprehensive tests for enhanced Account resource including new attributes, actions, and validations
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 2. Create FinancialManagement domain and TransactionCategory resource

  - Create new `Ashfolio.FinancialManagement` domain module
  - Implement `Ashfolio.FinancialManagement.TransactionCategory` resource with attributes: name, color, is_system, parent_category_id
  - Define relationships: belongs_to user, belongs_to parent_category, has_many child_categories, has_many transactions
  - Create CRUD actions with proper validations (name uniqueness per user, color format, system category protection)
  - Generate database migration for transaction_categories table
  - Write unit tests for TransactionCategory resource covering all CRUD operations and validations
  - _Requirements: 5.1, 5.2_

- [x] 3. Enhance Transaction resource with investment categories

  - Add optional `category_id` relationship to existing `Ashfolio.Portfolio.Transaction` resource
  - Add belongs_to relationship to TransactionCategory for investment organization
  - Keep existing transaction types focused on investments (buy, sell, dividend, fee, interest, liability)
  - Generate database migration for category relationship
  - Write comprehensive tests for enhanced Transaction resource including category relationships and validations
  - _Requirements: 5.4_

- [x] 4. Implement BalanceManager for manual cash balance updates

  - Create `Ashfolio.FinancialManagement.BalanceManager` module
  - Implement `update_cash_balance/3` function for manual balance adjustments with optional notes
  - Add simple balance history tracking (timestamp, old_balance, new_balance, notes)
  - Add PubSub broadcasting for balance changes using existing `Ashfolio.PubSub`
  - Write unit tests for BalanceManager covering manual balance updates and history tracking
  - Write integration tests for balance change notifications
  - _Requirements: 2.1, 2.3, 2.4_

- [x] 5. Implement NetWorthCalculator for cross-account calculations

  - Create `Ashfolio.FinancialManagement.NetWorthCalculator` module
  - Implement `calculate_net_worth/1` function combining investment values and cash balances
  - Add `calculate_total_cash_balances/1` and `calculate_account_breakdown/1` helper functions
  - Integrate with existing `Ashfolio.Portfolio.Calculator` for investment values
  - Add PubSub integration for real-time net worth updates
  - Write unit tests for NetWorthCalculator covering various account combinations and edge cases
  - Write integration tests for net worth calculation across both domains
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 6. Create SymbolSearch module for local symbol lookup and caching

  - **Goal**: Implement local-first symbol search with ETS caching, preparing foundation for external API integration
  - **Context API Integration**: Use `Ashfolio.Context.search_symbols/2` for cross-domain symbol operations
  - Create `Ashfolio.FinancialManagement.SymbolSearch` module for local Symbol resource search
  - Implement local search by ticker and company name (case-insensitive) with relevance ranking
  - Add ETS-based result caching with configurable TTL (default: 5 minutes)
  - Maximum 50 results per search to prevent UI overflow
  - Write unit tests for search logic, cache operations, and result ranking
  - Write integration tests for ETS table lifecycle and cache expiration
  - **Dependencies**: Tasks 1-5 complete
  - **Out of Scope**: External API integration, symbol creation, real-time price data
  - _Requirements: 4.1, 4.3_

- [x] 6a. Add external API integration to SymbolSearch

  - **Goal**: Extend SymbolSearch with external API fallback when local results insufficient
  - **Context API Integration**: Add `Context.create_symbol_from_external/1` function
  - Implement external API fallback when local results < 3 matches
  - Add rate limiting: maximum 10 API calls per minute per user
  - Add `create_symbol_from_external/1` function with validation
  - Implement graceful degradation when API unavailable
  - Add error handling with specific types (:rate_limited, :api_unavailable)
  - Write unit tests with mocked API responses using ExUnit.Mox
  - Write integration tests for symbol creation and rate limiting
  - **Dependencies**: Task 6 complete
  - **Out of Scope**: Real-time price updates, premium API features
  - _Requirements: 4.2, 4.4_

- [x] 7. Create SymbolAutocomplete server-side component

  - **Goal**: Implement LiveView server-side autocomplete logic with debouncing and state management
  - **Context API Integration**: Use `Context.search_symbols/2` for all symbol lookups
  - Create `AshfolioWeb.Components.SymbolAutocomplete` LiveView component
  - Implement server-side debouncing (300ms) to prevent excessive searches
  - Add search state management (loading, results, error states)
  - Maximum 10 displayed results with "show more" capability
  - Add accessibility support with proper ARIA attributes
  - Write unit tests for component state transitions and debounce logic
  - Write LiveView tests for event handling, state updates, error scenarios
  - Write integration tests for Context API integration and search flow
  - **Dependencies**: Task 6 complete
  - **Out of Scope**: JavaScript hooks, complex UI animations, keyboard navigation
  - _Requirements: 4.1, 4.2_

- [ ] 7a. Add SymbolAutocomplete UI enhancements

  - **Goal**: Add client-side enhancements for improved user experience
  - **Context API Integration**: None (pure UI layer)
  - Add JavaScript hooks for keyboard navigation (arrow keys, enter, escape)
  - Implement dropdown positioning and responsive design
  - Add visual loading indicators and smooth transitions
  - Add click-outside-to-close behavior and mobile-friendly touch interactions
  - Write LiveView tests for user interaction scenarios
  - Write browser tests for keyboard navigation and mobile responsiveness
  - Write accessibility tests for screen reader compatibility
  - **Dependencies**: Task 7 complete
  - **Out of Scope**: Advanced animations, complex styling frameworks
  - _Requirements: 4.1, 4.2_

- [x] 8. Enhance AccountLive with Context API integration

  - **Goal**: Integrate existing account management with new Context API and cash account types
  - **Context API Integration**:
    - Replace direct Account queries with `Context.get_user_dashboard_data/1`
    - Use `Context.get_account_with_transactions/2` for account details
    - Integrate cash account balance updates through Context layer
  - Update `AshfolioWeb.AccountLive.Index` to use Context API for account data
  - Add account type filtering (All, Investment, Cash) using Context data structures
  - Update balance display to show Context-calculated balances
  - Add form validation using Context API for account type constraints
  - Integrate real-time updates via PubSub through Context layer
  - Write unit tests for Context API integration and data transformation
  - Write LiveView tests for account filtering, balance display, form handling
  - Write integration tests for PubSub subscription and real-time updates
  - **Dependencies**: Tasks 1-5 complete, Context API available
  - **Out of Scope**: UI redesign, new form components, manual balance entry
  - _Requirements: 1.1-1.4, 2.1_

- [x] 8a. Add manual balance update interface for cash accounts

  - **Goal**: Add UI for manual cash account balance updates with audit trail
  - **Context API Integration**: Use `Context.update_cash_balance/3` for balance modifications
  - Add modal form for balance updates (current balance, new balance, notes)
  - Implement balance change confirmation with before/after display
  - Add balance history timeline in account details view
  - Add validation preventing negative balances for savings/checking accounts
  - Implement success/error messaging with specific error handling
  - Write LiveView tests for modal interactions, form validation, confirmation flow
  - Write integration tests for balance update workflow and history display
  - Write error tests for invalid balance scenarios and validation failures
  - **Dependencies**: Task 8 complete, BalanceManager available
  - **Out of Scope**: Bulk balance updates, automated balance imports
  - _Requirements: 2.1, 2.3, 2.4_

- [x] 9. Create investment category management interface

  - Create `AshfolioWeb.CategoryLive.Index` for investment category listing and management
  - Create `AshfolioWeb.CategoryLive.FormComponent` for category creation and editing
  - Implement color picker component for category colors
  - Focus on investment-focused categories (Growth, Income, Speculative, Index)
  - Implement system category protection (cannot delete/edit system categories)
  - Write LiveView tests for category management including CRUD operations and system category protection
  - _Requirements: 5.1, 5.2_

- [x] 10. Enhance TransactionLive with categories and symbol autocomplete

  - Update `AshfolioWeb.TransactionLive.FormComponent` to include investment category selection dropdown
  - Integrate SymbolAutocomplete component into transaction forms
  - Add category display and filtering to `AshfolioWeb.TransactionLive.Index`
  - Focus on investment transaction enhancement (no cash transaction forms needed)
  - Write LiveView tests for enhanced transaction forms including category assignment and symbol autocomplete
  - _Requirements: 4.1, 4.4, 5.3, 5.4_

- [x] 11. Enhance DashboardLive with net worth integration

  - Update `AshfolioWeb.DashboardLive` to display net worth summary alongside portfolio summary
  - Add investment vs cash breakdown visualization
  - Integrate real-time net worth updates via PubSub subscription
  - Add account type breakdown display (investment accounts vs cash accounts)
  - Update dashboard loading and error handling for net worth calculations
  - Write LiveView tests for enhanced dashboard including net worth display and real-time updates
  - _Requirements: 3.1, 3.2, 3.3_

- [x] 12. Create investment category seeding and system setup

  - Create `Ashfolio.FinancialManagement.CategorySeeder` module
  - Implement investment-focused system category seeding (Growth, Income, Speculative, Index, Cash, Bonds) with appropriate colors
  - Add category seeding to existing database seeding workflows
  - Create migration to seed system categories for existing users
  - Write tests for category seeding including idempotent seeding behavior
  - _Requirements: 5.1, 5.2_

- [x] 13. Add investment category filtering and display

  - Implement category-based filtering in investment transaction lists
  - Add color-coded category tags to transaction displays
  - Create category-based transaction grouping and summary views
  - Add investment category statistics and analysis
  - Implement category filter persistence in LiveView state
  - Write tests for category filtering, display, and statistics
  - _Requirements: 5.3, 5.4_

- [x] 14. Implement performance optimizations

  - Add database indexes for new query patterns (account_type, category_id)
  - Optimize net worth calculation queries with batch loading
  - Implement symbol search result caching with ETS
  - Add query optimization for category-based transaction filtering
  - Profile and optimize LiveView update performance for real-time features
  - Write performance tests and benchmarks for critical calculation paths
  - _Requirements: Performance targets from requirements_

- [x] 15. Enhance error handling for new features

  - ✅ Extended `Ashfolio.ErrorHandler` with 17 new v0.2.0 error categories (commit 2f1c155)
  - ✅ Added comprehensive symbol search error handling and fallback behavior
  - ✅ Added category management error handling with system category protection
  - ✅ Created user-friendly error messages with actionable guidance for all scenarios
  - ✅ Created comprehensive error testing: 67 handler tests + 16 component tests + 21 integration tests
  - ✅ Implemented 5 reusable LiveView error display components with accessibility
  - _Completed: August 15, 2025 - Production-ready error handling infrastructure_

- [ ] 16. Create comprehensive integration tests

  - Write end-to-end tests for complete cash account workflows with manual balance management
  - Create integration tests for net worth calculation across mixed account types
  - Test symbol autocomplete integration with transaction creation
  - Write tests for investment category assignment and filtering workflows
  - Test backward compatibility with existing v0.1.0 investment functionality
  - _Requirements: All requirements - integration aspects_

- [ ] 17. Final system integration and validation

  - Verify all PubSub integrations work correctly across domains
  - Test real-time updates for net worth, balances, and dashboard
  - Validate backward compatibility with existing data and functionality
  - Run complete test suite and ensure 100% pass rate
  - Perform manual testing of all new workflows
  - Update documentation and code comments for new features
  - _Requirements: All requirements - final validation_

- [ ] 18. Create comprehensive migration and backward compatibility tests

  - **Goal**: Ensure seamless upgrade path from v0.1.0 to v0.2.0 with data integrity
  - **Context API Integration**: Test Context API with existing v0.1.0 data structures
  - **Previous Attempt**: Task partially attempted but reverted due to raw SQL complexity
  - **Lessons Learned**: Avoid raw SQL migrations, use Ash Framework's migration patterns
  - Write migration tests for new account types with existing account data
  - Add data integrity verification for enhanced Transaction and Account resources
  - Test Context API compatibility with legacy data structures
  - Create performance benchmarks comparing v0.1.0 and v0.2.0 operations
  - Implement rollback procedures and testing for critical migration failures
  - Write migration tests for each database migration with realistic data volumes
  - Write compatibility tests for Context API functions with v0.1.0 data
  - Write performance tests ensuring no regression in core operation response times
  - **Dependencies**: Tasks 16-17 complete (Task 15 complete)
  - **Out of Scope**: Zero-downtime migrations, external data imports, raw SQL approaches
  - _Requirements: All requirements - backward compatibility aspects_
