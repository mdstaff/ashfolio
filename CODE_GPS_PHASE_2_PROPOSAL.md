# Code GPS Phase 2: Refactoring Intelligence Proposal

## Executive Summary

Extend Code GPS Phase 2 with **Refactoring Intelligence** - automated detection of consolidation opportunities, API inconsistencies, and architectural improvements based on real codebase patterns.

**Key Insight**: Our evidence-based refactoring analysis (34 files using `format_currency`, 3 implementations) demonstrates patterns that could be automatically detected and suggested by Code GPS.

---

## Proposed Feature: Consolidation Opportunity Detection

### 1. Duplicate Function Detection

**Current Gap**: Code GPS found `FormatHelpers.format_currency` pattern but didn't detect 3 different implementations

**Proposed Enhancement**:

```yaml
# === CONSOLIDATION OPPORTUNITIES ===
duplicate_functions:
  format_currency:
    implementations: 3
    files:
      [
        "helpers/format_helper.ex:116",
        "live/format_helpers.ex:29",
        "helpers/chart_helpers.ex:137",
      ]
    usage_sites: 34
    complexity_variance: medium # Different feature sets
    consolidation_priority: HIGH

  power:
    implementations: 2
    files: ["aer_calculator.ex:279", "forecast_calculator.ex:1187"]
    usage_sites: 2
    complexity_variance: low # Nearly identical
    consolidation_priority: MEDIUM
```

### 2. API Fragmentation Analysis

**Detection Logic**:

- Functions with same name but different arities/signatures
- Similar parameter patterns across modules
- Usage distribution analysis (heavy vs light usage)

### 3. Mathematical Function Clustering

**Pattern Recognition**:

- Mathematical operations (`power`, `nth_root`, `exp`, `ln`)
- Financial calculations (compound interest, growth rates)
- Data transformations (grouping, sorting, aggregating)

---

## Implementation Strategy

### Stage 2A: Pattern-Based Consolidation Detection

**Build on existing comprehensive analysis** from Phase 1

**New Analysis Module**:

```elixir
defmodule Mix.Tasks.CodeGps.ConsolidationAnalyzer do
  def detect_duplicate_functions(file_patterns) do
    # Group functions by name across files
    # Compare implementation complexity
    # Calculate usage impact scores
    # Generate consolidation recommendations
  end

  def analyze_api_fragmentation(modules) do
    # Detect similar function signatures
    # Map cross-module usage patterns
    # Identify abstraction opportunities
  end
end
```

### Stage 2B: Automated Refactoring Suggestions

**Integration with existing workflow**:

```bash
# Enhanced Code GPS output
mix code_gps --suggest-refactoring

# New YAML section:
# === REFACTORING OPPORTUNITIES ===
high_impact:
  - type: "function_consolidation"
    target: "format_currency"
    effort: "medium"
    impact: "34 files affected"
    risk: "medium - different feature sets"
    recommendation: "Create unified Ashfolio.Financial.Formatters API"

medium_impact:
  - type: "utility_extraction"
    target: "mathematical_functions"
    effort: "low"
    impact: "2 calculator modules"
    risk: "low - private functions"
    recommendation: "Extract to Ashfolio.Mathematical module"
```

### Stage 2C: Evidence-Based Decision Support

**Risk Assessment Integration**:

- **Test coverage analysis** for refactoring targets
- **Dependency impact mapping** (which modules would be affected)
- **Breaking change assessment** (API compatibility analysis)
- **Effort estimation** based on complexity and usage patterns

---

## Training Data from Ashfolio Analysis

### Real-World Refactoring Patterns Discovered

**1. Currency Formatting Consolidation Pattern**:

```yaml
pattern_signature:
  function_name: "format_currency"
  implementations: 3
  feature_variance:
    ["show_cents_parameter", "comma_formatting", "negative_handling"]
  usage_distribution: "widespread" # 34 files
  consolidation_approach: "unified_api_with_options"
```

**2. Mathematical Utility Extraction Pattern**:

```yaml
pattern_signature:
  function_category: "mathematical_operations"
  implementations: ["power", "nth_root", "exp", "ln"]
  scope: "private_functions"
  domain: "financial_calculations"
  consolidation_approach: "shared_utility_module"
```

**3. Pattern Detection Methodology**:

- **Evidence-first analysis** (no assumptions without grep/search validation)
- **Usage impact assessment** (34 files = high impact vs 2 files = medium)
- **Feature parity preservation** (unified API must support all current capabilities)
- **Risk-stratified approach** (LOW/MEDIUM/HIGH with specific criteria)

### False Positive Avoidance Lessons

- **Similar names ≠ duplicate implementations** (verify with line-by-line analysis)
- **High-quality codebase** may have few consolidation opportunities
- **Context matters** - specialized implementations may be intentionally different

---

## Integration with Existing Code GPS Architecture

### Phase 1 Foundation (✅ Complete)

- Comprehensive file analysis (not sampling)
- Real project pattern detection
- Code quality integration (Credo/Dialyzer)
- Performance optimization (fast/slow modes)

### Phase 2 Enhancement (Proposed)

- **Build on comprehensive analysis** already implemented
- **Reuse pattern detection infrastructure** from Phase 1
- **Extend YAML output format** with refactoring section
- **Maintain fast/slow mode design** (consolidation detection could be slow mode only)

### Backward Compatibility

- All existing Code GPS functionality preserved
- New refactoring analysis optional (flag-controlled)
- YAML output remains valid for existing AI agents

---

## Expected Outcomes

### For AI Agents

- **Targeted refactoring guidance** instead of broad suggestions
- **Evidence-based recommendations** with specific file:line references
- **Risk-aware suggestions** with effort/impact assessment
- **Concrete next steps** (create X module, consolidate Y functions)

### For Development Teams

- **Automated architectural review** catching consolidation opportunities
- **Maintenance burden assessment** (34 files affected by formatting changes)
- **Technical debt quantification** (3 implementations of same logic)
- **Refactoring prioritization** based on usage impact

### For Codebase Health

- **Proactive consolidation detection** before duplication becomes widespread
- **API consistency monitoring** across modules
- **Architectural drift prevention** through pattern analysis

---

## Implementation Timeline

### Week 1: Detection Algorithm Development

- Function signature analysis across files
- Usage pattern mapping and impact scoring
- Risk assessment framework implementation

### Week 2: YAML Integration and Testing

- Extend Code GPS output with refactoring section
- Test against Ashfolio patterns (validate currency formatting detection)
- Performance optimization for large codebases

### Week 3: AI Agent Integration

- Update AI agent prompts to use refactoring suggestions
- Test end-to-end workflow (detection → recommendation → implementation)
- Validate false positive filtering

---

## Success Metrics

### Quantitative

- **Detection Accuracy**: Correctly identify 3 format_currency implementations
- **Usage Impact**: Accurately count 34 affected files
- **False Positive Rate**: <10% of suggestions should be invalid
- **Performance**: Refactoring analysis completes in <30s for Ashfolio-sized codebase

### Qualitative

- **Actionable Recommendations**: Suggestions lead to successful refactoring
- **Risk Assessment Accuracy**: Risk levels match actual refactoring complexity
- **AI Agent Effectiveness**: Agents make better refactoring decisions with suggestions

---

## Next Steps

1. **Validate Proposal**: Confirm this direction aligns with Code GPS Phase 2 goals
2. **Prototype Core Algorithm**: Build function duplication detection with Ashfolio as test case
3. **YAML Format Design**: Extend existing format with refactoring section
4. **Integration Testing**: Ensure new features work with existing Phase 1 infrastructure

**Recommendation**: Start with **Stage 2A** (Pattern-Based Consolidation Detection) as it directly builds on the successful Phase 1 comprehensive analysis foundation.

---

**Proposal Date**: September 4, 2025  
**Based on**: Real refactoring analysis findings from Ashfolio codebase  
**Evidence**: 3 format_currency implementations, 34 usage sites, mathematical function duplication  
**Integration**: Extends Code GPS Phase 1 comprehensive analysis capabilities
