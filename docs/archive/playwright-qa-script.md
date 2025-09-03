# Ashfolio QA Testing Script - Playwright MCP

## Overview

This script provides comprehensive QA testing for the Ashfolio personal finance application using Playwright MCP commands. It tests core functionality, backwards compatibility, and user workflows to ensure the application meets quality standards.

## Prerequisites

- Ashfolio development server running (`just dev`)
- Server accessible at `http://localhost:4000`
- Database seeded with sample data

## QA Test Scenarios

### 1. Application Bootstrap & Health Check

Verify application loads and core systems are operational
Critical

```
# Start the server first
just server bg

# Navigate to application
mcp__playwright__browser_navigate {"url": "http://localhost:4000"}

# Take initial screenshot for baseline
mcp__playwright__browser_take_screenshot {"filename": "qa-01-initial-load.png", "fullPage": true}

# Verify page loads without errors
mcp__playwright__browser_console_messages {}

# Check that core elements are present
mcp__playwright__browser_snapshot {}
```

- Page loads successfully
- No console errors
- Navigation elements visible
- Dashboard displays

### 2. Navigation & Core Routes Testing

Verify all main navigation routes work correctly
High

```
# Test dashboard route
mcp__playwright__browser_navigate {"url": "http://localhost:4000/"}
mcp__playwright__browser_snapshot {}

# Test accounts route
mcp__playwright__browser_navigate {"url": "http://localhost:4000/accounts"}
mcp__playwright__browser_snapshot {}

# Test transactions route
mcp__playwright__browser_navigate {"url": "http://localhost:4000/transactions"}
mcp__playwright__browser_snapshot {}

# Test categories route
mcp__playwright__browser_navigate {"url": "http://localhost:4000/categories"}
mcp__playwright__browser_snapshot {}

# Take screenshots of each page
mcp__playwright__browser_take_screenshot {"filename": "qa-02-navigation-test.png", "fullPage": true}
```

- All routes load successfully
- LiveView components render correctly
- No 404 or server errors

### 3. Account Management Workflow

Test account creation and management functionality
High

```
# Navigate to accounts page
mcp__playwright__browser_navigate {"url": "http://localhost:4000/accounts"}
mcp__playwright__browser_snapshot {}

# Click "New Account" button (find the button first)
mcp__playwright__browser_click {"element": "New Account button", "ref": "[data-testid='new-account-btn']"}

# Fill in account form
mcp__playwright__browser_type {"element": "Account name input", "ref": "#account_name", "text": "QA Test Account"}
mcp__playwright__browser_type {"element": "Account type input", "ref": "#account_account_type", "text": "checking"}

# Submit form
mcp__playwright__browser_click {"element": "Save button", "ref": "[type='submit']"}

# Verify account was created
mcp__playwright__browser_snapshot {}
mcp__playwright__browser_take_screenshot {"filename": "qa-03-account-created.png"}
```

- Account form displays correctly
- Account is created successfully
- Redirect to account detail or list page

### 4. Transaction Management Workflow

Test transaction creation and viewing
High

```
# Navigate to transactions page
mcp__playwright__browser_navigate {"url": "http://localhost:4000/transactions"}
mcp__playwright__browser_snapshot {}

# Click "New Transaction" button
mcp__playwright__browser_click {"element": "New Transaction button", "ref": "[data-testid='new-transaction-btn']"}

# Fill transaction form with test data
mcp__playwright__browser_type {"element": "Symbol input", "ref": "#transaction_symbol", "text": "AAPL"}
mcp__playwright__browser_type {"element": "Quantity input", "ref": "#transaction_quantity", "text": "10"}
mcp__playwright__browser_type {"element": "Price input", "ref": "#transaction_price", "text": "150.00"}

# Submit transaction
mcp__playwright__browser_click {"element": "Save button", "ref": "[type='submit']"}

# Verify transaction appears in list
mcp__playwright__browser_snapshot {}
mcp__playwright__browser_take_screenshot {"filename": "qa-04-transaction-created.png"}
```

- Transaction form functions correctly
- Transaction is saved and displayed
- Calculations are accurate

### 5. Dashboard Functionality Test

Verify dashboard calculations and data display
High

```
# Navigate to dashboard
mcp__playwright__browser_navigate {"url": "http://localhost:4000/"}
mcp__playwright__browser_snapshot {}

# Check for net worth display
mcp__playwright__browser_evaluate {"function": "() => { return document.querySelector('[data-testid=\"net-worth\"]')?.textContent || 'Net worth not found'; }"}

# Check for account summaries
mcp__playwright__browser_evaluate {"function": "() => { return document.querySelectorAll('[data-testid=\"account-summary\"]').length; }"}

# Test responsive design by resizing browser
mcp__playwright__browser_resize {"width": 768, "height": 1024}
mcp__playwright__browser_take_screenshot {"filename": "qa-05-dashboard-mobile.png"}

mcp__playwright__browser_resize {"width": 1200, "height": 800}
mcp__playwright__browser_take_screenshot {"filename": "qa-05-dashboard-desktop.png"}
```

- Net worth calculations display correctly
- Account summaries are accurate
- Responsive design works on different screen sizes

### 6. Symbol Autocomplete Testing

Test symbol search and autocomplete functionality
Medium

```
# Navigate to transaction form
mcp__playwright__browser_navigate {"url": "http://localhost:4000/transactions/new"}
mcp__playwright__browser_snapshot {}

# Test symbol autocomplete
mcp__playwright__browser_type {"element": "Symbol input", "ref": "#transaction_symbol", "text": "AA", "slowly": true}

# Wait for autocomplete suggestions
mcp__playwright__browser_wait_for {"time": 2}
mcp__playwright__browser_snapshot {}

# Test selecting from autocomplete
mcp__playwright__browser_press_key {"key": "ArrowDown"}
mcp__playwright__browser_press_key {"key": "Enter"}

# Verify symbol was selected
mcp__playwright__browser_take_screenshot {"filename": "qa-06-symbol-autocomplete.png"}
```

- Autocomplete suggestions appear
- Symbol selection works correctly
- No JavaScript errors

### 7. Error Handling & Edge Cases

Test application resilience and error handling
Medium

```
# Test invalid routes
mcp__playwright__browser_navigate {"url": "http://localhost:4000/invalid-route"}
mcp__playwright__browser_snapshot {}

# Test form validation - submit empty form
mcp__playwright__browser_navigate {"url": "http://localhost:4000/accounts/new"}
mcp__playwright__browser_click {"element": "Save button", "ref": "[type='submit']"}
mcp__playwright__browser_snapshot {}

# Test invalid transaction data
mcp__playwright__browser_navigate {"url": "http://localhost:4000/transactions/new"}
mcp__playwright__browser_type {"element": "Quantity input", "ref": "#transaction_quantity", "text": "-1"}
mcp__playwright__browser_type {"element": "Price input", "ref": "#transaction_price", "text": "invalid"}
mcp__playwright__browser_click {"element": "Save button", "ref": "[type='submit']"}

mcp__playwright__browser_take_screenshot {"filename": "qa-07-error-handling.png"}
```

- 404 page displays for invalid routes
- Form validation prevents invalid submissions
- Error messages are user-friendly

### 8. Performance & Load Testing

Basic performance validation
Low

```
# Measure page load times
mcp__playwright__browser_evaluate {"function": "() => { return performance.getEntriesByType('navigation')[0].loadEventEnd - performance.getEntriesByType('navigation')[0].navigationStart; }"}

# Check for memory leaks by navigating multiple pages
mcp__playwright__browser_navigate {"url": "http://localhost:4000/"}
mcp__playwright__browser_navigate {"url": "http://localhost:4000/accounts"}
mcp__playwright__browser_navigate {"url": "http://localhost:4000/transactions"}
mcp__playwright__browser_navigate {"url": "http://localhost:4000/categories"}

# Check console for performance warnings
mcp__playwright__browser_console_messages {}

mcp__playwright__browser_take_screenshot {"filename": "qa-08-performance-test.png"}
```

- Page load times under 2 seconds
- No memory leak warnings
- Smooth navigation between pages

### 9. Database Integration Testing

Verify data persistence and integrity
High

```
# Create test data and verify persistence
mcp__playwright__browser_navigate {"url": "http://localhost:4000/accounts/new"}

# Create test account
mcp__playwright__browser_type {"element": "Account name input", "ref": "#account_name", "text": "Persistence Test Account"}
mcp__playwright__browser_select_option {"element": "Account type dropdown", "ref": "#account_account_type", "values": ["savings"]}
mcp__playwright__browser_click {"element": "Save button", "ref": "[type='submit']"}

# Navigate away and back to verify data persisted
mcp__playwright__browser_navigate {"url": "http://localhost:4000/"}
mcp__playwright__browser_navigate {"url": "http://localhost:4000/accounts"}

# Verify account still exists
mcp__playwright__browser_evaluate {"function": "() => { return document.body.textContent.includes('Persistence Test Account'); }"}

mcp__playwright__browser_take_screenshot {"filename": "qa-09-persistence-test.png"}
```

- Data persists across page reloads
- Database operations complete successfully
- No data corruption

### 10. Backwards Compatibility Verification

Ensure recent v0.2.1 changes don't break existing functionality
Critical

```
# Test existing transaction workflow (v0.1.0 functionality)
mcp__playwright__browser_navigate {"url": "http://localhost:4000/transactions"}
mcp__playwright__browser_snapshot {}

# Verify existing transactions are still accessible
mcp__playwright__browser_evaluate {"function": "() => { return document.querySelectorAll('[data-testid=\"transaction-row\"]').length; }"}

# Test existing account management
mcp__playwright__browser_navigate {"url": "http://localhost:4000/accounts"}
mcp__playwright__browser_evaluate {"function": "() => { return document.querySelectorAll('[data-testid=\"account-row\"]').length; }"}

# Test net worth calculation still works
mcp__playwright__browser_navigate {"url": "http://localhost:4000/"}
mcp__playwright__browser_evaluate {"function": "() => { const netWorth = document.querySelector('[data-testid=\"net-worth\"]'); return netWorth ? netWorth.textContent : 'Not found'; }"}

mcp__playwright__browser_take_screenshot {"filename": "qa-10-backwards-compatibility.png"}
```

- All v0.1.0 features continue to work
- No regression in existing functionality
- Data migration was successful

## Test Execution Checklist

- [ ] Server started and accessible
- [ ] Initial page load successful
- [ ] Navigation routes functional
- [ ] Account creation works
- [ ] Transaction creation works
- [ ] Dashboard calculations accurate
- [ ] Symbol autocomplete functional
- [ ] Error handling appropriate
- [ ] Performance acceptable
- [ ] Data persistence verified
- [ ] Backwards compatibility confirmed
- [ ] Screenshots captured for all scenarios
- [ ] Console errors reviewed

## Post-Test Actions

1.  Check all captured screenshots for visual regressions
2.  Review any JavaScript errors or warnings
3.  Validate page load times and memory usage
4.  Document any failures or issues found
5.  Remove any test data created during QA

## Integration with CI/CD

This script can be automated as part of the development workflow:

```bash
# Run QA testing after deployment
just server bg
sleep 5  # Wait for server startup
# Execute Playwright MCP commands
just server stop
```

## Notes

- All test scenarios should pass for a release to be considered ready
- Screenshots provide visual evidence of functionality
- Console message monitoring helps catch JavaScript errors
- Performance testing ensures application scalability
- Backwards compatibility testing is critical for user trust

This QA script ensures comprehensive testing of the Ashfolio application and provides confidence in the quality and reliability of the software.
