# Accessibility Testing Checklist

This document provides comprehensive procedures for testing WCAG AA compliance in the Ashfolio application.

## Overview

Ashfolio aims to meet WCAG 2.1 AA accessibility standards to ensure the application is usable by people with disabilities. This checklist provides systematic testing procedures for developers and QA teams.

## Testing Tools

### Automated Testing Tools

- Primary automated accessibility scanner
- Secondary validation tool
- Built into Chrome DevTools
- For CI/CD integration

### Manual Testing Tools

- NVDA (Windows), JAWS (Windows), VoiceOver (macOS)
- Standard keyboard testing
- WebAIM Contrast Checker, Colour Contrast Analyser

## WCAG AA Compliance Checklist

### 1. Color Contrast Testing

#### Automated Checks

- [ ] Run axe-core browser extension on all pages
- [ ] Run Lighthouse accessibility audit
- [ ] Check WAVE tool results for contrast errors

#### Manual Checks

- [ ] Minimum 4.5:1 contrast ratio
  - [ ] Body text against background
  - [ ] Link text against background
  - [ ] Button text against button background
  - [ ] Form labels against background
- [ ] Minimum 3:1 contrast ratio

  - [ ] Headings against background
  - [ ] Large button text
  - [ ] Large navigation text

- [ ] Sufficient contrast for all states
  - [ ] Default state
  - [ ] Hover state
  - [ ] Focus state
  - [ ] Active state
  - [ ] Disabled state

#### Testing Procedure

1. Use WebAIM Contrast Checker: https://webaim.org/resources/contrastchecker/
2. Test foreground and background color combinations
3. Document any failures with specific color values
4. Verify fixes meet minimum ratios

### 2. Keyboard Navigation Testing

#### Navigation Flow

- [ ] Tab order is logical and intuitive

  - [ ] Dashboard: Logo → Navigation → Main content → Footer
  - [ ] Accounts: Navigation → New Account button → Account list → Actions
  - [ ] Transactions: Navigation → New Transaction → Transaction list → Actions
  - [ ] Forms: Form fields in logical order → Submit → Cancel

- [ ] All interactive elements are keyboard accessible

  - [ ] Navigation links
  - [ ] Buttons (New Account, Edit, Delete, etc.)
  - [ ] Form inputs and selects
  - [ ] Modal close buttons
  - [ ] Table sorting controls

- [ ] Focus indicators are clearly visible
  - [ ] Focus outline is visible on all interactive elements
  - [ ] Focus outline has sufficient contrast (3:1 minimum)
  - [ ] Focus outline is not removed by CSS

#### Keyboard Shortcuts

- [ ] Standard shortcuts work correctly
  - [ ] Tab: Move to next focusable element
  - [ ] Shift+Tab: Move to previous focusable element
  - [ ] Enter: Activate buttons and links
  - [ ] Space: Activate buttons and checkboxes
  - [ ] Escape: Close modals and dropdowns

#### Testing Procedure

1. Disconnect mouse/trackpad
2. Use only Tab, Shift+Tab, Enter, Space, and Escape keys
3. Navigate through entire application
4. Verify all functionality is accessible
5. Document any unreachable elements

### 3. Screen Reader Testing

#### Screen Reader Setup

- VoiceOver (Cmd+F5 to enable)
- NVDA (free) or JAWS (commercial)
- Test with at least one screen reader

#### Content Structure

- [ ] Page structure is semantic and logical

  - [ ] Proper heading hierarchy (h1 → h2 → h3)
  - [ ] Main content areas use landmarks (main, nav, aside)
  - [ ] Lists use proper list markup (ul, ol, li)
  - [ ] Tables use proper table markup with headers

- [ ] All images have appropriate alt text

  - [ ] Informative images have descriptive alt text
  - [ ] Decorative images have empty alt text (alt="")
  - [ ] Complex images have detailed descriptions

- [ ] Form fields have proper labels
  - [ ] All inputs have associated labels
  - [ ] Labels are programmatically associated (for/id)
  - [ ] Required fields are clearly indicated
  - [ ] Error messages are associated with fields

#### ARIA Labels and Descriptions

- [ ] Interactive elements have appropriate ARIA labels

  - [ ] Buttons have descriptive labels
  - [ ] Links have meaningful text or aria-label
  - [ ] Form controls have labels or aria-labelledby
  - [ ] Complex widgets have appropriate ARIA roles

- [ ] Dynamic content updates are announced
  - [ ] Success/error messages use aria-live regions
  - [ ] Loading states are announced
  - [ ] Content changes are communicated

#### Testing Procedure

1. Enable screen reader
2. Navigate through application using screen reader commands
3. Verify all content is announced clearly
4. Test form submission and error handling
5. Document any unclear or missing announcements

### 4. Form Accessibility Testing

#### Form Structure

- [ ] All form fields have labels

  - [ ] Labels are visible and descriptive
  - [ ] Labels are programmatically associated with inputs
  - [ ] Placeholder text is not used as the only label

- [ ] Required fields are clearly indicated

  - [ ] Visual indicators (asterisk, "required" text)
  - [ ] Programmatic indicators (required attribute, aria-required)
  - [ ] Screen reader announcements include "required"

- [ ] Error handling is accessible
  - [ ] Error messages are clearly visible
  - [ ] Error messages are programmatically associated with fields
  - [ ] Error messages provide clear guidance for correction
  - [ ] Focus moves to first error field on submission

#### Form Validation

- [ ] Client-side validation is accessible

  - [ ] Validation messages are announced by screen readers
  - [ ] Invalid fields are clearly marked
  - [ ] Validation doesn't interfere with screen reader navigation

- [ ] Form submission feedback
  - [ ] Success messages are announced
  - [ ] Loading states during submission are communicated
  - [ ] Form remains usable if JavaScript fails

### 5. Table Accessibility Testing

#### Table Structure

- [ ] Data tables have proper headers

  - [ ] Column headers use `<th>` elements
  - [ ] Headers have `scope` attributes where needed
  - [ ] Complex tables use `headers` attribute

- [ ] Table captions and summaries
  - [ ] Tables have descriptive captions
  - [ ] Complex tables have summary information
  - [ ] Screen readers can navigate table structure

#### Holdings Table Specific Tests

- [ ] Portfolio holdings table
  - [ ] Column headers are properly marked
  - [ ] Sortable columns are announced as sortable
  - [ ] Current sort order is communicated
  - [ ] Numerical data is formatted consistently

### 6. Modal and Dialog Testing

#### Modal Accessibility

- [ ] Focus management

  - [ ] Focus moves to modal when opened
  - [ ] Focus is trapped within modal
  - [ ] Focus returns to trigger element when closed

- [ ] Keyboard interaction

  - [ ] Escape key closes modal
  - [ ] Tab navigation works within modal
  - [ ] Background content is not accessible

- [ ] Screen reader support
  - [ ] Modal has appropriate role (dialog)
  - [ ] Modal has accessible name (aria-labelledby)
  - [ ] Modal opening is announced

### 7. Navigation Testing

#### Main Navigation

- [ ] Navigation structure

  - [ ] Navigation uses semantic nav element
  - [ ] Current page is indicated (aria-current)
  - [ ] Navigation is consistent across pages

- [ ] Mobile navigation
  - [ ] Hamburger menu is keyboard accessible
  - [ ] Menu state changes are announced
  - [ ] Mobile menu can be closed with Escape

#### Breadcrumb Navigation

- [ ] Breadcrumb accessibility
  - [ ] Breadcrumbs use nav element with aria-label
  - [ ] Current page is marked with aria-current
  - [ ] Breadcrumb separators are handled properly

## Testing Procedures by Page

### Dashboard Page

1.  Run axe-core and Lighthouse
2.  Tab through all interactive elements
3.  Test portfolio summary announcements
4.  Verify gain/loss color coding meets standards
5.  Test price refresh button interaction

### Accounts Page

1.  Test account list table structure
2.  Test account creation/edit forms
3.  Test form modal behavior
4.  Test edit/delete button accessibility
5.  Test empty state messaging

### Transactions Page

1.  Test transaction table with multiple columns
2.  Test transaction form error handling
3.  Test date picker accessibility
4.  Test dropdown accessibility
5.  Test transaction filtering controls

## Automated Testing Integration

### Robust Test Implementation

Ashfolio's accessibility tests are designed to be resilient and work in various environments:

- Tests create default user in setup to prevent LiveView mounting failures
- Tests work reliably across all environments with proper database handling
- Addresses database concurrency issues at the source rather than with fallbacks
- Uses `inspect(error, limit: :infinity)` for comprehensive error diagnostics
- Provides detailed LiveView mounting error messages for debugging
- Clean test implementation with robust error handling

### CI/CD Integration

```bash
# Install Pa11y for automated testing
npm install -g pa11y

# Run accessibility tests
pa11y http://localhost:4000
pa11y http://localhost:4000/accounts
pa11y http://localhost:4000/transactions

# Generate accessibility report
pa11y-ci --sitemap http://localhost:4000/sitemap.xml
```

### Lighthouse CI

```yaml
# .github/workflows/accessibility.yml
name: Accessibility Tests
on: [push, pull_request]
jobs:
  accessibility:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run Lighthouse CI
        uses: treosh/lighthouse-ci-action@v7
        with:
          configPath: "./lighthouserc.json"
```

## Remediation Guidelines

### Common Issues and Solutions

#### Color Contrast Failures

- Text doesn't meet 4.5:1 contrast ratio
- Adjust text or background colors
- Use WebAIM contrast checker to find compliant colors

#### Missing Alt Text

- Images without alt attributes
- Add descriptive alt text or alt="" for decorative images
- `<img src="chart.png" alt="Portfolio performance chart showing 15% growth">`

#### Keyboard Navigation Issues

- Elements not reachable by keyboard
- Ensure tabindex is appropriate, add keyboard event handlers
- Add `tabindex="0"` and `onKeyDown` handlers for custom controls

#### Form Label Issues

- Form inputs without proper labels
- Use explicit labels with for/id association
- `<label for="account-name">Account Name</label><input id="account-name">`

#### Focus Management Problems

- Focus not visible or poorly managed
- Ensure focus indicators are visible, manage focus in dynamic content
- Never use `outline: none` without providing alternative focus indicator

## Documentation and Reporting

### Test Results Documentation

- Record all test results with screenshots
- Document specific WCAG criteria tested
- Include remediation recommendations
- Track progress over time

### Accessibility Statement

Maintain an accessibility statement that includes:

- Conformance level (WCAG 2.1 AA)
- Known limitations
- Contact information for accessibility feedback
- Date of last accessibility review

## Training and Resources

### Team Training

- Provide accessibility training for all developers
- Include accessibility in code review checklists
- Regular accessibility testing workshops

### External Resources

- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [WebAIM Resources](https://webaim.org/)
- [A11y Project Checklist](https://www.a11yproject.com/checklist/)
- [Deque axe-core Documentation](https://github.com/dequelabs/axe-core)

This checklist should be used regularly during development and before each release to ensure Ashfolio maintains high accessibility standards.
