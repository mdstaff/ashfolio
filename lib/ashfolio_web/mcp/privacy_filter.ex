defmodule AshfolioWeb.Mcp.PrivacyFilter do
  @moduledoc """
  Filters MCP tool results based on configured privacy mode.
  Prevents accidental exposure of sensitive financial data to cloud LLMs.

  ## Privacy Modes

  - `:strict` - Only aggregate data (counts, tiers). No names, amounts, or symbols.
  - `:anonymized` - Names become letter IDs, amounts become weights/tiers. Default mode.
  - `:standard` - Names included, but amounts hidden. Good for local LLMs.
  - `:full` - No filtering. Only for trusted, local environments.

  See: docs/features/proposed/mcp-integration/decisions/ADR-MCP-001-privacy-modes.md
  """

  require Logger

  @type privacy_mode :: :strict | :anonymized | :standard | :full

  @aggregate_only_tools [:get_portfolio_summary, :calculate_money_ratios]

  @asset_class_map %{
    "VTI" => "US Total Market",
    "VXUS" => "International",
    "BND" => "Bonds",
    "VNQ" => "Real Estate",
    "AAPL" => "US Large Cap",
    "MSFT" => "US Large Cap",
    "GOOGL" => "US Large Cap"
  }

  @doc """
  Get the currently configured privacy mode.

  Checks Process dictionary first for thread-safe test overrides,
  then falls back to Application configuration.
  """
  @spec current_mode() :: privacy_mode()
  def current_mode do
    case Process.get(:mcp_privacy_mode) do
      nil ->
        :ashfolio
        |> Application.get_env(:mcp, [])
        |> Keyword.get(:privacy_mode, :anonymized)

      mode when mode in [:strict, :anonymized, :standard, :full] ->
        mode

      invalid ->
        Logger.warning("Invalid privacy mode in Process dictionary: #{inspect(invalid)}, using :anonymized")
        :anonymized
    end
  end

  @doc """
  Filter tool result based on privacy mode.
  """
  @spec filter_result(any(), atom(), keyword()) :: any()
  def filter_result(result, tool_name, opts \\ []) do
    mode = Keyword.get(opts, :mode, current_mode())

    case mode do
      :strict -> apply_strict_filter(result, tool_name)
      :anonymized -> apply_anonymized_filter(result, tool_name)
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
      :strict -> tool_name in @aggregate_only_tools
      :anonymized -> true
      :standard -> true
      :full -> true
    end
  end

  # =============================================================================
  # Strict Mode - Only aggregates, no identifying information
  # =============================================================================

  defp apply_strict_filter(nil, _tool_name), do: %{accounts: [], portfolio: %{account_count: 0}}
  defp apply_strict_filter([], :list_accounts), do: %{account_count: 0, total_value: :under_10k}

  defp apply_strict_filter(accounts, :list_accounts) when is_list(accounts) do
    total = sum_balances(accounts)

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

  # =============================================================================
  # Anonymized Mode - Letter IDs, weights, tiers, asset classes
  # =============================================================================

  defp apply_anonymized_filter(nil, :list_accounts) do
    %{accounts: [], portfolio: %{account_count: 0}}
  end

  defp apply_anonymized_filter([], :list_accounts) do
    %{accounts: [], portfolio: %{account_count: 0}}
  end

  defp apply_anonymized_filter(accounts, :list_accounts) when is_list(accounts) do
    total = sum_balances(accounts)

    anonymized_accounts =
      accounts
      |> Enum.with_index()
      |> Enum.map(fn {account, index} ->
        %{
          id: letter_id(index),
          type: account.type,
          weight: calculate_weight(account.balance, total),
          asset_classes: anonymize_holdings(account[:holdings] || [])
        }
      end)

    %{
      accounts: anonymized_accounts,
      portfolio: %{
        account_count: length(accounts),
        value_tier: value_tier(total)
      }
    }
  end

  defp apply_anonymized_filter(transactions, :list_transactions) when is_list(transactions) do
    %{
      transactions:
        Enum.map(transactions, fn txn ->
          %{
            type: txn.type,
            relative_date: relative_date(txn.date)
          }
        end),
      summary: %{
        count: length(transactions),
        by_type: Enum.frequencies_by(transactions, & &1.type),
        date_range: %{
          oldest_relative: oldest_relative_date(transactions)
        }
      }
    }
  end

  defp apply_anonymized_filter(%{savings_rate: _, debt_to_income: _} = input, :get_portfolio_summary) do
    # Ratios pass through - they're already anonymous
    %{
      ratios: %{
        savings_rate: input.savings_rate,
        debt_to_income: input.debt_to_income
      }
    }
  end

  defp apply_anonymized_filter(result, tool_name) do
    Logger.warning("No anonymized filter defined for #{tool_name}, passing through")
    result
  end

  # =============================================================================
  # Standard Mode - Names visible, amounts hidden
  # =============================================================================

  defp apply_standard_filter(nil, _tool_name), do: nil
  defp apply_standard_filter([], _tool_name), do: %{accounts: []}

  defp apply_standard_filter(accounts, :list_accounts) when is_list(accounts) do
    total = sum_balances(accounts)

    %{
      accounts:
        Enum.map(accounts, fn acc ->
          %{
            name: acc.name,
            type: acc.type,
            weight: calculate_weight(acc.balance, total),
            holding_count: length(acc[:holdings] || [])
          }
        end)
    }
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

  # =============================================================================
  # Helper Functions
  # =============================================================================

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

  defp letter_id(index) when index < 26 do
    <<65 + index>>
  end

  defp letter_id(index) do
    "#{letter_id(div(index, 26) - 1)}#{letter_id(rem(index, 26))}"
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

  defp sum_balances(accounts) do
    accounts
    |> Enum.map(& &1.balance)
    |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  end

  defp calculate_date_span([]), do: 0

  defp calculate_date_span(transactions) do
    dates = Enum.map(transactions, & &1.date)
    Date.diff(Enum.max(dates, Date), Enum.min(dates, Date))
  end

  defp anonymize_holdings([]), do: []

  defp anonymize_holdings(holdings) do
    holdings
    |> Enum.map(fn holding ->
      Map.get(@asset_class_map, holding.symbol, "Other")
    end)
    |> Enum.uniq()
  end

  defp relative_date(date) do
    days_ago = Date.diff(Date.utc_today(), date)

    cond do
      days_ago == 0 -> "today"
      days_ago == 1 -> "yesterday"
      days_ago < 7 -> "#{days_ago} days ago"
      days_ago < 30 -> "#{div(days_ago, 7)} weeks ago"
      days_ago < 365 -> "#{div(days_ago, 30)} months ago"
      true -> "#{div(days_ago, 365)} years ago"
    end
  end

  defp oldest_relative_date([]), do: "no transactions"

  defp oldest_relative_date(transactions) do
    oldest = transactions |> Enum.map(& &1.date) |> Enum.min(Date)
    relative_date(oldest)
  end
end
