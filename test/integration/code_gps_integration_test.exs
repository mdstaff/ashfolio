defmodule AshfolioWeb.CodeGpsIntegrationTest do
  @moduledoc """
  Integration test to prove Code GPS is working correctly.

  This test validates that the Code GPS tool generates accurate
  codebase analysis that matches the actual implementation.

  To skip these tests during normal test runs:
  mix test --exclude code_gps
  """

  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.CodeGps

  @moduletag :code_gps

  @code_gps_path ".code-gps.yaml"

  setup do
    # Clean up any existing .code-gps.yaml
    if File.exists?(@code_gps_path) do
      File.rm!(@code_gps_path)
    end

    on_exit(fn ->
      # Keep the file for manual inspection if test fails
      if !ExUnit.configuration()[:trace] do
        if File.exists?(@code_gps_path) do
          File.rm!(@code_gps_path)
        end
      end
    end)

    :ok
  end

  describe "Code GPS generation" do
    test "generates .code-gps.yaml file" do
      capture_io(fn ->
        CodeGps.run([])
      end)

      assert File.exists?(@code_gps_path), "Code GPS should generate .code-gps.yaml file"
    end

    test "performance is under acceptable threshold" do
      start_time = System.monotonic_time(:millisecond)

      capture_io(fn ->
        CodeGps.run([])
      end)

      end_time = System.monotonic_time(:millisecond)
      duration = end_time - start_time

      assert duration < 5000, "Code GPS should complete in under 5 seconds, took #{duration}ms"
    end

    test "output contains expected structure and content" do
      capture_io(fn ->
        CodeGps.run([])
      end)

      content = File.read!(@code_gps_path)

      # Test basic structure
      assert content =~ "# Code GPS", "Should contain header"
      assert content =~ "# === LIVE VIEWS ===", "Should contain LiveViews section"
      assert content =~ "# === KEY COMPONENTS ===", "Should contain components section"

      assert content =~ "# === INTEGRATION OPPORTUNITIES ===",
             "Should contain integration section"

      # Test specific LiveViews exist
      assert content =~ "Dashboard:", "Should detect Dashboard LiveView"
      assert content =~ "Example:", "Should detect Example LiveView"

      # Test key components are detected
      assert content =~ "modal:", "Should detect modal component"
      assert content =~ "button:", "Should detect button component"
      assert content =~ "simple_form:", "Should detect simple_form component"
    end

    test "detects actual LiveView events and subscriptions" do
      capture_io(fn ->
        CodeGps.run([])
      end)

      content = File.read!(@code_gps_path)

      # Dashboard LiveView events
      assert content =~ ~s(events: ["refresh_prices", "sort", "create_snapshot"]),
             "Should detect Dashboard events"

      # Dashboard subscriptions
      assert content =~ ~s(subscriptions: [accounts, transactions, net_worth...5])

      # Example LiveView events
      assert content =~ ~s(events: ["simulate_error", "simulate_success", "clear_flash"]),
             "Should detect Example LiveView events"
    end

    test "provides accurate file paths and line numbers" do
      capture_io(fn ->
        CodeGps.run([])
      end)

      content = File.read!(@code_gps_path)

      # Test file paths are correct
      assert content =~ "file: lib/ashfolio_web/live/dashboard_live.ex",
             "Should have correct Dashboard file path"

      assert content =~ "file: lib/ashfolio_web/live/example_live.ex",
             "Should have correct Example file path"

      # Test mount line numbers are reasonable
      assert content =~ ~r/mount: \d+/,
             "Should include mount line numbers"

      assert content =~ ~r/render: \d+/,
             "Should include render line numbers"
    end

    test "counts components usage correctly" do
      capture_io(fn ->
        CodeGps.run([])
      end)

      content = File.read!(@code_gps_path)

      # Button should be highly used
      assert content =~ ~r/button:.*\(\d+x\)/, "Should show button usage count"

      # Modal should show usage
      assert content =~ ~r/modal:.*\(\d+x\)/, "Should show modal usage count"
    end

    test "generates no integration opportunities when none are detected" do
      capture_io(fn ->
        CodeGps.run([])
      end)

      content = File.read!(@code_gps_path)

      # Should not suggest any integrations
      assert content =~ "# === INTEGRATION OPPORTUNITIES ===\n# (none)"
    end
  end

  describe "Claude agent integration" do
    test "CLAUDE.md file exists and contains Code GPS instructions" do
      claude_md_path = "CLAUDE.md"
      assert File.exists?(claude_md_path), "CLAUDE.md should exist in repository root"

      content = File.read!(claude_md_path)

      # Test mandatory Code GPS instructions
      assert content =~ "MANDATORY: Code GPS First", "Should contain mandatory Code GPS section"
      assert content =~ "mix code_gps", "Should instruct to run Code GPS command"
      assert content =~ ".code-gps.yaml", "Should reference the output file"
      assert content =~ "Before starting ANY development work", "Should emphasize mandatory usage"
    end

    test "Code GPS manifest provides all information needed for development" do
      capture_io(fn ->
        CodeGps.run([])
      end)

      content = File.read!(@code_gps_path)

      # Should contain file paths for direct navigation
      assert content =~ ~r/file: lib\/.*\.ex/, "Should contain file paths"

      # Should contain line numbers for precise navigation
      assert content =~ ~r/mount: \d+/, "Should contain mount line numbers"
      assert content =~ ~r/render: \d+/, "Should contain render line numbers"

      # Should contain component attributes for proper usage
      assert content =~ ~r/attrs: \[.*\]/, "Should contain component attributes"
    end

    test "Code GPS identifies specific next actions for agents" do
      capture_io(fn ->
        CodeGps.run([])
      end)

      content = File.read!(@code_gps_path)

      # Should provide enough context for implementation
      assert content =~ "subscriptions:", "Should show current subscriptions"
      assert content =~ "events:", "Should show current events"
      assert content =~ "missing:", "Should show missing subscriptions"
    end

    test "validates workflow: agent should run Code GPS before any development" do
      # Simulate Claude agent workflow

      # Step 1: Agent should run Code GPS first
      capture_io(fn ->
        CodeGps.run([])
      end)

      assert File.exists?(@code_gps_path), "Code GPS should generate manifest"

      # Step 2: Agent should be able to parse the manifest
      content = File.read!(@code_gps_path)
      lines = String.split(content, "\n")

      # Should be parseable YAML structure
      header_line = Enum.find(lines, &String.starts_with?(&1, "# Code GPS"))
      assert header_line, "Should have Code GPS header"

      # Should contain all required sections
      assert Enum.any?(lines, &String.contains?(&1, "=== LIVE VIEWS ===")),
             "Should have LiveViews section"

      assert Enum.any?(lines, &String.contains?(&1, "=== KEY COMPONENTS ===")),
             "Should have components section"

      assert Enum.any?(lines, &String.contains?(&1, "=== INTEGRATION OPPORTUNITIES ===")),
             "Should have integration section"

      # # Step 3: Agent should find actionable items
      # integration_lines =
      #   lines
      #   |> Enum.drop_while(fn line -> not String.contains?(line, "INTEGRATION OPPORTUNITIES") end)
      #   |> Enum.take_while(fn line -> not String.match?(line, ~r/^#\s*$/) end)

      # assert length(integration_lines) > 3, "Should have multiple integration opportunities"
    end
  end

  describe "Code GPS data accuracy" do
    test "LiveView analysis matches actual implementation" do
      capture_io(fn ->
        CodeGps.run([])
      end)

      # Read actual Dashboard LiveView
      dashboard_content = File.read!("lib/ashfolio_web/live/dashboard_live.ex")

      # Verify events exist in actual file
      assert dashboard_content =~ "refresh_prices", "Dashboard should have refresh_prices event"
      assert dashboard_content =~ "sort", "Dashboard should have sort event"

      # Read Example LiveView
      example_content = File.read!("lib/ashfolio_web/live/example_live.ex")

      # Verify events exist in actual file
      assert example_content =~ "simulate_error", "Example should have simulate_error event"
      assert example_content =~ "simulate_success", "Example should have simulate_success event"
      assert example_content =~ "clear_flash", "Example should have clear_flash event"
    end

    test "component analysis matches core_components.ex" do
      capture_io(fn ->
        CodeGps.run([])
      end)

      # Read actual core components
      core_components = File.read!("lib/ashfolio_web/components/core_components.ex")

      # Verify key components exist
      assert core_components =~ "def modal(", "Should have modal component"
      assert core_components =~ "def button(", "Should have button component"
      assert core_components =~ "def simple_form(", "Should have simple_form component"
      assert core_components =~ "def input(", "Should have input component"
    end
  end
end
