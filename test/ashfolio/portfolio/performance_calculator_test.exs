defmodule Ashfolio.Portfolio.PerformanceCalculatorTest do
  @moduledoc """
  Test suite for professional portfolio performance calculations.

  Tests Time-Weighted Return (TWR), Money-Weighted Return (MWR), and rolling
  returns analysis following industry-standard methodologies with comprehensive
  edge case coverage and performance benchmarks.
  """

  use Ashfolio.DataCase, async: false

  alias Ashfolio.Portfolio.PerformanceCalculator

  describe "calculate_time_weighted_return/1" do
    @tag :unit
    test "calculates TWR with single cash flow correctly" do
      transactions = [
        %{date: ~D[2023-01-01], amount: Decimal.new("-10000"), type: :buy},
        %{date: ~D[2023-12-31], amount: Decimal.new("12000"), type: :current_value}
      ]

      # 20% return
      expected_twr = Decimal.new("20.00")

      assert {:ok, result} = PerformanceCalculator.calculate_time_weighted_return(transactions)
      assert Decimal.equal?(result, expected_twr)
    end

    @tag :unit
    test "handles multiple cash flows with period breakdown" do
      transactions = [
        %{date: ~D[2023-01-01], amount: Decimal.new("-10000"), type: :buy},
        # Additional investment
        %{date: ~D[2023-06-01], amount: Decimal.new("-5000"), type: :buy},
        %{date: ~D[2023-12-31], amount: Decimal.new("18500"), type: :current_value}
      ]

      # Should break into 2 sub-periods and compound the returns
      assert {:ok, twr} = PerformanceCalculator.calculate_time_weighted_return(transactions)
      # Positive return
      assert Decimal.compare(twr, Decimal.new("0")) == :gt
    end

    @tag :unit
    test "returns error for invalid transaction data" do
      invalid_transactions = []

      assert {:error, :insufficient_data} =
               PerformanceCalculator.calculate_time_weighted_return(invalid_transactions)
    end

    @tag :unit
    test "handles edge case with single transaction" do
      single_transaction = [
        %{date: ~D[2023-01-01], amount: Decimal.new("-10000"), type: :buy}
      ]

      assert {:error, :insufficient_data} =
               PerformanceCalculator.calculate_time_weighted_return(single_transaction)
    end

    @tag :unit
    test "returns error for non-list input" do
      assert {:error, :invalid_input} =
               PerformanceCalculator.calculate_time_weighted_return("invalid")

      assert {:error, :invalid_input} =
               PerformanceCalculator.calculate_time_weighted_return(%{not: "a list"})
    end

    @tag :performance
    test "calculates TWR within 500ms for large dataset" do
      # Generate 5 years of daily data (1825 transactions)
      large_transactions = generate_large_transaction_set(1825)

      {time_us, {:ok, _result}} =
        :timer.tc(fn ->
          PerformanceCalculator.calculate_time_weighted_return(large_transactions)
        end)

      # Must complete within 500ms benchmark
      assert time_us < 500_000, "TWR took #{time_us}μs, exceeds 500ms limit"
    end

    @tag :unit
    test "breaks transactions into correct sub-periods at cash flows" do
      transactions = [
        %{date: ~D[2023-01-01], amount: Decimal.new("-10000"), type: :buy},
        # Interim value
        %{date: ~D[2023-03-15], amount: Decimal.new("11000"), type: :value},
        # Cash flow
        %{date: ~D[2023-06-01], amount: Decimal.new("-5000"), type: :buy},
        # Interim value  
        %{date: ~D[2023-09-15], amount: Decimal.new("17500"), type: :value},
        %{date: ~D[2023-12-31], amount: Decimal.new("18500"), type: :current_value}
      ]

      periods = PerformanceCalculator.break_into_periods_for_test(transactions)

      # Should create 2 periods: Jan-June and June-Dec
      assert length(periods) == 2
      assert hd(periods).start_date == ~D[2023-01-01]
      assert hd(periods).end_date == ~D[2023-06-01]
    end

    @tag :unit
    test "calculates accurate period return with market values" do
      period_data = %{
        start_date: ~D[2023-01-01],
        start_value: Decimal.new("10000"),
        end_date: ~D[2023-06-01],
        end_value: Decimal.new("11000"),
        # No cash flows during period
        cash_flows: []
      }

      # 10% return
      expected_return = Decimal.new("10.00")

      assert {:ok, return} = PerformanceCalculator.calculate_time_weighted_return([period_data])
      assert Decimal.equal?(return, expected_return)
    end

    @tag :unit
    test "handles zero start value gracefully" do
      period_data = %{
        start_date: ~D[2023-01-01],
        start_value: Decimal.new("0"),
        end_date: ~D[2023-06-01],
        end_value: Decimal.new("1000"),
        cash_flows: []
      }

      # Cannot calculate return from zero base
      assert {:error, :zero_start_value} =
               PerformanceCalculator.calculate_time_weighted_return([period_data])
    end
  end

  describe "calculate_money_weighted_return/1" do
    @tag :unit
    test "calculates IRR for simple cash flow sequence" do
      cash_flows = [
        %{date: ~D[2023-01-01], amount: Decimal.new("-10000")},
        %{date: ~D[2023-06-01], amount: Decimal.new("-5000")},
        # Current value
        %{date: ~D[2023-12-31], amount: Decimal.new("17000")}
      ]

      # Expected IRR around 13% annually
      assert {:ok, mwr} = PerformanceCalculator.calculate_money_weighted_return(cash_flows)
      assert Decimal.compare(mwr, Decimal.new("10.00")) == :gt
      assert Decimal.compare(mwr, Decimal.new("20.00")) == :lt
    end

    @tag :unit
    test "handles edge case: all negative cash flows" do
      negative_flows = [
        %{date: ~D[2023-01-01], amount: Decimal.new("-10000")},
        %{date: ~D[2023-06-01], amount: Decimal.new("-5000")},
        # Portfolio worth nothing
        %{date: ~D[2023-12-31], amount: Decimal.new("0")}
      ]

      assert {:error, :negative_irr} = PerformanceCalculator.calculate_money_weighted_return(negative_flows)
    end

    @tag :unit
    test "uses bisection fallback when Newton-Raphson fails to converge" do
      # Create cash flows that cause convergence issues
      difficult_flows = generate_difficult_irr_case()

      assert {:ok, mwr} = PerformanceCalculator.calculate_money_weighted_return(difficult_flows)
      # Reasonable bounds
      assert Decimal.compare(mwr, Decimal.new("-50.00")) == :gt
      assert Decimal.compare(mwr, Decimal.new("100.00")) == :lt
    end

    @tag :performance
    test "MWR calculation completes within performance requirements" do
      large_cash_flows = generate_large_cash_flow_set(500)

      {time_us, {:ok, _result}} =
        :timer.tc(fn ->
          PerformanceCalculator.calculate_money_weighted_return(large_cash_flows)
        end)

      # Should complete within 1 second for 500 cash flows
      assert time_us < 1_000_000, "MWR took #{time_us}μs, exceeds 1s limit"
    end

    @tag :unit
    test "validates cash flow data structure" do
      invalid_flows = [
        # Missing amount
        %{date: ~D[2023-01-01]}
      ]

      assert {:error, :invalid_cash_flow_structure} =
               PerformanceCalculator.calculate_money_weighted_return(invalid_flows)
    end
  end

  describe "calculate_rolling_returns/3" do
    @tag :unit
    test "calculates 1-year rolling returns for multi-year dataset" do
      # 3 years of monthly performance data
      monthly_returns = generate_monthly_returns(36)

      rolling_returns = PerformanceCalculator.calculate_rolling_returns(monthly_returns, 12)

      # Should have 25 rolling 1-year periods (36 - 12 + 1)
      assert length(rolling_returns) == 25

      # Each rolling return should be annualized
      Enum.each(rolling_returns, fn rolling_return ->
        assert %{period_start: _, period_end: _, annualized_return: return} = rolling_return
        # Reasonable bounds
        assert Decimal.compare(return, Decimal.new("-50")) == :gt
        assert Decimal.compare(return, Decimal.new("100")) == :lt
      end)
    end

    @tag :unit
    test "identifies best and worst rolling periods" do
      returns_data = generate_mixed_performance_data()

      rolling_analysis = PerformanceCalculator.analyze_rolling_returns(returns_data, 12)

      assert %{
               best_period: best,
               worst_period: worst,
               average_return: _avg,
               volatility: _vol
             } = rolling_analysis

      # Best should be higher than worst
      assert Decimal.compare(best.annualized_return, worst.annualized_return) == :gt
    end

    @tag :unit
    test "handles insufficient data for rolling calculation" do
      # Only 6 months
      short_data = generate_monthly_returns(6)

      # Cannot calculate 12-month rolling returns
      assert {:error, :insufficient_periods} =
               PerformanceCalculator.calculate_rolling_returns(short_data, 12)
    end
  end

  # Helper functions for test data generation
  defp generate_large_transaction_set(count) do
    base_date = ~D[2020-01-01]

    Enum.map(1..count, fn i ->
      transaction_date = Date.add(base_date, i)
      # Mix of buy transactions and value updates
      {amount, type} =
        if rem(i, 100) == 0 do
          # Every 100th transaction is a buy
          {Decimal.new("-#{1000 + :rand.uniform(200)}"), :buy}
        else
          # Others are portfolio value updates
          portfolio_value = 10_000 + i * 5 + :rand.uniform(1000)
          {Decimal.new("#{portfolio_value}"), :current_value}
        end

      %{
        date: transaction_date,
        amount: amount,
        type: type
      }
    end)
  end

  defp generate_large_cash_flow_set(count) do
    base_date = ~D[2020-01-01]

    1..count
    |> Enum.map(fn i ->
      # Weekly cash flows
      flow_date = Date.add(base_date, i * 7)

      # Mix of investments and withdrawals
      amount =
        if rem(i, 10) == 0 do
          # Every 10th flow is a withdrawal
          Decimal.new("#{500 + :rand.uniform(200)}")
        else
          # Most are investments
          Decimal.new("-#{1000 + :rand.uniform(500)}")
        end

      %{date: flow_date, amount: amount}
    end)
    |> List.update_at(-1, fn last_flow ->
      # Last flow should be current portfolio value (positive)
      %{last_flow | amount: Decimal.new("#{50_000 + :rand.uniform(10_000)}")}
    end)
  end

  defp generate_difficult_irr_case do
    # Create a case with alternating large positive/negative flows
    # that can cause Newton-Raphson convergence issues
    [
      %{date: ~D[2023-01-01], amount: Decimal.new("-50000")},
      # Large return
      %{date: ~D[2023-02-01], amount: Decimal.new("25000")},
      %{date: ~D[2023-03-01], amount: Decimal.new("-30000")},
      %{date: ~D[2023-04-01], amount: Decimal.new("10000")},
      # Current value
      %{date: ~D[2023-12-31], amount: Decimal.new("48000")}
    ]
  end

  defp generate_monthly_returns(count) do
    base_date = ~D[2020-01-01]

    Enum.map(1..count, fn i ->
      month_date = Date.add(base_date, i * 30)

      # Approximate monthly
      # Generate returns between -10% and +15%
      return_pct = -10.0 + :rand.uniform() * 25.0

      %{
        date: month_date,
        return: Decimal.from_float(return_pct)
      }
    end)
  end

  defp generate_mixed_performance_data do
    # Create data with clear best and worst periods for testing
    [
      # Good period start
      %{date: ~D[2020-01-01], return: Decimal.new("15.0")},
      %{date: ~D[2020-02-01], return: Decimal.new("12.0")},
      %{date: ~D[2020-03-01], return: Decimal.new("8.0")},
      # Bad period start  
      %{date: ~D[2020-04-01], return: Decimal.new("-15.0")},
      %{date: ~D[2020-05-01], return: Decimal.new("-8.0")},
      %{date: ~D[2020-06-01], return: Decimal.new("-3.0")},
      # Best period
      %{date: ~D[2020-07-01], return: Decimal.new("20.0")},
      %{date: ~D[2020-08-01], return: Decimal.new("18.0")},
      %{date: ~D[2020-09-01], return: Decimal.new("5.0")}
    ]
  end
end
