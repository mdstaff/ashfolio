defmodule Ashfolio.ValidationTest do
  use ExUnit.Case, async: true

  import Ecto.Changeset
  alias Ashfolio.Validation

  # Helper function to create a basic changeset for testing
  defp test_changeset(attrs \\ %{}) do
    types = %{
      price: :decimal,
      quantity: :decimal,
      fee: :decimal,
      date: :date,
      symbol: :string,
      currency: :string,
      name: :string,
      platform: :string,
      balance: :decimal,
      current_price: :decimal,
      type: :string,
      unit_price: :decimal
    }

    {%{}, types}
    |> cast(attrs, Map.keys(types))
  end

  describe "validate_positive_decimal/2" do
    test "accepts positive decimal values" do
      changeset = test_changeset(%{price: Decimal.new("10.50")})
      |> Validation.validate_positive_decimal(:price)

      assert changeset.valid?
    end

    test "rejects zero values" do
      changeset = test_changeset(%{price: Decimal.new("0")})
      |> Validation.validate_positive_decimal(:price)

      refute changeset.valid?
      assert changeset.errors[:price] != []
    end

    test "rejects negative values" do
      changeset = test_changeset(%{price: Decimal.new("-5.00")})
      |> Validation.validate_positive_decimal(:price)

      refute changeset.valid?
      assert changeset.errors[:price] != []
    end
  end

  describe "validate_non_negative_decimal/2" do
    test "accepts positive decimal values" do
      changeset = test_changeset(%{fee: Decimal.new("1.50")})
      |> Validation.validate_non_negative_decimal(:fee)

      assert changeset.valid?
    end

    test "accepts zero values" do
      changeset = test_changeset(%{fee: Decimal.new("0")})
      |> Validation.validate_non_negative_decimal(:fee)

      assert changeset.valid?
    end

    test "rejects negative values" do
      changeset = test_changeset(%{fee: Decimal.new("-1.00")})
      |> Validation.validate_non_negative_decimal(:fee)

      refute changeset.valid?
      assert changeset.errors[:fee] != []
    end
  end

  describe "validate_not_future_date/2" do
    test "accepts today's date" do
      changeset = test_changeset(%{date: Date.utc_today()})
      |> Validation.validate_not_future_date(:date)

      assert changeset.valid?
    end

    test "accepts past dates" do
      past_date = Date.add(Date.utc_today(), -30)
      changeset = test_changeset(%{date: past_date})
      |> Validation.validate_not_future_date(:date)

      assert changeset.valid?
    end

    test "rejects future dates" do
      future_date = Date.add(Date.utc_today(), 1)
      changeset = test_changeset(%{date: future_date})
      |> Validation.validate_not_future_date(:date)

      refute changeset.valid?
      assert changeset.errors[:date] != []
    end
  end

  describe "validate_symbol_format/2" do
    test "accepts valid stock symbols" do
      valid_symbols = ["AAPL", "MSFT", "GOOGL", "SPY", "QQQ"]

      for symbol <- valid_symbols do
        changeset = test_changeset(%{symbol: symbol})
        |> Validation.validate_symbol_format(:symbol)

        assert changeset.valid?, "Expected #{symbol} to be valid"
      end
    end

    test "rejects symbols that are too long" do
      changeset = test_changeset(%{symbol: "VERYLONGSYMBOL"})
      |> Validation.validate_symbol_format(:symbol)

      refute changeset.valid?
      assert changeset.errors[:symbol] != []
    end
  end

  describe "validate_supported_currency/2" do
    test "accepts USD currency" do
      changeset = test_changeset(%{currency: "USD"})
      |> Validation.validate_supported_currency(:currency)

      assert changeset.valid?
    end

    test "rejects non-USD currencies" do
      changeset = test_changeset(%{currency: "EUR"})
      |> Validation.validate_supported_currency(:currency)

      refute changeset.valid?
      assert changeset.errors[:currency] != []
    end
  end

  describe "comprehensive validation functions" do
    test "validate_transaction_data/2 works with valid data" do
      attrs = %{
        type: "buy",
        quantity: Decimal.new("10"),
        unit_price: Decimal.new("150.00"),
        fee: Decimal.new("1.00"),
        date: Date.utc_today(),
        currency: "USD"
      }

      changeset = test_changeset(attrs)
      |> Validation.validate_transaction_data()

      assert changeset.valid?
    end

    test "validate_account_data/2 works with valid data" do
      attrs = %{
        name: "Test Account",
        platform: "Test Platform",
        balance: Decimal.new("1000.00"),
        currency: "USD"
      }

      changeset = test_changeset(attrs)
      |> Validation.validate_account_data()

      assert changeset.valid?
    end
  end
end
