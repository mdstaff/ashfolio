# IMPLEMENTATION_PLAN.md | v0.5.0 Refactoring Phase

## Overview

Post-credo cleanup refactoring to consolidate helper functions, eliminate duplicates, and improve API ergonomics across the codebase.

**Analysis Results**: ~2042 modules/functions analyzed
**Cleanup Potential**: ~2,052 LOC reduction across 28 modules
**Function Reduction**: ~242 functions can be eliminated/consolidated
**Quality Score**: 100/100 (0 credo issues, 0 dialyzer warnings)

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
- Safe conversion helpers
- Mathematical functions (power, nth_root, exp, ln)

**Deliverable**: `Ashfolio.Financial.DecimalHelpers` module with chainable operations
**Impact**: ~150-200 lines reduced, consistent precision handling
**Test cases**: Arithmetic operations, edge cases, type conversions

**Status**: Not Started

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