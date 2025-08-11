# URGENT: Domain Registration Fix Checklist

## Critical Blocking Issue - Immediate Action Required

**Time to Fix:** 2 minutes  
**Impact:** Prevents application startup and all FinancialManagement testing

## One-Line Summary
The `FinancialManagement` domain needs to register the `TransactionCategory` resource to enable cross-domain relationships.

## Quick Fix Steps

### Step 1: Edit Domain File (30 seconds)
**File:** `/Users/matthewstaff/Projects/github.com/mdstaff/ashfolio/lib/ashfolio/financial_management.ex`

**Replace this:**
```elixir
  resources do
    # Resources will be added as they are implemented
  end
```

**With this:**
```elixir
  resources do
    resource(Ashfolio.FinancialManagement.TransactionCategory)
  end
```

### Step 2: Verify Fix (30 seconds)
```bash
# Run this to verify domain registration works
mix ash.codegen --domains Ashfolio.Portfolio,Ashfolio.FinancialManagement
```

Should complete without errors.

### Step 3: Test Application Start (30 seconds)
```bash
# Verify app starts without domain errors
mix compile && iex -S mix
```

### Step 4: Quick Domain Verification (30 seconds)
In IEx:
```elixir
Ashfolio.FinancialManagement.Info.resources()
# Should return: [Ashfolio.FinancialManagement.TransactionCategory]
```

## Success Indicators
- ✅ No compilation errors
- ✅ Application starts successfully
- ✅ Domain returns registered resources
- ✅ Cross-domain relationship works

## After Fix
1. Run full test suite: `mix test`
2. Notify team that FinancialManagement work can resume
3. Continue with BalanceManager testing as planned

**For detailed analysis and additional issues, see:** `/Users/matthewstaff/Projects/github.com/mdstaff/ashfolio/docs/CRITICAL_ISSUES_RESOLUTION.md`