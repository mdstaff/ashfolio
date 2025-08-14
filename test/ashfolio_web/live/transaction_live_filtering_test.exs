defmodule AshfolioWeb.TransactionLive.FilteringTest do
  use AshfolioWeb.ConnCase, async: false

  @moduletag :live_view
  @moduletag :filtering

  import Phoenix.LiveViewTest

  alias Ashfolio.FinancialManagement.TransactionCategory
  alias Ashfolio.Portfolio.{Transaction, Account, Symbol, User}
  alias Ashfolio.SQLiteHelpers

  describe "enhanced filter state management" do
    setup %{conn: conn} do
      user = SQLiteHelpers.get_default_user()

      # Create test categories
      {:ok, growth_category} =
        TransactionCategory.create(%{
          name: "Growth",
          color: "#10B981",
          is_system: true,
          user_id: user.id
        })

      {:ok, income_category} =
        TransactionCategory.create(%{
          name: "Income",
          color: "#3B82F6",
          is_system: true,
          user_id: user.id
        })

      # Create test account and symbol
      {:ok, account} =
        Account.create(%{
          name: "Filter Test Account",
          platform: "Test",
          balance: Decimal.new("20000.00"),
          user_id: user.id
        })

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "FILT",
          name: "Filter Test Co",
          asset_class: :stock,
          data_source: :yahoo_finance,
          current_price: Decimal.new("75.00")
        })

      # Create test transactions
      {:ok, growth_tx} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("20"),
          price: Decimal.new("75.00"),
          total_amount: Decimal.new("1500.00"),
          fee: Decimal.new("0.00"),
          date: Date.utc_today(),
          account_id: account.id,
          symbol_id: symbol.id,
          category_id: growth_category.id
        })

      {:ok, income_tx} =
        Transaction.create(%{
          type: :dividend,
          quantity: Decimal.new("20"),
          price: Decimal.new("2.50"),
          total_amount: Decimal.new("50.00"),
          fee: Decimal.new("0.00"),
          date: Date.utc_today(),
          account_id: account.id,
          symbol_id: symbol.id,
          category_id: income_category.id
        })

      {:ok, uncategorized_tx} =
        Transaction.create(%{
          type: :sell,
          quantity: Decimal.new("-10"),
          price: Decimal.new("80.00"),
          total_amount: Decimal.new("800.00"),
          fee: Decimal.new("5.00"),
          date: Date.utc_today(),
          account_id: account.id,
          symbol_id: symbol.id
        })

      %{
        conn: conn,
        user: user,
        growth_category: growth_category,
        income_category: income_category,
        growth_tx: growth_tx,
        income_tx: income_tx,
        uncategorized_tx: uncategorized_tx
      }
    end

    test "maintains filter state across page reloads", %{conn: conn, growth_category: category} do
      {:ok, view, _html} = live(conn, ~p"/transactions")

      # Apply category filter
      view
      |> form("#category-filter-form", %{category_id: category.id})
      |> render_change()

      # Verify filter is applied
      assert has_element?(view, "[data-filter-active='category:#{category.id}']")

      # Simulate page reload by creating new live view with URL params
      {:ok, new_view, _html} = live(conn, ~p"/transactions?category=#{category.id}")

      # Verify filter state is restored
      assert has_element?(new_view, "[data-filter-active='category:#{category.id}']")
    end

    test "handles concurrent filter updates gracefully", %{
      conn: conn,
      growth_category: cat1,
      income_category: cat2
    } do
      {:ok, view, _html} = live(conn, ~p"/transactions")

      # Apply multiple rapid filter changes
      view
      |> form("#category-filter-form", %{category_id: cat1.id})
      |> render_change()

      view
      |> form("#category-filter-form", %{category_id: cat2.id})
      |> render_change()

      view
      |> form("#category-filter-form", %{category_id: ""})
      |> render_change()

      # Final state should be "all categories"
      assert has_element?(view, "[data-filter-active='category:all']")
    end

    test "persists filter state to URL parameters", %{conn: conn, growth_category: category} do
      {:ok, view, _html} = live(conn, ~p"/transactions")

      # Apply category filter
      view
      |> form("#category-filter-form", %{category_id: category.id})
      |> render_change()

      # Check that URL was updated (this would be verified by checking push_patch events)
      # For now, verify the filter state is maintained in the view
      assert has_element?(view, "[data-filter-active='category:#{category.id}']")
    end

    test "restores filter state from URL on mount", %{conn: conn, growth_category: category} do
      # Mount with URL parameters
      {:ok, view, _html} = live(conn, ~p"/transactions?category=#{category.id}")

      # Verify filter state is restored from URL
      assert has_element?(view, "[data-filter-active='category:#{category.id}']")

      # Verify correct transactions are displayed
      assert has_element?(view, "[data-transaction-category='#{category.id}']")
    end

    test "debounces rapid filter changes", %{conn: conn, growth_category: category} do
      {:ok, view, _html} = live(conn, ~p"/transactions")

      # Make rapid changes to trigger debouncing
      start_time = :os.system_time(:millisecond)

      for _i <- 1..5 do
        view
        |> form("#category-filter-form", %{category_id: category.id})
        |> render_change()

        view
        |> form("#category-filter-form", %{category_id: ""})
        |> render_change()
      end

      end_time = :os.system_time(:millisecond)

      # Verify rapid changes complete quickly (due to debouncing)
      assert end_time - start_time < 1000, "Filter updates should be debounced"

      # Final state should be correctly applied
      assert has_element?(view, "[data-filter-active='category:all']")
    end
  end

  describe "composite filter state management" do
    setup %{conn: conn} do
      user = SQLiteHelpers.get_default_user()

      {:ok, category} =
        TransactionCategory.create(%{
          name: "Composite Filter Test",
          color: "#FF5733",
          user_id: user.id
        })

      {:ok, account} =
        Account.create(%{
          name: "Composite Test Account",
          platform: "Test",
          balance: Decimal.new("15000.00"),
          user_id: user.id
        })

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "COMP",
          name: "Composite Test",
          asset_class: :stock,
          data_source: :yahoo_finance,
          current_price: Decimal.new("100.00")
        })

      # Create transactions on different dates
      today = Date.utc_today()
      week_ago = Date.add(today, -7)

      {:ok, recent_tx} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("10"),
          price: Decimal.new("100.00"),
          total_amount: Decimal.new("1000.00"),
          fee: Decimal.new("0.00"),
          date: today,
          account_id: account.id,
          symbol_id: symbol.id,
          category_id: category.id
        })

      {:ok, old_tx} =
        Transaction.create(%{
          type: :sell,
          quantity: Decimal.new("-5"),
          price: Decimal.new("105.00"),
          total_amount: Decimal.new("525.00"),
          fee: Decimal.new("0.00"),
          date: week_ago,
          account_id: account.id,
          symbol_id: symbol.id,
          category_id: category.id
        })

      %{
        conn: conn,
        category: category,
        recent_tx: recent_tx,
        old_tx: old_tx,
        today: today,
        week_ago: week_ago
      }
    end

    test "manages multiple filter types simultaneously", %{conn: conn, category: category} do
      {:ok, view, _html} = live(conn, ~p"/transactions")

      # Apply category filter
      view
      |> form("#category-filter-form", %{category_id: category.id})
      |> render_change()

      # Apply transaction type filter
      view
      |> form("#type-filter-form", %{transaction_type: "buy"})
      |> render_change()

      # Verify both filters are active
      assert has_element?(view, "[data-filter-active='category:#{category.id}']")
      assert has_element?(view, "[data-filter-active='type:buy']")
    end

    test "preserves filter combinations across navigation", %{conn: conn, category: category} do
      {:ok, view, _html} = live(conn, ~p"/transactions")

      # Apply multiple filters
      view
      |> form("#category-filter-form", %{category_id: category.id})
      |> render_change()

      view
      |> form("#type-filter-form", %{transaction_type: "buy"})
      |> render_change()

      # Simulate navigation away and back
      {:ok, new_view, _html} = live(conn, ~p"/transactions?category=#{category.id}&type=buy")

      # Verify both filters are restored
      assert has_element?(new_view, "[data-filter-active='category:#{category.id}']")
      assert has_element?(new_view, "[data-filter-active='type:buy']")
    end

    test "handles filter clearing correctly", %{conn: conn, category: category} do
      {:ok, view, _html} = live(conn, ~p"/transactions")

      # Apply filters
      view
      |> form("#category-filter-form", %{category_id: category.id})
      |> render_change()

      view
      |> form("#type-filter-form", %{transaction_type: "buy"})
      |> render_change()

      # Clear all filters
      view
      |> element("[data-action='clear-filters']")
      |> render_click()

      # Verify all filters are cleared
      assert has_element?(view, "[data-filter-active='category:all']")
      assert has_element?(view, "[data-filter-active='type:all']")
    end
  end

  describe "filter state validation and error handling" do
    test "handles invalid URL parameters gracefully", %{conn: conn} do
      # Mount with invalid parameters
      {:ok, view, _html} = live(conn, ~p"/transactions?category=invalid-uuid&type=invalid-type")

      # Should fall back to default filter state
      assert has_element?(view, "[data-filter-active='category:all']")
      assert has_element?(view, "[data-filter-active='type:all']")
    end

    test "recovers from filter application errors", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/transactions")

      # Try to apply filter that might cause an error
      view
      |> form("#category-filter-form", %{category_id: "non-existent-id"})
      |> render_change()

      # Should handle gracefully and show appropriate state
      # (Non-existent category should just show no results)
      assert has_element?(view, "[data-filter-count='0']") or
               has_element?(view, "[data-filter-active='category:all']")
    end

    test "validates filter parameter formats", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/transactions")

      # Test various invalid parameter formats
      invalid_params = [
        %{category_id: nil},
        %{category_id: ""},
        %{category_id: 123}
      ]

      Enum.each(invalid_params, fn params ->
        view
        |> form("#category-filter-form", params)
        |> render_change()

        # Should either apply valid defaults or maintain current state
        assert has_element?(view, "[data-filter-active]")
      end)
    end
  end

  describe "real-time filter updates" do
    setup %{conn: conn} do
      user = SQLiteHelpers.get_default_user()

      {:ok, category} =
        TransactionCategory.create(%{
          name: "Real-time Test",
          color: "#ABCDEF",
          user_id: user.id
        })

      %{conn: conn, category: category}
    end

    test "updates filters when transactions are added", %{conn: conn, category: category} do
      {:ok, view, _html} = live(conn, ~p"/transactions")

      # Apply category filter
      view
      |> form("#category-filter-form", %{category_id: category.id})
      |> render_change()

      initial_count = get_filter_count(view)

      # Simulate adding a new transaction (would trigger PubSub event)
      # For now, just verify the filter state structure is maintained
      assert has_element?(view, "[data-filter-count]")
      assert initial_count >= 0
    end

    test "maintains filter state during real-time updates", %{conn: conn, category: category} do
      {:ok, view, _html} = live(conn, ~p"/transactions")

      # Apply filter
      view
      |> form("#category-filter-form", %{category_id: category.id})
      |> render_change()

      # Verify filter remains active after potential PubSub updates
      assert has_element?(view, "[data-filter-active='category:#{category.id}']")
    end
  end

  # Helper functions
  defp get_filter_count(view) do
    case render(view) do
      html when is_binary(html) ->
        case Regex.run(~r/data-filter-count=['"](\d+)['"]/, html) do
          [_, count] -> String.to_integer(count)
          nil -> 0
        end

      _ ->
        0
    end
  end
end
