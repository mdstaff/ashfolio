defmodule Ashfolio.Integration.CategoryWorkflowIntegrationTest do
  @moduledoc """
  Comprehensive integration tests for investment category workflows in v0.2.0.

  Tests the complete category management and transaction categorization:
  - Category creation, editing, and deletion
  - System category protection
  - Transaction assignment to categories
  - Bulk category operations
  - Category-based filtering and reporting
  - Performance with large numbers of categorized transactions
  """

  use Ashfolio.DataCase, async: false

  alias Ashfolio.FinancialManagement.CategorySeeder
  alias Ashfolio.FinancialManagement.TransactionCategory
  alias Ashfolio.Portfolio.Account
  alias Ashfolio.Portfolio.Symbol
  alias Ashfolio.Portfolio.Transaction

  @moduletag :integration
  @moduletag :v0_2_0

  describe "investment category assignment workflows" do
    setup do
      # Database-as-user architecture: No user entity needed
      {:ok, account} =
        Account.create(%{
          name: "Investment Account",
          account_type: :investment,
          currency: "USD",
          balance: Decimal.new("0")
        })

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "VTI",
          name: "Vanguard Total Stock Market ETF",
          current_price: Decimal.new("220.50"),
          data_source: :manual,
          asset_class: :etf
        })

      # Seed system categories
      CategorySeeder.seed_system_categories()

      {:ok, account: account, symbol: symbol}
    end

    test "assign category during transaction creation", %{
      account: account,
      symbol: symbol
    } do
      # Get available categories
      {:ok, categories} = TransactionCategory.list()
      growth_category = Enum.find(categories, &(&1.name == "Growth"))
      assert growth_category

      # Create transaction with category assignment
      {:ok, transaction} =
        Transaction.create(%{
          account_id: account.id,
          symbol_id: symbol.id,
          type: :buy,
          quantity: Decimal.new("50"),
          price: Decimal.new("220.50"),
          date: Date.utc_today(),
          total_amount: Decimal.new("11025.00"),
          category_id: growth_category.id
        })

      # Verify category assignment
      assert transaction.category_id == growth_category.id

      # Load transaction with category relationship
      {:ok, transaction_with_category} = Transaction.get_by_id(transaction.id, load: [:category])
      assert transaction_with_category.category.name == "Growth"
      assert transaction_with_category.category.color == "#10B981"
    end

    test "bulk category assignment to existing transactions", %{
      account: account,
      symbol: symbol
    } do
      # Create multiple transactions without categories
      transactions =
        for i <- 1..5 do
          {:ok, transaction} =
            Transaction.create(%{
              account_id: account.id,
              symbol_id: symbol.id,
              type: :buy,
              quantity: Decimal.new("#{10 + i}"),
              price: Decimal.new("220.50"),
              date: Date.add(Date.utc_today(), -i),
              total_amount: Decimal.mult(Decimal.new("#{10 + i}"), Decimal.new("220.50"))
            })

          transaction
        end

      # Get Income category
      {:ok, categories} = TransactionCategory.list()
      income_category = Enum.find(categories, &(&1.name == "Income"))

      # Bulk assign category to first 3 transactions
      transaction_ids = transactions |> Enum.take(3) |> Enum.map(& &1.id)

      updated_count =
        Enum.reduce(transaction_ids, 0, fn transaction_id, acc ->
          case Transaction.get_by_id(transaction_id) do
            {:ok, transaction} when not is_nil(transaction) ->
              case Transaction.update(transaction, %{category_id: income_category.id}) do
                {:ok, _} -> acc + 1
                {:error, _} -> acc
              end

            _ ->
              acc
          end
        end)

      assert updated_count == 3

      # Verify assignments
      {:ok, categorized_transactions} = Transaction.by_category(income_category.id)
      assert length(categorized_transactions) == 3

      # Verify remaining transactions are uncategorized
      {:ok, all_transactions} = Transaction.by_account(account.id)
      uncategorized = Enum.filter(all_transactions, &is_nil(&1.category_id))
      assert length(uncategorized) == 2
    end

    test "filter transactions by category", %{account: account, symbol: symbol} do
      # Get categories
      {:ok, categories} = TransactionCategory.list()
      growth_category = Enum.find(categories, &(&1.name == "Growth"))
      income_category = Enum.find(categories, &(&1.name == "Income"))

      # Create transactions in different categories
      {:ok, growth_tx1} =
        Transaction.create(%{
          account_id: account.id,
          symbol_id: symbol.id,
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("220.50"),
          date: Date.utc_today(),
          total_amount: Decimal.new("22050.00"),
          category_id: growth_category.id
        })

      {:ok, growth_tx2} =
        Transaction.create(%{
          account_id: account.id,
          symbol_id: symbol.id,
          type: :sell,
          quantity: Decimal.new("-25"),
          price: Decimal.new("225.00"),
          date: Date.utc_today(),
          total_amount: Decimal.new("5625.00"),
          category_id: growth_category.id
        })

      {:ok, income_tx} =
        Transaction.create(%{
          account_id: account.id,
          symbol_id: symbol.id,
          type: :dividend,
          quantity: Decimal.new("75"),
          price: Decimal.new("2.50"),
          date: Date.utc_today(),
          total_amount: Decimal.new("187.50"),
          category_id: income_category.id
        })

      {:ok, uncategorized_tx} =
        Transaction.create(%{
          account_id: account.id,
          symbol_id: symbol.id,
          type: :buy,
          quantity: Decimal.new("10"),
          price: Decimal.new("220.50"),
          date: Date.utc_today(),
          total_amount: Decimal.new("2205.00")
          # No category_id
        })

      # Filter by Growth category
      {:ok, growth_transactions} = Transaction.by_category(growth_category.id)
      growth_ids = growth_transactions |> Enum.map(& &1.id) |> Enum.sort()
      expected_growth_ids = Enum.sort([growth_tx1.id, growth_tx2.id])
      assert growth_ids == expected_growth_ids

      # Filter by Income category
      {:ok, income_transactions} = Transaction.by_category(income_category.id)
      assert length(income_transactions) == 1
      assert hd(income_transactions).id == income_tx.id

      # Get uncategorized transactions
      {:ok, all_transactions} = Transaction.by_account(account.id)
      uncategorized = Enum.filter(all_transactions, &is_nil(&1.category_id))
      assert length(uncategorized) == 1
      assert hd(uncategorized).id == uncategorized_tx.id
    end

    test "category performance reporting", %{account: account, symbol: symbol} do
      # Get categories
      {:ok, categories} = TransactionCategory.list()
      growth_category = Enum.find(categories, &(&1.name == "Growth"))
      income_category = Enum.find(categories, &(&1.name == "Income"))

      # Create transactions with different amounts per category
      growth_transactions = [
        %{quantity: Decimal.new("100"), price: Decimal.new("200.00"), type: :buy},
        %{quantity: Decimal.new("50"), price: Decimal.new("210.00"), type: :buy},
        %{quantity: Decimal.new("-25"), price: Decimal.new("220.00"), type: :sell}
      ]

      for tx_data <- growth_transactions do
        Transaction.create(%{
          account_id: account.id,
          symbol_id: symbol.id,
          type: tx_data.type,
          quantity: tx_data.quantity,
          price: tx_data.price,
          date: Date.utc_today(),
          total_amount: Decimal.mult(tx_data.quantity, tx_data.price),
          category_id: growth_category.id
        })
      end

      # Create income transactions
      {:ok, _dividend} =
        Transaction.create(%{
          account_id: account.id,
          symbol_id: symbol.id,
          type: :dividend,
          quantity: Decimal.new("150"),
          price: Decimal.new("2.00"),
          date: Date.utc_today(),
          total_amount: Decimal.new("300.00"),
          category_id: income_category.id
        })

      # Calculate category statistics
      {:ok, growth_stats} = calculate_category_statistics(growth_category.id)
      {:ok, income_stats} = calculate_category_statistics(income_category.id)

      # Growth category should have buy/sell transactions
      assert growth_stats.transaction_count == 3
      assert growth_stats.buy_count == 2
      assert growth_stats.sell_count == 1
      # 20000 + 10500
      assert Decimal.equal?(growth_stats.total_invested, Decimal.new("30500.00"))
      # 25 * 220
      assert Decimal.equal?(growth_stats.total_proceeds, Decimal.new("5500.00"))

      # Income category should have dividend transactions
      assert income_stats.transaction_count == 1
      assert income_stats.dividend_count == 1
      assert Decimal.equal?(income_stats.total_dividends, Decimal.new("300.00"))
    end
  end

  describe "system category protection" do
    setup do
      # Database-as-user architecture: No user entity needed
      # Seed system categories
      CategorySeeder.seed_system_categories()

      :ok
    end

    test "system categories cannot be deleted" do
      {:ok, categories} = TransactionCategory.list()
      system_category = Enum.find(categories, &(&1.is_system == true))
      assert system_category

      # Attempt to delete system category should fail
      result = TransactionCategory.destroy(system_category)

      case result do
        {:error, _changeset} ->
          # Expected - system categories protected
          assert true

        {:ok, _} ->
          # Should not succeed
          flunk("System category was deleted when it should be protected")
      end

      # Verify category still exists
      {:ok, updated_categories} = TransactionCategory.list()
      still_exists = Enum.find(updated_categories, &(&1.id == system_category.id))
      assert still_exists
    end

    test "system categories cannot be edited" do
      {:ok, categories} = TransactionCategory.list()
      system_category = Enum.find(categories, &(&1.is_system == true))

      # Attempt to modify system category should fail or be ignored
      result =
        TransactionCategory.update(system_category, %{
          name: "Modified System Category",
          color: "#FF0000"
        })

      case result do
        {:error, _changeset} ->
          # Expected - system categories protected
          assert true

        {:ok, updated} ->
          # If update succeeds, original values should be preserved
          assert updated.name == system_category.name
          assert updated.color == system_category.color
      end
    end

    test "custom categories can be modified and deleted" do
      # Create custom category
      {:ok, custom_category} =
        TransactionCategory.create(%{
          name: "Custom Growth",
          color: "#FF5733",
          is_system: false
        })

      # Should be able to update
      {:ok, updated} =
        TransactionCategory.update(custom_category, %{
          name: "Updated Custom Growth",
          color: "#33FF57"
        })

      assert updated.name == "Updated Custom Growth"
      assert updated.color == "#33FF57"

      # Should be able to delete
      :ok = TransactionCategory.destroy(updated)

      # Verify deletion
      result = TransactionCategory.get_by_id(custom_category.id)
      assert result == {:ok, nil} or match?({:error, _}, result)
    end
  end

  describe "category workflow performance" do
    setup do
      # Database-as-user architecture: No user entity needed
      {:ok, account} =
        Account.create(%{
          name: "Performance Account",
          account_type: :investment,
          currency: "USD",
          balance: Decimal.new("0")
        })

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "PERF",
          name: "Performance Test Stock",
          current_price: Decimal.new("100.00"),
          data_source: :manual,
          asset_class: :stock
        })

      # Seed categories
      CategorySeeder.seed_system_categories()

      {:ok, account: account, symbol: symbol}
    end

    test "category filtering performance with many transactions", %{
      account: account,
      symbol: symbol
    } do
      # Get category for assignment
      {:ok, categories} = TransactionCategory.list()
      category = hd(categories)

      # Create many transactions in the same category
      _transactions =
        for i <- 1..100 do
          transaction_type = if(rem(i, 2) == 0, do: :buy, else: :sell)

          quantity =
            if(transaction_type == :sell, do: Decimal.new("-#{i}"), else: Decimal.new("#{i}"))

          {:ok, transaction} =
            Transaction.create(%{
              account_id: account.id,
              symbol_id: symbol.id,
              type: transaction_type,
              quantity: quantity,
              price: Decimal.new("100.00"),
              date: Date.add(Date.utc_today(), -rem(i, 365)),
              total_amount: Decimal.mult(Decimal.new("#{i}"), Decimal.new("100.00")),
              category_id: category.id
            })

          transaction
        end

      # Measure filtering performance
      start_time = System.monotonic_time()
      {:ok, filtered_transactions} = Transaction.by_category(category.id)
      end_time = System.monotonic_time()

      duration_ms = System.convert_time_unit(end_time - start_time, :native, :millisecond)

      # Verify all transactions are returned
      assert length(filtered_transactions) == 100

      # Performance should be under 50ms for 100 transactions
      assert duration_ms < 50, "Category filtering took #{duration_ms}ms, expected < 50ms"

      # Verify correct category assignment
      assert Enum.all?(filtered_transactions, &(&1.category_id == category.id))
    end

    test "category statistics calculation performance", %{
      account: account,
      symbol: symbol
    } do
      # Create multiple categories with transactions
      {:ok, categories} = TransactionCategory.list()

      # Distribute 200 transactions across categories
      for {category, i} <- Enum.with_index(categories) do
        for j <- 1..50 do
          transaction_type = Enum.random([:buy, :sell, :dividend])

          quantity =
            case transaction_type do
              :sell -> Decimal.new("-#{j}")
              _ -> Decimal.new("#{j}")
            end

          Transaction.create(%{
            account_id: account.id,
            symbol_id: symbol.id,
            type: transaction_type,
            quantity: quantity,
            price: Decimal.new("100.00"),
            date: Date.add(Date.utc_today(), -(i * 50 + j)),
            total_amount: Decimal.mult(Decimal.new("#{j}"), Decimal.new("100.00")),
            category_id: category.id
          })
        end
      end

      # Measure statistics calculation for all categories
      start_time = System.monotonic_time()

      category_stats =
        for category <- categories do
          {:ok, stats} = calculate_category_statistics(category.id)
          {category.name, stats}
        end

      end_time = System.monotonic_time()
      duration_ms = System.convert_time_unit(end_time - start_time, :native, :millisecond)

      # Verify statistics calculated for all categories
      assert length(category_stats) == length(categories)

      # Performance should be reasonable even with many categorized transactions
      assert duration_ms < 200, "Category statistics took #{duration_ms}ms, expected < 200ms"

      # Verify each category has 50 transactions
      Enum.each(category_stats, fn {_name, stats} ->
        assert stats.transaction_count == 50
      end)
    end
  end

  # Helper function for category statistics calculation
  defp calculate_category_statistics(category_id) do
    {:ok, transactions} = Transaction.by_category(category_id)

    stats = %{
      transaction_count: length(transactions),
      buy_count: Enum.count(transactions, &(&1.type == :buy)),
      sell_count: Enum.count(transactions, &(&1.type == :sell)),
      dividend_count: Enum.count(transactions, &(&1.type == :dividend)),
      total_invested: calculate_total_by_type(transactions, [:buy]),
      total_proceeds: calculate_total_by_type(transactions, [:sell]),
      total_dividends: calculate_total_by_type(transactions, [:dividend])
    }

    {:ok, stats}
  end

  defp calculate_total_by_type(transactions, types) do
    transactions
    |> Enum.filter(&(&1.type in types))
    |> Enum.map(&Decimal.abs(&1.total_amount))
    |> Enum.reduce(Decimal.new("0"), &Decimal.add/2)
  end
end
