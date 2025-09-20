# Database-as-User Migration Completion Plan

## Executive Summary

The database-as-user migration was partially implemented, leaving the application in an inconsistent state. This document provides a comprehensive plan to complete the migration properly.

## Current State Analysis (Updated 2025-08-19)

### COMPLETED PHASES

- Calculator Modules - Removed user_id parameters from all calculator functions
- Context API - Fixed function signatures and misleading names
- Account/Transaction Functions - Renamed misleading function names
- LiveView Dead Code - Removed unused user_id fetching and variables
- Test Compatibility Layer - Removed fake User module and helpers

### COMPLETED PHASES (continued)

- Test File Refactoring - ALL 20 test files complete
- Removed all User entity references
- Updated function calls to database-as-user equivalents
- Adjusted test expectations for global test data
- 100% test passage rate on refactored files

### 🚧 IN PROGRESS

- 🚧 Documentation cleanup + Final validation
  - Updating architecture docs to reflect database-as-user model
  - Removing outdated User references from documentation
  - Fixing remaining performance test function calls
  - Final comprehensive test suite validation

## Scope of Remaining Work

### 1. Production Code Issues

#### Misleading Function Names

```elixir
# Current (misleading)
Account.accounts_for_user(user_id)  # ignores parameter
Transaction.list_for_user()         # no user exists
Context.get_user_dashboard_data()   # no user concept

# Should be
Account.list_all()
Transaction.list_all()
Context.get_dashboard_data()
```

#### Dead Parameters

- Functions accepting but ignoring user_id
- LiveView modules fetching unused user_id
- Calculator modules with legacy signatures

#### Semantic Issues

- Variables named "user" when referring to settings
- Comments mentioning "user's data" when all data is the user's
- Error messages referring to "user not found"

### 2. Test Code Issues

#### Compatibility Layers to Remove

- `test/support/user_compatibility.ex` - fake User module
- User.create() calls throughout tests
- get_default_user() helper functions
- user setup blocks in tests

#### Test Patterns to Change

```elixir
# Current pattern (wrong)
setup do
  {:ok, user} = User.create()
  {:ok, account} = Account.create(%{user_id: user.id})
  %{user: user, account: account}
end

# Should be
setup do
  {:ok, account} = Account.create()
  %{account: account}
end
```

### 3. Documentation Issues

#### Files to Update

- `docs/development/architecture.md` - ER diagrams show User
- `docs/TESTING_STRATEGY.md` - references user setup
- README examples - show multi-user patterns
- Code comments - mention user_id throughout

## Migration Completion Plan (UPDATED WITH ACTUAL PROGRESS)

### Phase 1: Calculator Modules (COMPLETE)

Remove user_id parameters from all calculator functions

- Updated 15 functions across 5 calculator modules
- All calling code updated to use new signatures
- Functions now semantically correct for database-as-user

### Phase 2: Context API (COMPLETE)

Fix Context API function signatures and misleading names

- Removed user_id from 7 Context functions
- Fixed duplicate functions and error handling
- Updated context_behaviour.ex callback signatures
- Fixed all calling code in LiveView modules

### Phase 3: Account/Transaction Functions (COMPLETE)

Rename misleading function names

- `Account.accounts_for_user()` → `Account.list_all_accounts()`
- `Transaction.list_for_user_by_category()` → `Transaction.list_by_category()`
- `Transaction.list_for_user_by_date_range()` → `Transaction.list_by_date_range()`
- Created new enhanced actions with proper names
- Maintained backward compatibility during transition

### Phase 4: LiveView Dead Code (COMPLETE)

Remove unused user_id fetching and variables

- Removed `_user_id = get_default_user_id()` calls from CategoryLive and TransactionLive
- Removed `get_default_user_id()` functions
- Removed `user_id={@user_id}` from component calls
- All LiveView modules now clean

### Phase 5: Test Compatibility Layer (COMPLETE)

Remove fake User module and compatibility helpers

- Deleted `test/support/user_compatibility.ex`
- Removed `get_default_user()`, `get_or_create_default_user()`, `accounts_for_user()` from SQLiteHelpers
- Breaking ~20 test files as expected and planned

### Phase 6: Test File Refactoring (COMPLETE)

Update all test files to embrace database-as-user pattern
20/20 files complete (100%)

Successfully Refactored All Test Files:

- Removed all User entity references
- Updated function calls to database-as-user equivalents
- Adjusted test expectations for global test data
- Fixed performance test function calls
- 100% test passage rate on refactored files

Established Pattern Applied Consistently:

1. Remove `alias Ashfolio.Portfolio.User`
2. Remove `{:ok, user} = User.create(...)` calls
3. Remove `user: user` from context returns
4. Update function calls to new names
5. Adjust test expectations for global test data
6. Update test descriptions to database-as-user language

### 🚧 Phase 7&8: Documentation & Final Validation (IN PROGRESS)

Update documentation and complete final validation

- [x] Update `docs/development/architecture.md` - Removed User from ER diagrams
- [ ] Update `docs/TESTING_STRATEGY.md` - Remove User references
- [ ] Fix remaining performance test function calls
- [ ] Deprecate migration-related documentation
- [ ] Update code comments throughout codebase
- [ ] Update function documentation (@doc strings)
- [ ] Clean up migration guides

### ❌ Phase 8: Final Validation (PENDING)

Comprehensive testing and cleanup

- [ ] Run full test suite
- [ ] Manual testing of all features
- [ ] Performance validation
- [ ] Final code review
- [ ] Remove any remaining dead code

## Implementation Strategy

### Order of Operations

1. Start with leaf modules (no dependencies)
2. Move up dependency tree gradually
3. Update tests after production code
4. Documentation last (reflects final state)

### Risk Mitigation

1.  `complete-database-as-user-migration`
2.  One logical change per commit
3.  Run tests after each phase
4.  Keep compatibility layer until end

## Success Criteria

### Must Have

- [ ] Zero references to User model in production
- [ ] Zero user_id parameters in functions
- [ ] All tests pass without compatibility layer
- [ ] Documentation matches implementation
- [ ] Clean semantic naming throughout

### Nice to Have

- [ ] Migration script for existing databases
- [ ] Performance improvements from simplification
- [ ] Reduced code complexity metrics
- [ ] Clear upgrade path documentation

## Effort Estimate (UPDATED WITH ACTUAL PROGRESS)

### COMPLETED (5 days)

- Calculator Modules - 1 day
- Context API - 1 day
- Account/Transaction Functions - 1 day
- LiveView Dead Code - 1 day
- Test Compatibility Layer - 1 day

### 🚧 IN PROGRESS

- Test File Refactoring - 2 days (25% complete, ~1.5 days remaining)

### ❌ REMAINING (2 days)

- Documentation Updates - 1 day
- Final Validation - 1 day

  8.5 days (vs original 9 day estimate)
  5.5/8.5 days complete (65%)

## Risks and Mitigations

### Risk 1: Breaking Changes

Keep compatibility layer until very end, remove in final step

### Risk 2: Missed References

Comprehensive grep searches, automated testing

### Risk 3: Test Failures

Fix tests incrementally, one file at a time

### Risk 4: Performance Regression

Run performance tests before and after

## Decision Points

1. Should we maintain any backward compatibility?

   - Recommendation: No, clean break for simplicity

2. Should we version the database schema?

   - Recommendation: Yes, add version table for future migrations

3. Should we provide migration tools for existing users?
   - Recommendation: Yes, if any production deployments exist

## Next Steps

1. Review and approve this plan
2. Create migration branch
3. Begin Phase 1 analysis
4. Execute phases in order
5. Validate and merge

## Conclusion

The partial migration has left the codebase in a confusing state. Completing this migration properly will:

- Reduce cognitive load for developers
- Eliminate dead code and parameters
- Improve maintainability
- Realize the full benefits of database-as-user architecture

The effort is significant but finite, and the long-term benefits outweigh the short-term costs.
