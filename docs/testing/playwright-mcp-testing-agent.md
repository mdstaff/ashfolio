# Playwright MCP Testing Agent - Universal

## Mission

Execute comprehensive UI testing for any Ashfolio version using Playwright MCP tools. Automatically adapt to version-specific requirements and provide complete test coverage.

## Required MCP Tools

- `mcp__playwright__browser_navigate` - Page navigation
- `mcp__playwright__browser_snapshot` - Accessibility snapshots
- `mcp__playwright__browser_click` - Element interaction
- `mcp__playwright__browser_wait_for` - State waiting
- `mcp__playwright__browser_evaluate` - Data extraction
- `mcp__playwright__browser_take_screenshot` - Visual documentation
- `mcp__playwright__browser_console_messages` - Error monitoring

## Configuration Reference

### Code GPS Integration

Reference `@.code-gps.yaml` for:

- Current route mappings and LiveView components
- Available test endpoints and navigation paths
- Component usage patterns for element targeting

### Version Detection Pattern

```yaml
version_config:
  target: "v0.X.Y"
  checklist_path: "docs/archive/versions/vX.Y/VX.Y.Z_PLAYWRIGHT_TEST_CHECKLIST.md"
  assessment_path: "docs/archive/versions/vX.Y/VX.Y.Z_PLAYWRIGHT_COVERAGE_ASSESSMENT.md"
  primary_routes: [] # From .code-gps.yaml
```

## Adaptive Testing Framework

### Version-Specific Configurations

#### v0.6.0 Corporate Actions

```yaml
v0_6_0:
  primary_route: "/corporate-actions"
  key_features:
    - conditional_forms
    - validation_logic
    - action_types
  performance_targets:
    form_submission: 500ms
    validation: 100ms
  critical_selectors:
    - "select[name='action_type']"
    - "button:has-text('Apply Action')"
    - ".validation-error"
  validation_assertions:
    - field_visibility_changes
    - calculation_accuracy
    - data_persistence
```

#### v0.7.0 Portfolio Analytics

```yaml
v0_7_0:
  primary_route: "/advanced_analytics"
  key_features:
    - efficient_frontier
    - portfolio_optimization
    - cache_integration
  performance_targets:
    calculation: 500ms
    cache_hit: 100ms
    refresh_all: 2000ms
  critical_selectors:
    - "button:has-text('Calculate Efficient Frontier')"
    - ".bg-blue-50" # Min variance portfolio
    - ".bg-green-50" # Tangency portfolio
    - ".bg-purple-50" # Max return portfolio
  validation_assertions:
    - sharpe_ratio_ordering
    - weight_summation_100_percent
    - volatility_ordering
```

### Future Versions Template

```yaml
v0_X_Y:
  primary_route: "/feature-url"
  key_features: []
  performance_targets: {}
  critical_selectors: []
  validation_assertions: []
```

## Universal Test Execution

### Phase 1: Environment Setup

1. Route Discovery: Parse `@.code-gps.yaml` for available routes
2. Version Detection: Extract version from checklist path
3. Configuration Load: Apply version-specific test configuration
4. Server Verification:
   ```
   mcp__playwright__browser_navigate(url: "http://localhost:4000/health")
   ```

### Phase 2: Baseline Validation

1. Navigation Test: Navigate to primary route
2. Page Load: Take accessibility snapshot for element discovery
3. Initial Screenshot: Document starting state
4. Console Check: Verify no initial JavaScript errors

### Phase 3: Feature Testing

For each feature in version configuration:

1. Element Discovery: Use snapshot to locate interactive elements
2. Action Execution: Click buttons, fill forms using MCP tools
3. Performance Measurement: Time operations with wait_for
4. State Validation: Take screenshots and snapshots after actions

### Phase 4: Validation & Documentation

1. Data Extraction: Use evaluate tool for numerical validation
2. Error Collection: Check console messages for issues
3. Evidence Capture: Take final screenshots with naming convention
4. Results Documentation: Populate assessment documents

## MCP Tool Usage Patterns

### Navigation & Discovery

```yaml
navigation_sequence:
  - tool: mcp__playwright__browser_navigate
    params:
      url: "http://localhost:4000{route}"
  - tool: mcp__playwright__browser_snapshot
    purpose: "Discover page elements and structure"
  - tool: mcp__playwright__browser_take_screenshot
    params:
      filename: "{version}-{feature}-initial.png"
```

### Performance Testing

```yaml
performance_measurement:
  - tool: mcp__playwright__browser_evaluate
    params:
      function: "() => { window.testStartTime = Date.now(); }"
  - tool: mcp__playwright__browser_click
    params:
      element: "{button_description}"
      ref: "{element_reference}"
  - tool: mcp__playwright__browser_wait_for
    params:
      text: "{completion_indicator}"
  - tool: mcp__playwright__browser_evaluate
    params:
      function: "() => Date.now() - window.testStartTime"
```

### Data Validation

```yaml
mathematical_validation:
  - tool: mcp__playwright__browser_evaluate
    params:
      function: "() => Array.from(document.querySelectorAll('.allocation-weight')).map(el => parseFloat(el.textContent))"
  - tool: mcp__playwright__browser_evaluate
    params:
      function: "(weights) => Math.abs(weights.reduce((a,b) => a+b, 0) - 100) < 0.01"
```

### Error Monitoring

```yaml
error_detection:
  - tool: mcp__playwright__browser_console_messages
    purpose: "Collect all console output"
  - tool: mcp__playwright__browser_evaluate
    params:
      function: "() => window.errors || []"
```

## Route-Based Testing Strategy

### Code GPS Route Mapping

Reference current routes from `.code-gps.yaml`:

- `/advanced_analytics` → AdvancedAnalyticsLive (v0.7.0 target)
- `/corporate-actions` → CorporateActionLive (v0.6.0 target)
- `/transactions` → TransactionLive (data setup)
- `/` → DashboardLive (integration testing)

### Cross-Route Integration Testing

```yaml
integration_flow:
  setup_route: "/transactions"
  primary_route: "{version_primary_route}"
  validation_routes:
    - "/dashboard"
    - "/net_worth"
```

## Evidence Collection Standards

### Screenshot Naming Convention

```yaml
screenshot_patterns:
  initial: "{version}-{feature}-initial.png"
  loading: "{version}-{feature}-loading.png"
  results: "{version}-{feature}-results.png"
  error: "{version}-{feature}-error.png"
  mobile: "{version}-{feature}-mobile.png"
```

### Performance Data Structure

```yaml
performance_results:
  feature: "{feature_name}"
  measurement_type: "{calculation|navigation|interaction}"
  duration_ms: 0
  target_ms: 0
  passed: false
  timestamp: ""
```

### Validation Results Structure

```yaml
validation_results:
  feature: "{feature_name}"
  validation_type: "{mathematical|visual|functional}"
  expected: ""
  actual: ""
  passed: false
  details: ""
```

## Success Criteria

### Universal Requirements

- All checklist items marked complete
- All performance targets met
- Zero critical JavaScript errors
- All required screenshots captured
- Assessment document fully populated

### Version-Specific Requirements

- Version features validated per configuration
- Integration points verified
- Mathematical accuracy confirmed (where applicable)
- Visual elements properly displayed

## Usage Instructions

### Basic Testing Command

```
"Execute Playwright testing for {version} using @docs/archive/versions/{version}/{VERSION}_PLAYWRIGHT_TEST_CHECKLIST.md. Reference @.code-gps.yaml for route information and populate @docs/archive/versions/{version}/{VERSION}_PLAYWRIGHT_COVERAGE_ASSESSMENT.md with results."
```

### Advanced Options

```
"Execute comprehensive regression testing across multiple versions, comparing performance metrics and identifying functionality changes between v0.6.0 and v0.7.0."
```

This agent specification leverages MCP tools directly and integrates with the existing code GPS system for maximum effectiveness.
