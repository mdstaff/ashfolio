defmodule AshfolioWeb.Mcp.AnonymizerTest do
  use Ashfolio.DataCase, async: true

  alias AshfolioWeb.Mcp.Anonymizer

  # Fixtures
  @accounts [
    %{
      id: "uuid-1",
      name: "Fidelity 401k",
      type: :investment,
      balance: Decimal.new("125000.00"),
      holdings: [
        %{symbol: "VTI", shares: Decimal.new("100"), value: Decimal.new("25000")},
        %{symbol: "VXUS", shares: Decimal.new("50"), value: Decimal.new("5000")}
      ]
    },
    %{
      id: "uuid-2",
      name: "Vanguard Roth IRA",
      type: :ira,
      balance: Decimal.new("50000.00"),
      holdings: [
        %{symbol: "VTI", shares: Decimal.new("200"), value: Decimal.new("50000")}
      ]
    },
    %{
      id: "uuid-3",
      name: "Chase Checking",
      type: :checking,
      balance: Decimal.new("10000.00"),
      holdings: []
    }
  ]

  @transactions [
    %{
      id: "txn-1",
      type: :buy,
      symbol: "VTI",
      quantity: Decimal.new("10"),
      price: Decimal.new("250.00"),
      total_amount: Decimal.new("2500.00"),
      date: Date.add(Date.utc_today(), -45),
      account_id: "uuid-1"
    },
    %{
      id: "txn-2",
      type: :dividend,
      symbol: "VTI",
      quantity: Decimal.new("0.5"),
      price: Decimal.new("250.00"),
      total_amount: Decimal.new("125.00"),
      date: Date.add(Date.utc_today(), -10),
      account_id: "uuid-1"
    }
  ]

  describe "anonymize/2 for :list_accounts" do
    test "converts account names to letter IDs" do
      result = Anonymizer.anonymize(@accounts, :list_accounts)

      ids = Enum.map(result.accounts, & &1.id)
      assert ids == ["A", "B", "C"]

      # Original names not present
      refute result |> inspect() |> String.contains?("Fidelity")
      refute result |> inspect() |> String.contains?("Vanguard")
      refute result |> inspect() |> String.contains?("Chase")
    end

    test "converts balances to weights summing to 1.0" do
      result = Anonymizer.anonymize(@accounts, :list_accounts)

      weights = Enum.map(result.accounts, & &1.weight)
      assert_in_delta Enum.sum(weights), 1.0, 0.001

      # Individual weights correct
      # 125k / 185k ≈ 0.676
      assert_in_delta hd(weights), 0.68, 0.01
    end

    test "converts portfolio total to tier" do
      result = Anonymizer.anonymize(@accounts, :list_accounts)

      # 185k total = :six_figures
      assert result.portfolio.value_tier == :six_figures
    end

    test "preserves account type information" do
      result = Anonymizer.anonymize(@accounts, :list_accounts)

      types = Enum.map(result.accounts, & &1.type)
      assert :retirement_401k in types or :taxable_investment in types
      assert :retirement_roth_ira in types
      assert :checking in types
    end

    test "converts holdings to asset class breakdown" do
      result = Anonymizer.anonymize(@accounts, :list_accounts)

      first_account = hd(result.accounts)
      assert Map.has_key?(first_account, :asset_classes)
      assert is_map(first_account.asset_classes)

      # VTI + VXUS should show equity allocation
      assert Map.has_key?(first_account.asset_classes, :us_equity) or
               Map.has_key?(first_account.asset_classes, :equity)
    end

    test "calculates concentration level" do
      result = Anonymizer.anonymize(@accounts, :list_accounts)

      # 125k/185k ≈ 68% in largest account = :high concentration
      assert result.portfolio.concentration in [:high, :very_high, :moderate]
    end

    test "calculates diversification score" do
      result = Anonymizer.anonymize(@accounts, :list_accounts)

      assert is_float(result.portfolio.diversification_score)
      assert result.portfolio.diversification_score >= 0.0
      assert result.portfolio.diversification_score <= 1.0
    end
  end

  describe "anonymize/2 for :list_transactions" do
    test "converts dates to relative strings" do
      result = Anonymizer.anonymize(@transactions, :list_transactions)

      assert result.summary.date_range.oldest_relative =~ ~r/\d+ (days?|weeks?|months?) ago/
      assert result.summary.date_range.newest_relative =~ ~r/\d+ (days?|weeks?) ago/
    end

    test "groups transactions by type" do
      result = Anonymizer.anonymize(@transactions, :list_transactions)

      assert result.summary.by_type[:buy] == 1
      assert result.summary.by_type[:dividend] == 1
    end

    test "calculates transaction count" do
      result = Anonymizer.anonymize(@transactions, :list_transactions)

      assert result.summary.count == 2
    end

    test "calculates date span in days" do
      result = Anonymizer.anonymize(@transactions, :list_transactions)

      assert result.summary.date_range.span_days == 35
    end

    test "removes specific amounts" do
      result = Anonymizer.anonymize(@transactions, :list_transactions)

      result_str = inspect(result)
      refute String.contains?(result_str, "2500")
      refute String.contains?(result_str, "125.00")
    end

    test "removes symbol tickers" do
      result = Anonymizer.anonymize(@transactions, :list_transactions)

      refute result |> inspect() |> String.contains?("VTI")
    end

    test "provides amount tier distribution" do
      result = Anonymizer.anonymize(@transactions, :list_transactions)

      assert Map.has_key?(result.patterns, :avg_transaction_tier) or
               Map.has_key?(result.patterns, :amount_distribution)
    end
  end

  describe "anonymize/2 for :get_portfolio_summary" do
    @summary %{
      total_value: Decimal.new("185000"),
      ytd_return: 0.12,
      diversification: 0.65,
      risk_level: :moderate,
      allocation: %{equity: 0.95, cash: 0.05},
      savings_rate: 0.22,
      debt_to_income: 0.15,
      expense_ratio: 0.04
    }

    test "converts total value to tier" do
      result = Anonymizer.anonymize(@summary, :get_portfolio_summary)

      assert result.value_tier == :six_figures
      refute result |> inspect() |> String.contains?("185000")
    end

    test "passes through allocation percentages" do
      result = Anonymizer.anonymize(@summary, :get_portfolio_summary)

      assert result.allocation.equity == 0.95
      assert result.allocation.cash == 0.05
    end

    test "passes through ratios unchanged" do
      result = Anonymizer.anonymize(@summary, :get_portfolio_summary)

      assert result.ratios.savings_rate == 0.22
      assert result.ratios.debt_to_income == 0.15
      assert result.ratios.expense_ratio == 0.04
    end

    test "passes through metrics" do
      result = Anonymizer.anonymize(@summary, :get_portfolio_summary)

      assert result.metrics.ytd_return_pct == 0.12
      assert result.metrics.diversification_score == 0.65
      assert result.metrics.risk_level == :moderate
    end
  end

  describe "value_to_tier/1" do
    test "categorizes values into correct tiers" do
      assert Anonymizer.value_to_tier(Decimal.new("5000")) == :under_10k
      assert Anonymizer.value_to_tier(Decimal.new("50000")) == :five_figures
      assert Anonymizer.value_to_tier(Decimal.new("500000")) == :six_figures
      assert Anonymizer.value_to_tier(Decimal.new("5000000")) == :seven_figures
      assert Anonymizer.value_to_tier(Decimal.new("50000000")) == :eight_figures_plus
    end

    test "handles boundary values" do
      assert Anonymizer.value_to_tier(Decimal.new("9999.99")) == :under_10k
      assert Anonymizer.value_to_tier(Decimal.new("10000")) == :five_figures
      assert Anonymizer.value_to_tier(Decimal.new("99999.99")) == :five_figures
      assert Anonymizer.value_to_tier(Decimal.new("100000")) == :six_figures
    end

    test "handles zero and negative" do
      assert Anonymizer.value_to_tier(Decimal.new("0")) == :under_10k
      assert Anonymizer.value_to_tier(Decimal.new("-1000")) == :under_10k
    end
  end

  describe "days_ago/1" do
    test "returns 'today' for today" do
      assert Anonymizer.days_ago(Date.utc_today()) == "today"
    end

    test "returns 'yesterday' for yesterday" do
      assert Anonymizer.days_ago(Date.add(Date.utc_today(), -1)) == "yesterday"
    end

    test "returns days for less than a week" do
      assert Anonymizer.days_ago(Date.add(Date.utc_today(), -3)) == "3 days ago"
      assert Anonymizer.days_ago(Date.add(Date.utc_today(), -6)) == "6 days ago"
    end

    test "returns weeks for less than a month" do
      assert Anonymizer.days_ago(Date.add(Date.utc_today(), -14)) == "2 weeks ago"
      assert Anonymizer.days_ago(Date.add(Date.utc_today(), -21)) == "3 weeks ago"
    end

    test "returns months for less than a year" do
      assert Anonymizer.days_ago(Date.add(Date.utc_today(), -60)) == "2 months ago"
      assert Anonymizer.days_ago(Date.add(Date.utc_today(), -180)) == "6 months ago"
    end

    test "returns years for more than a year" do
      assert Anonymizer.days_ago(Date.add(Date.utc_today(), -400)) == "1 years ago"
      assert Anonymizer.days_ago(Date.add(Date.utc_today(), -800)) == "2 years ago"
    end
  end

  describe "edge cases" do
    test "handles empty accounts list" do
      result = Anonymizer.anonymize([], :list_accounts)

      assert result.accounts == []
      assert result.portfolio.account_count == 0
      assert result.portfolio.value_tier == :under_10k
    end

    test "handles single account" do
      single = [hd(@accounts)]
      result = Anonymizer.anonymize(single, :list_accounts)

      assert length(result.accounts) == 1
      assert hd(result.accounts).weight == 1.0
      assert result.portfolio.concentration == :very_high
    end

    test "handles account with no holdings" do
      no_holdings = [%{List.last(@accounts) | holdings: nil}]
      result = Anonymizer.anonymize(no_holdings, :list_accounts)

      assert hd(result.accounts).asset_classes == %{cash: 1.0}
    end

    test "handles empty transactions list" do
      result = Anonymizer.anonymize([], :list_transactions)

      assert result.summary.count == 0
    end
  end
end
