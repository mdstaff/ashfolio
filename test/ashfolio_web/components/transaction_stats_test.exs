defmodule AshfolioWeb.Components.TransactionStatsTest do
  use AshfolioWeb.ConnCase, async: true

  @moduletag :components
  @moduletag :transaction_stats

  import Phoenix.LiveViewTest

  alias AshfolioWeb.Components.TransactionStats
  alias Ashfolio.FinancialManagement.TransactionCategory
  alias Ashfolio.Portfolio.{Transaction, Account, Symbol}
  alias Ashfolio.SQLiteHelpers

  describe "TransactionStats component" do
    setup do
      user = SQLiteHelpers.get_default_user()

      {:ok, growth_category} =
        TransactionCategory.create(%{
          name: "Growth",
          color: "#10B981",
          user_id: user.id
        })

      {:ok, account} =
        Account.create(%{
          name: "Test Account",
          platform: "Test",
          balance: Decimal.new("10000.00"),
          user_id: user.id
        })

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "STAT",
          name: "Statistics Test Co",
          asset_class: :stock,
          data_source: :yahoo_finance,
          current_price: Decimal.new("100.00")
        })

      # Create sample transactions for statistics
      transactions = [
        create_transaction!(account, symbol, growth_category, %{
          type: :buy,
          quantity: Decimal.new("10"),
          price: Decimal.new("100.00"),
          total_amount: Decimal.new("1000.00"),
          date: ~D[2024-01-15]
        }),
        create_transaction!(account, symbol, growth_category, %{
          type: :sell,
          quantity: Decimal.new("-5"),
          price: Decimal.new("120.00"),
          total_amount: Decimal.new("600.00"),
          date: ~D[2024-02-15]
        }),
        create_transaction!(account, symbol, growth_category, %{
          type: :dividend,
          quantity: Decimal.new("10"),
          price: Decimal.new("2.50"),
          total_amount: Decimal.new("25.00"),
          date: ~D[2024-03-15]
        })
      ]

      %{
        user: user,
        transactions: transactions,
        growth_category: growth_category
      }
    end

    test "renders basic transaction statistics", %{transactions: transactions} do
      html =
        render_component(&TransactionStats.transaction_stats/1,
          transactions: transactions,
          show_breakdown: false
        )

      # Should show total count
      # Total transactions
      assert html =~ "3"

      # Should show total volume
      # Total transaction volume
      assert html =~ "1,625.00" or html =~ "$1,625"

      # Should show time period
      assert html =~ "2024" or html =~ "3 months"
    end

    test "displays transaction type breakdown", %{transactions: transactions} do
      html =
        render_component(&TransactionStats.transaction_stats/1,
          transactions: transactions,
          show_breakdown: true
        )

      # Should show breakdown by type
      assert html =~ "Buy"
      assert html =~ "Sell"
      assert html =~ "Dividend"

      # Should show percentages or counts
      # Individual counts
      assert html =~ "%" or html =~ "1"
    end

    test "shows category breakdown when enabled", %{transactions: transactions} do
      html =
        render_component(&TransactionStats.transaction_stats/1,
          transactions: transactions,
          show_breakdown: true,
          show_categories: true
        )

      # Should show category breakdown
      # Category name
      assert html =~ "Growth"
      # All transactions in one category
      assert html =~ "100%" or html =~ "3"
    end

    test "handles empty transaction list gracefully", %{} do
      html =
        render_component(&TransactionStats.transaction_stats/1,
          transactions: [],
          show_breakdown: false
        )

      # Should show zero state
      assert html =~ "No transactions" or html =~ "0"
      # No percentages for empty data
      refute html =~ "%"
    end

    test "calculates correct average transaction size", %{transactions: transactions} do
      html =
        render_component(&TransactionStats.transaction_stats/1,
          transactions: transactions,
          show_averages: true
        )

      # Average: (1000 + 600 + 25) / 3 = 541.67
      # Rounded average
      assert html =~ "541" or html =~ "542"
      assert html =~ "Average" or html =~ "Avg"
    end

    test "shows time period analysis", %{transactions: transactions} do
      html =
        render_component(&TransactionStats.transaction_stats/1,
          transactions: transactions,
          show_time_analysis: true
        )

      # Should show time span
      assert html =~ "Jan" or html =~ "Mar" or html =~ "2024"
      assert html =~ "period" or html =~ "span" or html =~ "range"
    end

    test "supports compact layout mode", %{transactions: transactions} do
      html =
        render_component(&TransactionStats.transaction_stats/1,
          transactions: transactions,
          compact: true
        )

      # Should have compact styling
      assert html =~ "text-sm" or html =~ "p-2" or html =~ "gap-2"

      # Should still show key metrics
      # Transaction count
      assert html =~ "3"
    end

    test "includes proper accessibility attributes", %{transactions: transactions} do
      html =
        render_component(&TransactionStats.transaction_stats/1,
          transactions: transactions
        )

      # Should have proper ARIA attributes
      assert html =~ "aria-label" or html =~ "role="

      # Should have proper heading structure
      assert html =~ "h3" or html =~ "h4"
    end

    test "handles large numbers with proper formatting", %{transactions: transactions} do
      # Create a large transaction
      large_transactions =
        transactions ++
          [
            %{
              id: "large-tx",
              type: :buy,
              total_amount: Decimal.new("50000.00"),
              date: ~D[2024-04-15]
            }
          ]

      html =
        render_component(&TransactionStats.transaction_stats/1,
          transactions: large_transactions
        )

      # Should format large numbers properly
      # Comma formatting
      assert html =~ "50,000" or html =~ "51,625"
      # Currency symbol
      assert html =~ "$"
    end

    test "supports custom CSS classes", %{transactions: transactions} do
      html =
        render_component(&TransactionStats.transaction_stats/1,
          transactions: transactions,
          class: "custom-stats-class extra-styling"
        )

      assert html =~ "custom-stats-class"
      assert html =~ "extra-styling"
    end
  end

  describe "TransactionStats calculation helpers" do
    test "correctly calculates transaction volume", %{transactions: transactions} do
      html =
        render_component(&TransactionStats.transaction_stats/1,
          transactions: transactions,
          show_volume_calculation: true
        )

      # Total volume: 1000 + 600 + 25 = 1625
      assert html =~ "1,625" or html =~ "$1,625"
    end

    test "handles different transaction types in calculations", %{transactions: transactions} do
      html =
        render_component(&TransactionStats.transaction_stats/1,
          transactions: transactions,
          show_breakdown: true
        )

      # Should differentiate between buy/sell/dividend
      assert html =~ "Buy" and html =~ "Sell" and html =~ "Dividend"
    end

    test "calculates correct date ranges", %{transactions: transactions} do
      html =
        render_component(&TransactionStats.transaction_stats/1,
          transactions: transactions,
          show_time_analysis: true
        )

      # Date range: Jan 15 to Mar 15, 2024
      assert html =~ "Jan" or html =~ "2024-01"
      assert html =~ "Mar" or html =~ "2024-03"
    end
  end

  describe "TransactionStats performance and display" do
    test "renders quickly with many transactions" do
      # Create 100 mock transactions
      many_transactions =
        Enum.map(1..100, fn i ->
          %{
            id: "tx-#{i}",
            type: Enum.random([:buy, :sell, :dividend]),
            total_amount: Decimal.new("#{100 + i}.00"),
            date: Date.add(~D[2024-01-01], i)
          }
        end)

      start_time = :os.system_time(:microsecond)

      html =
        render_component(&TransactionStats.transaction_stats/1,
          transactions: many_transactions
        )

      end_time = :os.system_time(:microsecond)
      render_time = end_time - start_time

      # Should render quickly (under 100ms)
      assert render_time < 100_000, "Rendering should be fast even with many transactions"

      # Should still show correct count
      assert html =~ "100"
    end

    test "handles edge cases in date calculations", %{} do
      edge_case_transactions = [
        %{
          id: "same-date-1",
          type: :buy,
          total_amount: Decimal.new("100.00"),
          date: ~D[2024-01-01]
        },
        %{
          id: "same-date-2",
          type: :sell,
          total_amount: Decimal.new("100.00"),
          date: ~D[2024-01-01]
        }
      ]

      html =
        render_component(&TransactionStats.transaction_stats/1,
          transactions: edge_case_transactions,
          show_time_analysis: true
        )

      # Should handle same-date transactions gracefully
      assert html =~ "2024-01-01" or html =~ "1 day" or html =~ "same day"
    end
  end

  # Helper function to create transactions
  defp create_transaction!(account, symbol, category, attrs) do
    default_attrs = %{
      fee: Decimal.new("0.00"),
      account_id: account.id,
      symbol_id: symbol.id,
      category_id: category.id
    }

    {:ok, transaction} = Transaction.create(Map.merge(default_attrs, attrs))
    transaction
  end
end
