# Code GPS Phase 2: Advanced Analysis & Refactoring Intelligence

## Overview

Building on Phase 1's successful foundation (robust pattern detection + code quality integration), Phase 2 focuses on **advanced architectural analysis** and **evidence-based refactoring intelligence** for AI agents.

**Phase 1 Achievements:**
- ✅ Deterministic pattern detection (real project patterns vs generic fallbacks)
- ✅ Code quality integration (2052 mods/funs analyzed comprehensively)
- ✅ Performance optimization (290ms fast mode, 0.9s test suite)
- ✅ AI-optimized YAML output with usage metrics

**Phase 2 Mission:** Transform Code GPS from structural analysis to **intelligent refactoring assistant**, providing AI agents with consolidation opportunities, API consistency insights, and evidence-based improvement recommendations.

## Philosophy

- **Evidence-Based Refactoring**: Use comprehensive analysis to identify real opportunities, not theoretical ones
- **Impact-Aware Suggestions**: Include usage metrics and consolidation priority for informed decisions
- **Workflow Integration**: Seamlessly integrate with AI development workflows via CLI flags
- **Progressive Disclosure**: Fast analysis by default, deep insights on demand

## Stage 1: Pattern-Based Refactoring Detection

**Deliverable:** Detect and prioritize code consolidation opportunities across the codebase

**Problem:** Current Code GPS finds patterns but doesn't identify duplication, fragmentation, or consolidation opportunities that could improve maintainability.

**Solution:** Analyze function signatures, implementation patterns, and usage distribution to identify refactoring opportunities.

**Key Features:**
```yaml
# Example output
CONSOLIDATION_OPPORTUNITIES:
  duplicate_functions:
    - pattern: "format_currency"
      implementations: 3
      files: [format_helper.ex, format_helpers.ex, chart_helpers.ex]
      usage_count: 34
      consolidation_priority: HIGH
      estimated_impact: "Remove 2 duplicate implementations, consolidate 34 call sites"
      
    - pattern: "calculate_compound_growth" 
      implementations: 2
      files: [forecast_calculator.ex, aer_calculator.ex]
      usage_count: 12
      consolidation_priority: MEDIUM
      estimated_impact: "Unify calculation methodology across forecasting"

  mathematical_patterns:
    - pattern_type: "percentage_calculation"
      occurrences: 18
      files: [calculator.ex, performance_calculator.ex, forecast_calculator.ex]
      consolidation_priority: MEDIUM
      suggested_utility: "MathHelpers.calculate_percentage/2"
```

**Implementation Strategy:**
1. **Function Signature Analysis**: Parse all function definitions and group by name patterns
2. **Implementation Similarity**: Use AST diffing to detect similar code blocks
3. **Usage Impact Assessment**: Count call sites and estimate refactoring scope
4. **Priority Scoring Framework**: 
   ```yaml
   consolidation_priority_score:
     usage_impact: 40%          # 34 files = high weight
     implementation_count: 30%  # 3 implementations = medium weight
     complexity_variance: 20%   # different features = adds complexity
     test_coverage: 10%         # safety factor
   ```

**Test Cases:**
```elixir
test "detects duplicate function implementations" do
  opportunities = analyze_consolidation_opportunities()
  
  format_currency_opportunity = find_opportunity(opportunities, "format_currency")
  assert format_currency_opportunity.implementations >= 2
  assert format_currency_opportunity.consolidation_priority in ["HIGH", "MEDIUM"]
  assert format_currency_opportunity.usage_count > 0
end

test "prioritizes consolidation by impact" do
  opportunities = analyze_consolidation_opportunities()
  
  high_priority = Enum.filter(opportunities, &(&1.consolidation_priority == "HIGH"))
  medium_priority = Enum.filter(opportunities, &(&1.consolidation_priority == "MEDIUM"))
  
  # HIGH priority should have more usage or more duplicates than MEDIUM
  Enum.each(high_priority, fn high ->
    assert high.usage_count >= 20 or high.implementations >= 3
  end)
end
```

**Status:** Not Started

---

## Stage 2: API Inconsistency Detection

**Deliverable:** Identify API fragmentation and suggest consistency improvements

**Problem:** Code GPS found `FormatHelpers.format_currency` but missed that there are actually 3 different implementations with potentially different behaviors.

**Solution:** Detect functions with same names but different signatures, similar logic with different APIs, and fragmentation opportunities.

**Key Features:**
```yaml
API_INCONSISTENCIES:
  signature_conflicts:
    - function_name: "format_currency"
      implementations:
        - signature: "format_currency(amount)"
          file: "lib/ashfolio/format_helper.ex"
          usage_count: 12
        - signature: "format_currency(amount, options)"
          file: "lib/ashfolio_web/format_helpers.ex" 
          usage_count: 18
        - signature: "format_currency(amount, currency, precision)"
          file: "lib/ashfolio/chart_helpers.ex"
          usage_count: 4
      consistency_score: 23  # Lower = more fragmented
      suggested_unification: "format_currency(amount, opts \\\\ [])"
      
  similar_logic_patterns:
    - pattern_name: "decimal_rounding"
      files: [calculator.ex, performance_calculator.ex, net_worth_calculator.ex]
      variation_count: 4
      consistency_opportunity: "Extract to shared DecimalHelpers module"
      estimated_lines_reduced: 45
```

**Implementation Strategy:**
1. **Function Catalog Building**: Index all functions by name across entire codebase
2. **Signature Comparison**: Group functions by name and compare parameter patterns
3. **Logic Pattern Detection**: Use AST analysis to find similar algorithmic patterns
4. **Consistency Scoring**: Calculate API fragmentation metrics
5. **Risk Assessment Matrix**:
   ```yaml
   risk_factors:
     LOW: "identical implementations, comprehensive tests, isolated usage"
     MEDIUM: "different features, widespread usage, partial test coverage"
     HIGH: "core functionality, complex dependencies, inadequate test coverage"
   ```

**Test Cases:**
```elixir
test "detects functions with same name but different signatures" do
  inconsistencies = analyze_api_inconsistencies()
  
  # Should find format_currency variations
  format_conflicts = find_signature_conflicts(inconsistencies, "format_currency")
  assert length(format_conflicts.implementations) >= 2
  assert format_conflicts.consistency_score < 50  # Indicates fragmentation
end

test "suggests unified API signatures" do
  inconsistencies = analyze_api_inconsistencies()
  
  Enum.each(inconsistencies.signature_conflicts, fn conflict ->
    assert conflict.suggested_unification != nil
    assert String.contains?(conflict.suggested_unification, conflict.function_name)
  end)
end
```

**Status:** Not Started

---

## Stage 3: Refactoring Workflow Integration

**Deliverable:** CLI integration for refactoring-focused analysis and AI workflow enhancement

**Problem:** Code GPS provides analysis but doesn't integrate into refactoring workflow or provide actionable commands.

**Solution:** Add refactoring-specific CLI modes and integrate with AI development workflow.

**Key Features:**
```bash
# Refactoring-focused analysis
mix code_gps --suggest-refactoring
# → "Found 3 implementations of format_currency across 34 files"
# → "Detected mathematical function duplication in calculators" 
# → "Integration opportunity: Consolidated formatting API"

# Impact assessment mode  
mix code_gps --impact-analysis
# → Shows usage metrics, file coupling, and refactoring risk scores

# AI agent integration mode
mix code_gps --ai-refactor-prep
# → Generates detailed refactoring plan with file-by-file changes
```

**YAML Output Enhancement:**
```yaml
# === REFACTORING INTELLIGENCE ===
consolidation_summary: "5 high-priority opportunities found"
api_consistency_score: 73/100
estimated_complexity_reduction: "15% (removing 234 duplicate lines)"

refactoring_roadmap:
  immediate_wins:
    - action: "Consolidate format_currency implementations"  
      effort: "2-3 hours"
      impact: "34 call sites simplified"
      risk: "LOW"
      
  strategic_improvements:
    - action: "Extract MathHelpers utility module"
      effort: "4-6 hours" 
      impact: "18 calculation patterns unified"
      risk: "MEDIUM"

# === AI AGENT INTEGRATION ===
refactoring_suggestions:
  - id: "format_currency_consolidation"
    type: "function_consolidation"
    confidence: 0.95
    effort_estimate: "2-3 days"
    breaking_changes: ["signature_modification"]
    migration_strategy: "gradual_with_compatibility_layer"
    next_steps: ["design_unified_api", "prototype_implementation", "test_migration"]
    files_affected: 34
    risk_assessment: "MEDIUM"
    test_coverage_impact: "requires_comprehensive_testing"

refactor_prep_data:
  safe_moves: ["consolidate format_currency", "extract percentage calculations"]
  requires_review: ["unify compound growth calculations"]  
  high_risk: []
```

**Implementation Strategy:**
1. **CLI Flag Processing**: Add new command-line options for refactoring modes
2. **Output Format Adaptation**: Modify YAML generation for refactoring context
3. **Risk Assessment**: Include complexity and coupling metrics for safety
4. **AI Integration**: Provide structured data for AI-driven refactoring

**Test Cases:**
```elixir
test "refactoring mode generates actionable suggestions" do
  manifest = CodeGps.run(["--suggest-refactoring"])
  
  assert Map.has_key?(manifest, :consolidation_opportunities)
  assert Map.has_key?(manifest, :api_inconsistencies)
  assert manifest.consolidation_summary != ""
end

test "AI integration mode provides structured refactoring data" do
  manifest = CodeGps.run(["--ai-refactor-prep"])
  
  assert Map.has_key?(manifest, :refactor_prep_data)
  assert is_list(manifest.refactor_prep_data.safe_moves)
  assert is_list(manifest.refactor_prep_data.requires_review)
end
```

**Status:** Not Started

---

## Implementation Strategy

### Building on Phase 1 Success

**Foundation Available:**
- Robust pattern detection engine (comprehensive vs sampling)
- Code quality integration (Credo/Dialyzer)
- Performance optimization (fast/slow modes)
- Test infrastructure (single manifest generation)

**Phase 2 Extensions:**
- AST analysis capabilities (needed for Stages 1 & 2)
- Function cataloging and signature comparison
- Usage metric integration with refactoring priority
- CLI mode expansion

### Development Order

1. **Stage 1 First**: Pattern-based refactoring detection builds on existing pattern detection
2. **Stage 2 Parallel**: API inconsistency detection can develop alongside Stage 1
3. **Stage 3 Final**: Workflow integration combines outputs from Stages 1 & 2

### Performance Considerations

- **Fast Mode Extension**: Add `--consolidation-only` for quick duplicate detection
- **Incremental Analysis**: Cache function catalogs between runs for speed
- **Memory Optimization**: Stream processing for large codebases
- **Timeout Protection**: Prevent hanging on complex AST analysis
- **Smart Integration Strategy**: 
  - Builds on Phase 1 foundation ✅ (comprehensive analysis, real patterns, performance optimization)
  - Extends existing YAML format with refactoring section
  - Maintains backward compatibility with current AI agents
  - Preserves fast/slow mode design (refactoring analysis in slow mode)

## Success Criteria

**Definition of Done:**
- [ ] Detects function duplication patterns with usage metrics
- [ ] Identifies API inconsistencies with consolidation suggestions  
- [ ] Provides refactoring-specific CLI modes
- [ ] Generates evidence-based refactoring priorities
- [ ] Maintains Phase 1 performance characteristics
- [ ] Integrates seamlessly with AI agent workflows

**Metrics:**
- **Detection Accuracy**: Finds real duplication opportunities (not false positives)
- **Priority Accuracy**: High-priority suggestions should have >20 usage count or >3 implementations
- **Performance**: Refactoring analysis completes in <10 seconds
- **Actionability**: Each suggestion includes effort estimate and impact assessment
- **Confidence Scoring**: Each suggestion includes confidence level (0.0-1.0)
- **Risk Calibration**: Risk assessments match actual refactoring complexity

## Integration with AI Development Workflow

### Evidence-Based Refactoring Process
1. **Real patterns detected** → Targeted investigation (not theoretical refactoring)
2. **Quality baseline established** → Safe refactoring confidence 
3. **Usage metrics provided** → Impact assessment before changes
4. **Consolidation priorities** → Focus on highest-value improvements

### AI Agent Enhancement
```bash
# AI workflow integration
mix code_gps --ai-refactor-prep
# → Structured data for AI agents to plan refactoring
# → Risk assessment for automated vs manual changes
# → Usage metrics for impact-aware refactoring
```

## Architectural Insights from Phase 1

**Key Learning**: The "2052 mods/funs analyzed" metric gave confidence that analysis was comprehensive rather than sampling-based. This number also explains why Credo found relatively few issues - the codebase is in excellent shape.

**Phase 2 Application**: Use comprehensive analysis to identify consolidation opportunities that sampling would miss, providing the same confidence level for refactoring decisions.

**Real Training Data**: Our Ashfolio analysis provides actual patterns to train the detection algorithms:
- Currency formatting consolidation pattern (3 implementations → unified API)
- Mathematical utility extraction pattern (private functions → shared module)  
- False positive avoidance lessons (high-quality codebases need evidence-first analysis)

**Integration with Current Work**: The timing is perfect! Our evidence-based refactoring analysis provides real training data for Phase 2 implementation:
- **Test case**: Detect our 3 format_currency implementations automatically
- **Validation**: Confirm 34 usage sites count matches reality  
- **Risk calibration**: Verify MEDIUM risk assessment matches actual complexity
- **Algorithm training**: Use real-world patterns vs synthetic examples

## Expected Phase 2 Outcomes

### For Ashfolio Codebase
- **Test Case**: Detect our 3 format_currency implementations automatically
- **Validation**: Confirm 34 usage sites count matches reality
- **Risk Calibration**: Verify MEDIUM risk assessment accuracy
- Identify mathematical calculation patterns across forecast/performance calculators  
- Provide evidence-based consolidation roadmap

### For AI Agents
- **Automated Discovery**: Future AI agents receive consolidation opportunities without manual analysis:
  ```yaml
  # === REFACTORING OPPORTUNITIES ===
  high_impact:
    - target: "format_currency"
      files: 34
      recommendation: "Create unified Ashfolio.Financial.Formatters API"
  ```
- Evidence-based refactoring suggestions instead of theoretical improvements
- Impact metrics for informed decision-making
- Safe vs risky refactoring categorization
- Structured data for automated code improvements

### For Development Workflow  
- `--suggest-refactoring` mode for periodic codebase health checks
- Integration with code review process
- Foundation for automated refactoring tools
- **Enhanced Feedback**: Instead of manual discovery, AI agents automatically receive:
  ```yaml
  # === REFACTORING OPPORTUNITIES ===
  high_impact:
    - target: "format_currency"
      files: 34
      recommendation: "Create unified Ashfolio.Financial.Formatters API"
      confidence: 0.95
      effort: "2-3 days"
      risk: "MEDIUM"
  ```

---

**Phase 2 Status: READY TO START**  
**Prerequisites: Phase 1 Complete ✅**  
**Recommended First Stage: Pattern-Based Refactoring Detection**

*Roadmap based on AI agent review feedback and Phase 1 success*  
*Focus: Evidence-based refactoring intelligence for AI agents*