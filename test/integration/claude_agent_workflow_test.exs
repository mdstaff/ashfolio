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
  import ExUnit.CaptureIO

  @code_gps_path ".code-gps.yaml"
  @claude_md_path "CLAUDE.md"

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

  test "complete Claude agent workflow simulation" do
    # === STEP 1: Agent reads CLAUDE.md ===
    assert File.exists?(@claude_md_path), "CLAUDE.md should exist for agent instructions"

    claude_instructions = File.read!(@claude_md_path)

    # Verify agent gets mandatory Code GPS instructions
    assert claude_instructions =~ "MANDATORY: Code GPS First"
    assert claude_instructions =~ "mix code_gps"
    assert claude_instructions =~ ".code-gps.yaml"

    # === STEP 2: Agent runs Code GPS ===
    output =
      capture_io(fn ->
        Mix.Tasks.CodeGps.run([])
      end)

    # Verify tool runs successfully
    assert output =~ "Code GPS generated"
    assert File.exists?(@code_gps_path)

    # === STEP 3: Agent reads Code GPS manifest ===
    manifest = File.read!(@code_gps_path)

    # Agent should understand current LiveViews
    assert manifest =~ "Dashboard:"
    assert manifest =~ "Example:"

    # Agent should understand current components
    assert manifest =~ "modal:"
    assert manifest =~ "button:"
    assert manifest =~ "simple_form:"

    # === STEP 4: Agent identifies work opportunities ===
    assert manifest =~ "add_expense_to_dashboard"
    assert manifest =~ "priority: high"

    # === STEP 5: Agent has enough context for development ===
    lines = String.split(manifest, "\n")

    # Should find Dashboard LiveView with specific context
    dashboard_section =
      lines
      |> Enum.drop_while(fn line -> not String.starts_with?(line, "Dashboard:") end)
      |> Enum.take_while(fn line ->
        not String.match?(line, ~r/^[A-Z]/) or String.starts_with?(line, "Dashboard:")
      end)

    # Agent should know Dashboard file location
    file_line = Enum.find(dashboard_section, &String.contains?(&1, "file:"))
    assert file_line =~ "lib/ashfolio_web/live/dashboard_live.ex"

    # Agent should know current events
    events_line = Enum.find(dashboard_section, &String.contains?(&1, "events:"))
    assert events_line =~ "refresh_prices"
    assert events_line =~ "sort"

    # Agent should know what's missing
    missing_line = Enum.find(dashboard_section, &String.contains?(&1, "missing:"))
    assert missing_line =~ "expenses"

    # === STEP 6: Agent can locate integration opportunities ===
    integration_section =
      lines
      |> Enum.drop_while(fn line -> not String.contains?(line, "INTEGRATION OPPORTUNITIES") end)
      # Take reasonable section
      |> Enum.take(20)

    expense_integration =
      Enum.find(integration_section, &String.contains?(&1, "add_expense_to_dashboard"))

    assert expense_integration, "Should find expense integration opportunity"

    # Should have actionable description
    desc_line = Enum.find(integration_section, &String.contains?(&1, "desc:"))
    assert desc_line =~ "Dashboard missing expense data integration"

    # === STEP 7: Verify agent has all needed information ===
    # Component usage counts for informed decisions
    assert manifest =~ ~r/\(\d+x\)/, "Should show component usage frequencies"

    # File paths for direct navigation
    assert manifest =~ ~r/lib\/.*\.ex/, "Should contain file paths"

    # Line numbers for precise changes
    assert manifest =~ ~r/mount: \d+/, "Should contain mount line numbers"
    assert manifest =~ ~r/render: \d+/, "Should contain render line numbers"

    # Priority levels for task planning
    assert manifest =~ "priority: high"
    assert manifest =~ "priority: medium"
  end

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
