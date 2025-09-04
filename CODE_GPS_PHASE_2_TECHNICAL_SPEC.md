# Code GPS Phase 2: Technical Implementation Specification

## Document Overview

This technical specification defines the implementation requirements for Code GPS Phase 2: Advanced Analysis & Refactoring Intelligence, based on comprehensive AI agent reviews and Phase 1 success.

**Phase 1 Foundation**: Robust pattern detection, code quality integration, performance optimization (290ms fast mode, 0.9s test suite)

**Phase 2 Goal**: Transform Code GPS into an intelligent refactoring assistant providing evidence-based consolidation opportunities and API consistency analysis.

## Architecture Overview

### Core Components

```elixir
# New modules to be added
defmodule Mix.Tasks.CodeGps.RefactoringAnalyzer do
  # Main orchestrator for refactoring analysis
end

defmodule Mix.Tasks.CodeGps.FunctionCatalog do
  # Function signature and usage analysis
end

defmodule Mix.Tasks.CodeGps.ConsolidationDetector do
  # Duplicate function detection and consolidation opportunities
end

defmodule Mix.Tasks.CodeGps.APIConsistencyAnalyzer do
  # API fragmentation and signature conflict detection
end

defmodule Mix.Tasks.CodeGps.RiskAssessment do
  # Risk scoring and safety analysis for refactoring suggestions
end
```

### Data Flow Architecture

```
Phase 1 Data → Function Cataloging → Consolidation Detection → API Analysis → Risk Assessment → YAML Output
     ↓              ↓                    ↓                    ↓              ↓
  Patterns     Signatures &         Duplicate           Inconsistency    Safety 
  & Usage      Usage Counts        Functions           Detection        Scoring
```

## Stage 1: Pattern-Based Refactoring Detection

### Implementation Requirements

#### 1.1 Function Cataloging System

```elixir
defmodule Mix.Tasks.CodeGps.FunctionCatalog do
  @doc """
  Builds comprehensive catalog of all functions in codebase with signatures and usage
  """
  def build_catalog(files) do
    %{
      functions: %{
        "format_currency" => [
          %{
            signature: "format_currency(amount)",
            file: "lib/ashfolio/format_helper.ex",
            line: 23,
            arity: 1,
            usage_sites: ["file1.ex:45", "file2.ex:12", ...],
            usage_count: 12,
            implementation_hash: "abc123", # AST hash for similarity detection
            complexity_score: 3
          },
          %{
            signature: "format_currency(amount, options)",
            file: "lib/ashfolio_web/format_helpers.ex", 
            line: 67,
            arity: 2,
            usage_sites: ["file3.ex:89", ...],
            usage_count: 18,
            implementation_hash: "def456",
            complexity_score: 5
          }
        ]
      },
      usage_index: %{
        "file1.ex" => ["format_currency/1", "calculate_total/2", ...],
        "file2.ex" => ["format_currency/1", ...]
      }
    }
  end
end
```

#### 1.2 Consolidation Detection Algorithm

```elixir
defmodule Mix.Tasks.CodeGps.ConsolidationDetector do
  @doc """
  Detects functions with same name but different implementations
  """
  def detect_consolidation_opportunities(catalog) do
    catalog.functions
    |> Enum.filter(fn {_name, implementations} -> length(implementations) > 1 end)
    |> Enum.map(&analyze_consolidation_opportunity/1)
    |> Enum.sort_by(& &1.priority_score, :desc)
  end

  defp analyze_consolidation_opportunity({function_name, implementations}) do
    total_usage = implementations |> Enum.map(& &1.usage_count) |> Enum.sum()
    implementation_count = length(implementations)
    complexity_variance = calculate_complexity_variance(implementations)
    test_coverage = assess_test_coverage(implementations)

    priority_score = calculate_priority_score(%{
      usage_impact: total_usage,
      implementation_count: implementation_count,
      complexity_variance: complexity_variance,
      test_coverage: test_coverage
    })

    %{
      pattern: function_name,
      implementations: implementation_count,
      files: implementations |> Enum.map(& &1.file) |> Enum.uniq(),
      usage_count: total_usage,
      consolidation_priority: priority_level(priority_score),
      priority_score: priority_score,
      estimated_impact: generate_impact_description(implementations),
      risk_assessment: assess_consolidation_risk(implementations),
      suggested_approach: suggest_consolidation_approach(implementations)
    }
  end
end
```

#### 1.3 Priority Scoring Framework

```elixir
defp calculate_priority_score(metrics) do
  # Weights based on AI agent feedback
  usage_weight = 0.40      # 34 files = high weight
  implementation_weight = 0.30  # 3 implementations = medium weight  
  complexity_weight = 0.20      # different features = adds complexity
  test_weight = 0.10           # safety factor

  # Normalize metrics to 0-100 scale
  usage_score = min(metrics.usage_impact / 50.0 * 100, 100)
  impl_score = min(metrics.implementation_count / 5.0 * 100, 100)
  complexity_score = metrics.complexity_variance # already 0-100
  test_score = metrics.test_coverage # already 0-100

  weighted_score = 
    (usage_score * usage_weight) +
    (impl_score * implementation_weight) +
    (complexity_score * complexity_weight) +
    (test_score * test_weight)

  round(weighted_score)
end

defp priority_level(score) when score >= 80, do: "HIGH"
defp priority_level(score) when score >= 50, do: "MEDIUM"  
defp priority_level(_), do: "LOW"
```

## Stage 2: API Inconsistency Detection

### Implementation Requirements

#### 2.1 Signature Conflict Detection

```elixir
defmodule Mix.Tasks.CodeGps.APIConsistencyAnalyzer do
  def analyze_api_inconsistencies(catalog) do
    %{
      signature_conflicts: detect_signature_conflicts(catalog),
      similar_logic_patterns: detect_similar_patterns(catalog),
      consistency_metrics: calculate_consistency_metrics(catalog)
    }
  end

  defp detect_signature_conflicts(catalog) do
    catalog.functions
    |> Enum.filter(fn {_name, impls} -> has_signature_conflicts?(impls) end)
    |> Enum.map(fn {name, impls} ->
      %{
        function_name: name,
        implementations: format_signature_variations(impls),
        consistency_score: calculate_consistency_score(impls),
        suggested_unification: suggest_unified_signature(impls),
        migration_complexity: assess_migration_complexity(impls)
      }
    end)
  end

  defp calculate_consistency_score(implementations) do
    # Lower score = more fragmented
    base_score = 100
    
    # Penalize for each additional arity
    arities = implementations |> Enum.map(& &1.arity) |> Enum.uniq()
    arity_penalty = (length(arities) - 1) * 20
    
    # Penalize for parameter name differences
    param_penalty = calculate_parameter_inconsistency(implementations)
    
    # Penalize for return type differences (if detectable)
    return_penalty = calculate_return_type_inconsistency(implementations)
    
    max(0, base_score - arity_penalty - param_penalty - return_penalty)
  end
end
```

#### 2.2 Risk Assessment Matrix

```elixir
defmodule Mix.Tasks.CodeGps.RiskAssessment do
  @risk_criteria %{
    low: %{
      description: "identical implementations, comprehensive tests, isolated usage",
      criteria: [
        {:implementation_similarity, :high},
        {:test_coverage, :comprehensive}, 
        {:usage_coupling, :isolated},
        {:breaking_changes, :none}
      ]
    },
    medium: %{
      description: "different features, widespread usage, partial test coverage", 
      criteria: [
        {:implementation_similarity, :partial},
        {:test_coverage, :partial},
        {:usage_coupling, :moderate},
        {:breaking_changes, :signature_only}
      ]
    },
    high: %{
      description: "core functionality, complex dependencies, inadequate test coverage",
      criteria: [
        {:implementation_similarity, :low},
        {:test_coverage, :inadequate},
        {:usage_coupling, :high},
        {:breaking_changes, :behavioral}
      ]
    }
  }

  def assess_consolidation_risk(implementations) do
    scores = %{
      implementation_similarity: assess_implementation_similarity(implementations),
      test_coverage: assess_test_coverage(implementations),
      usage_coupling: assess_usage_coupling(implementations),
      breaking_changes: assess_breaking_changes(implementations)
    }

    risk_level = determine_risk_level(scores)
    
    %{
      level: risk_level,
      description: @risk_criteria[risk_level].description,
      factors: scores,
      mitigation_strategies: suggest_mitigation_strategies(risk_level, scores)
    }
  end
end
```

## Stage 3: Refactoring Workflow Integration

### Implementation Requirements

#### 3.1 CLI Integration

```elixir
# Extend existing run/1 function in Mix.Tasks.CodeGps
def run(args) do
  # ... existing code ...
  
  cond do
    "--suggest-refactoring" in args ->
      run_refactoring_analysis(args)
    
    "--impact-analysis" in args ->
      run_impact_analysis(args)
      
    "--ai-refactor-prep" in args ->
      run_ai_refactor_prep(args)
      
    true ->
      # ... existing logic ...
  end
end

defp run_refactoring_analysis(args) do
  fast_mode = "--fast" in args
  
  manifest = generate_base_manifest(fast_mode)
  refactoring_data = RefactoringAnalyzer.analyze(manifest)
  
  # Output refactoring-focused summary
  IO.puts("🔧 Found #{length(refactoring_data.consolidation_opportunities)} consolidation opportunities")
  IO.puts("📊 API consistency score: #{refactoring_data.api_consistency_score}/100")
  
  # Generate enhanced YAML
  yaml_content = generate_refactoring_yaml(manifest, refactoring_data)
  File.write!(".code-gps.yaml", yaml_content)
end
```

#### 3.2 AI Agent Data Structures

```elixir
defmodule Mix.Tasks.CodeGps.AIIntegration do
  @doc """
  Generates structured data optimized for AI agent consumption
  """
  def generate_ai_refactor_data(refactoring_analysis) do
    %{
      refactoring_suggestions: format_for_ai_agents(refactoring_analysis),
      confidence_scores: extract_confidence_metrics(refactoring_analysis),
      execution_plan: generate_execution_plan(refactoring_analysis)
    }
  end

  defp format_for_ai_agents(analysis) do
    analysis.consolidation_opportunities
    |> Enum.map(fn opportunity ->
      %{
        id: generate_suggestion_id(opportunity),
        type: "function_consolidation",
        confidence: calculate_confidence(opportunity),
        effort_estimate: estimate_effort(opportunity),
        breaking_changes: identify_breaking_changes(opportunity),
        migration_strategy: suggest_migration_strategy(opportunity),
        next_steps: generate_next_steps(opportunity),
        files_affected: length(opportunity.files),
        risk_assessment: opportunity.risk_assessment.level,
        test_coverage_impact: assess_test_impact(opportunity),
        rollback_complexity: assess_rollback_complexity(opportunity)
      }
    end)
  end
end
```

#### 3.3 Enhanced YAML Output Format

```yaml
# === REFACTORING INTELLIGENCE ===
consolidation_summary: "5 high-priority opportunities found"
api_consistency_score: 73/100
estimated_complexity_reduction: "15% (removing 234 duplicate lines)"
analysis_confidence: 0.92

consolidation_opportunities:
  high_priority:
    - pattern: "format_currency"
      implementations: 3
      files_affected: 34
      usage_count: 67
      priority_score: 87
      risk_level: "MEDIUM"
      confidence: 0.95
      effort_estimate: "2-3 days"
      breaking_changes: ["signature_modification"]
      migration_strategy: "gradual_with_compatibility_layer"
      
api_inconsistencies:
  signature_conflicts:
    - function_name: "format_currency"
      consistency_score: 23
      implementations:
        - signature: "format_currency(amount)"
          file: "lib/ashfolio/format_helper.ex"
          usage_count: 12
        - signature: "format_currency(amount, options)" 
          file: "lib/ashfolio_web/format_helpers.ex"
          usage_count: 18
      suggested_unification: "format_currency(amount, opts \\\\ [])"

# === AI AGENT INTEGRATION ===
refactoring_suggestions:
  - id: "format_currency_consolidation_001"
    type: "function_consolidation"
    confidence: 0.95
    effort_estimate: "2-3 days"
    breaking_changes: ["signature_modification"]
    migration_strategy: "gradual_with_compatibility_layer"
    next_steps: ["design_unified_api", "prototype_implementation", "test_migration"]
    files_affected: 34
    risk_assessment: "MEDIUM"
    rollback_complexity: "LOW"
```

## Performance Requirements

### Speed Targets
- **Fast Mode**: Maintain <500ms (refactoring analysis skipped)
- **Refactoring Mode**: Complete analysis in <10 seconds
- **Memory Usage**: Stream processing for large codebases, <200MB peak

### Optimization Strategies
- **Incremental Analysis**: Cache function catalogs between runs
- **Lazy Loading**: Only analyze requested function groups
- **Parallel Processing**: AST analysis in parallel workers
- **Early Termination**: Stop analysis when confidence thresholds met

## Testing Strategy

### Unit Tests
```elixir
defmodule ConsolidationDetectorTest do
  test "detects format_currency consolidation opportunity" do
    catalog = build_test_catalog([
      function("format_currency", 1, "helper.ex", 12),
      function("format_currency", 2, "web_helper.ex", 18),
      function("format_currency", 3, "chart_helper.ex", 4)
    ])
    
    opportunities = ConsolidationDetector.detect_consolidation_opportunities(catalog)
    
    format_opp = find_opportunity(opportunities, "format_currency")
    assert format_opp.implementations == 3
    assert format_opp.usage_count == 34
    assert format_opp.consolidation_priority == "HIGH"
  end
end
```

### Integration Tests
```elixir
test "end-to-end refactoring analysis workflow" do
  # Test the complete workflow with real Ashfolio codebase patterns
  manifest = CodeGps.run(["--suggest-refactoring"])
  
  # Validate expected format_currency detection
  assert manifest.consolidation_opportunities |> 
    Enum.any?(&(&1.pattern == "format_currency"))
    
  # Validate YAML structure
  yaml_content = File.read!(".code-gps.yaml")
  assert yaml_content =~ "consolidation_opportunities:"
  assert yaml_content =~ "api_inconsistencies:"
end
```

### Performance Tests
```elixir
test "refactoring analysis completes within time limits" do
  {time, _result} = :timer.tc(fn ->
    CodeGps.run(["--suggest-refactoring"])
  end)
  
  # Should complete refactoring analysis in <10 seconds
  assert time < 10_000_000 # microseconds
end
```

## Error Handling & Edge Cases

### Graceful Degradation
```elixir
defp analyze_with_fallback(analysis_fn, fallback_value) do
  try do
    analysis_fn.()
  rescue
    error ->
      Logger.warn("Analysis failed: #{inspect(error)}, using fallback")
      fallback_value
  end
end
```

### Edge Cases to Handle
- **No Consolidation Opportunities**: Return empty list with confidence score
- **AST Parsing Failures**: Skip problematic files, continue analysis
- **Memory Limits**: Implement streaming for large codebases
- **Timeout Protection**: Abort long-running analysis with partial results

## Integration Points

### Phase 1 Integration
- **Pattern Detection**: Extends existing comprehensive analysis
- **Code Quality**: Incorporates Credo/Dialyzer findings into risk assessment  
- **Performance**: Maintains fast/slow mode architecture
- **YAML Format**: Backward compatible extensions

### External Tool Integration
- **AST Analysis**: Use Elixir's `Code.string_to_quoted/2`
- **Test Coverage**: Parse ExCover reports for coverage metrics
- **Complexity Analysis**: Integrate cyclomatic complexity from Credo
- **Documentation**: Extract @doc and @spec for API analysis

## Success Metrics

### Accuracy Metrics
- **Detection Rate**: Successfully find known consolidation opportunities (format_currency test case)
- **False Positive Rate**: <5% of suggestions should be invalid
- **Priority Accuracy**: HIGH priority suggestions should average >80 priority score
- **Risk Calibration**: Risk assessments should match actual refactoring complexity

### Performance Metrics  
- **Analysis Speed**: <10 seconds for refactoring analysis
- **Memory Usage**: <200MB peak usage for large codebases
- **Cache Hit Rate**: >80% for incremental analysis runs

### Usability Metrics
- **Confidence Score**: Average >0.8 for actionable suggestions
- **Effort Estimates**: Within 50% accuracy of actual refactoring time
- **Migration Success**: >90% of suggested refactorings should be successfully implementable

## Implementation Phases

### Phase 2.1: Foundation (2-3 weeks)
- Function cataloging system
- Basic consolidation detection
- Priority scoring framework
- Unit test coverage

### Phase 2.2: Analysis (2-3 weeks)  
- API inconsistency detection
- Risk assessment implementation
- Performance optimization
- Integration testing

### Phase 2.3: Integration (1-2 weeks)
- CLI workflow integration
- AI agent data structures
- YAML format enhancement
- End-to-end testing

### Phase 2.4: Validation (1 week)
- Real-world testing with Ashfolio codebase
- Performance benchmarking
- Documentation and examples
- Production readiness assessment

---

**Total Estimated Timeline**: 6-9 weeks for complete Phase 2 implementation
**Success Criteria**: Successfully detect and analyze the format_currency consolidation opportunity described in AI agent reviews
**Next Step**: Begin Phase 2.1 implementation with function cataloging system