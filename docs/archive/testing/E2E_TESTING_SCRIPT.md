# E2E Testing Script - v0.5.0 Complete Feature Validation

## Overview
End-to-end testing script for validating the complete v0.5.0 feature set using Playwright MCP tool. Tests all major user workflows across portfolio management, expense tracking, financial planning, tax planning, and Money Ratios assessment.

## Prerequisites
- Ashfolio running locally (`just work`)
- Playwright MCP tool available
- Fresh database state (or known test data)

## Test Scenarios

### 1. Dashboard & Navigation Validation
**Objective**: Verify main dashboard loads and all navigation works

```
1. Navigate to http://localhost:4000
2. Verify dashboard displays:
   - Net worth widget (should show current total)
   - Expense summary widget
   - Financial goals widget
   - Money ratios widget (new in v0.5.0)
3. Test navigation to all main sections:
   - Click "Accounts" - should load account management
   - Click "Expenses" - should load expense tracking
   - Click "Goals" - should load financial goals
   - Click "Money Ratios" - should load new ratios page
   - Click "Tax Planning" - should load tax planning tools
```

### 2. Portfolio Management Workflow
**Objective**: Complete portfolio setup and transaction management

```
1. Navigate to /accounts
2. Create investment account:
   - Click "New Account"
   - Enter: Name="Test Brokerage", Type="Investment", Institution="Test Broker"
   - Save and verify account appears
3. Add holdings:
   - Click into account
   - Add transaction: Buy 100 shares AAPL at $150.00 on 2024-01-01
   - Add transaction: Buy 50 shares MSFT at $300.00 on 2024-01-15
   - Verify transactions appear with correct cost basis
4. Test portfolio analytics:
   - Navigate to /advanced_analytics
   - Click "Calculate TWR" - should show performance metrics
   - Click "Calculate MWR" - should show return calculations
   - Verify charts render properly
```

### 3. Expense Tracking & Analytics
**Objective**: Validate complete expense management workflow

```
1. Navigate to /expenses
2. Create expense categories:
   - Click "Categories" → "New Category"
   - Create: "Housing", "Transportation", "Food"
3. Add sample expenses:
   - Add expense: $1200 Housing "Rent" on current month
   - Add expense: $300 Transportation "Gas" on current month
   - Add expense: $400 Food "Groceries" on current month
4. Verify analytics:
   - Navigate to /expenses/analytics
   - Check monthly breakdown chart appears
   - Verify category distribution pie chart
   - Test date range filtering
```

### 4. Financial Goals & Planning
**Objective**: Test complete goal-setting and retirement planning

```
1. Navigate to /goals
2. Create emergency fund goal:
   - Click "New Goal"
   - Select "Emergency Fund" template
   - Should auto-calculate 3-6 months of expenses
   - Set current saved amount: $2000
   - Save and verify progress calculation
3. Create custom retirement goal:
   - Click "New Goal" → "Custom"
   - Enter: $1,000,000 retirement target
   - Set timeline and contribution amount
   - Verify progress tracking works
4. Test retirement planning:
   - Navigate to /retirement
   - Verify 25x expenses calculation displays
   - Test scenario modeling with different contribution rates
   - Check interactive charts render
```

### 5. Money Ratios Assessment (v0.5.0 NEW)
**Objective**: Complete Money Ratios workflow validation

```
1. Navigate to /money-ratios
2. Create financial profile:
   - Should show "Create Financial Profile" form
   - Enter: Gross Income=$75000, Birth Year=1985, Household=1
   - Add: Home Value=$300000, Mortgage=$200000
   - Save profile
3. Verify ratio calculations:
   - Check Overview tab shows all 8 ratios
   - Verify status indicators (✅❌⚠️) appear
   - Check age-appropriate benchmarks display
4. Test all tabs:
   - Capital Analysis: Should show detailed capital ratio
   - Debt Management: Should show mortgage/education analysis
   - Financial Profile: Should show editable form
   - Action Plan: Should show personalized recommendations
5. Test dashboard integration:
   - Return to dashboard (/)
   - Verify Money Ratios widget appears
   - Should show financial health status
   - Click widget should navigate to /money-ratios
```

### 6. Tax Planning Tools (v0.5.0 NEW)
**Objective**: Validate tax planning and capital gains features

```
1. Ensure test portfolio has some gains/losses:
   - Navigate to /accounts
   - Add sell transaction: Sell 50 AAPL shares at $180 (gain)
   - Add sell transaction if possible (or verify existing data)
2. Navigate to tax planning:
   - Should be accessible via dashboard or navigation
   - Verify capital gains calculations appear
   - Check short-term vs long-term classification
   - Test tax-loss harvesting recommendations if available
3. Verify FIFO calculations:
   - Check that cost basis uses FIFO methodology
   - Verify gain/loss calculations are accurate
```

### 7. Data Import & Export
**Objective**: Test CSV import functionality

```
1. Navigate to /expenses/import
2. Test CSV import:
   - Upload sample CSV file (create if needed)
   - Verify validation and preview
   - Complete import and check data appears
3. Navigate to /accounts (portfolio import)
4. Test portfolio import:
   - Upload holdings CSV if available
   - Verify import process completes
   - Check imported data accuracy
```

### 8. Error Handling & Edge Cases
**Objective**: Validate error states and edge case handling

```
1. Test form validation:
   - Try creating account with empty name
   - Try invalid amounts in expense forms
   - Verify error messages appear appropriately
2. Test navigation edge cases:
   - Direct navigation to /money-ratios without profile
   - Navigate to non-existent routes
   - Verify proper error handling
3. Test data edge cases:
   - Zero amounts in calculations
   - Future dates in transactions
   - Very large numbers in inputs
```

### 9. Real-Time Features & PubSub
**Objective**: Validate live updates across the application

```
1. Open dashboard in one browser tab
2. Open specific feature (e.g., /expenses) in another tab
3. Make changes in feature tab:
   - Add new expense
   - Update financial goal
   - Modify portfolio holding
4. Switch back to dashboard:
   - Verify widgets update automatically
   - Check that changes reflect immediately
   - Test live calculation updates
```

### 10. Performance & Responsiveness
**Objective**: Validate application performance

```
1. Test large dataset handling:
   - Add multiple years of expenses
   - Create multiple portfolio accounts
   - Verify page load times remain reasonable
2. Test mobile responsiveness:
   - Resize browser to mobile width
   - Verify all pages remain functional
   - Check that charts and tables adapt properly
3. Test calculation performance:
   - Trigger complex calculations (analytics, ratios)
   - Verify results appear within reasonable time
   - Check for any UI freezing or delays
```

## Expected Outcomes

### Success Criteria
- ✅ All navigation works without errors
- ✅ Forms validate and save properly
- ✅ Calculations produce accurate results
- ✅ Charts and visualizations render correctly
- ✅ Real-time updates work across tabs
- ✅ Money Ratios feature fully functional
- ✅ Tax planning calculations accurate
- ✅ Mobile responsive design works
- ✅ Error handling provides clear feedback
- ✅ Performance remains sub-second for most operations

### Known Limitations to Document
- Manual price entry (no live market data)
- Single-user design (expected)
- SQLite local storage (by design)
- Limited asset types (planned for v0.6.0)

## Test Data Suggestions

### Sample Portfolio Data
```
Account: "Main Brokerage" (Investment)
- AAPL: 100 shares @ $150 (Jan 1, 2024)
- MSFT: 50 shares @ $300 (Jan 15, 2024)
- GOOGL: 25 shares @ $120 (Feb 1, 2024)
```

### Sample Expense Data
```
Monthly expenses for ratio calculations:
- Housing: $1500/month
- Transportation: $400/month
- Food: $600/month
- Utilities: $200/month
- Insurance: $300/month
Total: ~$3000/month = $36000/year
```

### Sample Financial Profile
```
- Gross Annual Income: $75,000
- Birth Year: 1985 (39 years old)
- Home Value: $300,000
- Mortgage Balance: $200,000
- Net Worth: ~$150,000 (for ratio calculations)
```

## Notes for Tester
- Take screenshots of any errors or unexpected behavior
- Note performance issues or slow loading times
- Document any UX improvements or confusing workflows
- Verify all new v0.5.0 features work end-to-end
- Test with both empty state and populated data scenarios

This comprehensive E2E test validates the complete v0.5.0 feature set and ensures all user workflows function properly.