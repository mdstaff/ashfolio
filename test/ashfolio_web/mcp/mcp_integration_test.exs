defmodule AshfolioWeb.Mcp.McpIntegrationTest do
  @moduledoc """
  Integration tests for MCP components.

  Tests interaction between MCP modules:
  - Tool discovery via Module Registry
  - Two-phase tool execution flow
  - Privacy filtering
  """
  use Ashfolio.DataCase, async: false

  @moduletag :mcp

  alias AshfolioWeb.Mcp.ModuleRegistry
  alias AshfolioWeb.Mcp.ParserToolExecutor
  alias AshfolioWeb.Mcp.PrivacyFilter

  test "module registry discovers all expected tools" do
    tools = ModuleRegistry.all_tools()
    names = Enum.map(tools, & &1.name)

    # Core tools from Phase 1
    assert :list_accounts in names
    assert :list_transactions in names
    assert :list_symbols in names
    assert :get_portfolio_summary in names

    # Parseable tools from Phase 2
    assert :add_expense in names
    assert :add_transaction in names

    # Tool search from Phase 2
    assert :search_tools in names
  end

  test "two-phase expense flow: guidance then execution" do
    # Phase 1: Get schema guidance
    {:guidance, guidance} = ParserToolExecutor.execute(:add_expense, %{"text" => "lunch $15"})

    assert guidance.needs_structure == true
    assert is_map(guidance.schema)
    assert "amount" in guidance.schema.required

    # Phase 2: Execute with structured data
    {:ok, expense} =
      ParserToolExecutor.execute(:add_expense, %{
        "expense" => %{
          "amount" => "$15",
          "category" => "Food",
          "date" => "2024-01-15",
          "description" => "Lunch"
        }
      })

    assert Decimal.equal?(expense.amount, Decimal.new("15"))
    assert expense.description == "Lunch"
  end

  test "privacy filter anonymizes account data" do
    # Set privacy mode for this test
    Application.put_env(:ashfolio, :mcp, privacy_mode: :anonymized)

    # Create test account data directly (don't rely on database state)
    account_maps = [
      %{
        name: "Test Brokerage",
        type: :investment,
        balance: Decimal.new("50000"),
        holdings: []
      }
    ]

    # Apply anonymized filtering
    filtered = PrivacyFilter.filter_result(account_maps, :list_accounts)

    # Account names should be replaced with letter IDs
    assert Map.has_key?(filtered, :accounts)
    assert Map.has_key?(filtered, :portfolio)

    # First account should have letter ID "A"
    [first | _] = filtered.accounts
    assert first.id == "A"
    refute Map.has_key?(first, :name)

    # Portfolio should show value tier, not exact amount
    assert filtered.portfolio.value_tier in [:under_10k, :five_figures, :six_figures]
  end

  test "tools_for_mode returns appropriate tools per privacy level" do
    strict_tools = ModuleRegistry.tools_for_mode(:strict)
    full_tools = ModuleRegistry.tools_for_mode(:full)

    # Strict mode should have fewer tools
    assert length(strict_tools) < length(full_tools)

    # Full mode should include all tools
    assert length(full_tools) == length(ModuleRegistry.all_tools())

    # list_symbols should be in strict (non-sensitive)
    strict_names = Enum.map(strict_tools, & &1.name)
    assert :list_symbols in strict_names
  end
end
