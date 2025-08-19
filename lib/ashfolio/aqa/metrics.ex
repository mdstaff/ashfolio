defmodule Ashfolio.AQA.Metrics do
  @moduledoc """
  Data structure representing test suite quality metrics.

  Used by the AQA analyzer to store and communicate analysis results.
  """

  defstruct [
    :total_tests,
    :test_files,
    :test_directories,
    :tag_distribution,
    :untagged_tests,
    :naming_violations,
    :structure_violations,
    :test_complexity_score,
    :maintainability_index,
    :large_test_files,
    :heavy_setup_tests,
    :untested_modules,
    :low_assertion_tests
  ]

  @type t :: %__MODULE__{
          total_tests: non_neg_integer(),
          test_files: non_neg_integer(),
          test_directories: [String.t()],
          tag_distribution: %{atom() => non_neg_integer()},
          untagged_tests: non_neg_integer(),
          naming_violations: [String.t()],
          structure_violations: [String.t()],
          test_complexity_score: float(),
          maintainability_index: float(),
          large_test_files: [String.t()],
          heavy_setup_tests: [String.t()],
          untested_modules: [String.t()],
          low_assertion_tests: [String.t()]
        }
end
