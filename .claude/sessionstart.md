# Ashfolio SessionStart - v0.5.0

## Essential Context

**Stack**: Phoenix LiveView + Ash 3.4 + SQLite  
**Pattern**: Database-as-user (no user_id fields)  
**Status**: 1,680 tests passing, production-ready financial platform  
**Focus**: Maintaining v0.5.0 excellence, considering v0.6.0 features  

## Quick Commands

```bash
mix code_gps        # ALWAYS start here
just test           # Run standard tests
just test unit      # <1s TDD cycle  
just test smoke     # <2s critical paths
just dev            # Start server (localhost:4000)
just check          # Format + compile + credo + smoke
just fix            # Auto-repair common issues
```

## Critical Rules

**HEEx Templates**: NEVER use local variables, ALWAYS use `@assigns`
**Financial Data**: MUST use Decimal type, never Float
**Performance**: <100ms portfolio calculations, <500ms dashboard
**Testing**: Include market crash/edge case scenarios for financial features

## Key Files
- `.code-gps.yaml` - Current architecture
- `docs/TESTING_STRATEGY.md` - Test organization  
- `justfile` - Available commands
- `.claude/financial-rules.md` - Specialized financial development rules

## Domains

**Portfolio**: Account, Symbol, Transaction, Position (FIFO cost basis)  
**FinancialManagement**: Expense, MoneyRatios, TaxStrategy, Categories

## Completed Features (v0.5.0)
- Money Ratios assessment (Charles Farrell methodology)
- Tax planning with FIFO calculations  
- Retirement planning (25x rule, 4% withdrawal)
- Expense analytics with advanced filtering
- Portfolio performance (TWR/MWR calculations)
- Real-time dashboard with PubSub updates

## Emergency Fixes
- `mix deps.get && mix compile` - undefined function
- `just db test-reset` - test DB locked
- `just fix` - mass test failures
- Check `@assigns` usage - template warnings