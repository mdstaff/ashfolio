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

- [ ] 6. Create SymbolSearch module for intelligent symbol autocomplete

  - Create `Ashfolio.FinancialManagement.SymbolSearch` module
  - Implement `search_symbols/2` function with local Symbol resource search first, then external API fallback
  - Add `create_symbol_from_external/1` function to create Symbol resources from API data
  - Implement ETS caching for search results with TTL cleanup
  - Add rate limiting and error handling for external API calls
  - Write unit tests for SymbolSearch covering local search, external API integration, and caching
  - Write integration tests for symbol creation from external data
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [ ] 7. Create SymbolAutocomplete LiveView component

  - Create `AshfolioWeb.Components.SymbolAutocomplete` LiveView component
  - Implement real-time search with 200ms debounce using JavaScript hooks
  - Add dropdown UI with symbol, company name, and current price display
  - Implement keyboard navigation (arrow keys, enter, escape)
  - Add loading states and error handling for search operations
  - Write LiveView component tests for search functionality, keyboard navigation, and error states
  - _Requirements: 4.1, 4.2_

- [ ] 8. Enhance AccountLive for cash account management with manual balance updates

  - Update `AshfolioWeb.AccountLive.Index` to display accounts by type with tabbed interface
  - Enhance `AshfolioWeb.AccountLive.FormComponent` with dynamic fields based on account_type
  - Add manual balance update interface for cash accounts (current balance, new balance, optional notes)
  - Update account listing to show type-specific metadata (interest rate, minimum balance, current balance)
  - Add cash account creation and editing workflows
  - Write LiveView tests for cash account management including manual balance updates and form validation
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2_

- [ ] 9. Create investment category management interface

  - Create `AshfolioWeb.CategoryLive.Index` for investment category listing and management
  - Create `AshfolioWeb.CategoryLive.FormComponent` for category creation and editing
  - Implement color picker component for category colors
  - Focus on investment-focused categories (Growth, Income, Speculative, Index)
  - Implement system category protection (cannot delete/edit system categories)
  - Write LiveView tests for category management including CRUD operations and system category protection
  - _Requirements: 5.1, 5.2_

- [ ] 10. Enhance TransactionLive with categories and symbol autocomplete

  - Update `AshfolioWeb.TransactionLive.FormComponent` to include investment category selection dropdown
  - Integrate SymbolAutocomplete component into transaction forms
  - Add category display and filtering to `AshfolioWeb.TransactionLive.Index`
  - Focus on investment transaction enhancement (no cash transaction forms needed)
  - Write LiveView tests for enhanced transaction forms including category assignment and symbol autocomplete
  - _Requirements: 4.1, 4.4, 5.3, 5.4_

- [ ] 11. Enhance DashboardLive with net worth integration

  - Update `AshfolioWeb.DashboardLive` to display net worth summary alongside portfolio summary
  - Add investment vs cash breakdown visualization
  - Integrate real-time net worth updates via PubSub subscription
  - Add account type breakdown display (investment accounts vs cash accounts)
  - Update dashboard loading and error handling for net worth calculations
  - Write LiveView tests for enhanced dashboard including net worth display and real-time updates
  - _Requirements: 3.1, 3.2, 3.3_

- [ ] 12. Create investment category seeding and system setup

  - Create `Ashfolio.FinancialManagement.CategorySeeder` module
  - Implement investment-focused system category seeding (Growth, Income, Speculative, Index) with appropriate colors
  - Add category seeding to existing database seeding workflows
  - Create migration to seed system categories for existing users
  - Write tests for category seeding including idempotent seeding behavior
  - _Requirements: 5.1, 5.2_

- [ ] 13. Add investment category filtering and display

  - Implement category-based filtering in investment transaction lists
  - Add color-coded category tags to transaction displays
  - Create category-based transaction grouping and summary views
  - Add investment category statistics and analysis
  - Implement category filter persistence in LiveView state
  - Write tests for category filtering, display, and statistics
  - _Requirements: 5.3, 5.4_

- [ ] 14. Implement performance optimizations

  - Add database indexes for new query patterns (account_type, category_id)
  - Optimize net worth calculation queries with batch loading
  - Implement symbol search result caching with ETS
  - Add query optimization for category-based transaction filtering
  - Profile and optimize LiveView update performance for real-time features
  - Write performance tests and benchmarks for critical calculation paths
  - _Requirements: Performance targets from requirements_

- [ ] 15. Enhance error handling for new features

  - Extend `Ashfolio.ErrorHandler` with cash balance management error handling
  - Add symbol search error handling and fallback behavior
  - Add category management error handling
  - Create user-friendly error messages for all new error scenarios
  - Write tests for error handling covering all new error scenarios and recovery paths
  - _Requirements: All requirements - error handling aspects_

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

- [ ] 19. Final system integration and validation
  - Verify all PubSub integrations work correctly across domains
  - Test real-time updates for net worth, balances, and dashboard
  - Validate backward compatibility with existing data and functionality
  - Run complete test suite and ensure 100% pass rate
  - Perform manual testing of all new workflows
  - Update documentation and code comments for new features
  - _Requirements: All requirements - final validation_
