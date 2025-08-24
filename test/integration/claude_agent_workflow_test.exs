defmodule AshfolioWeb.ClaudeAgentWorkflowTest do
  @moduledoc """
  Test that validates the complete Claude agent workflow using Code GPS.

  This test simulates what a Claude agent should do when starting work:
  1. Read CLAUDE.md for instructions
  2. Run mix code_gps
  3. Read .code-gps.yaml for codebase understanding
  4. Use the information to make informed development decisions
  """

  use ExUnit.Case, async: false
  @moduletag :skip
  import ExUnit.CaptureIO

  @code_gps_path ".code-gps.yaml"

  setup do
    # Clean up any existing .code-gps.yaml
    if File.exists?(@code_gps_path) do
      File.rm!(@code_gps_path)
    end

    on_exit(fn ->
      if File.exists?(@code_gps_path) do
        File.rm!(@code_gps_path)
      end
    end)

    :ok
  end

  @tag :skip
  test "workflow performance meets agent requirements" do
    # Agent workflow should be fast enough for interactive use
    start_time = System.monotonic_time(:millisecond)

    # Complete workflow simulation
    capture_io(fn ->
      Mix.Tasks.CodeGps.run([])
    end)

    # Read step
    File.read!(@code_gps_path)

    end_time = System.monotonic_time(:millisecond)
    duration = end_time - start_time

    # Should complete in under 2 seconds for good UX
    assert duration < 2000, "Agent workflow should complete quickly, took #{duration}ms"
  end

  test "manifest provides enough context to avoid reading multiple files" do
    capture_io(fn ->
      Mix.Tasks.CodeGps.run([])
    end)

    manifest = File.read!(@code_gps_path)

    # Agent should understand project structure without reading multiple files
    essential_sections = [
      # Architecture overview
      "LIVE VIEWS",
      # UI building blocks
      "KEY COMPONENTS",
      # Next actions
      "INTEGRATION OPPORTUNITIES"
    ]

    Enum.each(essential_sections, fn section ->
      assert manifest =~ section, "Should contain #{section} section"
    end)

    # Key data points for development
    essential_data = [
      # Available interactions
      "events:",
      # Data dependencies
      "subscriptions:",
      # Integration gaps
      "missing:",
      # Navigation paths
      "file:",
      # Code locations
      "mount:",
      # Task prioritization
      "priority:"
    ]

    Enum.each(essential_data, fn data ->
      assert manifest =~ data, "Should contain #{data} for agent understanding"
    end)

    # Verify conciseness - should fit in reasonable context window
    line_count = manifest |> String.split("\n") |> length()

    assert line_count < 100,
           "Should be concise enough for AI consumption, was #{line_count} lines"
  end
end
