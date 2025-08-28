defmodule AshfolioWeb.Integration.PerformanceBenchmarksTest do
  @moduledoc """
  Performance benchmark tests to verify key performance requirements:
  - Page load times under 500ms
  - Price refresh under 2s
  - Portfolio calculations under 100ms

  Task 29.3: Verify Performance Benchmarks
  """
  use AshfolioWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Ashfolio.Portfolio.Account
  alias Ashfolio.Portfolio.Calculator
  alias Ashfolio.Portfolio.HoldingsCalculator
  alias Ashfolio.Portfolio.Symbol
  alias Ashfolio.Portfolio.Transaction
  alias Ashfolio.SQLiteHelpers

  @moduletag :integration
  @moduletag :slow
  @moduletag :performance
  setup do
    # Database-as-user architecture: No user entity needed
    {:ok, account} =
      Account.create(%{
        name: "Performance Test Account",
        platform: "Test Platform",
        balance: Decimal.new("100000")
      })

    # Create multiple symbols for realistic testing
    symbols = ["AAPL", "MSFT", "GOOGL", "TSLA", "AMZN"]

    created_symbols =
      Enum.map(symbols, fn symbol_name ->
        SQLiteHelpers.get_or_create_symbol(symbol_name, %{
          name: "#{symbol_name} Inc.",
          asset_class: :stock,
          data_source: :yahoo_finance,
          current_price: Decimal.new("#{100 + :rand.uniform(200)}.00")
        })
      end)

    # Create realistic transaction volume (50 transactions)
    Enum.each(created_symbols, fn symbol ->
      # Create 10 transactions per symbol
      for i <- 1..10 do
        tx_type = if rem(i, 4) == 0, do: :sell, else: :buy

        tx_quantity =
          if rem(i, 4) == 0, do: Decimal.new("-#{10 + i}"), else: Decimal.new("#{10 + i}")

        {:ok, _} =
          Transaction.create(%{
            type: tx_type,
            account_id: account.id,
            symbol_id: symbol.id,
            quantity: tx_quantity,
            price: Decimal.new("#{100 + i}.00"),
            total_amount: Decimal.new("#{1000 + i * 100}.00"),
            date: Date.add(~D[2024-01-01], i)
          })
      end
    end)

    %{account: account, symbols: created_symbols}
  end

  describe "Performance Benchmarks" do
    test "dashboard page load time under 500ms", %{conn: conn} do
      # Measure page load time
      {time_microseconds, {:ok, _view, _html}} =
        :timer.tc(fn ->
          live(conn, "/")
        end)

      time_milliseconds = time_microseconds / 1000

      # Should load under 500ms
      assert time_milliseconds < 500,
             "Dashboard loaded in #{time_milliseconds}ms, expected < 500ms"
    end

    test "accounts page load time under 500ms", %{conn: conn} do
      {time_microseconds, {:ok, _view, _html}} =
        :timer.tc(fn ->
          live(conn, "/accounts")
        end)

      time_milliseconds = time_microseconds / 1000

      assert time_milliseconds < 500,
             "Accounts page loaded in #{time_milliseconds}ms, expected < 500ms"
    end

    test "transactions page load time under 500ms", %{conn: conn} do
      {time_microseconds, {:ok, _view, _html}} =
        :timer.tc(fn ->
          live(conn, "/transactions")
        end)

      time_milliseconds = time_microseconds / 1000

      assert time_milliseconds < 500,
             "Transactions page loaded in #{time_milliseconds}ms, expected < 500ms"
    end

    test "portfolio calculations under 100ms" do
      # Measure portfolio calculation time
      {time_microseconds, _result} =
        :timer.tc(fn ->
          Calculator.calculate_total_return()
        end)

      time_milliseconds = time_microseconds / 1000

      assert time_milliseconds < 100,
             "Portfolio calculations took #{time_milliseconds}ms, expected < 100ms"
    end

    test "holdings calculations under 100ms" do
      {time_microseconds, _result} =
        :timer.tc(fn ->
          HoldingsCalculator.get_holdings_summary()
        end)

      time_milliseconds = time_microseconds / 1000

      assert time_milliseconds < 100,
             "Holdings calculations took #{time_milliseconds}ms, expected < 100ms"
    end

    test "large transaction list performance", %{account: account} do
      # Test listing many transactions
      {time_microseconds, _result} =
        :timer.tc(fn ->
          Transaction.by_account(account.id)
        end)

      time_milliseconds = time_microseconds / 1000

      # Should be able to list 50+ transactions quickly
      assert time_milliseconds < 50,
             "Transaction listing took #{time_milliseconds}ms, expected < 50ms"
    end

    test "account operations performance" do
      {time_microseconds, _result} =
        :timer.tc(fn ->
          Account.list()
        end)

      time_milliseconds = time_microseconds / 1000

      assert time_milliseconds < 50,
             "Account listing took #{time_milliseconds}ms, expected < 50ms"
    end

    test "symbol operations performance" do
      {time_microseconds, _result} =
        :timer.tc(fn ->
          Symbol.list!()
        end)

      time_milliseconds = time_microseconds / 1000

      assert time_milliseconds < 50,
             "Symbol listing took #{time_milliseconds}ms, expected < 50ms"
    end

    # Note: Price refresh performance test would require mocking the external API
    # and is more complex to test reliably, so we focus on internal calculations

    test "database connection performance" do
      # Test basic database operations
      {time_microseconds, _result} =
        :timer.tc(fn ->
          # Simple database query - test account listing instead
          Account.list()
        end)

      time_milliseconds = time_microseconds / 1000

      assert time_milliseconds < 20,
             "Database query took #{time_milliseconds}ms, expected < 20ms"
    end

    test "memory usage is reasonable during calculations" do
      # Get initial memory
      :erlang.garbage_collect()
      initial_memory = :erlang.memory(:total)

      # Perform calculations
      _result = Calculator.calculate_total_return()
      _result = HoldingsCalculator.get_holdings_summary()

      # Force garbage collection and check memory
      :erlang.garbage_collect()
      final_memory = :erlang.memory(:total)

      memory_increase = final_memory - initial_memory
      memory_increase_mb = memory_increase / (1024 * 1024)

      # Memory increase should be reasonable (< 10MB for this test)
      assert memory_increase_mb < 10,
             "Memory increased by #{memory_increase_mb}MB during calculations, expected < 10MB"
    end
  end
end
