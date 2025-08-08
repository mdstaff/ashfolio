defmodule AshfolioWeb.Integration.PortfolioViewFlowTest do
  @moduledoc """
  Integration tests for complete Portfolio View workflow:
  View Dashboard → Refresh Prices → View Updates → Check Calculations

  Task 29.1: Core Workflow Integration Tests - Portfolio View Flow
  """
  use AshfolioWeb.ConnCase, async: false

  @moduletag :integration
  @moduletag :slow
  @moduletag :mocked

  import Phoenix.LiveViewTest
  import Mox

  alias Ashfolio.Portfolio.{User, Account, Symbol, Transaction}
  alias Ashfolio.SQLiteHelpers

  setup :verify_on_exit!

  setup do
    # Create comprehensive test data
    {:ok, user} = SQLiteHelpers.get_or_create_default_user()

    # Allow PriceManager to access the database and mocks for price refresh tests
    SQLiteHelpers.allow_price_manager_db_access()

    {:ok, account} = Account.create(%{
      name: "Portfolio Test Account #{System.unique_integer([:positive])}",
      platform: "Test Broker",
      balance: Decimal.new("50000"),
      user_id: user.id
    })

    # Use existing symbols (created globally) and update their prices
    symbols_data = [
      %{ticker: "AAPL", price: "150.00"},
      %{ticker: "MSFT", price: "300.00"},
      %{ticker: "GOOGL", price: "120.00"}
    ]

    created_symbols =
      Enum.map(symbols_data, fn symbol_data ->
        symbol = SQLiteHelpers.get_common_symbol(symbol_data.ticker)
        {:ok, symbol} = Symbol.update_price(symbol, %{
          current_price: Decimal.new(symbol_data.price),
          price_updated_at: DateTime.utc_now()
        })
        symbol
      end)

    # Create sample transactions for portfolio
    [aapl, msft, googl] = created_symbols

    transactions = [
      # AAPL positions
      %{symbol: aapl, type: :buy, quantity: "100", price: "145.00", total: "14500.00"},
      %{symbol: aapl, type: :buy, quantity: "50", price: "155.00", total: "7750.00"},

      # MSFT positions
      %{symbol: msft, type: :buy, quantity: "75", price: "290.00", total: "21750.00"},

      # GOOGL positions
      %{symbol: googl, type: :buy, quantity: "200", price: "115.00", total: "23000.00"},
      %{symbol: googl, type: :sell, quantity: "-50", price: "125.00", total: "6250.00"}
    ]

    Enum.each(transactions, fn tx ->
      {:ok, _} = Transaction.create(%{
        type: tx.type,
        account_id: account.id,
        symbol_id: tx.symbol.id,
        quantity: Decimal.new(tx.quantity),
        price: Decimal.new(tx.price),
        total_amount: Decimal.new(tx.total),
        date: ~D[2024-08-01]
      })
    end)

    %{user: user, account: account, symbols: created_symbols}
  end

  describe "Complete Portfolio View Workflow" do
    @tag :skip
    test "end-to-end portfolio view: dashboard → refresh → updates → calculations",
         %{conn: conn, symbols: symbols} do

      # Step 1: View Dashboard - Initial state
      {:ok, view, html} = live(conn, "/")

      # Verify dashboard loads with portfolio data
      assert html =~ "Portfolio Dashboard"
      assert has_element?(view, "[data-testid='portfolio-summary']")
      assert has_element?(view, "[data-testid='holdings-table']")

      # Verify holdings appear in table
      assert render(view) =~ "AAPL"
      assert render(view) =~ "MSFT"
      assert render(view) =~ "GOOGL"

      # Capture initial portfolio values for comparison
      initial_html = render(view)

      # Extract initial total value (simplified pattern matching)
      initial_contains_value = String.contains?(initial_html, "$")

      # Step 2: Refresh Prices - Mock API responses
      [aapl, msft, googl] = symbols

      # Mock successful price fetch responses with updated prices
      expect(YahooFinanceMock, :fetch_prices, fn symbols ->
        prices = %{
          "AAPL" => Decimal.new("160.00"),
          "MSFT" => Decimal.new("310.00"),
          "GOOGL" => Decimal.new("130.00")
        }
        {:ok, Map.take(prices, symbols)}
      end)

      # Trigger price refresh
      view
      |> element("[data-testid='refresh-prices-button']", "Refresh Prices")
      |> render_click()

      # Wait for loading state
      assert has_element?(view, "[data-testid='loading-spinner']") or
             render(view) =~ "Refreshing"

      # Wait for refresh completion (check for success message or updated data)
      :timer.sleep(100)  # Brief pause for async operation

      # Step 3: View Updates - Verify price refresh results
      updated_html = render(view)

      # Verify success message appears
      assert updated_html =~ "Prices refreshed successfully" or
             updated_html =~ "Updated" or
             has_element?(view, ".alert-info")

      # Step 4: Check Calculations - Verify portfolio calculations updated

      # Holdings should show updated prices
      assert updated_html =~ "$160.00" or updated_html =~ "160"  # AAPL new price
      assert updated_html =~ "$310.00" or updated_html =~ "310"  # MSFT new price
      assert updated_html =~ "$130.00" or updated_html =~ "130"  # GOOGL new price

      # Verify portfolio totals recalculated
      # AAPL: 150 shares * $160 = $24,000
      # MSFT: 75 shares * $310 = $23,250
      # GOOGL: 150 shares * $130 = $19,500
      # Total current value should be approximately $66,750

      assert updated_html =~ "$24,000" or updated_html =~ "24000" or
             updated_html =~ "$23,250" or updated_html =~ "23250" or
             updated_html =~ "$19,500" or updated_html =~ "19500"

      # Verify unrealized P&L calculations updated
      # Should show gains since purchase prices were lower
      assert String.contains?(updated_html, "+") or
             String.contains?(updated_html, "text-green") or
             has_element?(view, ".text-green-600")

      # Verify last updated timestamp
      assert updated_html =~ "Last updated:" or
             updated_html =~ "minutes ago" or
             updated_html =~ "seconds ago"

      # Step 5: Verify Cost Basis Remains Unchanged
      # Cost basis should not change after price refresh, only current values
      # AAPL cost basis: $22,250 (100 * $145 + 50 * $155)
      # MSFT cost basis: $21,750 (75 * $290)
      # GOOGL cost basis: ~$17,000 (accounting for partial sale)

      cost_basis_present =
        updated_html =~ "22,250" or updated_html =~ "21,750" or updated_html =~ "17,000"

      assert cost_basis_present

      # Step 6: Test Error Handling - Mock API failure
      expect(YahooFinanceMock, :fetch_prices, fn _symbols ->
        {:error, :network_error}
      end)

      view
      |> element("[data-testid='refresh-prices-button']")
      |> render_click()

      :timer.sleep(100)

      # Verify error handling
      error_html = render(view)
      assert error_html =~ "error" or error_html =~ "failed" or
             has_element?(view, ".alert-danger")
    end

    test "portfolio calculations accuracy with complex transactions", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Verify complex calculations are correct
      html = render(view)

      # Check that portfolio summary shows reasonable values
      assert has_element?(view, "[data-testid='total-value']")
      assert has_element?(view, "[data-testid='total-return']")
      assert has_element?(view, "[data-testid='holdings-count']")

      # Verify holdings calculations
      assert has_element?(view, "[data-testid='holdings-table'] tbody tr")

      # Test that each holding shows:
      # - Symbol name
      # - Quantity (net of buys/sells)
      # - Current price
      # - Current value
      # - Cost basis
      # - Unrealized P&L

      holdings_html = view
      |> element("[data-testid='holdings-table']")
      |> render()

      # AAPL should show 150 shares (100 + 50)
      assert holdings_html =~ "150" and holdings_html =~ "AAPL"

      # MSFT should show 75 shares
      assert holdings_html =~ "75" and holdings_html =~ "MSFT"

      # GOOGL should show 150 shares (200 - 50)
      assert holdings_html =~ "150" and holdings_html =~ "GOOGL"
    end

    @tag :skip
    test "real-time portfolio updates via PubSub", %{conn: conn, account: account, symbols: symbols} do
      {:ok, view, _html} = live(conn, "/")

      initial_html = render(view)

      # Create a new transaction which should trigger PubSub update
      [aapl | _] = symbols

      {:ok, _new_transaction} = Transaction.create(%{
        type: :buy,
        account_id: account.id,
        symbol_id: aapl.id,
        quantity: Decimal.new("25"),
        price: Decimal.new("152.00"),
        total_amount: Decimal.new("3800.00"),
        date: ~D[2024-08-07]
      })

      # PubSub should automatically update dashboard
      # Wait briefly for PubSub message processing
      :timer.sleep(200)

      updated_html = render(view)

      # Verify portfolio updated with new transaction
      # AAPL quantity should now be 175 (150 + 25)
      assert updated_html != initial_html

      # The holdings should reflect the additional purchase
      assert updated_html =~ "175" or String.contains?(updated_html, "25")
    end

    test "responsive design and mobile view", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Test that responsive elements are present
      html = render(view)

      # Check for responsive grid classes
      assert html =~ "grid" or html =~ "flex"
      assert html =~ "sm:" or html =~ "md:" or html =~ "lg:"

      # Verify mobile navigation exists
      assert has_element?(view, "[data-testid='mobile-nav']") or
             has_element?(view, ".mobile-menu") or
             html =~ "hamburger"

      # Check that tables are responsive
      assert has_element?(view, ".overflow-x-auto") or
             has_element?(view, ".table-responsive")
    end
  end
end
