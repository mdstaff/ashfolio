# HEEx Template Development Checklist

## Overview

This checklist prevents HEEx template variable issues that can break compilation and Code GPS functionality.

**Key Rule**: All variables accessed in HEEx templates (`~H"""..."""`) must be in the `assigns` map and prefixed with `@`.

## Pre-Development Checklist

Before creating any Phoenix component or LiveView:

- [ ] Plan all template variables to be passed via `assigns`
- [ ] Never use local variables directly in `~H` templates
- [ ] Use `~H"""<!-- content -->"""` for empty templates, never `~H""`
- [ ] Test template rendering with `rendered_to_string/1`

## During Development

### Every 30 minutes:
- [ ] Run `mix compile --warnings-as-errors`
- [ ] Check for HEEx-specific warnings

### After each template:
- [ ] Verify all variables use `@variable` syntax
- [ ] Check that no local variables are accessed in templates
- [ ] Test rendering with sample data

### Before switching files:
- [ ] Run compilation check
- [ ] Verify no syntax errors

## HEEx Template Patterns

### ❌ NEVER DO THIS
```elixir
def render_component(assigns) do
  scenarios = [:pessimistic, :realistic, :optimistic]
  colors = ["#red", "#blue", "#green"]
  
  ~H"""
  <%= for {scenario, color} <- Enum.zip(scenarios, colors) do %>
    <div style={"color: #{color}"}><%= scenario %></div>
  <% end %>
  """
end
```

### ✅ ALWAYS DO THIS
```elixir
def render_component(assigns) do
  scenarios = [:pessimistic, :realistic, :optimistic]
  colors = ["#red", "#blue", "#green"]
  
  assigns = assign(assigns, :scenario_data, Enum.zip(scenarios, colors))
  
  ~H"""
  <%= for {scenario, color} <- @scenario_data do %>
    <div style={"color: #{color}"}><%= scenario %></div>
  <% end %>
  """
end
```

### ✅ EMPTY TEMPLATES
```elixir
# Correct empty template
defp render_empty(assigns) do
  ~H"""
  <!-- no content -->
  """
end

# Or for conditional rendering
defp render_when_empty(%{items: []} = assigns) do
  ~H"""
  <!-- no items to display -->
  """
end
```

## Common Patterns

### Pattern 1: Multiple Local Variables
```elixir
defp render_axis_labels(assigns) do
  margin = 60
  y_pos = assigns.height - margin + 20
  years = assigns.chart_data.years
  step = max(1, div(length(years), 6))
  
  # Convert all to assigns
  assigns = 
    assigns
    |> assign(:y_pos, y_pos)
    |> assign(:year_labels, Enum.with_index(years) |> Enum.filter(fn {_year, index} -> rem(index, step) == 0 end))

  ~H"""
  <%= for {year, _index} <- @year_labels do %>
    <text y={@y_pos}><%= year %></text>
  <% end %>
  """
end
```

### Pattern 2: Conditional Rendering
```elixir
defp render_markers(%{show: false} = assigns) do
  ~H"""
  <!-- markers disabled -->
  """
end

defp render_markers(%{show: true, markers: markers} = assigns) do
  assigns = assign(assigns, :markers, markers)
  
  ~H"""
  <%= for marker <- @markers do %>
    <g class="marker"><%= marker.label %></g>
  <% end %>
  """
end
```

## Warning Checks

### Immediate Checks (After Each Template)
```bash
# Check compilation
mix compile --warnings-as-errors

# Look for common HEEx issues
grep -r "~H\"\"\"" lib/ --include="*.ex" | grep -v "<!-- "
```

### Pre-Commit Checks
```bash
# Full compilation check
mix compile --warnings-as-errors

# Verify Code GPS can run
mix code_gps --dry-run

# Run tests to catch template issues
mix test
```

## Error Patterns to Watch For

### 1. Variable Access Warning
```
warning: you are accessing the variable "scenarios" inside a LiveView template.
```
**Fix**: Move variable to `assigns` and use `@scenarios`

### 2. Empty Template Error
```
** (RuntimeError) ~H requires a variable named "assigns" to exist and be set to a map
```
**Fix**: Use `~H"""<!-- content -->"""` instead of `~H""`

### 3. Undefined Function
```
warning: AshfolioWeb.Components.ForecastChart.forecast_chart/1 is undefined or private
```
**Fix**: Check function name and ensure it's public

## Quality Gates

### Definition of Done (HEEx-specific)
- [ ] All HEEx templates compile without warnings
- [ ] All template variables accessed via `@assigns`
- [ ] No empty `~H""` templates
- [ ] Code GPS runs successfully
- [ ] Templates render correctly in tests

### Pre-Production Checklist
- [ ] `mix compile --warnings-as-errors` passes
- [ ] `mix code_gps` generates manifest
- [ ] All Phoenix LiveView tests pass
- [ ] Template accessibility tested
- [ ] No console errors in browser

## Recovery Steps

If you encounter HEEx template compilation errors:

1. **Identify the error location** from compiler output
2. **Check for local variables** being accessed in templates
3. **Move variables to assigns** using `assign(assigns, :var_name, value)`
4. **Fix empty templates** to use proper syntax
5. **Test compilation** with `mix compile --warnings-as-errors`
6. **Verify Code GPS** with `mix code_gps --dry-run`

## Integration with Development Workflow

### Daily Development
- Check HEEx templates every 30 minutes
- Run warning checks before switching files
- Verify Code GPS after major changes

### Before Commits
- Full compilation check
- Code GPS verification
- LiveView test suite

### Before Pull Requests
- Clean compilation (no warnings)
- Code GPS generates complete manifest
- All integration tests pass

## Resources

- [Phoenix LiveView HEEx Guide](https://hexdocs.pm/phoenix_live_view/assigns-eex.html)
- [Phoenix Component Documentation](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html)
- Project CLAUDE.md guidelines
- Phoenix LiveView layout architecture docs