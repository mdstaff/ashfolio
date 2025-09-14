defmodule Ashfolio.Financial.BenchmarkAnalyzerTest do
  use ExUnit.Case, async: true

  import Mox

  alias Ashfolio.Financial.BenchmarkAnalyzer

  setup :verify_on_exit!
  setup :set_mox_from_context

  describe "analyze_vs_benchmark/4" do
    @tag :mocked
    test "calculates portfolio vs S&P 500 performance analysis" do
      # Mock Yahoo Finance to return S&P 500 price
      expect(YahooFinanceMock, :fetch_price, fn "SPY" ->
        {:ok, Decimal.new("450.00")}
      end)

      portfolio_start = Decimal.new("100000")
      # 10% return
      portfolio_end = Decimal.new("110000")
      days = 365

      assert {:ok, analysis} = BenchmarkAnalyzer.analyze_vs_benchmark(portfolio_start, portfolio_end, days, :sp500)

      # Portfolio achieved 10% return
      assert Decimal.equal?(analysis.portfolio_return, Decimal.new("0.10"))

      # S&P 500 historical average used (10%)
      assert Decimal.equal?(analysis.benchmark_return, Decimal.new("0.10"))

      # Equal performance
      assert Decimal.equal?(analysis.relative_performance, Decimal.new("0.00"))
      assert Decimal.equal?(analysis.alpha, Decimal.new("0.00"))

      assert analysis.benchmark_symbol == "SPY"
      assert analysis.period_days == 365
      # Equal performance
      refute analysis.outperformed
    end

    test "identifies portfolio outperformance" do
      expect(YahooFinanceMock, :fetch_price, fn "SPY" ->
        {:ok, Decimal.new("450.00")}
      end)

      portfolio_start = Decimal.new("100000")
      # 15% return
      portfolio_end = Decimal.new("115000")
      days = 365

      assert {:ok, analysis} = BenchmarkAnalyzer.analyze_vs_benchmark(portfolio_start, portfolio_end, days, :sp500)

      assert Decimal.equal?(analysis.portfolio_return, Decimal.new("0.15"))
      assert Decimal.equal?(analysis.benchmark_return, Decimal.new("0.10"))
      assert Decimal.equal?(analysis.relative_performance, Decimal.new("0.05"))
      # 5% alpha
      assert Decimal.equal?(analysis.alpha, Decimal.new("5.00"))

      assert analysis.outperformed
    end

    test "identifies portfolio underperformance" do
      expect(YahooFinanceMock, :fetch_price, fn "SPY" ->
        {:ok, Decimal.new("450.00")}
      end)

      portfolio_start = Decimal.new("100000")
      # 5% return
      portfolio_end = Decimal.new("105000")
      days = 365

      assert {:ok, analysis} = BenchmarkAnalyzer.analyze_vs_benchmark(portfolio_start, portfolio_end, days, :sp500)

      assert Decimal.equal?(analysis.portfolio_return, Decimal.new("0.05"))
      assert Decimal.equal?(analysis.benchmark_return, Decimal.new("0.10"))
      assert Decimal.equal?(analysis.relative_performance, Decimal.new("-0.05"))
      # -5% alpha
      assert Decimal.equal?(analysis.alpha, Decimal.new("-5.00"))

      refute analysis.outperformed
    end

    test "supports different benchmark options" do
      expect(YahooFinanceMock, :fetch_price, fn "VTI" ->
        {:ok, Decimal.new("220.00")}
      end)

      portfolio_start = Decimal.new("100000")
      portfolio_end = Decimal.new("110000")
      days = 365

      assert {:ok, analysis} =
               BenchmarkAnalyzer.analyze_vs_benchmark(portfolio_start, portfolio_end, days, :total_market)

      assert analysis.benchmark_symbol == "VTI"
      # Total market average
      assert Decimal.equal?(analysis.benchmark_return, Decimal.new("0.09"))
    end

    test "validates portfolio values" do
      assert {:error, :invalid_start_value} =
               BenchmarkAnalyzer.analyze_vs_benchmark(Decimal.new("0"), Decimal.new("100000"), 365)

      assert {:error, :invalid_end_value} =
               BenchmarkAnalyzer.analyze_vs_benchmark(Decimal.new("100000"), Decimal.new("0"), 365)

      assert {:error, :invalid_portfolio_values} =
               BenchmarkAnalyzer.analyze_vs_benchmark("invalid", Decimal.new("100000"), 365)
    end

    test "validates days parameter" do
      assert {:error, :invalid_days} =
               BenchmarkAnalyzer.analyze_vs_benchmark(Decimal.new("100000"), Decimal.new("110000"), 0)

      assert {:error, :invalid_days} =
               BenchmarkAnalyzer.analyze_vs_benchmark(Decimal.new("100000"), Decimal.new("110000"), 5000)

      assert {:error, :invalid_days} =
               BenchmarkAnalyzer.analyze_vs_benchmark(Decimal.new("100000"), Decimal.new("110000"), "invalid")
    end

    test "handles unsupported benchmark" do
      assert {:error, :unsupported_benchmark} =
               BenchmarkAnalyzer.analyze_vs_benchmark(
                 Decimal.new("100000"),
                 Decimal.new("110000"),
                 365,
                 :invalid_benchmark
               )
    end

    test "handles Yahoo Finance API errors" do
      expect(YahooFinanceMock, :fetch_price, fn "SPY" ->
        {:error, :network_error}
      end)

      assert {:error, :network_error} =
               BenchmarkAnalyzer.analyze_vs_benchmark(Decimal.new("100000"), Decimal.new("110000"), 365)
    end
  end

  describe "calculate_beta/3" do
    test "calculates portfolio beta vs benchmark" do
      # Mock benchmark returns
      portfolio_returns = [
        # 2% day
        Decimal.new("0.02"),
        # -1% day
        Decimal.new("-0.01"),
        # 1.5% day
        Decimal.new("0.015"),
        # 0.5% day
        Decimal.new("0.005"),
        # -0.5% day
        Decimal.new("-0.005")
      ]

      assert {:ok, beta_analysis} = BenchmarkAnalyzer.calculate_beta(portfolio_returns, :sp500, 5)

      # Should include beta calculation
      assert Map.has_key?(beta_analysis, :beta)
      assert Map.has_key?(beta_analysis, :correlation)
      assert Map.has_key?(beta_analysis, :r_squared)

      assert is_struct(beta_analysis.beta, Decimal)
      assert is_struct(beta_analysis.correlation, Decimal)
      assert is_struct(beta_analysis.r_squared, Decimal)

      assert beta_analysis.benchmark_symbol == "SPY"
      assert beta_analysis.sample_size == 5
      assert beta_analysis.period_days == 5
    end

    test "validates returns data" do
      # Too few data points (< 5)
      short_returns = [Decimal.new("0.01"), Decimal.new("0.02")]
      assert {:error, :insufficient_portfolio_data} = BenchmarkAnalyzer.calculate_beta(short_returns, :sp500, 30)
    end

    test "handles empty returns list" do
      assert {:error, :insufficient_portfolio_data} = BenchmarkAnalyzer.calculate_beta([], :sp500, 30)
    end

    test "handles invalid benchmark for beta calculation" do
      portfolio_returns = Enum.map(1..10, fn _ -> Decimal.new("0.01") end)

      assert {:error, :unsupported_benchmark} =
               BenchmarkAnalyzer.calculate_beta(portfolio_returns, :invalid_benchmark, 30)
    end
  end

  describe "get_benchmark_data/2" do
    test "retrieves S&P 500 benchmark data" do
      expect(YahooFinanceMock, :fetch_price, 2, fn "SPY" ->
        {:ok, Decimal.new("450.25")}
      end)

      assert {:ok, benchmark_data} = BenchmarkAnalyzer.get_benchmark_data(:sp500, 365)

      assert benchmark_data.benchmark == :sp500
      assert benchmark_data.symbol == "SPY"
      assert Decimal.equal?(benchmark_data.current_price, Decimal.new("450.25"))
      assert Decimal.equal?(benchmark_data.period_return, Decimal.new("0.10"))
      assert benchmark_data.period_days == 365
      assert %DateTime{} = benchmark_data.last_updated
    end

    test "retrieves total market benchmark data" do
      expect(YahooFinanceMock, :fetch_price, 2, fn "VTI" ->
        {:ok, Decimal.new("220.50")}
      end)

      assert {:ok, benchmark_data} = BenchmarkAnalyzer.get_benchmark_data(:total_market, 180)

      assert benchmark_data.benchmark == :total_market
      assert benchmark_data.symbol == "VTI"
      assert Decimal.equal?(benchmark_data.period_return, Decimal.new("0.09"))
    end

    test "handles benchmark fetch errors" do
      expect(YahooFinanceMock, :fetch_price, fn "SPY" ->
        {:error, :timeout}
      end)

      assert {:error, :timeout} = BenchmarkAnalyzer.get_benchmark_data(:sp500, 365)
    end
  end

  describe "compare_multiple_portfolios/3" do
    test "compares multiple portfolios against benchmark" do
      expect(YahooFinanceMock, :fetch_price, fn "SPY" ->
        {:ok, Decimal.new("450.00")}
      end)

      portfolios = [
        %{
          label: "Conservative Portfolio",
          start_value: Decimal.new("100000"),
          # 5% return
          end_value: Decimal.new("105000")
        },
        %{
          label: "Aggressive Portfolio",
          start_value: Decimal.new("100000"),
          # 15% return
          end_value: Decimal.new("115000")
        },
        %{
          label: "Balanced Portfolio",
          start_value: Decimal.new("100000"),
          # 8% return
          end_value: Decimal.new("108000")
        }
      ]

      assert {:ok, comparison} = BenchmarkAnalyzer.compare_multiple_portfolios(portfolios, :sp500, 365)

      assert comparison.benchmark == :sp500
      assert comparison.benchmark_symbol == "SPY"
      assert Decimal.equal?(comparison.benchmark_return, Decimal.new("0.10"))
      assert comparison.period_days == 365

      # Should have 3 portfolio analyses
      assert length(comparison.portfolio_analyses) == 3

      # Check individual portfolio analysis
      conservative = Enum.find(comparison.portfolio_analyses, &(&1.label == "Conservative Portfolio"))
      assert Decimal.equal?(conservative.portfolio_return, Decimal.new("0.05"))
      assert Decimal.equal?(conservative.alpha, Decimal.new("-5.00"))
      refute conservative.outperformed

      aggressive = Enum.find(comparison.portfolio_analyses, &(&1.label == "Aggressive Portfolio"))
      assert Decimal.equal?(aggressive.portfolio_return, Decimal.new("0.15"))
      assert Decimal.equal?(aggressive.alpha, Decimal.new("5.00"))
      assert aggressive.outperformed

      # Best and worst performers identified
      assert comparison.best_performer.label == "Aggressive Portfolio"
      assert comparison.worst_performer.label == "Conservative Portfolio"
    end

    test "validates portfolios input format" do
      invalid_portfolios = [
        # Missing start_value and end_value
        %{label: "Missing values"},
        %{start_value: "invalid", end_value: Decimal.new("100000"), label: "Invalid start"}
      ]

      assert {:error, :invalid_portfolios_format} = BenchmarkAnalyzer.compare_multiple_portfolios(invalid_portfolios)
    end

    test "handles empty portfolios list" do
      expect(YahooFinanceMock, :fetch_price, fn "SPY" ->
        {:ok, Decimal.new("450.00")}
      end)

      assert {:ok, comparison} = BenchmarkAnalyzer.compare_multiple_portfolios([], :sp500, 365)
      assert comparison.portfolio_analyses == []
      assert comparison.best_performer == nil
      assert comparison.worst_performer == nil
    end
  end

  describe "edge cases and error handling" do
    test "handles zero portfolio returns" do
      expect(YahooFinanceMock, :fetch_price, fn "SPY" ->
        {:ok, Decimal.new("450.00")}
      end)

      # Same start and end value = 0% return
      portfolio_start = Decimal.new("100000")
      portfolio_end = Decimal.new("100000")

      assert {:ok, analysis} = BenchmarkAnalyzer.analyze_vs_benchmark(portfolio_start, portfolio_end, 365, :sp500)

      assert Decimal.equal?(analysis.portfolio_return, Decimal.new("0.00"))
      # Underperformed by 10%
      assert Decimal.equal?(analysis.relative_performance, Decimal.new("-0.10"))
    end

    test "handles negative portfolio returns" do
      expect(YahooFinanceMock, :fetch_price, fn "SPY" ->
        {:ok, Decimal.new("450.00")}
      end)

      portfolio_start = Decimal.new("100000")
      # -10% return
      portfolio_end = Decimal.new("90000")

      assert {:ok, analysis} = BenchmarkAnalyzer.analyze_vs_benchmark(portfolio_start, portfolio_end, 365, :sp500)

      assert Decimal.equal?(analysis.portfolio_return, Decimal.new("-0.10"))
      # Underperformed by 20%
      assert Decimal.equal?(analysis.relative_performance, Decimal.new("-0.20"))
      assert Decimal.equal?(analysis.alpha, Decimal.new("-20.00"))
    end

    test "handles very small portfolio values" do
      expect(YahooFinanceMock, :fetch_price, fn "SPY" ->
        {:ok, Decimal.new("450.00")}
      end)

      portfolio_start = Decimal.new("0.01")
      # 10% return on small amount
      portfolio_end = Decimal.new("0.011")

      assert {:ok, analysis} = BenchmarkAnalyzer.analyze_vs_benchmark(portfolio_start, portfolio_end, 365, :sp500)

      assert Decimal.equal?(analysis.portfolio_return, Decimal.new("0.10"))
    end
  end
end
