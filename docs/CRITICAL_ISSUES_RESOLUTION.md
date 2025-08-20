# Critical Issues Resolution Guide

## Financial Management v0.2.0 Implementation

**Document Version:** 1.0  
**Date:** August 10, 2025  
**Urgency:** HIGH - Blocking Issue Identified

## Executive Summary

The project architect has identified a **CRITICAL BLOCKING ISSUE** in the FinancialManagement v0.2.0 implementation that must be resolved immediately. The `TransactionCategory` resource is not registered in the `FinancialManagement` domain, breaking the cross-domain relationship with the `Transaction` resource.

**Impact:** This prevents the application from starting and blocks all testing of the new financial management features.

## Critical Issue - Domain Registration Missing

### Problem Description

The `Ashfolio.FinancialManagement` domain has an empty `resources` block at `/Users/matthewstaff/Projects/github.com/mdstaff/ashfolio/lib/ashfolio/financial_management.ex`:

```elixir
defmodule Ashfolio.FinancialManagement do
  use Ash.Domain

  resources do
    # Resources will be added as they are implemented  <-- EMPTY!
  end
end
```

However, the `TransactionCategory` resource exists and is properly configured, and the `Transaction` resource already references it:

```elixir
# In Transaction resource - this relationship will fail without domain registration
belongs_to :category, Ashfolio.FinancialManagement.TransactionCategory do
  allow_nil?(true)
  description("Optional category for investment organization")
end
```

### Root Cause

The `TransactionCategory` resource declares its domain correctly:

```elixir
use Ash.Resource, domain: Ashfolio.FinancialManagement
```

But the domain doesn't register the resource, creating a mismatch that prevents Ash from properly managing cross-domain relationships.

## Immediate Fix Required

### Step 1: Register TransactionCategory in FinancialManagement Domain

**File:** `/Users/matthewstaff/Projects/github.com/mdstaff/ashfolio/lib/ashfolio/financial_management.ex`

**Change Required:**

```elixir
defmodule Ashfolio.FinancialManagement do
  @moduledoc """
  FinancialManagement domain for Ashfolio.

  This domain handles comprehensive financial management features including:
  - Cash account balance management
  - Net worth calculations across investment and cash accounts
  - Transaction categorization for investments
  - Symbol search and autocomplete functionality
  """

  use Ash.Domain

  resources do
    resource(Ashfolio.FinancialManagement.TransactionCategory)
  end
end
```

### Step 2: Verify Cross-Domain Relationship

After the fix, verify the relationship works by running:

```bash
mix ash.codegen --domains Ashfolio.Portfolio,Ashfolio.FinancialManagement
```

This should complete without errors and recognize the cross-domain relationship.

### Step 3: Test Domain Registration

Run a quick test to ensure the domain is properly configured:

```elixir
# In IEx
Ashfolio.FinancialManagement.Info.resources()
# Should return: [Ashfolio.FinancialManagement.TransactionCategory]
```

## Additional Configuration Issues to Verify

### 1. Application Configuration (Medium Priority)

**Investigation Needed:** Check if `Ashfolio.FinancialManagement` needs to be registered in the application configuration.

**File to Check:** `/Users/matthewstaff/Projects/github.com/mdstaff/ashfolio/config/config.exs`

**Action:** Look for existing domain configurations and add `Ashfolio.FinancialManagement` if required by the Ash Framework setup.

### 2. PubSub Module Verification (Low Priority)

**Issue:** The `BalanceManager` module uses `Ashfolio.PubSub` but we should verify this module is properly configured.

**Current Usage in BalanceManager:**

```elixir
# Line 137 in balance_manager.ex
PubSub.broadcast("balance_changes", {:balance_updated, message})
```

**Verification Steps:**

1. Confirm `Ashfolio.PubSub` is started in `application.ex` ( Already verified - line 17)
2. Test PubSub functionality in BalanceManager tests
3. Ensure topic naming convention follows project standards

### 3. ETS State Management Review (Low Priority)

**Issue:** The `BalanceManager` uses ETS tables for balance history storage which may need review for production readiness.

**Current Implementation:**

```elixir
# Lines 152-170 in balance_manager.ex
defp balance_history_table do
  table_name = :balance_history

  case :ets.whereis(table_name) do
    :undefined ->
      try do
        :ets.new(table_name, [:named_table, :public, :bag])
      rescue
        ArgumentError ->
          table_name
      end
    _ ->
      table_name
  end

  table_name
end
```

**Considerations:**

- ETS data is not persisted across application restarts
- Consider if balance history should be stored in database for audit trails
- Current implementation is acceptable for v0.2.0 MVP

## Implementation Priority

### 🚨 IMMEDIATE (Must fix before any testing)

1. **Fix domain registration** - Register `TransactionCategory` in `FinancialManagement` domain
2. **Verify cross-domain relationship** - Ensure Transaction → TransactionCategory works

### 🟡 HIGH (Verify during current sprint)

3. **Application configuration check** - Ensure domain is properly configured in app config
4. **PubSub functionality test** - Verify BalanceManager PubSub integration works

### 🟢 MEDIUM (Address in next sprint)

5. **ETS storage review** - Consider database persistence for balance history

## Testing Checklist

After fixing the critical issue, verify these work correctly:

- [ ] Application starts without errors
- [ ] `mix ash.codegen` completes successfully
- [ ] Transaction can be created with category_id
- [ ] TransactionCategory CRUD operations work
- [ ] Cross-domain relationships load properly
- [ ] BalanceManager PubSub broadcasts function
- [ ] All existing tests continue to pass

## Team Coordination

### For the Development Team

1. **STOP** all work on FinancialManagement features until domain registration is fixed
2. **PRIORITY FIX** - One developer should immediately implement the domain registration fix
3. **TESTING** - After fix, run full test suite to ensure no regressions
4. **COORDINATION** - Notify the other agent working on BalanceManager tests that this fix is required first

### For the Agent Working on BalanceManager

- The BalanceManager implementation looks solid overall
- Tests can proceed after domain registration is fixed
- PubSub integration should be tested as part of your test suite
- ETS usage is acceptable for current MVP scope

## Success Criteria

The critical issue is resolved when:

1.  Application starts without domain-related errors
2.  `Ashfolio.FinancialManagement.Info.resources()` returns `[Ashfolio.FinancialManagement.TransactionCategory]`
3.  Cross-domain Transaction → TransactionCategory relationship works in tests
4.  All existing tests continue to pass (383/383)
5.  New FinancialManagement features can be tested and developed

## Architect Assessment Validation

**Original Rating:** 4.2/5 - Well-architected but needs configuration fixes  
**Post-Fix Expected Rating:** 4.8/5 - Production-ready with proper domain configuration

This confirms the architect's assessment was accurate - the implementation is well-designed but blocked by a critical configuration issue that prevents proper functionality.
