# Account Management Implementation Plan

This implementation plan converts the account management design into a series of discrete, manageable coding tasks that build incrementally toward a complete account management system. Each task is designed to be actionable by a coding agent and builds upon previous tasks.

## Task Overview

The implementation is organized into 4 phases:

1. **Foundation Setup** - Core LiveView structure and routing
2. **Account Listing** - Display and basic interactions
3. **CRUD Operations** - Create, edit, delete functionality
4. **Polish and Integration** - Testing, accessibility, and final integration

## Phase 1: Foundation Setup (90% confidence)

- [x] 1. Set up AccountLive module structure and routing

  - ✅ Created directory structure: `lib/ashfolio_web/live/account_live/`
  - ✅ Created comprehensive `AccountLive.Index` module with mount/3, handle_params/3, handle_event/3, handle_info/3, and render/1 functions
  - ✅ Prepared for `AccountLive.Show` module for account details (referenced in apply_action)
  - ✅ Added routing configuration in `router.ex` for `/accounts` paths (existing from Task 17)
  - ✅ Verified routing works with full account management interface
  - _Requirements: 1.1, 7.1_
  - **Completed: 2025-08-03**

- [x] 2. Implement basic account listing functionality

  - Enhance `AccountLive.Index.mount/3` to load accounts using `Account.accounts_for_user!/1`
  - Add assigns for accounts list, page title, and current page navigation
  - Create basic table display using existing `.table` component from core_components
  - Display account name, platform, balance, and exclusion status in table columns
  - Integrate with `assign_current_page(:accounts)` for navigation highlighting
  - _Requirements: 1.1, 1.2_

- [x] 3. Add currency formatting and visual enhancements

  - ✅ Integrated `FormatHelpers.format_currency/1` for balance display formatting
  - ✅ Added visual indicators for excluded accounts (status badges with icons)
  - ✅ Implemented enhanced empty state display with call-to-action
  - ✅ Added responsive CSS classes for mobile-first table layout
  - ✅ Created "New Account" button in header with proper styling
  - ✅ Added account icons, status badges, and improved visual hierarchy
  - ✅ Implemented responsive design with mobile-optimized action buttons
  - ✅ Added table footer with account count and total balance summary
  - _Requirements: 1.3, 1.4_
  - **Completed: 2025-08-03**

## Phase 2: Account Display and Basic Interactions (85% confidence)

- [x] 4. Create AccountLive.Show module for account details

  - ✅ Implemented `AccountLive.Show` with `mount/3` and `handle_params/3` functions
  - ✅ Load account data using `Account.get_by_id!/1` with account ID from URL params
  - ✅ Load associated transactions using `Transaction.by_account!/1` for transaction summary
  - ✅ Display account information in stat cards (balance, transaction count, status)
  - ✅ Add breadcrumb navigation back to accounts list
  - ✅ Comprehensive test suite with 8 test cases covering all functionality
  - _Requirements: 7.2, 7.3_
  - **Completed: 2025-08-03**

- [x] 5. Implement account detail view layout and transaction summary

  - ✅ Created comprehensive account detail layout with header, stats, and transaction summary
  - ✅ Display transaction statistics with counts and totals for buy/sell/dividend/fee transactions
  - ✅ Added account status indicators (active/excluded) with proper styling and visual feedback
  - ✅ Calculate and display transaction summary statistics using `calculate_transaction_stats/1`
  - ✅ Added "Edit Account" action button with proper navigation
  - ✅ Implemented empty state for accounts with no transactions with call-to-action
  - _Requirements: 7.4, 7.5_
  - **Completed: 2025-08-03**

- [x] 6. Add account exclusion toggle functionality

  - ✅ Implemented `handle_event("toggle_exclusion", params, socket)` in AccountLive.Index
  - ✅ Uses `Account.toggle_exclusion/2` to update account exclusion status
  - ✅ Added success/error flash message handling using `ErrorHelpers.put_success_flash/2` and `ErrorHelpers.put_error_flash/3`
  - ✅ Updates account list display after successful toggle with `list_accounts/1`
  - ✅ Added visual feedback during toggle operation with loading state and spinner animation
  - ✅ Proper button styling with conditional classes for Include/Exclude states
  - ✅ Disabled button state during toggle operation to prevent double-clicks
  - ✅ Comprehensive error handling with user-friendly messages
  - _Requirements: 5.1, 5.2, 5.3_
  - **Completed: 2025-08-03**

## Phase 3: CRUD Operations (80% confidence)

> **🚨 NEXT AGENT PRIORITY**
>
> **Current Status**: Phase 8 Foundation + Account CRUD Complete (Tasks 1-9 ✅)
> **Next Task**: Task 10 - Implement account deletion functionality
> **Test Suite**: All account management tests passing (100% pass rate)
>
> **Key Context for Next Agent**:
>
> - Complete account management system implemented (create, read, edit, exclusion toggle)
> - FormComponent handles both creation and editing with proper validation
> - All Ash resource operations working (Account.create/1, Account.update/2, Account.toggle_exclusion/2)
> - FormatHelpers and ErrorHelpers modules fully integrated
> - Ready to implement safe account deletion with transaction checking

- [x] 7. Create AccountLive.FormComponent for reusable forms

  - ✅ Created `AccountLive.FormComponent` as a live_component module with complete modal-based form
  - ✅ Implemented modal-based form layout with close button and proper styling
  - ✅ Added form fields for name, platform, balance, and is_excluded using `.simple_form`
  - ✅ Implemented `update/2` callback to initialize form with account data or empty account for both :new and :edit actions
  - ✅ Added form validation display using Ash changeset validation with real-time feedback
  - ✅ Integrated with AshPhoenix.Form for proper Ash resource form handling
  - ✅ Added proper event handling for validate, save, and cancel actions
  - ✅ Implemented parent notification system for form completion and cancellation
  - ✅ Added loading states and proper form submission handling
  - ✅ Professional modal styling with backdrop and responsive design
  - _Requirements: 2.1, 8.1, 8.2_
  - **Completed: 2025-08-04**

- [x] 8. Implement account creation functionality

  - ✅ Added `handle_event("new_account", params, socket)` to show creation form
  - ✅ Implemented `handle_event("save", params, socket)` in FormComponent for creation
  - ✅ Uses `Account.create/1` with user_id assignment for new account creation
  - ✅ Added form validation with real-time feedback using `handle_event("validate", params, socket)`
  - ✅ Handles creation success/error with appropriate flash messages and form state updates
  - ✅ Fixed test parameter naming from `account:` to `form:` to match FormComponent implementation
  - ✅ All 10 account creation tests now passing with comprehensive form validation coverage
  - _Requirements: 2.2, 2.3, 2.4, 2.5_
  - **Completed: 2025-08-04**

- [x] 9. Implement account editing functionality

  - ✅ Added `handle_event("edit_account", params, socket)` to show edit form with pre-populated data
  - ✅ Implemented account update logic in FormComponent using `Account.update/2`
  - ✅ Added edit form validation and error display for update operations
  - ✅ Implemented success/error handling for account updates with flash messages
  - ✅ Form closes and account list refreshes after successful update
  - ✅ Comprehensive test suite with 7 test cases covering all editing functionality
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_
  - **Completed: 2025-08-04**

- [ ] 10. Implement account deletion functionality

  - Add `handle_event("delete_account", params, socket)` with confirmation dialog
  - Implement safe deletion check using `Transaction.by_account!/1` to verify no associated transactions
  - Use `Account.destroy/1` only when account has no transactions
  - Add JavaScript confirmation dialog using `data-confirm` attribute
  - Handle deletion success with flash message and account list refresh
  - Handle deletion prevention (account has transactions) with user-friendly error message suggesting account exclusion instead
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [ ] 11. Implement balance management functionality

  - Add balance update capability in edit form with decimal precision validation
  - Implement balance validation to prevent negative values using Ash validations
  - Add currency input formatting and validation in form component (manual entry for Phase 1)
  - Display last updated timestamp for balance information
  - Handle balance update success/error with appropriate user feedback
  - Add helper text explaining manual balance management approach for Phase 1
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

## Phase 4: Polish and Integration (85% confidence)

- [ ] 12. Add comprehensive form validation and error handling

  - Enhance FormComponent validation with field-level error display
  - Add client-side validation feedback using `phx-change="validate"` events
  - Implement user-friendly error messages for all validation scenarios
  - Add loading states for form submission with disabled buttons and spinners
  - Handle network errors and system errors with recovery suggestions
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ] 13. Implement responsive design and accessibility features

  - Add responsive CSS classes for mobile, tablet, and desktop layouts
  - Implement proper ARIA labels and semantic markup for screen readers
  - Add keyboard navigation support for all interactive elements
  - Ensure WCAG AA color contrast compliance for all text and UI elements
  - Test and fix focus management for modal forms and navigation
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [ ] 14. Add portfolio system integration

  - Implement PubSub broadcasting for account changes that affect portfolio calculations
  - Add `handle_info` callbacks to listen for portfolio update events
  - Ensure account exclusion changes trigger portfolio recalculation
  - Add integration with existing navigation system and breadcrumbs
  - Test integration with dashboard and other portfolio features
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [ ] 15. Create comprehensive test suite

  - Write unit tests for AccountLive.Index covering all event handlers and state management
  - Create unit tests for AccountLive.Show testing account detail display and navigation
  - Add unit tests for FormComponent covering form validation, submission, and error handling
  - Write integration tests for complete account management workflows (create → edit → delete)
  - Add specific tests for safe account deletion (prevention when transactions exist)
  - Test portfolio integration scenarios (exclusion changes, balance updates)
  - Add performance tests for account list loading with multiple accounts (up to 50)
  - Add accessibility tests to verify WCAG compliance and keyboard navigation
  - _Requirements: Test coverage for all functionality including enhanced requirements_

- [ ] 16. Final polish and performance optimization

  - Add loading states and optimistic updates for better user experience
  - Implement debounced form validation to reduce server load
  - Add caching for account lists using ETS integration (if needed for performance)
  - Optimize database queries with proper preloading and indexing
  - Ensure account list loads within 500ms for up to 50 accounts (Phase 1 target)
  - Add performance monitoring and error tracking for production readiness
  - Document Phase 1 limitations and future enhancement paths
  - _Requirements: Performance and reliability optimization, Requirement 11_

## Implementation Notes

### Key Technical Patterns

- **Form Handling**: Use Ash changesets for validation with Phoenix LiveView forms
- **State Management**: Leverage LiveView assigns for UI state and form data
- **Error Handling**: Use existing ErrorHelpers module for consistent error display
- **Navigation**: Integrate with existing navigation system and breadcrumb patterns
- **Styling**: Follow existing Tailwind CSS patterns and component styles

### Integration Points

- **Account Resource**: Use existing `Ashfolio.Portfolio.Account` Ash resource
- **Format Helpers**: Leverage `FormatHelpers.format_currency/1` for consistent formatting
- **Error Helpers**: Use `ErrorHelpers.put_error_flash/3` for user feedback
- **Core Components**: Use existing `.table`, `.button`, `.simple_form` components
- **Navigation**: Integrate with `assign_current_page/2` helper function

### Testing Strategy

- **Unit Tests**: Test individual LiveView modules and components in isolation
- **Integration Tests**: Test complete workflows and cross-module interactions
- **Accessibility Tests**: Verify WCAG compliance and assistive technology support
- **Performance Tests**: Ensure fast response times and smooth user interactions

### Success Criteria

Each task is complete when:

- All functionality works as specified in requirements
- Code follows existing project patterns and conventions
- Tests are written and passing for new functionality
- Integration with existing system is verified
- User experience is smooth and error-free

## Dependencies

- **Existing Account Resource**: All CRUD operations depend on the existing Account Ash resource
- **Format Helpers**: Currency formatting depends on existing FormatHelpers module
- **Core Components**: UI components depend on existing Phoenix core components
- **Navigation System**: Integration depends on existing navigation helper functions
- **Test Infrastructure**: Testing depends on existing test setup and patterns
