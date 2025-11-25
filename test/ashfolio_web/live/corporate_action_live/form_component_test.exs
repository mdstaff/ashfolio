defmodule AshfolioWeb.CorporateActionLive.FormComponentTest do
  use AshfolioWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Ashfolio.Portfolio.CorporateAction

  @moduletag :live

  describe "conditional field rendering" do
    setup do
      # Create test symbols
      aapl = Ashfolio.SQLiteHelpers.get_or_create_symbol("AAPL", %{name: "Apple Inc."})
      msft = Ashfolio.SQLiteHelpers.get_or_create_symbol("MSFT", %{name: "Microsoft Corporation"})
      newco = Ashfolio.SQLiteHelpers.get_or_create_symbol("NEWCO", %{name: "New Company"})

      %{symbols: [aapl, msft, newco]}
    end

    test "displays split ratio fields when stock_split is selected", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/corporate-actions/new")

      # Select stock split action type
      view
      |> form("#corporate-action-form", %{
        "form" => %{"action_type" => "stock_split"}
      })
      |> render_change()

      # Assert split ratio fields are visible
      assert has_element?(view, "#form_split_ratio_from")
      assert has_element?(view, "#form_split_ratio_to")
      assert has_element?(view, "[data-role='split-details']")

      # Assert help text is visible
      assert render(view) =~ "For a 2:1 split"
    end

    test "displays dividend fields when cash_dividend is selected", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/corporate-actions/new")

      view
      |> form("#corporate-action-form", %{
        "form" => %{"action_type" => "cash_dividend"}
      })
      |> render_change()

      # Assert dividend fields are visible
      assert has_element?(view, "#form_dividend_amount")
      assert has_element?(view, "#form_dividend_currency")
      assert has_element?(view, "#form_qualified_dividend")
      assert has_element?(view, "[data-role='dividend-details']")
    end

    test "displays dividend fields when stock_dividend is selected", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/corporate-actions/new")

      view
      |> form("#corporate-action-form", %{
        "form" => %{"action_type" => "stock_dividend"}
      })
      |> render_change()

      # Assert dividend fields are visible (same as cash dividend)
      assert has_element?(view, "#form_dividend_amount")
      assert has_element?(view, "#form_dividend_currency")
      assert has_element?(view, "[data-role='dividend-details']")

      # Stock dividend might not show qualified checkbox
      # We'll verify this behavior after implementation
    end

    test "displays merger fields when merger is selected", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/corporate-actions/new")

      view
      |> form("#corporate-action-form", %{
        "form" => %{"action_type" => "merger"}
      })
      |> render_change()

      # Assert merger fields are visible
      assert has_element?(view, "#form_exchange_ratio")
      assert has_element?(view, "#form_cash_consideration")
      assert has_element?(view, "[data-role='merger-details']")
    end

    test "displays spinoff fields when spinoff is selected", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/corporate-actions/new")

      view
      |> form("#corporate-action-form", %{
        "form" => %{"action_type" => "spinoff"}
      })
      |> render_change()

      # Assert spinoff fields are visible
      assert has_element?(view, "#form_new_symbol_id")
      assert has_element?(view, "#form_exchange_ratio")
      assert has_element?(view, "[data-role='spinoff-details']")
    end

    test "displays dividend fields when return_of_capital is selected", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/corporate-actions/new")

      view
      |> form("#corporate-action-form", %{
        "form" => %{"action_type" => "return_of_capital"}
      })
      |> render_change()

      # Assert dividend amount field is visible (return of capital uses dividend amount)
      assert has_element?(view, "#form_dividend_amount")
      assert has_element?(view, "[data-role='dividend-details']")
    end

    test "hides conditional fields when action type is cleared", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/corporate-actions/new")

      # First select an action type
      view
      |> form("#corporate-action-form", %{
        "form" => %{"action_type" => "stock_split"}
      })
      |> render_change()

      assert has_element?(view, "#form_split_ratio_from")

      # Then clear it
      view
      |> form("#corporate-action-form", %{
        "form" => %{"action_type" => ""}
      })
      |> render_change()

      # Assert fields are hidden
      refute has_element?(view, "#form_split_ratio_from")
      refute has_element?(view, "[data-role='split-details']")
    end

    test "switches between different action types correctly", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/corporate-actions/new")

      # Start with stock split
      view
      |> form("#corporate-action-form", %{
        "form" => %{"action_type" => "stock_split"}
      })
      |> render_change()

      assert has_element?(view, "#form_split_ratio_from")
      refute has_element?(view, "#form_dividend_amount")

      # Switch to cash dividend
      view
      |> form("#corporate-action-form", %{
        "form" => %{"action_type" => "cash_dividend"}
      })
      |> render_change()

      refute has_element?(view, "#form_split_ratio_from")
      assert has_element?(view, "#form_dividend_amount")

      # Switch to merger
      view
      |> form("#corporate-action-form", %{
        "form" => %{"action_type" => "merger"}
      })
      |> render_change()

      refute has_element?(view, "#form_dividend_amount")
      assert has_element?(view, "#form_exchange_ratio")
    end
  end

  describe "form submission with conditional fields" do
    setup do
      aapl = Ashfolio.SQLiteHelpers.get_or_create_symbol("AAPL", %{name: "Apple Inc."})
      %{symbol: aapl}
    end

    test "successfully creates stock split with ratio fields", %{conn: conn, symbol: symbol} do
      {:ok, view, _html} = live(conn, ~p"/corporate-actions/new")

      # First trigger action_type change to render conditional fields
      view
      |> form("#corporate-action-form", %{
        "form" => %{
          "action_type" => "stock_split",
          "symbol_id" => symbol.id,
          "ex_date" => "2024-06-01",
          "description" => "2:1 stock split"
        }
      })
      |> render_change()

      # Now submit with all fields including conditional ones
      view
      |> form("#corporate-action-form", %{
        "form" => %{
          "action_type" => "stock_split",
          "symbol_id" => symbol.id,
          "ex_date" => "2024-06-01",
          "description" => "2:1 stock split",
          "split_ratio_from" => "1",
          "split_ratio_to" => "2"
        }
      })
      |> render_submit()

      # Should redirect to index
      assert_redirect(view, ~p"/corporate-actions")

      # Verify the action was created by checking the database
      actions = CorporateAction.read!()
      assert length(actions) > 0

      stock_split = Enum.find(actions, &(&1.action_type == :stock_split))
      assert stock_split
      assert stock_split.symbol_id == symbol.id
      assert stock_split.description == "2:1 stock split"
    end

    test "successfully creates cash dividend with amount and currency", %{conn: conn, symbol: symbol} do
      {:ok, view, _html} = live(conn, ~p"/corporate-actions/new")

      # First trigger action_type change to render conditional fields
      view
      |> form("#corporate-action-form", %{
        "form" => %{
          "action_type" => "cash_dividend",
          "symbol_id" => symbol.id,
          "ex_date" => "2024-06-15",
          "description" => "Q2 dividend"
        }
      })
      |> render_change()

      # Now submit with all fields including conditional ones
      view
      |> form("#corporate-action-form", %{
        "form" => %{
          "action_type" => "cash_dividend",
          "symbol_id" => symbol.id,
          "ex_date" => "2024-06-15",
          "description" => "Q2 dividend",
          "dividend_amount" => "1.50",
          "dividend_currency" => "USD",
          "qualified_dividend" => "true"
        }
      })
      |> render_submit()

      assert_redirect(view, ~p"/corporate-actions")

      # Verify the action was created by checking the database
      actions = CorporateAction.read!()
      cash_dividend = Enum.find(actions, &(&1.action_type == :cash_dividend))
      assert cash_dividend
      assert cash_dividend.symbol_id == symbol.id
      assert cash_dividend.description == "Q2 dividend"
    end

    test "shows validation errors for missing split ratios", %{conn: conn, symbol: symbol} do
      {:ok, view, _html} = live(conn, ~p"/corporate-actions/new")

      # First trigger action_type change to render conditional fields
      view
      |> form("#corporate-action-form", %{
        "form" => %{
          "action_type" => "stock_split",
          "symbol_id" => symbol.id,
          "ex_date" => "2024-06-01",
          "description" => "Missing ratios"
        }
      })
      |> render_change()

      # Now submit without required split ratio fields
      view
      |> form("#corporate-action-form", %{
        "form" => %{
          "action_type" => "stock_split",
          "symbol_id" => symbol.id,
          "ex_date" => "2024-06-01",
          "description" => "Missing ratios"
          # Missing split_ratio_from and split_ratio_to
        }
      })
      |> render_submit()

      # Should not redirect, stays on form with errors
      # Validation shows split_ratio_from error first (validation proceeds field-by-field)
      assert render(view) =~ "Split ratio from is required for stock splits"
    end

    test "shows validation errors for missing dividend amount", %{conn: conn, symbol: symbol} do
      {:ok, view, _html} = live(conn, ~p"/corporate-actions/new")

      # First trigger action_type change to render conditional fields
      view
      |> form("#corporate-action-form", %{
        "form" => %{
          "action_type" => "cash_dividend",
          "symbol_id" => symbol.id,
          "ex_date" => "2024-06-15",
          "description" => "Missing amount"
        }
      })
      |> render_change()

      # Now submit without required dividend amount field
      view
      |> form("#corporate-action-form", %{
        "form" => %{
          "action_type" => "cash_dividend",
          "symbol_id" => symbol.id,
          "ex_date" => "2024-06-15",
          "description" => "Missing amount"
          # Missing dividend_amount
        }
      })
      |> render_submit()

      assert render(view) =~ "Dividend amount is required"
    end

    @tag :flaky
    test "validates merger requires either exchange ratio or cash consideration", %{conn: conn, symbol: symbol} do
      {:ok, view, _html} = live(conn, ~p"/corporate-actions/new")

      # First trigger action_type change to render conditional fields
      view
      |> form("#corporate-action-form", %{
        "form" => %{
          "action_type" => "merger",
          "symbol_id" => symbol.id,
          "ex_date" => "2024-07-01",
          "description" => "Missing merger details"
        }
      })
      |> render_change()

      # Try to submit without either exchange ratio or cash consideration
      view
      |> form("#corporate-action-form", %{
        "form" => %{
          "action_type" => "merger",
          "symbol_id" => symbol.id,
          "ex_date" => "2024-07-01",
          "description" => "Missing merger details"
        }
      })
      |> render_submit()

      assert render(view) =~ "Merger must have either exchange ratio or cash consideration"
    end
  end

  describe "edge cases" do
    setup do
      aapl = Ashfolio.SQLiteHelpers.get_or_create_symbol("AAPL", %{name: "Apple Inc."})
      %{symbol: aapl}
    end

    test "handles rapid action type changes", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/corporate-actions/new")

      # Rapidly change action types
      for type <- ["stock_split", "cash_dividend", "merger", "spinoff", "stock_split"] do
        view
        |> form("#corporate-action-form", %{"form" => %{"action_type" => type}})
        |> render_change()
      end

      # Should end with stock split fields visible
      assert has_element?(view, "#form_split_ratio_from")
      assert has_element?(view, "#form_split_ratio_to")
    end

    test "preserves common field values when switching types", %{conn: conn, symbol: symbol} do
      {:ok, view, _html} = live(conn, ~p"/corporate-actions/new")

      # Set common fields and stock split
      view
      |> form("#corporate-action-form", %{
        "form" => %{
          "action_type" => "stock_split",
          "symbol_id" => symbol.id,
          "ex_date" => "2024-06-01",
          "description" => "Test description"
        }
      })
      |> render_change()

      # Switch to dividend
      view
      |> form("#corporate-action-form", %{
        "form" => %{"action_type" => "cash_dividend"}
      })
      |> render_change()

      # Common fields should be preserved
      html = render(view)
      assert html =~ "2024-06-01"
      assert html =~ "Test description"
    end
  end
end
