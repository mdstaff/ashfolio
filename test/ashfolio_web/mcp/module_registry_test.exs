defmodule AshfolioWeb.Mcp.ModuleRegistryTest do
  @moduledoc """
  Tests for the MCP Module Registry.

  The registry discovers tools from Ash domains and parseable modules,
  and provides lookup and filtering capabilities.
  """
  use Ashfolio.DataCase, async: false

  @moduletag :mcp

  alias AshfolioWeb.Mcp.ModuleRegistry

  # Note: The registry is started by the application supervisor,
  # so we don't need to start it in tests.

  describe "all_tools/0" do
    test "returns list of discovered tools" do
      tools = ModuleRegistry.all_tools()

      assert is_list(tools)
      assert length(tools) >= 6
    end

    test "includes tools from Portfolio domain" do
      tools = ModuleRegistry.all_tools()
      names = Enum.map(tools, & &1.name)

      assert :list_accounts in names
      assert :list_transactions in names
      assert :list_symbols in names
      assert :get_portfolio_summary in names
    end

    test "includes parseable tools" do
      tools = ModuleRegistry.all_tools()
      names = Enum.map(tools, & &1.name)

      assert :add_expense in names
      assert :add_transaction in names
    end

    test "each tool has required fields" do
      tools = ModuleRegistry.all_tools()

      for tool <- tools do
        assert Map.has_key?(tool, :name)
        assert Map.has_key?(tool, :description)
        assert Map.has_key?(tool, :source)
        assert Map.has_key?(tool, :privacy_modes)
        assert is_atom(tool.name)
        assert is_binary(tool.description)
        assert tool.source in [:ash_domain, :parseable, :runtime]
        assert is_list(tool.privacy_modes)
      end
    end
  end

  describe "find_tool/1" do
    test "returns {:ok, tool} for existing tool" do
      assert {:ok, tool} = ModuleRegistry.find_tool(:list_accounts)

      assert tool.name == :list_accounts
      assert tool.source == :ash_domain
      assert is_binary(tool.description)
    end

    test "returns :error for non-existent tool" do
      assert :error = ModuleRegistry.find_tool(:nonexistent_tool)
    end

    test "finds parseable tools" do
      assert {:ok, tool} = ModuleRegistry.find_tool(:add_expense)

      assert tool.name == :add_expense
    end

    test "tool includes domain and action info for ash_domain tools" do
      assert {:ok, tool} = ModuleRegistry.find_tool(:list_accounts)

      assert tool.domain == Ashfolio.Portfolio
      assert tool.action == :list_accounts_filtered
      assert tool.resource == AshfolioWeb.Mcp.Tools
    end
  end

  describe "tools_for_mode/1" do
    test "returns only tools available in strict mode" do
      tools = ModuleRegistry.tools_for_mode(:strict)
      names = Enum.map(tools, & &1.name)

      # list_symbols is available in all modes
      assert :list_symbols in names

      # These should NOT be in strict mode
      refute :add_expense in names
      refute :add_transaction in names
    end

    test "returns more tools in anonymized mode" do
      strict_tools = ModuleRegistry.tools_for_mode(:strict)
      anon_tools = ModuleRegistry.tools_for_mode(:anonymized)

      assert length(anon_tools) >= length(strict_tools)
    end

    test "returns all tools in full mode" do
      full_tools = ModuleRegistry.tools_for_mode(:full)
      all_tools = ModuleRegistry.all_tools()

      assert length(full_tools) == length(all_tools)
    end

    test "validates mode parameter" do
      assert is_list(ModuleRegistry.tools_for_mode(:strict))
      assert is_list(ModuleRegistry.tools_for_mode(:anonymized))
      assert is_list(ModuleRegistry.tools_for_mode(:standard))
      assert is_list(ModuleRegistry.tools_for_mode(:full))
    end

    test "each returned tool includes the requested mode in privacy_modes" do
      for mode <- [:strict, :anonymized, :standard, :full] do
        tools = ModuleRegistry.tools_for_mode(mode)

        for tool <- tools do
          assert mode in tool.privacy_modes,
                 "Tool #{tool.name} returned for mode #{mode} but doesn't include it in privacy_modes"
        end
      end
    end
  end

  describe "register_tool/2" do
    test "registers a new runtime tool" do
      initial_count = length(ModuleRegistry.all_tools())

      :ok = ModuleRegistry.register_tool(:test_tool, %{description: "A test tool"})

      tools = ModuleRegistry.all_tools()
      assert length(tools) == initial_count + 1

      {:ok, tool} = ModuleRegistry.find_tool(:test_tool)
      assert tool.source == :runtime
      assert tool.description == "A test tool"

      # Cleanup
      ModuleRegistry.unregister_tool(:test_tool)
    end

    test "returns error when registering existing discovered tool" do
      assert {:error, message} = ModuleRegistry.register_tool(:list_accounts, %{description: "Duplicate"})
      assert message =~ "already exists"
    end

    test "allows registering tool with same name as previously unregistered" do
      :ok = ModuleRegistry.register_tool(:temp_tool, %{description: "First"})
      :ok = ModuleRegistry.unregister_tool(:temp_tool)
      :ok = ModuleRegistry.register_tool(:temp_tool, %{description: "Second"})

      {:ok, tool} = ModuleRegistry.find_tool(:temp_tool)
      assert tool.description == "Second"

      # Cleanup
      ModuleRegistry.unregister_tool(:temp_tool)
    end
  end

  describe "unregister_tool/1" do
    test "removes a runtime-registered tool" do
      :ok = ModuleRegistry.register_tool(:removable_tool, %{description: "To remove"})
      assert {:ok, _} = ModuleRegistry.find_tool(:removable_tool)

      :ok = ModuleRegistry.unregister_tool(:removable_tool)
      assert :error = ModuleRegistry.find_tool(:removable_tool)
    end

    test "returns error when unregistering discovered tool" do
      assert {:error, message} = ModuleRegistry.unregister_tool(:list_accounts)
      assert message =~ "not found or cannot be unregistered"
    end

    test "returns error when unregistering non-existent tool" do
      assert {:error, _} = ModuleRegistry.unregister_tool(:nonexistent)
    end
  end

  describe "refresh/0" do
    test "re-discovers tools" do
      # This is mostly a smoke test - refresh should not crash
      assert :ok = ModuleRegistry.refresh()

      # Give it time to process
      :timer.sleep(50)

      # Tools should still be available
      tools = ModuleRegistry.all_tools()
      assert length(tools) >= 6
    end

    test "preserves runtime-registered tools after refresh" do
      :ok = ModuleRegistry.register_tool(:preserved_tool, %{description: "Should survive refresh"})

      :ok = ModuleRegistry.refresh()
      :timer.sleep(50)

      assert {:ok, _} = ModuleRegistry.find_tool(:preserved_tool)

      # Cleanup
      ModuleRegistry.unregister_tool(:preserved_tool)
    end
  end

  describe "privacy mode inference" do
    test "list_symbols is available in all modes" do
      {:ok, tool} = ModuleRegistry.find_tool(:list_symbols)

      assert :strict in tool.privacy_modes
      assert :anonymized in tool.privacy_modes
      assert :standard in tool.privacy_modes
      assert :full in tool.privacy_modes
    end

    test "add_expense is only available in standard/full modes" do
      {:ok, tool} = ModuleRegistry.find_tool(:add_expense)

      refute :strict in tool.privacy_modes
      refute :anonymized in tool.privacy_modes
      assert :standard in tool.privacy_modes
      assert :full in tool.privacy_modes
    end

    test "list_accounts is available in anonymized and above" do
      {:ok, tool} = ModuleRegistry.find_tool(:list_accounts)

      refute :strict in tool.privacy_modes
      assert :anonymized in tool.privacy_modes
      assert :standard in tool.privacy_modes
      assert :full in tool.privacy_modes
    end
  end
end
