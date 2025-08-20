# ADR-003: Browser Testing Strategy

Proposed
2025-08-11
Claude (Architect)

## Context

The SymbolAutocomplete component includes JavaScript functionality for keyboard navigation, mobile responsiveness, and accessibility features that require browser-based testing. Currently, Wallaby is included in mix.exs but fails to run due to missing system dependencies (Chrome/ChromeDriver).

### Current Situation

1.  Added to mix.exs (`{:wallaby, "~> 0.30", only: :test}`)
2.  Created at `test/ashfolio_web/browser/symbol_autocomplete_browser_test.exs`
3.  Wallaby requires Chrome/ChromeDriver installation
4.  Mostly disabled test cases with basic Wallaby session test
5.  Comprehensive LiveView-based UI tests exist in `symbol_autocomplete_ui_test.exs`

### JavaScript Functionality Requiring Testing

The SymbolAutocomplete JavaScript hook provides:

- Keyboard navigation (arrow keys, enter, escape, tab)
- Click-outside-to-close behavior
- Dropdown positioning and responsive behavior
- Touch interaction support
- Focus management and accessibility

## Decision

**REMOVE Wallaby and adopt LiveView-First Testing Strategy**

## Rationale

### Why Remove Wallaby

1. **System Dependency Complexity**

   - Requires Chrome/ChromeDriver installation on all development machines
   - Adds CI/CD pipeline complexity and maintenance overhead
   - Creates development environment setup friction
   - Not aligned with "local-first, zero-configuration" project philosophy

2. **Limited Value for Current JavaScript**

   - SymbolAutocomplete JavaScript is primarily UI enhancement, not core functionality
   - Dropdown behavior and keyboard navigation can be adequately tested through LiveView tests
   - Most functionality is server-side with JavaScript providing UX improvements

3. **Existing Test Coverage**

   - Comprehensive LiveView tests already exist (`symbol_autocomplete_ui_test.exs`)
   - Tests cover component rendering, event handling, and accessibility attributes
   - Manual testing can verify JavaScript behavior during development

4. **Development Philosophy Alignment**
   - Local-first approach prioritizes simplicity and minimal dependencies
   - SQLite + Phoenix LiveView architecture reduces need for heavy browser testing
   - Focus on server-side functionality with progressive JavaScript enhancement

### LiveView-First Testing Strategy

1. **Server-Side Testing Priority**

   - Use Phoenix LiveViewTest for all component interactions
   - Test event handling, state changes, and template rendering
   - Verify accessibility attributes and ARIA compliance

2. **JavaScript as Progressive Enhancement**

   - Treat JavaScript functionality as UX improvements, not core features
   - Ensure component works without JavaScript enabled
   - Use manual testing for JavaScript-specific behavior verification

3. **Manual Testing Guidelines**
   - Document manual test cases for JavaScript functionality
   - Include keyboard navigation and mobile responsiveness in review checklist
   - Use browser dev tools for accessibility auditing

## Implementation

### Immediate Actions

1. **Remove Wallaby Dependency**

   - Remove `{:wallaby, "~> 0.30", only: :test}` from mix.exs
   - Delete `test/ashfolio_web/browser/` directory
   - Update test suite to exclude `:browser` tagged tests

2. **Enhance Existing LiveView Tests**

   - Ensure comprehensive coverage in `symbol_autocomplete_ui_test.exs`
   - Add tests for all event handlers and state transitions
   - Verify accessibility attribute presence and correctness

3. **Create Manual Testing Guide**
   - Document JavaScript behavior test cases
   - Include keyboard navigation test scenarios
   - Add mobile responsiveness verification steps

### Future Considerations

**When to Reconsider Browser Testing:**

- Complex multi-step user flows requiring JavaScript coordination
- Heavy client-side state management or SPA-like behavior
- JavaScript-dependent features critical to core functionality
- User-reported issues that manual testing cannot reliably catch

**Alternative Tools to Evaluate:**

- Lighter alternative to Wallaby
- Test JavaScript through LiveView events
- Modern browser automation if needed

## Testing Strategy

### Primary: LiveView Tests

```elixir
# Test component rendering and event handling
test "keyboard navigation events are properly handled" do
  {:ok, view, html} = live(conn, "/test")
  assert has_element?(view, "[phx-keydown='keydown']")
  assert render_keydown(view, "ArrowDown") # Test server-side handling
end
```

### Secondary: Manual Testing

```markdown
## Manual JavaScript Test Cases

1. Keyboard Navigation
   - Arrow keys move focus between options
   - Enter selects highlighted option
   - Escape closes dropdown
2. Mobile Responsiveness
   - Touch interactions work on mobile devices
   - Dropdown adapts to screen size
   - Focus management works with virtual keyboards
```

### Documentation: Component Behavior

- Document expected JavaScript behavior in component modules
- Include accessibility requirements and ARIA patterns
- Provide troubleshooting guide for JavaScript issues

## Consequences

### Positive

- No system dependencies or setup complexity
- No browser automation overhead in test pipeline
- Fewer dependencies to maintain and update
- Supports local-first, minimal dependency approach
- Prioritizes server-side functionality over client-side polish

### Negative

- Cannot automatically test complex client-side interactions
- Requires disciplined manual testing for JavaScript behavior
- JavaScript bugs may not be caught automatically

### Mitigation Strategies

- Implement comprehensive manual testing checklist
- Use TypeScript for JavaScript code to catch errors at compile time
- Design JavaScript as progressive enhancement, not core dependency
- Regular accessibility auditing using browser dev tools

## Alternatives Considered

### 1. Keep Wallaby with Setup Documentation

Comprehensive browser testing capability
Setup complexity, maintenance overhead, CI/CD complications
Rejected due to philosophy mismatch

### 2. Use Hound Instead of Wallaby

Lighter alternative, fewer dependencies
Still requires browser installation, adds complexity
Rejected for same philosophical reasons

### 3. Phoenix LiveViewTest + JavaScript Events

Leverages existing Phoenix testing tools
Limited to server-side event simulation
Partially adopted as primary strategy

### 4. No JavaScript Testing

Simplest approach, fastest development
Zero coverage of client-side behavior
Rejected as too minimal

## Success Metrics

- Reduced setup time for new developers
- Faster test suite execution without browser startup overhead
- Fewer flaky tests and dependency updates
- Maintain quality through manual testing discipline
- Verify ARIA attributes through LiveView tests

## Review and Update

This decision should be revisited when:

- JavaScript complexity significantly increases
- User-reported issues indicate need for automated browser testing
- Team size grows and manual testing becomes unsustainable
- New tools emerge that better align with project philosophy

---

ADR-003
When adding complex client-side features
ADR-001 (Local-First Architecture)
