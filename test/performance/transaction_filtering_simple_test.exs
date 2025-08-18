defmodule Ashfolio.Performance.TransactionFilteringSimpleTest do
  @moduledoc """
  Simplified transaction filtering performance tests for Task 14 Stage 4.

  Basic performance tests to establish baseline:
  - Category filtering performance: <50ms
  - Date range filtering: <50ms
  - Basic pagination: <25ms
  """

  use Ashfolio.DataCase, async: false

  @moduletag :performance
  @moduletag :slow
  @moduletag :transaction_filtering

  alias Ashfolio.Portfolio.{Transaction, Account}
  alias Ashfolio.FinancialManagement.TransactionCategory
  alias Ashfolio.SQLiteHelpers

  describe "Basic Transaction Filtering Performance" do
    setup do
      # Create a test account
      {:ok, account} =
        Account.create(%{
          name: "Test Investment Account",
          platform: "Test Broker",
          account_type: :investment,
          balance: Decimal.new("10000")
        })

      # Create a test category
      {:ok, category} =
        TransactionCategory.create(%{
          name: "Test Category",
          color: "#FF0000"
        })

      # Create test symbols
      symbol =
        SQLiteHelpers.get_or_create_symbol("AAPL", %{
          name: "Apple Inc.",
          current_price: Decimal.new("150.00")
        })

      # Create test transactions
      transactions = create_test_transactions(account.id, category.id, symbol.id, 100)

      %{
        account: account,
        category: category,
        symbol: symbol,
        transactions: transactions
      }
    end

    test "category filtering performance under 50ms", %{category: category} do
      {time_us, results} =
        :timer.tc(fn ->
          Transaction.by_category(category.id)
        end)

      time_ms = time_us / 1000

      assert length(results) > 0

      assert time_ms < 50,
             "Category filtering took #{time_ms}ms, expected < 50ms"
    end

    test "date range filtering performance under 50ms" do
      start_date = Date.add(Date.utc_today(), -30)
      end_date = Date.utc_today()

      {time_us, results} =
        :timer.tc(fn ->
          Transaction.list_for_user_by_date_range!(start_date, end_date)
        end)

      time_ms = time_us / 1000

      assert length(results) > 0

      assert time_ms < 50,
             "Date range filtering took #{time_ms}ms, expected < 50ms"
    end

    test "account filtering performance under 50ms", %{account: account} do
      {time_us, results} =
        :timer.tc(fn ->
          Transaction.list_for_account!(account.id)
        end)

      time_ms = time_us / 1000

      assert length(results) > 0

      assert time_ms < 50,
             "Account filtering took #{time_ms}ms, expected < 50ms"
    end

    test "pagination performance under 25ms" do
      {time_us, results} =
        :timer.tc(fn ->
          Transaction.list_for_user_paginated!(1, 20)
        end)

      time_ms = time_us / 1000

      assert length(results) > 0

      assert time_ms < 25,
             "Pagination took #{time_ms}ms, expected < 25ms"
    end

    test "consistent performance across multiple calls", %{category: category} do
      # Run filtering multiple times to test consistency
      times =
        for _ <- 1..5 do
          {time_us, _results} =
            :timer.tc(fn ->
              Transaction.by_category(category.id)
            end)

          time_us / 1000
        end

      avg_time = Enum.sum(times) / length(times)
      max_time = Enum.max(times)

      assert avg_time < 40, "Average filtering time #{avg_time}ms too high"
      assert max_time < 60, "Max filtering time #{max_time}ms indicates performance issue"
    end
  end

  # Helper function to create test transactions
  defp create_test_transactions(account_id, category_id, symbol_id, count) do
    for i <- 1..count do
      transaction_type =
        case rem(i, 3) do
          0 -> :buy
          1 -> :sell
          2 -> :dividend
        end

      quantity =
        case transaction_type do
          :sell -> Decimal.new("-#{5 + rem(i, 20)}")
          _ -> Decimal.new("#{5 + rem(i, 20)}")
        end

      {:ok, transaction} =
        Transaction.create(%{
          type: transaction_type,
          account_id: account_id,
          category_id: category_id,
          symbol_id: symbol_id,
          quantity: quantity,
          price: Decimal.new("#{100 + rem(i, 100)}.00"),
          total_amount: Decimal.new("#{500 + i * 10}.00"),
          date: Date.add(Date.utc_today(), -rem(i, 180))
        })

      transaction
    end
  end
end
