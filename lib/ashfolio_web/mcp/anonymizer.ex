defmodule AshfolioWeb.Mcp.Anonymizer do
  @moduledoc """
  Transforms financial data into anonymized form for cloud LLM analysis.
  Preserves analytical value (ratios, percentages, patterns) while removing
  sensitive identifiers (names, exact amounts, symbols).

  ## Transformations

  - Account names → Letter IDs (A, B, C...)
  - Balances → Relative weights (sum to 1.0)
  - Net worth → Tier enum (:five_figures, :six_figures, etc.)
  - Symbols → Asset class categories
  - Dates → Relative strings ("3 months ago")
  - Ratios/percentages → Pass through unchanged
  """

  @value_tiers [
    {:under_10k, 0, 10_000},
    {:five_figures, 10_000, 100_000},
    {:six_figures, 100_000, 1_000_000},
    {:seven_figures, 1_000_000, 10_000_000},
    {:eight_figures_plus, 10_000_000, :infinity}
  ]

  # Symbol to asset class mapping
  @symbol_asset_classes %{
    # US Total Market
    "VTI" => :us_equity,
    "ITOT" => :us_equity,
    "SPTM" => :us_equity,
    "VOO" => :us_equity,
    "SPY" => :us_equity,
    # International
    "VXUS" => :intl_equity,
    "IXUS" => :intl_equity,
    "VEA" => :intl_equity,
    "VWO" => :intl_equity,
    # Bonds
    "BND" => :bonds,
    "AGG" => :bonds,
    "VBTLX" => :bonds,
    # Real Estate
    "VNQ" => :real_estate,
    "SCHH" => :real_estate
  }

  @default_asset_class :other_equity

  # =============================================================================
  # Public API
  # =============================================================================

  @doc """
  Anonymize data based on tool type.
  """
  def anonymize(data, tool_name)

  def anonymize([], :list_accounts) do
    %{
      accounts: [],
      portfolio: %{
        value_tier: :under_10k,
        account_count: 0,
        concentration: :well_distributed,
        diversification_score: 0.0
      }
    }
  end

  def anonymize(accounts, :list_accounts) when is_list(accounts) do
    total = sum_balances(accounts)

    %{
      accounts:
        accounts
        |> Enum.with_index()
        |> Enum.map(fn {acc, idx} -> anonymize_account(acc, idx, total) end),
      portfolio: %{
        value_tier: value_to_tier(total),
        account_count: length(accounts),
        concentration: concentration_level(accounts, total),
        diversification_score: calculate_diversification(accounts)
      }
    }
  end

  def anonymize([], :list_transactions) do
    %{
      summary: %{count: 0, date_range: %{}, by_type: %{}},
      patterns: %{}
    }
  end

  def anonymize(transactions, :list_transactions) when is_list(transactions) do
    %{
      summary: %{
        count: length(transactions),
        date_range: calculate_date_range(transactions),
        by_type: Enum.frequencies_by(transactions, & &1.type)
      },
      patterns: %{
        avg_transaction_tier: avg_amount_tier(transactions),
        frequency: transaction_frequency(transactions),
        categories: category_breakdown(transactions)
      }
    }
  end

  def anonymize(summary, :get_portfolio_summary) when is_map(summary) do
    %{
      value_tier: value_to_tier(summary.total_value),
      allocation: summary.allocation,
      metrics: %{
        ytd_return_pct: summary.ytd_return,
        diversification_score: summary.diversification,
        risk_level: summary.risk_level
      },
      ratios: Map.take(summary, [:savings_rate, :debt_to_income, :expense_ratio])
    }
  end

  def anonymize(data, _tool_name), do: data

  # =============================================================================
  # Public Helpers (for testing)
  # =============================================================================

  @doc """
  Convert a monetary value to a tier enum.
  """
  def value_to_tier(nil), do: :under_10k

  def value_to_tier(amount) when is_struct(amount, Decimal) do
    amount_float = Decimal.to_float(amount)
    value_to_tier_float(amount_float)
  end

  def value_to_tier(amount) when is_number(amount), do: value_to_tier_float(amount)

  @doc """
  Convert a date to a relative string.
  """
  def days_ago(date) do
    diff = Date.diff(Date.utc_today(), date)

    cond do
      diff == 0 -> "today"
      diff == 1 -> "yesterday"
      diff < 7 -> "#{diff} days ago"
      diff < 30 -> "#{div(diff, 7)} weeks ago"
      diff < 365 -> "#{div(diff, 30)} months ago"
      true -> "#{div(diff, 365)} years ago"
    end
  end

  # =============================================================================
  # Private Functions
  # =============================================================================

  defp value_to_tier_float(amount) when amount < 0, do: :under_10k

  defp value_to_tier_float(amount) do
    Enum.find_value(@value_tiers, :under_10k, fn {tier, min, max} ->
      max_check = if max == :infinity, do: true, else: amount < max
      if amount >= min && max_check, do: tier
    end)
  end

  defp anonymize_account(account, index, total) do
    %{
      id: account_id(index),
      type: anonymize_account_type(account),
      weight: calculate_weight(account.balance, total),
      asset_classes: anonymize_holdings(account[:holdings])
    }
  end

  defp account_id(index) when index < 26, do: <<?A + index>>
  defp account_id(index), do: "Account#{index + 1}"

  defp anonymize_account_type(%{type: type, name: name}) do
    name_lower = String.downcase(name || "")

    cond do
      String.contains?(name_lower, "401k") -> :retirement_401k
      String.contains?(name_lower, "403b") -> :retirement_403b
      String.contains?(name_lower, "roth") and String.contains?(name_lower, "ira") -> :retirement_roth_ira
      String.contains?(name_lower, "ira") -> :retirement_ira
      type == :checking -> :checking
      type == :savings -> :savings
      type in [:investment, :brokerage] -> :taxable_investment
      true -> :other
    end
  end

  defp anonymize_account_type(%{type: type}), do: type
  defp anonymize_account_type(_), do: :other

  defp anonymize_holdings(nil), do: %{cash: 1.0}
  defp anonymize_holdings([]), do: %{cash: 1.0}

  defp anonymize_holdings(holdings) do
    total_value =
      holdings
      |> Enum.map(& &1.value)
      |> Enum.reduce(Decimal.new(0), &safe_add/2)

    if Decimal.compare(total_value, 0) == :gt do
      holdings
      |> Enum.map(fn h ->
        asset_class = Map.get(@symbol_asset_classes, h.symbol, @default_asset_class)
        weight = h.value |> Decimal.div(total_value) |> Decimal.to_float() |> Float.round(2)
        {asset_class, weight}
      end)
      |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
      |> Map.new(fn {class, weights} -> {class, Float.round(Enum.sum(weights), 2)} end)
    else
      %{cash: 1.0}
    end
  end

  defp sum_balances(accounts) do
    accounts
    |> Enum.map(& &1.balance)
    |> Enum.reduce(Decimal.new(0), &safe_add/2)
  end

  defp safe_add(a, b) do
    Decimal.add(a || Decimal.new(0), b || Decimal.new(0))
  end

  defp calculate_weight(balance, total) do
    if Decimal.compare(total, 0) == :gt do
      balance
      |> Decimal.div(total)
      |> Decimal.to_float()
      |> Float.round(2)
    else
      0.0
    end
  end

  defp concentration_level(accounts, total) do
    max_weight =
      accounts
      |> Enum.map(&calculate_weight(&1.balance, total))
      |> Enum.max(fn -> 0 end)

    cond do
      max_weight >= 0.8 -> :very_high
      max_weight >= 0.6 -> :high
      max_weight >= 0.4 -> :moderate
      true -> :well_distributed
    end
  end

  defp calculate_diversification(accounts) do
    n = length(accounts)

    if n == 0 do
      0.0
    else
      # Herfindahl-Hirschman Index inverted
      total = sum_balances(accounts)

      hhi =
        accounts
        |> Enum.map(fn a ->
          w = calculate_weight(a.balance, total)
          w * w
        end)
        |> Enum.sum()

      # Convert HHI to 0-1 score (lower HHI = more diverse)
      Float.round(1 - hhi, 2)
    end
  end

  defp calculate_date_range([]), do: %{}

  defp calculate_date_range(transactions) do
    dates = Enum.map(transactions, & &1.date)
    min_date = Enum.min(dates, Date)
    max_date = Enum.max(dates, Date)

    %{
      span_days: Date.diff(max_date, min_date),
      oldest_relative: days_ago(min_date),
      newest_relative: days_ago(max_date)
    }
  end

  defp avg_amount_tier(transactions) do
    if Enum.empty?(transactions) do
      :under_10k
    else
      avg =
        transactions
        |> Enum.map(&Decimal.to_float(&1.total_amount))
        |> then(&(Enum.sum(&1) / length(&1)))

      value_to_tier_float(avg)
    end
  end

  defp transaction_frequency(transactions) do
    count = length(transactions)

    cond do
      count == 0 -> :none
      count < 5 -> :low
      count < 20 -> :moderate
      count < 50 -> :high
      true -> :very_high
    end
  end

  defp category_breakdown(transactions) do
    transactions
    |> Enum.group_by(&Map.get(&1, :category, "Uncategorized"))
    |> Map.new(fn {cat, txns} -> {cat, length(txns)} end)
  end
end
