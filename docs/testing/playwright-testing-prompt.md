# Universal Playwright MCP Testing Prompt

## Mission

Execute comprehensive UI testing for any Ashfolio version using Playwright MCP tools. Automatically adapt to version-specific requirements and provide complete test coverage.

## Usage Pattern

```
"Execute Playwright testing for [VERSION] using the checklist at @docs/archive/versions/[VERSION]/[VERSION]_PLAYWRIGHT_TEST_CHECKLIST.md and populate the coverage assessment at @docs/archive/versions/[VERSION]/[VERSION]_PLAYWRIGHT_COVERAGE_ASSESSMENT.md"
```

## Agent Capabilities

Read `@docs/testing/playwright-mcp-testing-agent.md` for complete specification including:

- MCP Tool Integration: Uses 7 Playwright MCP tools for browser automation
- Code GPS Integration: References `@.code-gps.yaml` for route discovery and navigation
- YAML Configuration: Version-specific test configurations with performance targets
- Adaptive Testing: Automatically adjusts to any version requirements
- Evidence Collection: Structured screenshot and performance data capture

## Quick Start Examples

### v0.7.0 Portfolio Analytics Testing

```
"Execute Playwright testing for v0.7.0 using @docs/archive/versions/v0.7/V0.7.0_PLAYWRIGHT_TEST_CHECKLIST.md and populate @docs/archive/versions/v0.7/V0.7.0_PLAYWRIGHT_COVERAGE_ASSESSMENT.md. Focus on Efficient Frontier performance (<500ms) and mathematical validation."
```

### v0.6.0 Corporate Actions Testing

```
"Execute Playwright testing for v0.6.0 using @docs/archive/versions/v0.6/V0.6.0_PLAYWRIGHT_TEST_CHECKLIST.md and populate @docs/archive/versions/v0.6/V0.6.0_PLAYWRIGHT_COVERAGE_ASSESSMENT.md. Focus on conditional form logic and validation accuracy."
```

### Multi-Version Regression Testing

```
"Execute regression testing across v0.6.0 and v0.7.0 using their respective Playwright test checklists. Compare performance metrics and identify any functionality degradation between versions."
```

## Key Features

- Version Agnostic: Works with any version's test documentation
- Self-Adapting: Reads test requirements and adjusts approach
- Performance Focused: Validates timing targets automatically
- Mathematical Precision: Ensures calculation accuracy
- Complete Documentation: Fills all assessment fields with actual results

Simply specify the version and checklist path - the agent handles the rest.
