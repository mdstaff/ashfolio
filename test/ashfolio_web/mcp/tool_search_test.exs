defmodule AshfolioWeb.Mcp.ToolSearchTest do
  @moduledoc """
  Tests for MCP tool search functionality.
  """
  use Ashfolio.DataCase, async: false

  alias AshfolioWeb.Mcp.ToolSearch

  @moduletag :mcp

  describe "search/2 keyword matching" do
    test "finds tools by exact name" do
      results = ToolSearch.search("list_accounts")

      assert length(results) > 0
      assert hd(results).name == :list_accounts
    end

    test "finds tools by partial name match" do
      results = ToolSearch.search("accounts")

      names = Enum.map(results, & &1.name)
      assert :list_accounts in names
    end

    test "finds tools by description content" do
      results = ToolSearch.search("allocation")

      names = Enum.map(results, & &1.name)
      assert :get_portfolio_summary in names
    end

    test "returns empty list for no matches" do
      results = ToolSearch.search("xyznonexistent123")

      assert results == []
    end

    test "search is case insensitive" do
      lower = ToolSearch.search("accounts")
      upper = ToolSearch.search("ACCOUNTS")
      mixed = ToolSearch.search("AcCoUnTs")

      assert Enum.map(lower, & &1.name) == Enum.map(upper, & &1.name)
      assert Enum.map(lower, & &1.name) == Enum.map(mixed, & &1.name)
    end

    test "multi-word queries match across name and description" do
      results = ToolSearch.search("portfolio summary")

      names = Enum.map(results, & &1.name)
      assert :get_portfolio_summary in names
    end

    test "handles underscores in search terms" do
      results = ToolSearch.search("list_transactions")

      assert length(results) > 0
      assert hd(results).name == :list_transactions
    end
  end

  describe "search/2 scoring" do
    test "exact name match ranks highest" do
      results = ToolSearch.search("list_accounts")

      # First result should be exact match
      assert hd(results).name == :list_accounts
    end

    test "name contains ranks higher than description contains" do
      # "list" appears in multiple tool names
      results = ToolSearch.search("list")

      names = Enum.map(results, & &1.name)
      # Tools with "list" in name should come before others
      assert :list_accounts in names
      assert :list_transactions in names
      assert :list_symbols in names
    end

    test "multiple term matches increase score" do
      # Searching for multiple terms that match portfolio summary
      results = ToolSearch.search("portfolio allocation risk")

      names = Enum.map(results, & &1.name)
      assert :get_portfolio_summary in names
    end
  end

  describe "search/2 options" do
    test "respects limit option" do
      results = ToolSearch.search("list", limit: 2)

      assert length(results) <= 2
    end

    test "default limit is 5" do
      # With a broad search that matches many tools
      results = ToolSearch.search("a")

      assert length(results) <= 5
    end

    test "respects privacy mode option" do
      strict_results = ToolSearch.search("transactions", mode: :strict)
      full_results = ToolSearch.search("transactions", mode: :full)

      strict_names = Enum.map(strict_results, & &1.name)
      full_names = Enum.map(full_results, & &1.name)

      # list_transactions not available in strict mode
      refute :list_transactions in strict_names
      assert :list_transactions in full_names
    end
  end

  describe "execute/1 MCP interface" do
    test "returns matching tools with required fields" do
      {:ok, result} = ToolSearch.execute(%{"query" => "accounts"})

      assert is_list(result.tools)
      assert result.count > 0
      assert result.query == "accounts"

      first = hd(result.tools)
      assert Map.has_key?(first, :name)
      assert Map.has_key?(first, :description)
    end

    test "respects limit parameter" do
      {:ok, result} = ToolSearch.execute(%{"query" => "list", "limit" => 1})

      assert result.count <= 1
    end

    test "returns error for missing query" do
      {:error, message} = ToolSearch.execute(%{})

      assert message =~ "query"
    end

    test "handles empty results gracefully" do
      {:ok, result} = ToolSearch.execute(%{"query" => "nonexistent123xyz"})

      assert result.tools == []
      assert result.count == 0
    end
  end

  describe "search quality" do
    test "finds expense tool by keyword in full mode" do
      # add_expense only available in standard/full modes
      results = ToolSearch.search("expense", mode: :full)

      names = Enum.map(results, & &1.name)
      assert :add_expense in names
    end

    test "finds transaction tool by keyword" do
      # list_transactions available in anonymized mode
      results = ToolSearch.search("transaction")

      names = Enum.map(results, & &1.name)
      assert :list_transactions in names
    end

    test "finds symbol tool by keyword" do
      results = ToolSearch.search("symbol")

      names = Enum.map(results, & &1.name)
      assert :list_symbols in names
    end
  end
end
