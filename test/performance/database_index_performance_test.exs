defmodule Ashfolio.Performance.DatabaseIndexPerformanceTest do
  @moduledoc """
  Database index performance tests for Task 14 Stage 1.

  Tests specific v0.2.0 query patterns to ensure database indexes are effective:
  - Account filtering by type (cash vs investment)
  - Transaction filtering by category_id
  - Combined user + account_type queries
  - Transaction filtering with categories and dates

  Performance targets:
  - Account type queries: < 10ms for 100+ accounts
  - Category filtering: < 20ms for 1000+ transactions
  - Complex composite queries: < 50ms
  """

  use Ashfolio.DataCase, async: false

  alias Ashfolio.FinancialManagement.TransactionCategory
  alias Ashfolio.Portfolio.Account
  alias Ashfolio.Portfolio.Transaction
  alias Ashfolio.SQLiteHelpers

  @moduletag :performance
  @moduletag :slow
  @moduletag :database_indexes

  @performance_account_count 100
  @performance_transaction_count 1000

  describe "Account Type Index Performance" do
    setup do
      # Database-as-user architecture: No user needed
      # Create realistic account mix: 30% cash, 70% investment
      accounts = create_performance_accounts(@performance_account_count)

      %{accounts: accounts}
    end

    test "account type filtering performs under 10ms", %{accounts: _accounts} do
      # Test cash account filtering
      {time_us, {:ok, cash_accounts}} =
        :timer.tc(fn ->
          Account.cash_accounts()
        end)

      time_ms = time_us / 1000

      assert length(cash_accounts) > 0

      assert time_ms < 10,
             "Cash account filtering took #{time_ms}ms, expected < 10ms"

      # Test investment account filtering
      {time_us, {:ok, investment_accounts}} =
        :timer.tc(fn ->
          Account.investment_accounts()
        end)

      time_ms = time_us / 1000

      assert length(investment_accounts) > 0

      assert time_ms < 10,
             "Investment account filtering took #{time_ms}ms, expected < 10ms"
    end

    test "composite user + account_type queries under 15ms", %{accounts: _accounts} do
      # Test the common Context API pattern
      {time_us, {:ok, _accounts}} =
        :timer.tc(fn ->
          Account.accounts_by_type(:checking)
        end)

      time_ms = time_us / 1000

      assert time_ms < 15,
             "User + account type query took #{time_ms}ms, expected < 15ms"
    end

    test "account balance filtering with type performs under 20ms", %{accounts: _accounts} do
      # Test balance filtering within account types
      {time_us, _accounts} =
        :timer.tc(fn ->
          Ashfolio.Repo.all(from(a in Account, where: a.account_type == :checking and a.balance > 0, select: a))
        end)

      time_ms = time_us / 1000

      assert time_ms < 20,
             "Account type + balance filtering took #{time_ms}ms, expected < 20ms"
    end
  end

  describe "Transaction Category Index Performance" do
    setup do
      # Database-as-user architecture: No user needed
      # Create categories
      {:ok, categories} = create_performance_categories()

      # Create account for transactions
      {:ok, account} =
        Account.create(%{
          name: "Performance Test Account",
          platform: "Test",
          balance: Decimal.new("10000"),
          account_type: :investment
        })

      # Create symbol
      symbol =
        SQLiteHelpers.get_or_create_symbol("PERF", %{
          name: "Performance Test Corp",
          asset_class: :stock,
          current_price: Decimal.new("100.00")
        })

      # Create many transactions with category assignments
      transactions =
        create_performance_transactions(
          account.id,
          symbol.id,
          categories,
          @performance_transaction_count
        )

      %{account: account, categories: categories, transactions: transactions}
    end

    test "transaction category filtering under 20ms", %{categories: [category | _]} do
      {time_us, transactions} =
        :timer.tc(fn ->
          Ashfolio.Repo.all(from(t in Transaction, where: t.category_id == ^category.id, select: t))
        end)

      time_ms = time_us / 1000

      assert length(transactions) > 0

      assert time_ms < 20,
             "Category filtering took #{time_ms}ms, expected < 20ms"
    end

    test "uncategorized transaction filtering under 15ms" do
      {time_us, _transactions} =
        :timer.tc(fn ->
          Ashfolio.Repo.all(from(t in Transaction, where: is_nil(t.category_id), select: t))
        end)

      time_ms = time_us / 1000

      assert time_ms < 15,
             "Uncategorized filtering took #{time_ms}ms, expected < 15ms"
    end

    test "complex category + date filtering under 50ms", %{categories: [category | _]} do
      start_date = Date.add(Date.utc_today(), -30)

      {time_us, _transactions} =
        :timer.tc(fn ->
          Ashfolio.Repo.all(
            from(t in Transaction,
              where: t.category_id == ^category.id and t.date >= ^start_date,
              order_by: [desc: t.date],
              select: t
            )
          )
        end)

      time_ms = time_us / 1000

      assert time_ms < 50,
             "Complex category + date filtering took #{time_ms}ms, expected < 50ms"
    end

    test "transaction category join query performance under 30ms", %{account: account} do
      # Test joining transactions with categories (common display pattern)
      {time_us, results} =
        :timer.tc(fn ->
          Ashfolio.Repo.all(
            from(t in Transaction,
              left_join: c in TransactionCategory,
              on: t.category_id == c.id,
              where: t.account_id == ^account.id,
              select: {t, c.name, c.color},
              limit: 100
            )
          )
        end)

      time_ms = time_us / 1000

      assert length(results) > 0

      assert time_ms < 30,
             "Transaction category join took #{time_ms}ms, expected < 30ms"
    end
  end

  describe "Index Utilization Analysis" do
    test "verify account_type index is used" do
      # This would normally require EXPLAIN QUERY PLAN in SQLite
      # For now, we test performance which indicates index usage

      # Database-as-user architecture: No user needed
      create_performance_accounts(50)

      # Multiple queries should maintain consistent performance (index usage)
      times =
        for _ <- 1..5 do
          {time_us, _} =
            :timer.tc(fn ->
              Account.cash_accounts()
            end)

          time_us / 1000
        end

      avg_time = Enum.sum(times) / length(times)
      max_time = Enum.max(times)

      # Consistent performance indicates index usage
      assert avg_time < 10, "Average query time #{avg_time}ms too high"
      assert max_time < 15, "Max query time #{max_time}ms indicates missing index"

      # Performance should be consistent (std deviation low)
      std_dev = calculate_standard_deviation(times)
      assert std_dev < 5, "Performance too inconsistent: std_dev #{std_dev}ms"
    end

    test "verify category_id index is used" do
      # Database-as-user architecture: No user needed
      {:ok, categories} = create_performance_categories()

      {:ok, account} =
        Account.create(%{
          name: "Index Test Account",
          platform: "Test",
          balance: Decimal.new("1000"),
          account_type: :investment
        })

      symbol =
        SQLiteHelpers.get_or_create_symbol("IDX", %{
          name: "Index Test Corp",
          asset_class: :stock
        })

      create_performance_transactions(account.id, symbol.id, categories, 200)

      # Test category filtering performance consistency
      category = List.first(categories)

      times =
        for _ <- 1..5 do
          {time_us, _} =
            :timer.tc(fn ->
              Ashfolio.Repo.all(from(t in Transaction, where: t.category_id == ^category.id))
            end)

          time_us / 1000
        end

      avg_time = Enum.sum(times) / length(times)

      assert avg_time < 15, "Category filtering average time #{avg_time}ms too high"

      std_dev = calculate_standard_deviation(times)
      assert std_dev < 3, "Category filtering inconsistent: std_dev #{std_dev}ms"
    end
  end

  # Helper functions for creating performance test data

  defp create_performance_accounts(count) do
    # 30% cash accounts (checking, savings), 70% investment
    account_types = [:checking, :savings, :investment, :investment, :investment]

    for i <- 1..count do
      account_type = Enum.at(account_types, rem(i, 5))

      {:ok, account} =
        Account.create(%{
          name: "Performance Account #{i}",
          platform: "Platform #{rem(i, 3)}",
          balance: Decimal.new("#{1000 + i * 100}"),
          account_type: account_type
        })

      account
    end
  end

  defp create_performance_categories do
    categories = [
      {"Growth", "#10B981"},
      {"Income", "#3B82F6"},
      {"Speculative", "#F59E0B"},
      {"Index", "#8B5CF6"}
    ]

    created_categories =
      Enum.map(categories, fn {name, color} ->
        {:ok, category} =
          TransactionCategory.create(%{
            name: name,
            color: color,
            is_system: false
          })

        category
      end)

    {:ok, created_categories}
  end

  defp create_performance_transactions(account_id, symbol_id, categories, count) do
    # 80% categorized, 20% uncategorized for realistic distribution

    for i <- 1..count do
      category_id =
        if rem(i, 5) == 0 do
          # 20% uncategorized
          nil
        else
          # 80% randomly categorized
          random_category = Enum.at(categories, rem(i, length(categories)))
          random_category.id
        end

      transaction_type = if rem(i, 4) == 0, do: :sell, else: :buy

      # For sell transactions, quantity must be negative
      quantity =
        if transaction_type == :sell do
          Decimal.new("-#{10 + rem(i, 50)}")
        else
          Decimal.new("#{10 + rem(i, 50)}")
        end

      {:ok, transaction} =
        Transaction.create(%{
          type: transaction_type,
          account_id: account_id,
          symbol_id: symbol_id,
          quantity: quantity,
          price: Decimal.new("#{50 + rem(i, 100)}.00"),
          total_amount: Decimal.new("#{500 + i * 10}.00"),
          date: Date.add(Date.utc_today(), -rem(i, 365)),
          category_id: category_id
        })

      transaction
    end
  end

  defp calculate_standard_deviation(values) do
    mean = Enum.sum(values) / length(values)
    variance = Enum.sum(Enum.map(values, fn x -> :math.pow(x - mean, 2) end)) / length(values)
    :math.sqrt(variance)
  end
end
