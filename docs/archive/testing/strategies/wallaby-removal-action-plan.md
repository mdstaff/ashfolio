# Wallaby Removal - Immediate Action Plan

2025-08-11
Claude (Architect)
ADR-003 (Browser Testing Strategy), RFC-001 (Dependency Governance)

## Executive Summary

Based on ADR-003, we are removing Wallaby from the project to align with local-first architecture principles. This document outlines the immediate actions needed to clean up the Wallaby implementation and strengthen our LiveView-based testing approach.

## Current State Analysis

### What Exists

- `{:wallaby, "~> 0.30", only: :test}` in mix.exs dependencies
- `test/ashfolio_web/browser/symbol_autocomplete_browser_test.exs` with disabled test cases
- Wallaby fails to start due to missing Chrome/ChromeDriver system dependencies
- Comprehensive LiveView tests already exist in `symbol_autocomplete_ui_test.exs`

### Impact Assessment

- Low - Wallaby tests are disabled and not contributing to CI/CD
- Low - Single dependency removal with minimal code cleanup
- No reduction - LiveView tests provide comprehensive coverage

## Immediate Actions (Priority Order)

### 1. Remove Wallaby Dependency

Immediate
None - dependency not functional

```bash
# Edit mix.exs to remove wallaby line
# Run mix deps.clean wallaby --build
# Run mix deps.get to update lock file
```

- `/Users/matthewstaff/Projects/github.com/mdstaff/ashfolio/mix.exs` (remove line 77)

### 2. Remove Browser Test Directory

Immediate
None - contains only disabled tests

```bash
# Remove entire browser test directory
rm -rf test/ashfolio_web/browser/
```

- `/Users/matthewstaff/Projects/github.com/mdstaff/ashfolio/test/ashfolio_web/browser/symbol_autocomplete_browser_test.exs`

### 3. Update Test Configuration

Immediate
None - removing unused test tags

- `test/test_helper.exs` - Remove any Wallaby-specific configuration
- `config/test.exs` - Remove any Wallaby-specific settings

### 4. Verify Test Suite

Immediate
Low - ensure no broken references

```bash
# Run full test suite to verify no issues
mix test
# Specifically run UI tests to ensure coverage
mix test test/ashfolio_web/components/symbol_autocomplete_ui_test.exs
```

### 5. Update Documentation

Same day
None - documentation update

- Update any testing documentation to reflect browser testing decision
- Ensure manual testing guidelines are in place

## Detailed Implementation Steps

### Step 1: Remove Wallaby from mix.exs

```elixir
{:wallaby, "~> 0.30", only: :test}
```

Delete this line entirely

### Step 2: Clean Up Dependencies

```bash
cd /Users/matthewstaff/Projects/github.com/mdstaff/ashfolio
mix deps.clean wallaby --build
mix deps.get
```

### Step 3: Remove Browser Test File

```bash
rm -rf test/ashfolio_web/browser/
```

### Step 4: Verify No Wallaby References

```bash
# Search for any remaining Wallaby references
grep -r "wallaby\|Wallaby" . --exclude-dir=_build --exclude-dir=deps
# Search for any browser test tags
grep -r "@moduletag :browser" test/
```

### Step 5: Run Test Suite Verification

```bash
# Full test suite
mix test
# Check for any :browser tagged tests
mix test --only browser
# Verify UI tests still work
mix test test/ashfolio_web/components/symbol_autocomplete_ui_test.exs
```

## Verification Checklist

- [ ] Wallaby dependency removed from mix.exs
- [ ] `mix deps.get` runs without errors
- [ ] Browser test directory removed
- [ ] No remaining Wallaby references in codebase
- [ ] Full test suite passes
- [ ] No `:browser` tagged tests remain
- [ ] SymbolAutocomplete UI tests still pass
- [ ] No compilation warnings related to Wallaby

## Testing Strategy Post-Removal

### Primary: Enhanced LiveView Tests

The existing `symbol_autocomplete_ui_test.exs` provides:

- Component rendering verification
- Event handler testing
- Accessibility attribute validation
- Error handling scenarios
- Keyboard navigation server-side logic

### Secondary: Manual Testing Guidelines

Create checklist for JavaScript functionality:

- Keyboard navigation (arrows, enter, escape, tab)
- Click-outside-to-close behavior
- Mobile responsiveness and touch interactions
- Dropdown positioning and visual transitions
- Screen reader compatibility

### Documentation: Test Case References

Document the disabled browser test cases as manual test scenarios:

- Convert commented test cases to manual testing checklist
- Include in component documentation
- Add to PR review template

## Risk Mitigation

### Potential Issues

1.  Other components might reference Wallaby
2.  Wallaby config might be in multiple files
3.  Build scripts might reference browser tests

### Mitigation Steps

1.  Grep entire codebase for Wallaby references
2.  Verify complete test suite after removal
3.  Check all test-related documentation

### Rollback Plan

If issues arise:

1.  Simple revert of dependency removal commit
2.  Add Wallaby back with version pin
3.  Restore browser test directory from git history

## Success Criteria

### Technical Success

- [ ] Mix compilation succeeds without Wallaby
- [ ] All existing tests continue to pass
- [ ] No dependency conflicts introduced
- [ ] Clean `mix deps.tree` output

### Process Success

- [ ] ADR-003 implementation completed
- [ ] Dependency governance process followed
- [ ] Documentation updated appropriately
- [ ] Manual testing procedures established

## Timeline

- Remove Wallaby dependency and browser tests
- Verify test suite passes
- Update documentation references

- Create manual testing checklist
- Update any related documentation
- Communicate change to team/stakeholders

- Integrate manual testing into PR review process
- Monitor for any issues or missing test coverage
- Complete documentation of new testing approach

## Communication

### Stakeholders to Notify

- Development team
- QA/Testing team (if separate)
- Any external contributors

### Key Messages

1.  Decision supports local-first principles
2.  JavaScript behavior remains unchanged
3.  Simpler setup, faster tests
4.  Better LiveView test coverage

### Follow-up Items

- Monitor for any user-reported issues that manual testing missed
- Evaluate testing strategy effectiveness after 1 month
- Consider tooling improvements for manual testing workflow

---

Ready for Implementation
Development Team
ADR-003 provides full architectural justification
