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
