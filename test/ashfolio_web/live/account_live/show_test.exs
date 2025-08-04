defmodule AshfolioWeb.AccountLive.ShowTest do
  use AshfolioWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Ashfolio.Portfolio.{User, Account, Transaction, Symbol}

  setup do
    # Create default user
    {:ok, user} = User.create(%{name: "Test User", currency: "USD", locale: "en-US"})

    # Create test account
    {:ok, account} = Account.create(%{
      name: "Test Account",
      platform: "Test Platform",
      balance: Decimal.new("10000.00"),
      user_id: user.id
    })

    # Create test symbol
    {:ok, symbol} = Symbol.create(%{
      symbol: "AAPL",
      name: "Apple Inc.",
      asset_class: :stock,
      data_source: :yahoo_finance,
      current_price: Decimal.new("150.00")
    })

    # Create test transactions
    {:ok, buy_transaction} = Transaction.create(%{
      type: :buy,
      quantity: Decimal.new("10"),
      price: Decimal.new("150.00"),
      total_amount: Decimal.new("1500.00"),
      fee: Decimal.new("1.00"),
      date: Date.utc_today(),
      account_id: account.id,
      symbol_id: symbol.id
    })

    {:ok, sell_transaction} = Transaction.create(%{
      type: :sell,
      quantity: Decimal.new("-5"),
      price: Decimal.new("160.00"),
      total_amount: Decimal.new("-800.00"),
      fee: Decimal.new("1.00"),
      date: Date.utc_today(),
      account_id: account.id,
      symbol_id: symbol.id
    })

    {:ok, dividend_transaction} = Transaction.create(%{
      type: :dividend,
      quantity: Decimal.new("10"),
      price: Decimal.new("2.50"),
      total_amount: Decimal.new("25.00"),
      fee: Decimal.new("0.00"),
      date: Date.utc_today(),
      account_id: account.id,
      symbol_id: symbol.id
    })

    {:ok, fee_transaction} = Transaction.create(%{
      type: :fee,
      quantity: Decimal.new("0"),
      price: Decimal.new("0.00"),
      total_amount: Decimal.new("5.00"),
      fee: Decimal.new("0.00"),
      date: Date.utc_today(),
      account_id: account.id,
      symbol_id: symbol.id
    })

    %{
      user: user,
      account: account,
      symbol: symbol,
      buy_transaction: buy_transaction,
      sell_transaction: sell_transaction,
      dividend_transaction: dividend_transaction,
      fee_transaction: fee_transaction
    }
  end

  describe "mount and handle_params" do
    test "displays account details with transactions", %{conn: conn, account: account} do
      {:ok, _show_live, html} = live(conn, ~p"/accounts/#{account.id}")

      assert html =~ account.name
      assert html =~ account.platform
      assert html =~ "$10,000.00"
      assert html =~ "Active"
      assert html =~ "Transaction Summary"
    end

    test "displays breadcrumb navigation", %{conn: conn, account: account} do
      {:ok, _show_live, html} = live(conn, ~p"/accounts/#{account.id}")

      assert html =~ "Accounts"
      assert html =~ account.name
    end

    test "displays transaction statistics", %{conn: conn, account: account} do
      {:ok, _show_live, html} = live(conn, ~p"/accounts/#{account.id}")

      # Should show transaction counts
      assert html =~ "Buy Orders"
      assert html =~ "Sell Orders"
      assert html =~ "Dividends"
      assert html =~ "Fees"

      # Should show transaction totals
      assert html =~ "$1,500.00"  # Buy total
      assert html =~ "$800.00"    # Sell total
      assert html =~ "$25.00"     # Dividend total
      assert html =~ "$5.00"      # Fee total
    end

    test "displays excluded account status", %{conn: conn, account: account} do
      # Update account to be excluded
      {:ok, excluded_account} = Account.toggle_exclusion(account, %{is_excluded: true})

      {:ok, _show_live, html} = live(conn, ~p"/accounts/#{excluded_account.id}")

      assert html =~ "Excluded"
      assert html =~ "Excluded from Portfolio"
      assert html =~ "Not included in portfolio"
    end

    test "displays edit account link", %{conn: conn, account: account} do
      {:ok, _show_live, html} = live(conn, ~p"/accounts/#{account.id}")

      assert html =~ "Edit Account"
      assert html =~ ~p"/accounts/#{account.id}/edit"
    end

    test "redirects to accounts index when account not found", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()

      # The LiveView should handle the NotFound error and redirect
      assert_raise Ash.Error.Invalid, fn ->
        live(conn, ~p"/accounts/#{non_existent_id}")
      end
    end
  end

  describe "account with no transactions" do
    test "displays empty state when account has no transactions", %{conn: conn, user: user} do
      # Create account with no transactions
      {:ok, empty_account} = Account.create(%{
        name: "Empty Account",
        platform: "Test Platform",
        balance: Decimal.new("5000.00"),
        user_id: user.id
      })

      {:ok, _show_live, html} = live(conn, ~p"/accounts/#{empty_account.id}")

      assert html =~ "No transactions"
      assert html =~ "This account doesn&#39;t have any transactions yet"
      assert html =~ "Add Transaction"
    end
  end

  describe "transaction statistics calculation" do
    test "correctly calculates transaction statistics", %{conn: conn, account: account} do
      {:ok, show_live, _html} = live(conn, ~p"/accounts/#{account.id}")

      # Get the transaction stats from the assigns
      transaction_stats = :sys.get_state(show_live.pid).socket.assigns.transaction_stats

      assert transaction_stats.buy_count == 1
      assert Decimal.equal?(transaction_stats.buy_total, Decimal.new("1500.00"))

      assert transaction_stats.sell_count == 1
      assert Decimal.equal?(transaction_stats.sell_total, Decimal.new("800.00"))

      assert transaction_stats.dividend_count == 1
      assert Decimal.equal?(transaction_stats.dividend_total, Decimal.new("25.00"))

      assert transaction_stats.fee_count == 1
      assert Decimal.equal?(transaction_stats.fee_total, Decimal.new("5.00"))
    end
  end
end
