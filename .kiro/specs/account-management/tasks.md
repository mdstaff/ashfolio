# Account Management Implementation Plan

This implementation plan converts the account management design into a series of discrete, manageable coding tasks that build incrementally toward a complete account management system. Each task is designed to be actionable by a coding agent and builds upon previous tasks.

## Task Overview

The implementation is organized into 4 phases:

1. **Foundation Setup** - Core LiveView structure and routing
2. **Account Listing** - Display and basic interactions
3. **CRUD Operations** - Create, edit, delete functionality
4. **Polish and Integration** - Testing, accessibility, and final integration

## Phase 1: Foundation Setup (90% confidence)

- [ ] 1. Set up AccountLive module structure and routing

  - Create directory structure: `lib/ashfolio_web/live/account_live/`
  - Create basic `AccountLive.Index` module with mount/3 and render/1 functions
  - Create basic `AccountLive.Show` module for account details
  - Add routing configuration in `router.ex` for `/accounts` paths
  - Verify routing works with basic "Accounts" page display
  - _Requirements: 1.1, 7.1_

- [ ] 2. Implement basic account listing functionality

  - Enhance `AccountLive.Index.mount/3` to load accounts using `Account.accounts_for_user!/1`
  - Add assigns for accounts list, page title, and current page navigation
  - Create basic table display using existing `.table` component from core_components
  - Display account name, platform, balance, and exclusion status in table columns
  - Integrate with `assign_current_page(:accounts)` for navigation highlighting
  - _Requirements: 1.1, 1.2_

- [ ] 3. Add currency formatting and visual enhancements

  - Integrate `FormatHelpers.format_currency/1` for balance display formatting
  - Add visual indicators for excluded accounts (badges/styling)
  - Implement empty state display when no accounts exist
  - Add proper CSS classes for responsive table layout
  - Create "New Account" button in header (non-functional for now)
  - _Requirements: 1.3, 1.4_

## Phase 2: Account Display and Basic Interactions (85% confidence)

- [ ] 4. Create AccountLive.Show module for account details

  - Implement `AccountLive.Show` with `mount/3` and `handle_params/3` functions
  - Load account data using `Account.get_by_id!/1` with account ID from URL params
  - Load associated transactions using `Transaction.by_account!/1` for transaction summary
  - Display account information in stat cards (balance, transaction count, status)
  - Add breadcrumb navigation back to accounts list
  - _Requirements: 7.2, 7.3_

- [ ] 5. Implement account detail view layout and transaction summary

  - Create comprehensive account detail layout with header, stats, and transaction list
  - Display recent transactions table (limit to 10 most recent)
  - Add account status indicators (active/excluded) with proper styling
  - Calculate and display transaction summary statistics
  - Add "Edit Account" and "Delete Account" action buttons (non-functional for now)
  - _Requirements: 7.4, 7.5_

- [ ] 6. Add account exclusion toggle functionality

  - Implement `handle_event("toggle_exclusion", params, socket)` in AccountLive.Index
  - Use `Account.toggle_exclusion/2` to update account exclusion status
  - Add success/error flash message handling using existing ErrorHelpers
  - Update account list display after successful toggle
  - Add visual feedback during toggle operation (loading state)
  - _Requirements: 5.1, 5.2, 5.3_

## Phase 3: CRUD Operations (80% confidence)

- [ ] 7. Create AccountLive.FormComponent for reusable forms

  - Create `AccountLive.FormComponent` as a live_component module
  - Implement modal-based form layout with close button and proper styling
  - Add form fields for name, platform, balance, and is_excluded using `.simple_form`
  - Implement `update/2` callback to initialize form with account data or empty account
  - Add form validation display using Ash changeset validation
  - _Requirements: 2.1, 8.1, 8.2_

- [ ] 8. Implement account creation functionality

  - Add `handle_event("new_account", params, socket)` to show creation form
  - Implement `handle_event("save", params, socket)` in FormComponent for creation
  - Use `Account.create/1` with user_id assignment for new account creation
  - Add form validation with real-time feedback using `handle_event("validate", params, socket)`
  - Handle creation success/error with appropriate flash messages and form state updates
  - _Requirements: 2.2, 2.3, 2.4, 2.5_

- [ ] 9. Implement account editing functionality

  - Add `handle_event("edit_account", params, socket)` to show edit form with pre-populated data
  - Implement account update logic in FormComponent using `Account.update/2`
  - Handle edit form validation and error display for update operations
  - Add success/error handling for account updates with flash messages
  - Ensure form closes and account list refreshes after successful update
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

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
