# Credo Issues

## Progress Summary

- **Original:** 62 issues  
- **Fixed:** 7 issues  
- **Remaining:** 55 issues  
- **Progress:** 11.3% complete  

## Issues by Complexity

EASY (Low Complexity) - 15 issues (6 completed ✅)

Simple structural improvements, minimal risk

Nesting Depth 3 (max 2) - LiveView Event Handlers (8 issues, 6 completed ✅)

- AshfolioWeb.ExpenseLive.Index.apply_sorting:707 ✅ COMPLETED
- AshfolioWeb.ExpenseLive.Import.handle_event:100 ✅ COMPLETED  
- AshfolioWeb.DashboardLive.handle_event:133 ✅ COMPLETED
- AshfolioWeb.CategoryLive.Index.handle_event:89 ✅ COMPLETED
- AshfolioWeb.AccountLive.Index.handle_event:140 ✅ COMPLETED
- AshfolioWeb.Components.SymbolAutocomplete.handle_event:241
- Ashfolio.Context.validate_account_name_uniqueness:554
- Ashfolio.Context.get_recent_transactions:203 ✅ COMPLETED

Pattern: Simple nested if/case statements that can be extracted to private functions

Low Complexity (10-11) - Simple Form Logic (7 issues)

- AshfolioWeb.ExpenseLive.FormComponent.update:188 (complexity 11)
- AshfolioWeb.ExpenseLive.FormComponent.validate_expense_form:372 (complexity 12)
- AshfolioWeb.AccountLive.BalanceUpdateComponent.parse_and_validate_balance:293 (complexity 10)
- Ashfolio.FinancialManagement.ContributionAnalyzer.build_timing_recommendation:948 (complexity 10)
- Ashfolio.FinancialManagement.FinancialGoal.setup_emergency_fund_goal!:270 (complexity 11)
- Ashfolio.FinancialManagement.FinancialGoal.analyze_emergency_fund_readiness!:313 (complexity 11)
- Ashfolio.FinancialManagement.TransactionFiltering.apply_category_filter:79 (complexity 13)

Pattern: Form validation and simple business logic with multiple conditional branches

---

MEDIUM (Moderate Complexity) - 23 issues (1 completed ✅)

Business logic that requires domain understanding

Nesting Depth 3-4 - Financial Calculations (8 issues)

- Ashfolio.Portfolio.PerformanceCalculator.calculate_rolling_returns:110 (depth 3)
- Ashfolio.Portfolio.HoldingsCalculator.calculate_cost_basis_from_transactions:326 (depth 3)
- Ashfolio.Portfolio.Calculator.calculate_position_summary:253 (depth 3)
- Ashfolio.Portfolio.CalculatorOptimized.calculate_position_summary:98 (depth 3)
- Ashfolio.Portfolio.CalculatorOptimized.get_all_holdings_optimized:40 (depth 3)
- Ashfolio.Portfolio.PerformanceCalculator.calculate_simple_irr:292 (depth 4)
- Ashfolio.Portfolio.HoldingsCalculator.get_symbol_transactions:365 (depth 4)
- Ashfolio.FinancialManagement.ContributionAnalyzer.calculate_success_probability:660 (depth 3)

Pattern: Financial algorithms with nested loops and conditional calculations

Medium Complexity (12-16) - Business Rules (7 issues, 1 completed ✅)

- AshfolioWeb.ExpenseLive.Import.handle_event:81 (complexity 10) ✅ COMPLETED
- AshfolioWeb.TransactionLive.Index.build_filter_active_string:507 (complexity 15)
- AshfolioWeb.FinancialGoalLive.Index.apply_sorting:714 (complexity 11)
- AshfolioWeb.ExpenseLive.FormComponent.handle_event:272 (complexity 11)
- Ashfolio.SQLiteHelpers.get_or_create_symbol:322 (complexity 16)
- Ashfolio.MarketData.PriceManager.fetch_individually_with_rate_limit:269 (depth 3)
- Mix.Tasks.CodeGps.analyze_dependencies:712 (depth 3)

Pattern: Complex filtering, sorting, and database operations with multiple conditions

Contribution Analyzer Functions (8 issues)

- Ashfolio.FinancialManagement.ContributionAnalyzer.calculate_contribution_variations:488 (depth 3)
- Ashfolio.FinancialManagement.ContributionAnalyzer.find_required_years:744 (depth 3)
- Ashfolio.FinancialManagement.ContributionAnalyzer.optimize_contribution_for_goal:207 (depth 4)
- Ashfolio.FinancialManagement.ContributionAnalyzer.binary_search_contribution:559 (depth 4)
- Ashfolio.FinancialManagement.FinancialGoal.setup_emergency_fund_goal!:292 (depth 4)
- Ashfolio.FinancialManagement.FinancialGoal.analyze_emergency_fund_readiness!:346 (depth 3)
- Ashfolio.FinancialManagement.CategorySeeder.create_or_find_categories:93 (depth 4)
- Ashfolio.FinancialManagement.TransactionFiltering.apply_category_filter:105 (depth 4)

Pattern: Complex financial planning algorithms with iterative calculations

---

HARD (High Complexity) - 14 issues

Critical business logic requiring significant architectural changes

Very High Complexity (20-26) - Core Business Logic (3 issues)

- Ashfolio.Portfolio.Transaction.validate_quantity_for_type:407 ⭐ HIGHEST (complexity 26)
- AshfolioWeb.AccountLive.FormComponent.generate_validation_messages:408 (complexity 22)
- AshfolioWeb.Components.ForecastChart.process_chart_data:616 (complexity 20)

Pattern: Core domain validation and data processing with extensive branching

Test Infrastructure (6 issues)

- Ashfolio.SQLiteHelpers.get_or_create_symbol:351 (depth 6) ⭐ DEEPEST NESTING
- Ashfolio.SQLiteConcurrencyHelpers.cleanup_test_data:133 (depth 5)
- Ashfolio.SQLiteHelpers.get_or_create_account:304 (depth 4)
- Ashfolio.SQLiteHelpers.create_common_symbols!:108 (depth 3)
- Ashfolio.ClearFailureFormatter.handle_cast:49 (complexity 11)
- Test.Performance.\* functions (complexity 10 each)

Pattern: Test setup utilities with complex database state management

Data Processing (5 issues)

- AshfolioWeb.Components.RealizedGainsChart.prepare_chart_data:204 (complexity 18)
- AshfolioWeb.Components.PortfolioAllocationChart.filter_chart_data:126 (complexity 17)
- AshfolioWeb.Components.NetWorthChart.calculate_running_balance:139 (complexity 16)
- AshfolioWeb.Components.ExpenseChart.process_expenses_for_chart:156 (complexity 15)
- AshfolioWeb.Components.PortfolioChart.filter_chart_data:137 (complexity 14)

Pattern: Chart data transformation with extensive conditional formatting

---

Ranking by Refactoring Complexity:

🟢 START HERE (Easy Wins) - 6/8 LiveView handlers completed ✅

1. LiveView event handlers - Simple extraction to private functions (6/8 completed)
2. Basic form validation logic - Extract validation rules

🟡 SECOND PHASE (Business Impact)

1. Financial calculation functions - Require domain expertise
2. ContributionAnalyzer functions - Complex but contained

🔴 ADVANCED (Architectural)

1. Transaction.validate_quantity_for_type - Core business rules
2. Chart data processing components - Complex transformations
3. Test infrastructure - System-wide impacts

⚪ LOWEST PRIORITY

- Performance test utilities - Non-production code
- Code GPS tasks - Development tooling

⏺ Progress Update:

**Excellent progress!** We've completed 7 out of 62 issues (11.3% complete):
- 6/8 LiveView event handlers completed ✅
- 1/7 medium complexity business rules completed ✅

Quick wins (15 easy issues) can be tackled with minimal risk, focusing on extracting nested logic into private functions.

The highest impact targets are:

- Transaction.validate_quantity_for_type (complexity 26) - critical validation logic
- Test helper functions (6 issues) - foundational infrastructure
- Chart processing functions (5 issues) - user-facing performance
