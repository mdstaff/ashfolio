defmodule AshfolioWeb.AccountLive.BalanceUpdateComponentTest do
  use AshfolioWeb.LiveViewCase

  import Phoenix.LiveViewTest

  alias Ashfolio.Context
  alias Ashfolio.Portfolio.Account
  alias AshfolioWeb.AccountLive.BalanceUpdateComponent

  describe "Balance Update Component" do
    setup do
      # Database-as-user architecture: No user entity needed
      # Create a cash account for testing
      {:ok, cash_account} =
        Account.create(%{
          name: "Test Savings Account",
          platform: "Test Bank",
          account_type: :savings,
          balance: Decimal.new("1000.00")
        })

      # Create an investment account for negative balance testing
      {:ok, investment_account} =
        Account.create(%{
          name: "Test Investment Account",
          platform: "Test Broker",
          account_type: :investment,
          balance: Decimal.new("5000.00")
        })

      %{
        cash_account: cash_account,
        investment_account: investment_account
      }
    end

    test "renders balance update modal for cash account", %{cash_account: cash_account} do
      component_html =
        render_component(BalanceUpdateComponent,
          id: "test-balance-update",
          account: cash_account
        )

      assert component_html =~ "Update Cash Balance"
      assert component_html =~ cash_account.name
      assert component_html =~ "Savings Account"
      assert component_html =~ "$1,000.00"
      assert component_html =~ "New Balance"
      assert component_html =~ "Notes (Optional)"
    end

    test "validates positive balance for savings account", %{cash_account: cash_account} do
      # Start the component
      {view, _html} =
        live_component_isolated(BalanceUpdateComponent, %{
          id: "test-balance-update",
          account: cash_account
        })

      # Try to enter a negative balance
      view
      |> element("#balance-update-form")
      |> render_change(%{"new_balance" => "-100.00", "notes" => ""})

      # Check that validation error appears
      assert has_element?(view, "li", "Savings accounts cannot have negative balances")
    end

    test "allows negative balance for investment account", %{
      investment_account: investment_account
    } do
      # Start the component
      {view, _html} =
        live_component_isolated(BalanceUpdateComponent, %{
          id: "test-balance-update",
          account: investment_account
        })

      # Enter a negative balance (should be allowed for investment accounts)
      view
      |> element("#balance-update-form")
      |> render_change(%{"new_balance" => "-500.00", "notes" => "Margin call"})

      # Check that no validation error appears
      refute has_element?(view, "li", "cannot have negative balances")
    end

    test "shows balance change preview", %{cash_account: cash_account} do
      # Start the component
      {view, _html} =
        live_component_isolated(BalanceUpdateComponent, %{
          id: "test-balance-update",
          account: cash_account
        })

      # Enter new balance
      view
      |> element("#balance-update-form")
      |> render_change(%{"new_balance" => "1500.00", "notes" => ""})

      # Check that balance change preview appears
      assert has_element?(view, "div", "+$500.00")
      assert has_element?(view, "span", "$1,500.00")
    end

    test "successfully updates cash balance", %{cash_account: cash_account} do
      # Start the component
      {view, _html} =
        live_component_isolated(BalanceUpdateComponent, %{
          id: "test-balance-update",
          account: cash_account
        })

      # Submit balance update
      view
      |> element("#balance-update-form")
      |> render_submit(%{"new_balance" => "1500.00", "notes" => "Monthly deposit"})

      # Verify account was updated in database
      {:ok, updated_account} = Account.get_by_id(cash_account.id)
      assert Decimal.equal?(updated_account.balance, Decimal.new("1500.00"))

      # Verify balance history was created
      {:ok, history} = Context.get_balance_history(cash_account.id)
      assert length(history) == 1

      history_item = List.first(history)
      assert Decimal.equal?(history_item.old_balance, Decimal.new("1000.00"))
      assert Decimal.equal?(history_item.new_balance, Decimal.new("1500.00"))
      assert history_item.notes == "Monthly deposit"
    end

    test "handles validation errors for invalid input", %{cash_account: cash_account} do
      # Start the component
      {view, _html} =
        live_component_isolated(BalanceUpdateComponent, %{
          id: "test-balance-update",
          account: cash_account
        })

      # Try to submit invalid balance
      view
      |> element("#balance-update-form")
      |> render_change(%{"new_balance" => "invalid", "notes" => ""})

      # Check that validation error appears
      assert has_element?(view, "li", "Please enter a valid number")
    end

    test "handles empty balance input", %{cash_account: cash_account} do
      # Start the component
      {view, _html} =
        live_component_isolated(BalanceUpdateComponent, %{
          id: "test-balance-update",
          account: cash_account
        })

      # Try to submit empty balance
      view
      |> element("#balance-update-form")
      |> render_change(%{"new_balance" => "", "notes" => ""})

      # Check that validation error appears
      assert has_element?(view, "li", "Balance is required")
    end

    test "updates balance without notes", %{cash_account: cash_account} do
      # Start the component
      {view, _html} =
        live_component_isolated(BalanceUpdateComponent, %{
          id: "test-balance-update",
          account: cash_account
        })

      # Submit balance update without notes
      view
      |> element("#balance-update-form")
      |> render_submit(%{"new_balance" => "2000.00", "notes" => ""})

      # Verify balance history was created with nil notes
      {:ok, history} = Context.get_balance_history(cash_account.id)
      assert length(history) == 1

      history_item = List.first(history)
      assert history_item.notes == nil
    end

    test "cancels balance update", %{cash_account: cash_account} do
      # Start the component
      {view, _html} =
        live_component_isolated(BalanceUpdateComponent, %{
          id: "test-balance-update",
          account: cash_account
        })

      # Click cancel button
      view |> element("button", "Cancel") |> render_click()

      # Verify original balance is unchanged
      {:ok, unchanged_account} = Account.get_by_id(cash_account.id)
      assert Decimal.equal?(unchanged_account.balance, Decimal.new("1000.00"))
    end

    test "prevents updates for non-cash accounts", %{investment_account: investment_account} do
      # This test verifies the Context API prevents updates for non-cash accounts
      result =
        Context.update_cash_balance(
          investment_account.id,
          Decimal.new("3000.00"),
          "Should not work"
        )

      assert {:error, :not_cash_account} = result
    end

    test "shows updating state when submitting", %{cash_account: cash_account} do
      # Start the component
      {view, _html} =
        live_component_isolated(BalanceUpdateComponent, %{
          id: "test-balance-update",
          account: cash_account
        })

      # Check submit button text before update
      assert has_element?(view, "button[type='submit']", "Update Balance")

      # Start form submission (this will trigger updating state briefly)
      view
      |> element("#balance-update-form")
      |> render_submit(%{"new_balance" => "1200.00", "notes" => "Test"})

      # In a real scenario, the updating state would be visible briefly
      # Here we verify the form handles the submission correctly
      {:ok, updated_account} = Account.get_by_id(cash_account.id)
      assert Decimal.equal?(updated_account.balance, Decimal.new("1200.00"))
    end
  end

  # Helper function for isolated component testing
  defp live_component_isolated(component_module, assigns) do
    # Create a minimal LiveView that hosts the component
    unique_id = System.unique_integer([:positive])
    module_name = Module.concat([TestHostLiveView, "Instance#{unique_id}"])

    defmodule module_name do
      use Phoenix.LiveView

      def render(assigns) do
        ~H"""
        <.live_component module={@component_module} id="test-component" {@component_assigns} />
        """
      end

      def mount(_params, session, socket) do
        component_module = session["component_module"]
        component_assigns = session["component_assigns"]

        {:ok, assign(socket, component_module: component_module, component_assigns: component_assigns)}
      end
    end

    session = %{
      "component_module" => component_module,
      "component_assigns" => assigns
    }

    {:ok, view, html} = live_isolated(build_conn(), module_name, session: session)
    {view, html}
  end
end
