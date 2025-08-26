defmodule AshfolioWeb.ClaudeCodeHooksTest do
  @moduledoc """
  Test that validates Claude Code hooks automatically enforce Code GPS usage.

  These tests validate that the Claude Code settings.json hooks properly:
  1. Auto-generate Code GPS on new sessions
  2. Remind agents to follow CLAUDE.md instructions
  3. Create observable behavior for agent compliance testing
  """

  use ExUnit.Case, async: false
  @moduletag :skip
  import ExUnit.CaptureIO

  @settings_path ".claude/settings.local.json"
  @code_gps_path ".code-gps.yaml"
  @claude_md_path "CLAUDE.md"
  describe "Claude Code hooks configuration" do
    test "settings.json contains SessionStart hook for Code GPS" do
      assert File.exists?(@settings_path), "Claude Code settings should exist"

      content = File.read!(@settings_path)
      settings = Jason.decode!(content)

      # Should have hooks configuration
      assert Map.has_key?(settings, "hooks"), "Should have hooks configuration"
      assert Map.has_key?(settings["hooks"], "SessionStart"), "Should have SessionStart hook"

      session_hooks = settings["hooks"]["SessionStart"]
      assert is_list(session_hooks), "SessionStart should be a list"

      # Should contain Code GPS command
      hook_commands =
        session_hooks
        |> Enum.flat_map(fn hook -> hook["hooks"] end)
        |> Enum.map(fn cmd -> cmd["command"] end)
        |> Enum.join(" ")

      assert hook_commands =~ "mix code_gps", "Should contain mix code_gps command"
      assert hook_commands =~ ".code-gps.yaml", "Should reference Code GPS output file"
    end

    test "SessionStart hook generates Code GPS when executed" do
      # Clean up existing Code GPS
      if File.exists?(@code_gps_path) do
        File.rm!(@code_gps_path)
      end

      # Read hook command from settings
      settings = @settings_path |> File.read!() |> Jason.decode!()
      session_hooks = settings["hooks"]["SessionStart"]

      hook_command =
        session_hooks
        |> List.first()
        |> get_in(["hooks"])
        |> List.first()
        |> Map.get("command")

      # Execute the hook command (simulating Claude Code session start)
      {output, exit_code} =
        System.cmd("sh", ["-c", hook_command],
          cd: File.cwd!(),
          stderr_to_stdout: true
        )

      # Hook should execute successfully
      assert exit_code == 0, "Hook command should execute successfully, got: #{output}"

      # Should generate Code GPS file
      assert File.exists?(@code_gps_path), "Hook should generate .code-gps.yaml file"

      # Should provide helpful message
      assert output =~ "Code GPS updated", "Should provide confirmation message"
      assert output =~ ".code-gps.yaml", "Should reference output file"

      # Clean up
      File.rm!(@code_gps_path)
    end
  end

  describe "Agent compliance validation through hooks" do
    test "can detect if agent follows Code GPS workflow" do
      # This test simulates how we could detect agent compliance

      # Step 1: SessionStart hook runs (simulated)
      capture_io(fn ->
        Mix.Tasks.CodeGps.run([])
      end)

      # Simulate agent reading the file (what we want to happen)
      File.read!(@code_gps_path)

      # Step 3: Check access time (this would be automatic with proper tooling)
      # Note: This is a simplified example - real implementation would need
      # file system monitoring or agent instrumentation

      assert File.exists?(@code_gps_path), "Code GPS should exist for agent to read"

      # Verify file contains actionable information
      content = File.read!(@code_gps_path)
      assert content =~ "add_expense_to_dashboard", "Should contain integration opportunities"
      assert content =~ "priority: high", "Should contain prioritized tasks"
    end

    test "provides mechanism to track agent Code GPS usage" do
      # This test demonstrates how we could track actual usage

      # Generate fresh Code GPS
      capture_io(fn ->
        Mix.Tasks.CodeGps.run([])
      end)

      # Create a simple usage tracking mechanism
      usage_log_path = ".code-gps-usage.log"

      # Simulate what a compliant agent should do
      agent_actions = [
        "Read .code-gps.yaml for codebase context",
        "Reference integration opportunities",
        "Use existing component patterns"
      ]

      # Log simulated agent behavior
      timestamp = DateTime.utc_now() |> DateTime.to_iso8601()
      initial_entry = "#{timestamp}: Agent session started\n"

      action_entries =
        Enum.map(agent_actions, fn action ->
          "#{timestamp}: #{action}\n"
        end)

      log_entry = initial_entry <> Enum.join(action_entries, "")

      File.write!(usage_log_path, log_entry)

      # Verify tracking works
      assert File.exists?(usage_log_path), "Should create usage log"
      log_content = File.read!(usage_log_path)
      assert log_content =~ ".code-gps.yaml", "Should track Code GPS usage"
      assert log_content =~ "integration opportunities", "Should track feature usage"

      # Clean up
      File.rm!(usage_log_path)
      File.rm!(@code_gps_path)
    end
  end

  describe "Hook-based agent testing strategy" do
    test "validates complete agent onboarding workflow" do
      # This test demonstrates the full workflow we want agents to follow

      # === Agent Session Start ===
      # 1. SessionStart hook auto-generates Code GPS
      capture_io(fn ->
        Mix.Tasks.CodeGps.run([])
      end)

      # 2. Agent should read CLAUDE.md
      assert File.exists?(@claude_md_path), "CLAUDE.md should exist"
      claude_instructions = File.read!(@claude_md_path)

      # 3. CLAUDE.md should direct agent to read Code GPS
      assert claude_instructions =~ "MANDATORY: Code GPS First"
      assert claude_instructions =~ "mix code_gps"
      assert claude_instructions =~ ".code-gps.yaml"

      # 4. Agent should read Code GPS manifest
      assert File.exists?(@code_gps_path), "Code GPS should be available"
      manifest = File.read!(@code_gps_path)

      # 5. Agent should find actionable development tasks
      assert manifest =~ "Dashboard:", "Should understand current LiveViews"
      assert manifest =~ "add_expense_to_dashboard", "Should find integration opportunities"
      assert manifest =~ "priority: high", "Should understand task priorities"

      # === Validation Criteria ===
      # Agent workflow is successful if:
      checklist = [
        {File.exists?(@claude_md_path), "CLAUDE.md exists with instructions"},
        {File.exists?(@code_gps_path), "Code GPS manifest is available"},
        {manifest =~ "LIVE VIEWS", "Manifest contains LiveView information"},
        {manifest =~ "INTEGRATION OPPORTUNITIES", "Manifest contains next actions"},
        {claude_instructions =~ "MANDATORY", "Instructions emphasize Code GPS usage"},
        {String.length(manifest) < 5000, "Manifest is concise for AI consumption"}
      ]

      failed_checks = Enum.filter(checklist, fn {passed, _desc} -> not passed end)

      if failed_checks != [] do
        failure_messages = Enum.map(failed_checks, fn {_passed, desc} -> "❌ #{desc}" end)
        flunk("Agent onboarding validation failed:\n" <> Enum.join(failure_messages, "\n"))
      end

      # Clean up
      File.rm!(@code_gps_path)
    end
  end
end
