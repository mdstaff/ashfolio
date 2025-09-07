# IMPLEMENTATION_PLAN.md | v0.5.0 Refactoring Phase

## Overview

Post-credo cleanup refactoring to consolidate helper functions, eliminate duplicates, and improve API ergonomics across the codebase.

**Analysis Results**: 2,110 modules/functions analyzed (219 modules: 101 lib + 118 test)
**Cleanup Potential**: ~300 function reduction achievable through consolidation  
**Function Reduction**: Target ~14% decrease from current levels
**Quality Score**: 85/100 (9 credo issues, 0 dialyzer warnings)

---

## Stage 1: Financial Formatters Consolidation

**Objective**: Eliminate 4 duplicate formatting implementations and create unified formatting API

**Files to consolidate**:
- `lib/ashfolio_web/helpers/format_helper.ex` (primary)
- `lib/ashfolio_web/live/format_helpers.ex` (duplicate logic)
- `lib/ashfolio_web/helpers/chart_helpers.ex` (chart formatting)
- `lib/ashfolio_web/components/transaction_stats.ex` (component-local)

**Deliverable**: Single `Ashfolio.Financial.Formatters` module
**Impact**: ~200-300 lines eliminated, single import across codebase
**Test cases**: Currency formatting, percentage display, chart axis labels

**Status**: ✅ Complete

---

## Stage 2: Decimal Helper Utilities

**Objective**: Reduce repetitive Decimal operations across 47+ files

**Target patterns**:
- `Decimal.add/sub/mult/div` operations 
- Safe conversion helpers (ensure_decimal, to_percentage, monthly_to_annual)
- Mathematical functions (safe_power, safe_nth_root, compound interest)
- Sign checking helpers (positive?, negative?, zero?)

**Deliverable**: `Ashfolio.Financial.DecimalHelpers` module with chainable operations
**Impact**: 22 helper functions created, 45 comprehensive tests, enhanced precision handling
**Test cases**: ✅ Arithmetic operations, edge cases, type conversions (45 tests passing)

**Files Refactored**:
- ✅ `lib/ashfolio/financial_management/forecast_calculator.ex` - DecimalHelpers integration complete
- ✅ `lib/ashfolio/financial_management/contribution_analyzer.ex` - DecimalHelpers integration complete  
- 🔄 `lib/ashfolio/financial_management/retirement_calculator.ex` - In progress

**Status**: ⚠️ Partially Complete - Helper created but need to REMOVE duplicates, not just add helpers

**⚠️ Critical Issue**: Function count increased from 2,072 to 2,110 despite refactoring
**Root Cause**: Adding helpers without removing duplicate code  
**Next Actions**: 
1. Continue RetirementCalculator refactoring
2. **DELETE** redundant format modules (format_helpers.ex, format_helper.ex)
3. Focus on ELIMINATION, not just consolidation

---

## Stage 2.5: High-Impact Module Refactoring (PRIORITY)

**Objective**: Refactor the largest, most complex modules identified by Code GPS analysis

**Target modules** (Top complexity offenders):
- ✅ `lib/ashfolio_web/components/forecast_chart.ex` - 72→64 functions (extracted ChartData + ChartGeometry modules)
- ✅ `lib/ashfolio/error_handler.ex` - 71→<30 functions (extracted ErrorCategorizer + ErrorFormatter modules)  
- `lib/mix/tasks/code_gps.ex` - 68 functions (tool needs splitting)
- `lib/ashfolio_web/live/dashboard_live.ex` - 61 functions (extract patterns)
- `lib/ashfolio/financial_management/contribution_analyzer.ex` - 58 functions (domain splitting)

**Completed Refactorings**:
1. **ForecastChart** (72→64 functions): Extracted data processing to `ChartData` (17 functions) and geometry calculations to `ChartGeometry` (11 functions)
2. **ErrorHandler** (71→<30 functions): Extracted domain categorization to `ErrorCategorizer` (20+ functions) and message formatting to `ErrorFormatter` (25+ functions)

**Deliverable**: Split oversized modules, extract shared patterns  
**Impact**: ~17 functions reduced so far, targeting 150-200 total function reduction
**Priority**: HIGH - These modules represent 25% of total complexity

**Current Function Count**: 1,597 (down from 1,606, targeting <1,800)

**Status**: ⚠️ In Progress - 2 of 5 modules completed

---

## Stage 3: Data Transformation Utilities  

**Objective**: Standardize common list processing patterns in LiveViews

**Target patterns**:
- Account/transaction grouping logic
- Sorting and filtering operations
- Date/period calculations

**Deliverable**: `Ashfolio.DataHelpers` module with generic transformations
**Impact**: ~100-150 lines consolidated, consistent data processing
**Test cases**: Grouping operations, sorting, date range filtering

**Status**: Not Started

---

## Stage 4: Form Helper Consolidation

**Objective**: Reduce repetitive form handling across 8+ components

**Target patterns**:
- Decimal parsing in forms
- Changeset error handling
- Form validation workflows

**Deliverable**: `AshfolioWeb.FormHelpers` module
**Impact**: Improved form consistency, reduced boilerplate
**Test cases**: Decimal parsing, error display, validation chains

**Status**: Not Started

---

## Stage 5: Mathematical Operations Module

**Objective**: Consolidate duplicate math functions from multiple calculators

**Files with duplicates**:
- `lib/ashfolio/financial_management/aer_calculator.ex` (lines 279-311)  
- `lib/ashfolio_web/helpers/chart_helpers.ex` (lines 156-192)
- `lib/ashfolio/financial_management/forecast_calculator.ex`

**Deliverable**: `Ashfolio.Mathematical` module with precise operations
**Impact**: Single source of truth for financial math, consistent precision
**Test cases**: Power/root calculations, compound interest, edge cases

**Status**: Not Started

---

## Current Metrics (Code GPS Analysis)

**Module Distribution**:
- Total modules: 219 (101 lib + 118 test)  
- Total functions: 1,628 (1,577 lib + 51 test helper functions)
- Test coverage: 1,486 test functions across 117 test modules
- Complex modules (>30 functions): 16 modules

**Top Refactoring Targets**:
1. ForecastChart: 72 functions
2. ErrorHandler: 71 functions  
3. CodeGps: 69 functions
4. DashboardLive: 61 functions
5. ContributionAnalyzer: 58 functions

**Function Count Trajectory**:
- v0.4.x baseline: ~2,072 functions
- Current (Stage 2 partial): 2,110 functions (+38)
- Target (v0.5.0 complete): 1,800 functions (-310 from current)

**Key Insight**: We must REMOVE duplicate code, not just add helpers