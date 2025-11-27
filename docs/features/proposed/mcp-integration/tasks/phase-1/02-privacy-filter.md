# Task: Privacy Filter Implementation

**Phase**: 1 - Core MCP Tools
**Priority**: P0 (Blocking)
**Estimate**: 4-6 hours
**Status**: Complete

## Objective

Implement the `PrivacyFilter` module that intercepts all MCP tool results and filters them based on the configured privacy mode.

## Prerequisites

- [ ] Task 01 (Router Setup) complete
- [ ] Understanding of privacy mode requirements

## Acceptance Criteria

### Functional Requirements

1. Four privacy modes supported: `:strict`, `:anonymized`, `:standard`, `:full`
2. Default mode is `:anonymized`
3. Mode read from application configuration
4. All tool results pass through filter before returning
5. Filter behavior differs per mode and tool type

### Non-Functional Requirements

1. Filter processing < 5ms for typical results
2. No sensitive data leakage in `:strict` or `:anonymized` modes
3. Comprehensive test coverage for all modes

## TDD Test Cases

### Test File: `test/ashfolio_web/mcp/privacy_filter_test.exs`

```elixir
defmodule AshfolioWeb.Mcp.PrivacyFilterTest do
  use Ashfolio.DataCase, async: true

  alias AshfolioWeb.Mcp.PrivacyFilter

  # Test data fixtures
  @sample_accounts [
    %{
      id: "uuid-1",
      name: "Fidelity 401k",
      type: :investment,
      balance: Decimal.new("125432.17"),
      holdings: [%{symbol: "VTI", shares: 100}, %{symbol: "VXUS", shares: 50}]
    },
    %{
      id: "uuid-2",
      name: "Chase Checking",
      type: :checking,
      balance: Decimal.new("8500.00"),
      holdings: []
    }
  ]

  @sample_transactions [
    %{
      id: "txn-1",
      type: :buy,
      symbol: "VTI",
      quantity: Decimal.new("10"),
      price: Decimal.new("250.00"),
      total_amount: Decimal.new("2500.00"),
      date: ~D[2024-06-15],
      account_name: "Fidelity 401k"
    }
  ]

  describe "current_mode/0" do
    test "returns configured mode" do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :strict)
      assert PrivacyFilter.current_mode() == :strict
    end

    test "defaults to :anonymized when not configured" do
      Application.delete_env(:ashfolio, :mcp)
      assert PrivacyFilter.current_mode() == :anonymized
    end
  end

  describe "filter_result/3 with :strict mode" do
    setup do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :strict)
      :ok
    end

    test "accounts become count and total only" do
      result = PrivacyFilter.filter_result(@sample_accounts, :list_accounts)

      assert result.account_count == 2
      assert Map.has_key?(result, :total_value)
      refute Map.has_key?(result, :accounts)
      refute result |> inspect() |> String.contains?("Fidelity")
      refute result |> inspect() |> String.contains?("125432")
    end

    test "transactions become summary only" do
      result = PrivacyFilter.filter_result(@sample_transactions, :list_transactions)

      assert result.transaction_count == 1
      assert Map.has_key?(result, :by_type)
      refute result |> inspect() |> String.contains?("VTI")
      refute result |> inspect() |> String.contains?("2500")
    end
  end

  describe "filter_result/3 with :anonymized mode" do
    setup do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :anonymized)
      :ok
    end

    test "account names become letter IDs" do
      result = PrivacyFilter.filter_result(@sample_accounts, :list_accounts)

      account_ids = Enum.map(result.accounts, & &1.id)
      assert "A" in account_ids
      assert "B" in account_ids
      refute Enum.any?(result.accounts, &(&1[:name] == "Fidelity 401k"))
    end

    test "balances become weights" do
      result = PrivacyFilter.filter_result(@sample_accounts, :list_accounts)

      weights = Enum.map(result.accounts, & &1.weight)
      assert_in_delta Enum.sum(weights), 1.0, 0.01
      refute result |> inspect() |> String.contains?("125432")
    end

    test "net worth becomes tier" do
      result = PrivacyFilter.filter_result(@sample_accounts, :list_accounts)

      assert result.portfolio.value_tier in [:five_figures, :six_figures, :seven_figures]
    end

    test "symbols become asset classes" do
      result = PrivacyFilter.filter_result(@sample_accounts, :list_accounts)

      first_account = hd(result.accounts)
      assert Map.has_key?(first_account, :asset_classes)
      refute first_account |> inspect() |> String.contains?("VTI")
    end

    test "dates become relative strings" do
      result = PrivacyFilter.filter_result(@sample_transactions, :list_transactions)

      assert result.summary.date_range.oldest_relative =~ ~r/(ago|today|yesterday)/
    end

    test "ratios pass through unchanged" do
      input = %{
        savings_rate: 0.22,
        debt_to_income: 0.15,
        total_value: Decimal.new("100000")
      }

      result = PrivacyFilter.filter_result(input, :get_portfolio_summary)

      assert result.ratios.savings_rate == 0.22
      assert result.ratios.debt_to_income == 0.15
    end
  end

  describe "filter_result/3 with :standard mode" do
    setup do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :standard)
      :ok
    end

    test "account names are included" do
      result = PrivacyFilter.filter_result(@sample_accounts, :list_accounts)

      names = Enum.map(result.accounts, & &1.name)
      assert "Fidelity 401k" in names
    end

    test "exact balances still hidden" do
      result = PrivacyFilter.filter_result(@sample_accounts, :list_accounts)

      # Standard shows names but not exact amounts
      refute result |> inspect() |> String.contains?("125432.17")
    end

    test "transaction summaries include account names" do
      result = PrivacyFilter.filter_result(@sample_transactions, :list_transactions)

      assert result |> inspect() |> String.contains?("Fidelity")
    end
  end

  describe "filter_result/3 with :full mode" do
    setup do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :full)
      :ok
    end

    test "returns unfiltered data" do
      result = PrivacyFilter.filter_result(@sample_accounts, :list_accounts)

      assert result == @sample_accounts
    end

    test "all sensitive data included" do
      result = PrivacyFilter.filter_result(@sample_accounts, :list_accounts)

      assert result |> inspect() |> String.contains?("Fidelity 401k")
      assert result |> inspect() |> String.contains?("125432.17")
      assert result |> inspect() |> String.contains?("VTI")
    end
  end

  describe "mode_allows?/2" do
    test ":strict allows only aggregate tools" do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :strict)

      assert PrivacyFilter.mode_allows?(:get_portfolio_summary, :strict)
      refute PrivacyFilter.mode_allows?(:list_transactions, :strict)
    end

    test ":full allows all tools" do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :full)

      assert PrivacyFilter.mode_allows?(:list_accounts, :full)
      assert PrivacyFilter.mode_allows?(:list_transactions, :full)
      assert PrivacyFilter.mode_allows?(:calculate_tax_lots, :full)
    end
  end

  describe "edge cases" do
    test "empty list returns empty result" do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :anonymized)

      result = PrivacyFilter.filter_result([], :list_accounts)

      assert result.accounts == []
      assert result.portfolio.account_count == 0
    end

    test "nil input handled gracefully" do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :anonymized)

      result = PrivacyFilter.filter_result(nil, :list_accounts)

      assert result == %{accounts: [], portfolio: %{account_count: 0}}
    end

    test "unknown tool type passes through with warning" do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :anonymized)

      # Should log warning but not crash
      result = PrivacyFilter.filter_result(%{foo: "bar"}, :unknown_tool)

      assert result == %{foo: "bar"}
    end
  end
end
```

## Implementation Steps

### Step 1: Create Privacy Filter Module

```elixir
# lib/ashfolio_web/mcp/privacy_filter.ex

defmodule AshfolioWeb.Mcp.PrivacyFilter do
  @moduledoc """
  Filters MCP tool results based on configured privacy mode.
  Prevents accidental exposure of sensitive financial data to cloud LLMs.
  """

  require Logger

  alias AshfolioWeb.Mcp.Anonymizer

  @type privacy_mode :: :strict | :anonymized | :standard | :full

  @doc """
  Get the currently configured privacy mode.
  """
  @spec current_mode() :: privacy_mode()
  def current_mode do
    Application.get_env(:ashfolio, :mcp, [])
    |> Keyword.get(:privacy_mode, :anonymized)
  end

  @doc """
  Filter tool result based on privacy mode.
  """
  @spec filter_result(any(), atom(), keyword()) :: any()
  def filter_result(result, tool_name, opts \\ []) do
    mode = Keyword.get(opts, :mode, current_mode())

    case mode do
      :strict -> apply_strict_filter(result, tool_name)
      :anonymized -> Anonymizer.anonymize(result, tool_name)
      :standard -> apply_standard_filter(result, tool_name)
      :full -> result
    end
  end

  @doc """
  Check if the current mode allows a specific tool.
  """
  @spec mode_allows?(atom(), privacy_mode()) :: boolean()
  def mode_allows?(tool_name, mode) do
    case mode do
      :strict -> tool_name in [:get_portfolio_summary, :calculate_money_ratios]
      :anonymized -> true  # All tools allowed, just filtered
      :standard -> true
      :full -> true
    end
  end

  # Private implementation

  defp apply_strict_filter(nil, _tool_name), do: %{accounts: [], portfolio: %{account_count: 0}}
  defp apply_strict_filter([], :list_accounts), do: %{account_count: 0, total_value: 0}

  defp apply_strict_filter(accounts, :list_accounts) when is_list(accounts) do
    total = accounts
      |> Enum.map(& &1.balance)
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

    %{
      account_count: length(accounts),
      total_value: value_tier(total),
      allocation: calculate_allocation_percentages(accounts, total)
    }
  end

  defp apply_strict_filter(transactions, :list_transactions) when is_list(transactions) do
    %{
      transaction_count: length(transactions),
      by_type: Enum.frequencies_by(transactions, & &1.type),
      date_range: %{
        span_days: calculate_date_span(transactions)
      }
    }
  end

  defp apply_strict_filter(result, tool_name) do
    Logger.warning("No strict filter defined for #{tool_name}, passing through")
    result
  end

  defp apply_standard_filter(nil, _tool_name), do: nil
  defp apply_standard_filter([], _tool_name), do: []

  defp apply_standard_filter(accounts, :list_accounts) when is_list(accounts) do
    # Include names but not exact balances
    Enum.map(accounts, fn acc ->
      %{
        name: acc.name,
        type: acc.type,
        weight: calculate_weight(acc.balance, total_balance(accounts)),
        holding_count: length(acc.holdings || [])
      }
    end)
  end

  defp apply_standard_filter(transactions, :list_transactions) when is_list(transactions) do
    Enum.map(transactions, fn txn ->
      %{
        type: txn.type,
        account_name: txn.account_name,
        date: txn.date,
        category: Map.get(txn, :category, "Uncategorized")
      }
    end)
  end

  defp apply_standard_filter(result, _tool_name), do: result

  # Helpers

  defp value_tier(amount) do
    amount_float = Decimal.to_float(amount)
    cond do
      amount_float < 10_000 -> :under_10k
      amount_float < 100_000 -> :five_figures
      amount_float < 1_000_000 -> :six_figures
      amount_float < 10_000_000 -> :seven_figures
      true -> :eight_figures_plus
    end
  end

  defp calculate_allocation_percentages(accounts, total) do
    accounts
    |> Enum.map(fn acc ->
      {acc.type, calculate_weight(acc.balance, total)}
    end)
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Map.new(fn {type, weights} -> {type, Float.round(Enum.sum(weights), 2)} end)
  end

  defp calculate_weight(balance, total) do
    if Decimal.compare(total, 0) == :gt do
      balance |> Decimal.div(total) |> Decimal.to_float() |> Float.round(2)
    else
      0.0
    end
  end

  defp total_balance(accounts) do
    accounts
    |> Enum.map(& &1.balance)
    |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  end

  defp calculate_date_span([]), do: 0
  defp calculate_date_span(transactions) do
    dates = Enum.map(transactions, & &1.date)
    Date.diff(Enum.max(dates, Date), Enum.min(dates, Date))
  end
end
```

### Step 2: Run Tests

```bash
mix test test/ashfolio_web/mcp/privacy_filter_test.exs --trace
```

### Step 3: Wire Into MCP Server (Later Task)

The privacy filter will be called from a custom wrapper around AshAi.Mcp.Server in a later task.

## Definition of Done

- [ ] All TDD tests pass
- [ ] Privacy filter module created
- [ ] Four modes implemented: strict, anonymized, standard, full
- [ ] Default mode is :anonymized
- [ ] Edge cases handled (nil, empty, unknown)
- [ ] No compilation warnings
- [ ] `mix test` passes (no regressions)

## Dependencies

**Blocked By**: Task 01 (Router Setup)
**Blocks**: Task 03 (Anonymizer), Task 04 (Core Tools)

## Notes

- Anonymizer is a separate module (Task 03)
- Privacy filter delegates to Anonymizer for :anonymized mode
- Consider adding metrics for filter performance

---

*Parent: [../README.md](../README.md)*
