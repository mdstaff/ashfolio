# Code GPS

AI-optimized codebase analysis tool for instant navigation.

## Quick Start

```bash
mix code_gps
# Outputs: .code-gps.yaml
```

## Purpose

Generate concise YAML manifest for AI assistants containing:

- LiveViews with key functions and missing integrations
- Important components and patterns
- Specific integration suggestions with line numbers

Goal: Replace reading multiple files with single manifest.

## Example Output (31 lines vs 777!)

```yaml
# Code GPS - Generated 107ms

# === LIVE VIEWS ===
Dashboard: lib/ashfolio_web/live/dashboard_live.ex:11 events: ["refresh_prices", "sort"] MISSING: ["expenses"]

# === KEY COMPONENTS ===
button: lib/ashfolio_web/components/core_components.ex:229 (used 20x)
stat_card: lib/ashfolio_web/components/core_components.ex:822 (used 5x)

# === TODO: INTEGRATION OPPORTUNITIES ===
add_expense_to_dashboard: Dashboard missing expense data integration
  TODO: Add PubSub subscription at lib/ashfolio_web/live/dashboard_live.ex:13
```

## Results

- 31 lines instead of reading multiple files
- 100ms generation for 173 files
- Instant integration hints with exact line numbers

## Use Cases

### 1. Feature Implementation

```bash
# AI prompt: "Add expense tracking to dashboard"
# Code GPS provides: exact files, lines, and code patterns
```

### 2. Code Review

```bash
# Instantly see: missing tests, pattern violations, integration gaps
```

### 3. Onboarding

```bash
# New developers get: complete codebase map in seconds
```

### 4. Refactoring

```bash
# Identify: circular dependencies, unused components, optimization opportunities
```

## Architecture

Built with Elixir's native AST parsing and pattern matching:

- File Analysis: Regex + AST parsing for accuracy
- Pattern Detection: Project-specific conventions
- Suggestion Engine: Heuristics for common integration patterns
- YAML Generation: AI-optimized structure with comments

## Testing

```bash
mix test test/mix/tasks/code_gps_test.exs
```

Validates:

- ✅ Manifest generation
- ✅ LiveView analysis accuracy
- ✅ Integration suggestion quality
- ✅ Performance <5 seconds (achieves ~100ms)

## Integration Workflow

### Development Loop

```bash
# 1. Make changes
git commit -m "Add expense resource"

# 2. Regenerate manifest
mix code_gps

# 3. AI reads updated manifest
# 4. AI provides precise integration code
```

### CI/CD Integration

```yaml
# .github/workflows/code-gps.yml
- name: Update Code GPS
  run: mix code_gps
- name: Upload manifest
  uses: actions/upload-artifact@v2
  with:
    name: code-gps-manifest
    path: .code-gps.yaml
```

## Future Enhancements

### Planned Features

- Real-time updates: File watcher mode
- Dependency graph: Visual relationship mapping
- Performance profiling: Complexity analysis
- Custom patterns: Project-specific rules

### Advanced Analysis

- AST complexity: Function complexity scoring
- Test coverage gaps: Systematic missing test detection
- Optimization opportunities: N+1 queries, unused code

## Implementation Roadmap

This roadmap outlines the next steps for improving the Code GPS tool. The goal is to make the tool more robust, reliable, and feature-rich.

### Phase 1: Stabilize and Harden

This phase focuses on improving the existing implementation to make it more reliable and easier to maintain.

#### 1. Robust Pattern Detection

*   **Problem:** The current pattern detection mechanism samples a small number of files, which can lead to inconsistent results.
*   **Solution:** Modify the `extract_patterns` function to analyze all relevant files instead of a small sample. This will ensure that the detected patterns are representative of the entire codebase.

#### 2. Decouple Suggestion Engine

*   **Problem:** The suggestion logic is hardcoded in the `generate_integration_hints` function, making it brittle and difficult to extend.
*   **Solution:** Refactor the suggestion engine to be data-driven. Create a configurable rules engine where relationships between different parts of the application can be defined. For example, a rule could specify that the `DashboardLive` view should always display data from the `Expense` resource.

#### 3. AST-based Parsing

*   **Problem:** The tool currently relies heavily on regular expressions for parsing code, which can be unreliable.
*   **Solution:** Replace all regex-based parsing with Abstract Syntax Tree (AST) parsing. Elixir's built-in `Code.string_to_quoted/2` function can be used to parse code into an AST, which can then be traversed to find the required information. This will make the analysis much more robust and resilient to code formatting changes.

### Phase 2: Advanced Analysis

This phase focuses on implementing the advanced features from the roadmap.

#### 1. Test Coverage Analysis

*   **Goal:** Provide a more detailed analysis of test coverage.
*   **Implementation:** The tool can be extended to parse the output of the `mix test --cover` command. The `cover/excover.html` file contains detailed information about test coverage, which can be extracted and included in the Code GPS manifest.

#### 2. Function Complexity Scoring

*   **Goal:** Automatically identify complex functions that may need refactoring.
*   **Implementation:** Use AST analysis to calculate the cyclomatic complexity of each function. This metric can be used to identify functions that are too complex and should be simplified.

#### 3. Custom Rule Engine

*   **Goal:** Allow projects to define their own custom analysis rules.
*   **Implementation:** Create a simple DSL (Domain-Specific Language) or a configuration file where users can define their own patterns and suggestions. This would make the Code GPS tool much more flexible and adaptable to different projects.

## Comparison to LSP

| Feature   | LSP               | Code GPS          |
| --------- | ----------------- | ----------------- |
| Target    | IDE features      | AI consumption    |
| Output    | Live analysis     | Static manifest   |
| Speed     | Real-time         | 100ms generation  |
| Structure | Symbol navigation | Integration hints |
| Format    | Protocol messages | YAML + comments   |

Code GPS complements LSP by providing AI-optimized codebase intelligence.

## Success Metrics

✅ Generation Speed: <100ms (target: <5s)
✅ Coverage: 173 files analyzed
✅ Accuracy: Correct LiveView/component detection
✅ Utility: 2 actionable integration suggestions
✅ Format: AI-readable YAML structure

## Contributing

The tool is designed for extension:

```elixir
# Add new analysis patterns
defp extract_new_pattern(files) do
  # Custom pattern detection logic
end

# Add new suggestion types
defp generate_custom_suggestions(modules) do
  # Custom integration hints
end
```

---

Code GPS: Turn any codebase into an AI-navigable map in 100ms! 🚀
