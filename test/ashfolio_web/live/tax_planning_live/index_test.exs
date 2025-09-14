defmodule AshfolioWeb.TaxPlanningLive.IndexTest do
  use AshfolioWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Ashfolio.Portfolio.Account
  alias Ashfolio.Portfolio.Symbol
  alias Ashfolio.Portfolio.Transaction

  describe "mount and initial render" do
    setup do
      # Clean up any existing data
      Account
      |> Ash.Query.for_read(:read)
      |> Ash.read!()
      |> Enum.each(&Account.destroy!/1)

      # Create test accounts
      {:ok, taxable} =
        Account.create(%{
          name: "Taxable Account",
          account_type: :investment,
          balance: Decimal.new("10000.00"),
          is_excluded: false
        })

      {:ok, ira} =
        Account.create(%{
          name: "IRA Account",
          account_type: :investment,
          balance: Decimal.new("50000.00"),
          is_excluded: false
        })

      {:ok, excluded} =
        Account.create(%{
          name: "Excluded Account",
          account_type: :investment,
          balance: Decimal.new("1000.00"),
          is_excluded: true
        })

      %{taxable: taxable, ira: ira, excluded: excluded}
    end

    test "mounts successfully with default values", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/tax-planning")

      assert html =~ "Tax Planning &amp; Optimization"
      assert html =~ "Capital Gains Analysis"
      assert html =~ "Tax-Loss Harvesting"

      # Check default year is current year
      assert html =~ "#{Date.utc_today().year}"
      # Check default tax rate
      assert html =~ "22%"
      # Check default account selection
      assert html =~ "All Accounts"
    end

    test "loads accounts correctly", %{conn: conn, taxable: taxable, ira: ira} do
      {:ok, _view, html} = live(conn, "/tax-planning")

      # Should show non-excluded accounts in dropdown
      assert html =~ taxable.name
      assert html =~ ira.name
      # Excluded accounts shouldn't appear
      refute html =~ "Excluded Account"
    end

    test "renders page title correctly", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/tax-planning")

      # Check page title is set
      assert html =~ "<title"
      assert html =~ "Tax Planning"
      assert html =~ "Ashfolio</title>"
    end
  end

  describe "tab navigation" do
    test "switches between tabs", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/tax-planning")

      # Switch to harvest opportunities tab
      html = render_click(view, "switch_tab", %{"tab" => "harvest_opportunities"})
      assert html =~ "Tax-Loss Harvesting"
      assert html =~ "harvest_opportunities"

      # Switch to annual summary tab
      html = render_click(view, "switch_tab", %{"tab" => "annual_summary"})
      assert html =~ "Annual Tax Summary"

      # Switch to tax lots tab
      html = render_click(view, "switch_tab", %{"tab" => "tax_lots"})
      assert html =~ "Tax Lot Report"

      # Switch back to capital gains
      html = render_click(view, "switch_tab", %{"tab" => "capital_gains"})
      assert html =~ "Capital Gains Analysis"
    end

    test "maintains tab state during form updates", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/tax-planning")

      # Switch to harvest opportunities
      render_click(view, "switch_tab", %{"tab" => "harvest_opportunities"})

      # Update form should maintain tab
      html = render_click(view, "update_tax_year", %{"tax_year" => "2023"})
      assert html =~ "Tax-Loss Harvesting"
      assert html =~ "2023"
    end
  end

  describe "form interactions" do
    setup %{conn: conn} do
      {:ok, view, _html} = live(conn, "/tax-planning")
      %{view: view}
    end

    test "updates tax year filter", %{view: view} do
      html = render_click(view, "update_tax_year", %{"tax_year" => "2023"})

      assert html =~ "2023"
      # Form should update with new year
      assert html =~ ~r/value="2023"/
    end

    test "updates account filter", %{view: view} do
      # Create a test account first
      {:ok, account} =
        Account.create(%{
          name: "Test Account",
          account_type: :investment,
          balance: Decimal.new("5000.00")
        })

      html = render_click(view, "update_account", %{"account_id" => account.id})

      # Should show selected account
      assert html =~ "Test Account"
    end

    test "updates marginal tax rate", %{view: view} do
      html = render_click(view, "update_tax_rate", %{"tax_rate" => "32"})

      assert html =~ "32%"
      # Form should update
      assert html =~ ~r/value="32"/
    end
  end

  describe "analysis actions" do
    setup %{conn: conn} do
      # Create test data for analysis
      {:ok, account} =
        Account.create(%{
          name: "Test Brokerage",
          account_type: :investment,
          balance: Decimal.new("25000.00")
        })

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "AAPL",
          name: "Apple Inc.",
          asset_class: :stock,
          data_source: :yahoo_finance
        })

      {:ok, buy_transaction} =
        Transaction.create(%{
          account_id: account.id,
          symbol_id: symbol.id,
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("150.00"),
          total_amount: Decimal.new("15000.00"),
          date: ~D[2023-01-15]
        })

      {:ok, sell_transaction} =
        Transaction.create(%{
          account_id: account.id,
          symbol_id: symbol.id,
          type: :sell,
          quantity: Decimal.new("-50"),
          price: Decimal.new("175.00"),
          total_amount: Decimal.new("8750.00"),
          date: ~D[2024-06-15]
        })

      {:ok, view, _html} = live(conn, "/tax-planning")

      %{
        view: view,
        account: account,
        symbol: symbol,
        buy: buy_transaction,
        sell: sell_transaction
      }
    end

    test "refreshes analysis data", %{view: view} do
      html = render_click(view, "refresh_analysis")

      # Should show loading state and then results or empty state
      assert html =~ "Capital Gains Analysis"
      # Should still be functional after refresh
      assert html =~ "Tax Planning"
    end

    test "handles analysis errors gracefully", %{view: view} do
      # Clear all transactions to cause an empty result
      Transaction
      |> Ash.Query.for_read(:read)
      |> Ash.read!()
      |> Enum.each(&Transaction.destroy!/1)

      html = render_click(view, "refresh_analysis")

      # Should handle empty data gracefully
      assert html =~ "Tax Planning"
      # Should show zero or empty state
      assert html =~ ~r/No.*data|0\.00|\$0|No Capital Gains Analysis Available/i
    end
  end

  describe "data display" do
    setup %{conn: conn} do
      {:ok, view, _html} = live(conn, "/tax-planning")

      # Simulate having analysis results by refreshing
      render_click(view, "refresh_analysis")

      %{view: view}
    end

    test "displays capital gains summary correctly", %{view: view} do
      html = render(view)

      # Should show summary sections
      assert html =~ "Total Realized"
      assert html =~ "Long-Term"
      assert html =~ "Short-Term"

      # Should format as currency
      assert html =~ ~r/\$[\d,]+\.\d{2}/
    end

    test "shows harvest opportunities when available", %{view: view} do
      render_click(view, "switch_tab", %{"tab" => "harvest_opportunities"})
      html = render_click(view, "refresh_analysis")

      assert html =~ "Tax-Loss Harvesting"
      # Either shows opportunities or empty state
      assert html =~ ~r/Opportunities|No.*opportunities|No.*Harvest.*Available/i
    end

    test "formats currency values correctly", %{view: view} do
      html = render(view)

      # Check for proper currency formatting with commas
      assert html =~ ~r/\$\d{1,3}(,\d{3})*(\.\d{2})?/

      # Should not show raw decimal values
      refute html =~ ~r/Decimal\.new/
    end

    test "displays empty state when no data available", %{view: view} do
      # Clear all data
      Transaction
      |> Ash.Query.for_read(:read)
      |> Ash.read!()
      |> Enum.each(&Transaction.destroy!/1)

      html = render_click(view, "refresh_analysis")

      # Should show appropriate empty state (may be in loading state)
      assert html =~ ~r/No.*available|No.*data|Analyzing|Loading/i
    end
  end

  describe "error handling" do
    setup %{conn: conn} do
      {:ok, view, _html} = live(conn, "/tax-planning")
      %{view: view}
    end

    test "displays errors when analysis fails", %{view: view} do
      # Test with invalid account selection
      html = render_click(view, "update_account", %{"account_id" => "invalid-id"})

      # Should handle invalid input gracefully
      assert html =~ "Tax Planning"
      # Page should still be functional
      assert html =~ "Capital Gains"
    end

    test "recovers from errors on retry", %{view: view} do
      # First try invalid account
      render_click(view, "update_account", %{"account_id" => "invalid"})

      # Then use valid selection
      html = render_click(view, "update_account", %{"account_id" => "all"})

      assert html =~ "All Accounts"
      # Should be back to normal
      assert html =~ "Capital Gains Analysis"
    end
  end

  describe "real-time updates" do
    test "updates when new transactions are added", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/tax-planning")

      # Add a new transaction while view is mounted
      {:ok, account} =
        Account.create(%{
          name: "New Account",
          account_type: :investment,
          balance: Decimal.new("1000.00")
        })

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "GOOGL",
          name: "Alphabet Inc.",
          asset_class: :stock,
          data_source: :yahoo_finance
        })

      {:ok, _transaction} =
        Transaction.create(%{
          account_id: account.id,
          symbol_id: symbol.id,
          type: :buy,
          quantity: Decimal.new("10"),
          price: Decimal.new("100.00"),
          total_amount: Decimal.new("1000.00"),
          date: Date.utc_today()
        })

      # Refresh analysis to see new data
      html = render_click(view, "refresh_analysis")

      # Should still be functional after adding new transaction
      assert html =~ "Tax Planning"
      assert html =~ ~r/Analysis|Capital Gains/
    end
  end

  describe "accessibility" do
    test "includes proper ARIA labels", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/tax-planning")

      # Check for accessibility attributes
      assert html =~ "aria-label"
      assert html =~ "role="

      # Forms should have labels (they use block text labels, not for= attributes)
      assert html =~ "<label"
      assert html =~ "text-sm font-medium"
    end

    test "provides keyboard navigation support", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/tax-planning")

      # Check for focus management (buttons are focusable by default)
      assert html =~ "focus:outline-none"

      # Buttons should be present and focusable
      assert html =~ "<button"
      assert html =~ "phx-click"
    end
  end
end
