# E2E Testing Checklist - v0.5.0 Playwright Validation

## Pre-Test Setup
- [ ] Start Ashfolio: `just work`
- [ ] Confirm server running at http://localhost:4000
- [ ] Take initial screenshot for baseline
- [ ] Clear browser cache/cookies if needed

---

## ✅ Test 1: Dashboard & Core Navigation

### 1.1 Dashboard Load
- [ ] Navigate to http://localhost:4000
- [ ] Take screenshot of dashboard
- [ ] Verify page title contains "Dashboard"
- [ ] Check for 4 main widgets visible

### 1.2 Navigation Menu
- [ ] Click "Accounts" link → verify URL contains "/accounts"
- [ ] Click "Expenses" link → verify URL contains "/expenses" 
- [ ] Click "Goals" link → verify URL contains "/goals"
- [ ] Click "Money Ratios" link → verify URL contains "/money-ratios"
- [ ] Click "Tax Planning" or find tax features
- [ ] Return to dashboard via logo/home link

**Pass Criteria**: All navigation works, no 404 errors, dashboard widgets visible

---

## ✅ Test 2: Money Ratios Feature (v0.5.0 Core)

### 2.1 Initial Profile Creation
- [ ] Navigate to /money-ratios
- [ ] Take screenshot of empty state
- [ ] Verify "Create Financial Profile" form appears
- [ ] Fill form:
  - Gross Annual Income: 75000
  - Birth Year: 1985
  - Household Members: 1
  - Primary Residence Value: 300000
  - Mortgage Balance: 200000
- [ ] Click "Create Profile" button
- [ ] Verify success message appears

### 2.2 Ratios Display Validation
- [ ] Take screenshot of Overview tab with ratios
- [ ] Count visible ratio cards (should be 4+ ratios)
- [ ] Verify status icons appear (✅❌⚠️)
- [ ] Check for "Target:" text in ratio displays
- [ ] Verify age-appropriate benchmarks show

### 2.3 Tab Navigation
- [ ] Click "Capital Analysis" tab → verify content changes
- [ ] Click "Debt Management" tab → verify mortgage info
- [ ] Click "Financial Profile" tab → verify editable form
- [ ] Click "Action Plan" tab → verify recommendations
- [ ] Return to "Overview" tab

### 2.4 Dashboard Integration  
- [ ] Navigate back to dashboard (/)
- [ ] Scroll to find Money Ratios widget
- [ ] Take screenshot showing widget
- [ ] Click widget → verify navigates to /money-ratios

**Pass Criteria**: Profile creation works, all 5 tabs functional, ratios calculate, dashboard widget present

---

## ✅ Test 3: Portfolio Management

### 3.1 Account Creation
- [ ] Navigate to /accounts
- [ ] Click "New Account" or equivalent button
- [ ] Fill form: Name="Test Brokerage", Type="Investment"
- [ ] Save and verify account appears in list
- [ ] Take screenshot of accounts page

### 3.2 Transaction Entry
- [ ] Click into the test account
- [ ] Add buy transaction: 100 AAPL @ $150.00, date: 2024-01-01
- [ ] Verify transaction appears in list
- [ ] Add second transaction: 50 MSFT @ $300.00, date: 2024-02-01
- [ ] Take screenshot showing both transactions

### 3.3 Analytics Verification
- [ ] Navigate to /advanced_analytics or portfolio analytics
- [ ] Click "Calculate TWR" button if present
- [ ] Click "Calculate MWR" button if present  
- [ ] Verify performance metrics display
- [ ] Take screenshot of analytics page

**Pass Criteria**: Account creation works, transactions save correctly, analytics calculate

---

## ✅ Test 4: Financial Goals & Planning

### 4.1 Emergency Fund Goal
- [ ] Navigate to /goals
- [ ] Click "New Goal" button
- [ ] Select "Emergency Fund" if available as template
- [ ] Set target amount (should auto-calculate or manual entry)
- [ ] Set current saved: $2000
- [ ] Save goal and verify it appears

### 4.2 Retirement Planning
- [ ] Navigate to /retirement
- [ ] Verify retirement calculation appears
- [ ] Check for 25x expenses or similar calculation
- [ ] Test scenario inputs if available
- [ ] Take screenshot of retirement page

**Pass Criteria**: Goals creation works, retirement calculations display

---

## ✅ Test 5: Expense Tracking

### 5.1 Category Setup
- [ ] Navigate to /expenses
- [ ] Find and click "Categories" section
- [ ] Create category: "Housing"
- [ ] Create category: "Food"
- [ ] Verify categories saved

### 5.2 Expense Entry
- [ ] Navigate to main expenses page
- [ ] Add expense: $1200, Category="Housing", Description="Rent"
- [ ] Add expense: $400, Category="Food", Description="Groceries"
- [ ] Verify expenses appear in list
- [ ] Take screenshot showing expenses

### 5.3 Analytics Check
- [ ] Navigate to /expenses/analytics
- [ ] Verify charts render (pie chart, trend lines)
- [ ] Test date range filter if available
- [ ] Take screenshot of analytics

**Pass Criteria**: Expense entry works, categories function, analytics display

---

## ✅ Test 6: Tax Planning (v0.5.0 Feature)

### 6.1 Access Tax Features
- [ ] Navigate to tax planning section (find via menu/dashboard)
- [ ] Take screenshot of tax planning interface
- [ ] Verify capital gains calculations if visible

### 6.2 Test with Portfolio Data
- [ ] Ensure portfolio has some transactions from Test 3
- [ ] Add a sell transaction if possible: Sell 25 AAPL @ $180
- [ ] Navigate back to tax planning
- [ ] Verify gain/loss calculations update
- [ ] Check for FIFO cost basis methodology

**Pass Criteria**: Tax planning accessible, calculations work with portfolio data

---

## ✅ Test 7: Real-Time Updates & PubSub

### 7.1 Multi-Tab Testing
- [ ] Open dashboard in current tab
- [ ] Open new tab → navigate to /expenses  
- [ ] In expenses tab: add new expense
- [ ] Switch back to dashboard tab
- [ ] Verify expense widget updates automatically (may need refresh)
- [ ] Close extra tab

**Pass Criteria**: Dashboard reflects changes from other sections

---

## ✅ Test 8: Error Handling & Validation

### 8.1 Form Validation
- [ ] Navigate to /money-ratios profile form
- [ ] Try submitting with empty income field
- [ ] Verify error message appears
- [ ] Try negative income value
- [ ] Verify validation prevents submission

### 8.2 Navigation Edge Cases  
- [ ] Navigate to /invalid-route
- [ ] Verify proper 404 or error handling
- [ ] Navigate back to working page

**Pass Criteria**: Forms validate properly, error states handled gracefully

---

## ✅ Test 9: Mobile Responsiveness

### 9.1 Resize Testing
- [ ] Resize browser to mobile width (~375px)
- [ ] Navigate to dashboard → verify layout adapts
- [ ] Navigate to /money-ratios → verify tabs work on mobile
- [ ] Navigate to /expenses → verify forms usable
- [ ] Resize back to desktop width
- [ ] Verify everything still works

**Pass Criteria**: All major pages work on mobile viewport

---

## ✅ Test 10: Performance & Final Validation

### 10.1 Speed Testing
- [ ] Navigate between all major sections rapidly
- [ ] Time page load for dashboard (should be <2 seconds)
- [ ] Time Money Ratios calculation (should be <1 second)
- [ ] Note any slow operations

### 10.2 Final Screenshots
- [ ] Take final screenshot of dashboard with all data
- [ ] Take screenshot of Money Ratios overview
- [ ] Take screenshot of portfolio with transactions
- [ ] Document any issues found

**Pass Criteria**: All operations complete in reasonable time

---

## ✅ Post-Test Summary

### Final Checklist
- [ ] All 10 test sections completed
- [ ] Screenshots taken for key pages
- [ ] No critical errors encountered  
- [ ] v0.5.0 features (Money Ratios + Tax Planning) working
- [ ] Core portfolio/expense functionality verified
- [ ] Dashboard integration confirmed

### Success Metrics
- **Money Ratios**: Profile creation → calculation → dashboard widget ✅
- **Tax Planning**: Accessible and functional with portfolio data ✅  
- **Portfolio**: Account creation → transactions → analytics ✅
- **Expenses**: Categories → entry → analytics ✅
- **Goals**: Creation and tracking functional ✅
- **Navigation**: All major sections accessible ✅
- **Real-time**: Dashboard updates with changes ✅
- **Mobile**: Responsive design works ✅
- **Performance**: Sub-2 second page loads ✅

### Issue Reporting Template
```
❌ ISSUE: [Brief description]
Page: [URL where found]
Steps to reproduce: [1, 2, 3...]
Expected: [What should happen]
Actual: [What actually happened]
Screenshot: [If applicable]
```

**Total Expected Time**: 30-45 minutes for complete validation