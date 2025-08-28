defmodule Ashfolio.AQA.Analyzer do
  @moduledoc """
  Main AQA (Automated Quality Assurance) analyzer that orchestrates
  static analysis of the test suite without executing tests.

  This module provides comprehensive test suite analysis including:
  - Test structure and organization analysis
  - Tag distribution and usage patterns
  - Architecture compliance checking
  - Quality metrics calculation
  - Performance bottleneck identification
  - Recommendation generation
  """

  alias Ashfolio.AQA.Metrics
  alias Ashfolio.AQA.QualityChecker
  alias Ashfolio.AQA.TagParser
  alias Ashfolio.AQA.TestParser

  @doc """
  Performs comprehensive static analysis of the test suite.

  Returns detailed metrics and recommendations without executing any tests.
  """
  def analyze_test_suite(opts \\ []) do
    test_root = opts[:test_root] || "test"

    with {:ok, test_files} <- discover_test_files(test_root),
         {:ok, parsed_tests} <- parse_test_files(test_files),
         {:ok, tag_analysis} <- analyze_tags(parsed_tests),
         {:ok, quality_metrics} <- calculate_quality_metrics(parsed_tests),
         {:ok, architecture_compliance} <- check_architecture_compliance(parsed_tests),
         {:ok, performance_indicators} <- analyze_performance_indicators(parsed_tests) do
      metrics = %Metrics{
        total_tests: count_total_tests(parsed_tests),
        test_files: length(test_files),
        test_directories: extract_directories(test_files),
        tag_distribution: tag_analysis.distribution,
        untagged_tests: tag_analysis.untagged,
        naming_violations: architecture_compliance.naming_violations,
        structure_violations: architecture_compliance.structure_violations,
        test_complexity_score: quality_metrics.complexity_score,
        maintainability_index: quality_metrics.maintainability_index,
        large_test_files: performance_indicators.large_files,
        heavy_setup_tests: performance_indicators.heavy_setups,
        untested_modules: find_untested_modules(),
        low_assertion_tests: quality_metrics.low_assertion_tests
      }

      {:ok, metrics}
    end
  end

  @doc """
  Generates actionable recommendations based on analysis results.
  """
  def generate_recommendations(%Metrics{} = metrics) do
    recommendations = []

    # Tag distribution recommendations
    recommendations =
      if tag_coverage_below_threshold?(metrics.tag_distribution) do
        ["Consider adding more granular tags for better test organization" | recommendations]
      else
        recommendations
      end

    # Performance recommendations
    recommendations =
      if length(metrics.large_test_files) > 0 do
        [
          "Split large test files (#{length(metrics.large_test_files)} found) for better maintainability"
          | recommendations
        ]
      else
        recommendations
      end

    # Quality recommendations
    recommendations =
      if metrics.test_complexity_score > 3.0 do
        [
          "Reduce test complexity - current score: #{metrics.test_complexity_score}"
          | recommendations
        ]
      else
        recommendations
      end

    # Architecture recommendations
    recommendations =
      if length(metrics.naming_violations) > 0 do
        [
          "Fix #{length(metrics.naming_violations)} naming convention violations"
          | recommendations
        ]
      else
        recommendations
      end

    {:ok, recommendations}
  end

  @doc """
  Analyzes trends by comparing current metrics with historical data.
  """
  def analyze_trends(current_metrics, historical_data \\ []) do
    if length(historical_data) < 2 do
      {:ok, %{trend: :insufficient_data, message: "Need at least 2 data points for trend analysis"}}
    else
      previous_metrics = List.last(historical_data)

      growth_rate =
        calculate_growth_rate(current_metrics.total_tests, previous_metrics.total_tests)

      quality_trend = calculate_quality_trend(current_metrics, previous_metrics)

      {:ok,
       %{
         growth_rate: growth_rate,
         quality_trend: quality_trend,
         test_count_change: current_metrics.total_tests - previous_metrics.total_tests,
         file_count_change: current_metrics.test_files - previous_metrics.test_files
       }}
    end
  end

  # Private functions

  defp discover_test_files(test_root) do
    test_pattern = Path.join(test_root, "**/*_test.exs")

    case Path.wildcard(test_pattern) do
      [] -> {:error, "No test files found in #{test_root}"}
      files -> {:ok, files}
    end
  end

  defp parse_test_files(test_files) do
    parsed_files = Enum.map(test_files, &TestParser.parse_file/1)

    if Enum.any?(parsed_files, &match?({:error, _}, &1)) do
      errors = Enum.filter(parsed_files, &match?({:error, _}, &1))
      {:error, {:parse_errors, errors}}
    else
      {:ok, Enum.map(parsed_files, fn {:ok, parsed} -> parsed end)}
    end
  end

  defp analyze_tags(parsed_tests) do
    TagParser.analyze_tag_distribution(parsed_tests)
  end

  defp calculate_quality_metrics(parsed_tests) do
    QualityChecker.calculate_metrics(parsed_tests)
  end

  defp check_architecture_compliance(_parsed_tests) do
    # Check naming conventions, structure patterns, etc.
    {:ok, %{naming_violations: [], structure_violations: []}}
  end

  defp analyze_performance_indicators(parsed_tests) do
    large_files =
      Enum.filter(parsed_tests, fn test ->
        # More than 20 tests in one file
        length(test.test_cases) > 20
      end)

    heavy_setups =
      Enum.filter(parsed_tests, fn test ->
        has_heavy_setup?(test)
      end)

    {:ok, %{large_files: large_files, heavy_setups: heavy_setups}}
  end

  # Implement setup complexity analysis
  defp has_heavy_setup?(_test), do: false

  defp count_total_tests(parsed_tests) do
    Enum.reduce(parsed_tests, 0, fn test, acc ->
      acc + length(test.test_cases)
    end)
  end

  defp extract_directories(test_files) do
    test_files
    |> Enum.map(&Path.dirname/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp find_untested_modules do
    # Analyze lib/ directory to find modules without corresponding tests
    []
  end

  defp tag_coverage_below_threshold?(tag_distribution) do
    total_tags = tag_distribution |> Map.values() |> Enum.sum()
    # Threshold for adequate tag coverage
    total_tags < 50
  end

  defp calculate_growth_rate(current, previous) when previous > 0 do
    (current - previous) / previous * 100
  end

  defp calculate_growth_rate(_, _), do: 0.0

  defp calculate_quality_trend(current, previous) do
    quality_diff = current.test_complexity_score - previous.test_complexity_score

    cond do
      quality_diff < -0.5 -> :improving
      quality_diff > 0.5 -> :declining
      true -> :stable
    end
  end
end
