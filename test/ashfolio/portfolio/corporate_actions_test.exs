defmodule Ashfolio.Portfolio.CorporateActionsTest do
  use Ashfolio.DataCase, async: false

  alias Ashfolio.Portfolio.CorporateAction

  @moduletag :ash_resources
  @moduletag :corporate_actions
  @moduletag :unit

  describe "CorporateAction resource" do
    setup do
      # Create a test symbol to use in all tests
      symbol = Ashfolio.SQLiteHelpers.get_or_create_symbol("AAPL", %{name: "Apple Inc."})
      {:ok, symbol: symbol}
    end

    test "creates a valid stock split corporate action", %{symbol: symbol} do
      # Test data following TDD approach
      action_attrs = %{
        action_type: :stock_split,
        symbol_id: symbol.id,
        ex_date: ~D[2024-12-01],
        description: "2:1 stock split",
        split_ratio_from: Decimal.new("1"),
        split_ratio_to: Decimal.new("2"),
        status: :pending
      }

      # This test will fail until we implement the CorporateAction resource
      assert {:ok, corporate_action} = CorporateAction.create(action_attrs)

      assert corporate_action.action_type == :stock_split
      assert corporate_action.symbol_id == symbol.id
      assert corporate_action.ex_date == ~D[2024-12-01]
      assert corporate_action.description == "2:1 stock split"
      assert Decimal.equal?(corporate_action.split_ratio_from, Decimal.new("1"))
      assert Decimal.equal?(corporate_action.split_ratio_to, Decimal.new("2"))
      assert corporate_action.status == :pending
    end

    test "creates a valid cash dividend corporate action", %{symbol: symbol} do
      action_attrs = %{
        action_type: :cash_dividend,
        symbol_id: symbol.id,
        ex_date: ~D[2024-12-01],
        pay_date: ~D[2024-12-15],
        description: "$0.50 quarterly dividend",
        dividend_amount: Decimal.new("0.50"),
        dividend_currency: "USD",
        qualified_dividend: true,
        status: :pending
      }

      assert {:ok, corporate_action} = CorporateAction.create(action_attrs)

      assert corporate_action.action_type == :cash_dividend
      assert corporate_action.ex_date == ~D[2024-12-01]
      assert corporate_action.pay_date == ~D[2024-12-15]
      assert Decimal.equal?(corporate_action.dividend_amount, Decimal.new("0.50"))
      assert corporate_action.qualified_dividend == true
    end

    test "creates a valid stock merger corporate action", %{symbol: symbol} do
      # Create new symbol for merger
      new_symbol = Ashfolio.SQLiteHelpers.get_or_create_symbol("XYZ", %{name: "XYZ Corp."})

      action_attrs = %{
        action_type: :merger,
        symbol_id: symbol.id,
        ex_date: ~D[2024-12-01],
        description: "Acquisition by XYZ Corp - 1.5 XYZ shares per old share",
        merger_type: :stock_for_stock,
        new_symbol_id: new_symbol.id,
        exchange_ratio: Decimal.new("1.5"),
        status: :pending
      }

      assert {:ok, corporate_action} = CorporateAction.create(action_attrs)

      assert corporate_action.action_type == :merger
      assert corporate_action.merger_type == :stock_for_stock
      assert corporate_action.new_symbol_id == new_symbol.id
      assert Decimal.equal?(corporate_action.exchange_ratio, Decimal.new("1.5"))
    end

    test "requires mandatory fields", %{symbol: _symbol} do
      # Missing required fields should cause validation errors
      invalid_attrs = %{
        action_type: :stock_split
        # Missing symbol_id, ex_date, etc.
      }

      assert {:error, changeset} = CorporateAction.create(invalid_attrs)
      # Check that validation errors are returned (exact format may vary)
      assert changeset.errors != []
    end

    test "validates stock split ratios are positive", %{symbol: symbol} do
      invalid_attrs = %{
        action_type: :stock_split,
        symbol_id: symbol.id,
        ex_date: ~D[2024-12-01],
        description: "Invalid split",
        # Invalid - cannot be zero
        split_ratio_from: Decimal.new("0"),
        split_ratio_to: Decimal.new("2"),
        status: :pending
      }

      assert {:error, changeset} = CorporateAction.create(invalid_attrs)
      assert changeset.errors != []
    end

    test "validates dividend amount is positive for cash dividends", %{symbol: symbol} do
      invalid_attrs = %{
        action_type: :cash_dividend,
        symbol_id: symbol.id,
        ex_date: ~D[2024-12-01],
        description: "Invalid dividend",
        # Invalid - cannot be negative
        dividend_amount: Decimal.new("-0.50"),
        status: :pending
      }

      assert {:error, changeset} = CorporateAction.create(invalid_attrs)
      assert changeset.errors != []
    end

    test "validates ex_date is not in the future for applied actions", %{symbol: symbol} do
      future_date = Date.add(Date.utc_today(), 30)

      invalid_attrs = %{
        action_type: :stock_split,
        symbol_id: symbol.id,
        ex_date: future_date,
        description: "Future split",
        split_ratio_from: Decimal.new("1"),
        split_ratio_to: Decimal.new("2"),
        # Cannot be applied if ex_date is in future
        status: :applied
      }

      # This validation might not be implemented yet, so just check for error
      assert {:error, _changeset} = CorporateAction.create(invalid_attrs)
    end
  end

  describe "CorporateAction relationships and queries" do
    setup do
      # Create test data using SQLite helpers
      account = Ashfolio.SQLiteHelpers.get_default_account()
      symbol = Ashfolio.SQLiteHelpers.get_or_create_symbol("AAPL", %{name: "Apple Inc."})

      {:ok, account: account, symbol: symbol}
    end

    test "finds actions by symbol", %{symbol: symbol} do
      # Create multiple corporate actions for the symbol
      {:ok, _split_action} =
        CorporateAction.create(%{
          action_type: :stock_split,
          symbol_id: symbol.id,
          ex_date: ~D[2024-01-01],
          description: "2:1 split",
          split_ratio_from: Decimal.new("1"),
          split_ratio_to: Decimal.new("2"),
          status: :applied
        })

      {:ok, _dividend_action} =
        CorporateAction.create(%{
          action_type: :cash_dividend,
          symbol_id: symbol.id,
          ex_date: ~D[2024-06-01],
          description: "$1.00 dividend",
          dividend_amount: Decimal.new("1.00"),
          status: :applied
        })

      # Query actions for the symbol
      actions = CorporateAction.by_symbol!(symbol.id)

      assert length(actions) == 2
      action_types = Enum.map(actions, & &1.action_type)
      assert :stock_split in action_types
      assert :cash_dividend in action_types
    end

    test "finds actions by date range", %{symbol: symbol} do
      # Create actions across different dates
      {:ok, _old_action} =
        CorporateAction.create(%{
          action_type: :stock_split,
          symbol_id: symbol.id,
          ex_date: ~D[2023-01-01],
          description: "Old split",
          split_ratio_from: Decimal.new("1"),
          split_ratio_to: Decimal.new("2"),
          status: :applied
        })

      {:ok, recent_action} =
        CorporateAction.create(%{
          action_type: :cash_dividend,
          symbol_id: symbol.id,
          ex_date: ~D[2024-06-01],
          description: "Recent dividend",
          dividend_amount: Decimal.new("1.00"),
          status: :applied
        })

      # Query actions in date range (2024 only)
      actions = CorporateAction.by_date_range!(~D[2024-01-01], ~D[2024-12-31])

      assert length(actions) == 1
      assert List.first(actions).id == recent_action.id
    end

    test "finds pending actions requiring application", %{symbol: symbol} do
      # Create mix of pending and applied actions
      {:ok, pending_action} =
        CorporateAction.create(%{
          action_type: :stock_split,
          symbol_id: symbol.id,
          # Ex-date in past
          ex_date: Date.add(Date.utc_today(), -5),
          description: "Pending split",
          split_ratio_from: Decimal.new("1"),
          split_ratio_to: Decimal.new("2"),
          status: :pending
        })

      {:ok, _applied_action} =
        CorporateAction.create(%{
          action_type: :cash_dividend,
          symbol_id: symbol.id,
          ex_date: ~D[2024-01-01],
          description: "Applied dividend",
          dividend_amount: Decimal.new("1.00"),
          status: :applied
        })

      # Query only pending actions
      pending_actions = CorporateAction.pending!()

      assert length(pending_actions) == 1
      assert List.first(pending_actions).id == pending_action.id
      assert List.first(pending_actions).status == :pending
    end
  end

  describe "CorporateAction audit trail" do
    setup do
      symbol = Ashfolio.SQLiteHelpers.get_or_create_symbol("MSFT", %{name: "Microsoft Corp."})
      {:ok, symbol: symbol}
    end

    test "maintains created_at and updated_at timestamps", %{symbol: symbol} do
      {:ok, action} =
        CorporateAction.create(%{
          action_type: :stock_split,
          symbol_id: symbol.id,
          ex_date: ~D[2024-12-01],
          description: "2:1 split",
          split_ratio_from: Decimal.new("1"),
          split_ratio_to: Decimal.new("2"),
          status: :pending
        })

      assert %DateTime{} = action.inserted_at
      assert %DateTime{} = action.updated_at

      # Update the action
      {:ok, updated_action} = CorporateAction.update(action, %{status: :applied})

      assert DateTime.after?(updated_action.updated_at, action.updated_at)
    end

    test "tracks who applied the action", %{symbol: symbol} do
      {:ok, action} =
        CorporateAction.create(%{
          action_type: :stock_split,
          symbol_id: symbol.id,
          ex_date: ~D[2024-12-01],
          description: "2:1 split",
          split_ratio_from: Decimal.new("1"),
          split_ratio_to: Decimal.new("2"),
          status: :pending
        })

      # Apply the action with audit info
      {:ok, applied_action} =
        CorporateAction.update(action, %{
          status: :applied,
          applied_by: "system",
          applied_at: DateTime.utc_now()
        })

      assert applied_action.applied_by == "system"
      assert %DateTime{} = applied_action.applied_at
    end
  end
end
