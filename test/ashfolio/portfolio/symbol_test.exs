defmodule Ashfolio.Portfolio.SymbolTest do
  use Ashfolio.DataCase, async: false

  @moduletag :ash_resources
  @moduletag :unit
  @moduletag :fast
  @moduletag :smoke

  import Ashfolio.SQLiteHelpers
  alias Ashfolio.Portfolio.Symbol

  describe "Symbol resource" do
    test "can create symbol with required attributes" do
      # Use unique symbol to avoid conflicts with global data
      unique_symbol = "TEST#{System.unique_integer([:positive])}"

      {:ok, symbol} =
        Ash.create(Symbol, %{
          symbol: unique_symbol,
          asset_class: :stock,
          data_source: :yahoo_finance
        })

      assert symbol.symbol == unique_symbol
      assert symbol.asset_class == :stock
      assert symbol.data_source == :yahoo_finance
      # Default value
      assert symbol.currency == "USD"
      # Default value
      assert symbol.sectors == []
      # Default value
      assert symbol.countries == []
      assert symbol.id != nil
    end

    test "can create symbol with all attributes" do
      current_time = DateTime.utc_now()
      unique_symbol = "FULL#{System.unique_integer([:positive])}"

      {:ok, symbol} =
        Ash.create(Symbol, %{
          symbol: unique_symbol,
          name: "Test Company Inc.",
          asset_class: :stock,
          currency: "USD",
          isin: "US0378331005",
          sectors: ["Technology", "Consumer Electronics"],
          countries: ["United States"],
          data_source: :yahoo_finance,
          current_price: Decimal.new("150.25"),
          price_updated_at: current_time
        })

      assert symbol.symbol == unique_symbol
      assert symbol.name == "Test Company Inc."
      assert symbol.asset_class == :stock
      assert symbol.currency == "USD"
      assert symbol.isin == "US0378331005"
      assert symbol.sectors == ["Technology", "Consumer Electronics"]
      assert symbol.countries == ["United States"]
      assert symbol.data_source == :yahoo_finance
      assert Decimal.equal?(symbol.current_price, Decimal.new("150.25"))
      # Allow for small time differences due to processing
      assert DateTime.diff(symbol.price_updated_at, current_time, :millisecond) |> abs() < 1000
    end

    test "requires symbol attribute" do
      {:error, changeset} =
        Ash.create(Symbol, %{
          asset_class: :stock,
          data_source: :yahoo_finance
        })

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :symbol end)
    end

    test "requires asset_class attribute" do
      unique_symbol = "REQ#{System.unique_integer([:positive])}"

      {:error, changeset} =
        Ash.create(Symbol, %{
          symbol: unique_symbol,
          data_source: :yahoo_finance
        })

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :asset_class end)
    end


    test "validates asset_class is one of allowed values" do
      unique_symbol = "VAL#{System.unique_integer([:positive])}"

      {:error, changeset} =
        Ash.create(Symbol, %{
          symbol: unique_symbol,
          asset_class: :invalid_class,
          data_source: :yahoo_finance
        })

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :asset_class end)
    end





    test "allows valid symbol formats" do
      # Use unique identifiers to avoid conflicts
      unique_id = System.unique_integer([:positive])
      valid_formats = ["ABC", "BTC-USD", "SPY", "VTI", "MSFT", "GOOGL", "AMZN.L"]

      for format <- valid_formats do
        unique_symbol = "#{format}#{unique_id}#{System.unique_integer([:positive])}"
        {:ok, symbol} =
          Ash.create(Symbol, %{
            symbol: unique_symbol,
            asset_class: :stock,
            data_source: :yahoo_finance
          })

        assert symbol.symbol == unique_symbol
      end
    end
  end

  describe "Symbol actions" do
    setup do
      # Use unique symbols to avoid conflicts with global data
      unique_id = System.unique_integer([:positive])

      # Create test symbols with unique identifiers
      {:ok, aapl} =
        Ash.create(Symbol, %{
          symbol: "AAPL#{unique_id}",
          name: "Apple Inc. Test",
          asset_class: :stock,
          data_source: :yahoo_finance,
          current_price: Decimal.new("150.00"),
          price_updated_at: DateTime.utc_now()
        })

      {:ok, btc} =
        Ash.create(Symbol, %{
          symbol: "BTC#{unique_id}",
          name: "Bitcoin Test",
          asset_class: :crypto,
          data_source: :coingecko,
          current_price: Decimal.new("45000.00"),
          # 2 hours ago
          price_updated_at: DateTime.utc_now() |> DateTime.add(-7200, :second)
        })

      {:ok, spy} =
        Ash.create(Symbol, %{
          symbol: "SPY#{unique_id}",
          name: "SPDR S&P 500 ETF Test",
          asset_class: :etf,
          data_source: :yahoo_finance
        })

      %{aapl: aapl, btc: btc, spy: spy}
    end

    test "can find symbol by ticker symbol", %{aapl: aapl} do
      {:ok, [found_symbol]} = Symbol.find_by_symbol(aapl.symbol)
      assert found_symbol.id == aapl.id
      assert found_symbol.symbol == aapl.symbol
    end

    test "can find symbols by asset class", %{aapl: aapl} do
      {:ok, symbols} = Symbol.by_asset_class(:stock)
      symbol_ids = Enum.map(symbols, & &1.id)
      assert aapl.id in symbol_ids
    end

    test "can find symbols by data source", %{aapl: aapl, spy: spy} do
      {:ok, symbols} = Symbol.by_data_source(:yahoo_finance)
      symbol_ids = Enum.map(symbols, & &1.id)
      assert aapl.id in symbol_ids
      assert spy.id in symbol_ids
    end

    test "can find symbols with prices", %{aapl: aapl, btc: btc} do
      {:ok, symbols} = Ash.read(Symbol, action: :with_prices)
      symbol_ids = Enum.map(symbols, & &1.id)
      assert aapl.id in symbol_ids
      assert btc.id in symbol_ids
      assert length(symbols) >= 2
    end

    test "can find symbols with stale prices", %{btc: btc} do
      # BTC was updated 2 hours ago, so it should be stale with 1 hour threshold
      one_hour_ago = DateTime.utc_now() |> DateTime.add(-3600, :second)
      {:ok, symbols} = Symbol.stale_prices(one_hour_ago)

      symbol_ids = Enum.map(symbols, & &1.id)
      assert btc.id in symbol_ids
    end

    test "can update symbol price", %{aapl: aapl} do
      new_price = Decimal.new("155.50")
      new_time = DateTime.utc_now()

      {:ok, updated_symbol} =
        Ash.update(
          aapl,
          %{
            current_price: new_price,
            price_updated_at: new_time
          },
          action: :update_price
        )

      assert Decimal.equal?(updated_symbol.current_price, new_price)
      # Allow for small time differences due to processing
      assert DateTime.diff(updated_symbol.price_updated_at, new_time, :millisecond) |> abs() <
               1000
    end

    test "can update symbol attributes", %{spy: spy} do
      {:ok, updated_symbol} =
        Ash.update(
          spy,
          %{
            name: "SPDR S&P 500 ETF Trust",
            sectors: ["Diversified", "Large Cap"],
            countries: ["United States"]
          },
          action: :update
        )

      assert updated_symbol.name == "SPDR S&P 500 ETF Trust"
      assert updated_symbol.sectors == ["Diversified", "Large Cap"]
      assert updated_symbol.countries == ["United States"]
    end

    test "can destroy symbol", %{spy: spy} do
      :ok = Ash.destroy(spy)

      {:ok, symbols} = Ash.read(Symbol)
      symbol_ids = Enum.map(symbols, & &1.id)
      refute spy.id in symbol_ids
    end
  end

  describe "Symbol code interface" do
    test "create function works" do
      unique_symbol = "CI#{System.unique_integer([:positive])}"

      {:ok, symbol} =
        Symbol.create(%{
          symbol: unique_symbol,
          name: "Test Corporation",
          asset_class: :stock,
          data_source: :yahoo_finance
        })

      assert symbol.symbol == unique_symbol
      assert symbol.name == "Test Corporation"
    end

    test "list function works" do
      unique_symbol = "LIST#{System.unique_integer([:positive])}"

      {:ok, _} =
        Symbol.create(%{
          symbol: unique_symbol,
          asset_class: :stock,
          data_source: :yahoo_finance
        })

      {:ok, symbols} = Symbol.list()
      assert length(symbols) >= 1
    end

    test "find_by_symbol function works" do
      unique_symbol = "FIND#{System.unique_integer([:positive])}"

      {:ok, created_symbol} =
        Symbol.create(%{
          symbol: unique_symbol,
          asset_class: :stock,
          data_source: :yahoo_finance
        })

      {:ok, [found_symbol]} = Symbol.find_by_symbol(unique_symbol)
      assert found_symbol.id == created_symbol.id
    end

    test "by_asset_class function works" do
      unique_symbol = "ETF#{System.unique_integer([:positive])}"

      {:ok, _} =
        Symbol.create(%{
          symbol: unique_symbol,
          asset_class: :etf,
          data_source: :yahoo_finance
        })

      {:ok, etf_symbols} = Symbol.by_asset_class(:etf)
      assert length(etf_symbols) >= 1
      assert Enum.all?(etf_symbols, fn s -> s.asset_class == :etf end)
    end

    test "with_prices function works" do
      unique_symbol = "PRICE#{System.unique_integer([:positive])}"

      {:ok, _} =
        Symbol.create(%{
          symbol: unique_symbol,
          asset_class: :stock,
          data_source: :yahoo_finance,
          current_price: Decimal.new("200.00"),
          price_updated_at: DateTime.utc_now()
        })

      {:ok, symbols_with_prices} = Symbol.with_prices()
      assert length(symbols_with_prices) >= 1
      assert Enum.all?(symbols_with_prices, fn s -> s.current_price != nil end)
    end
  end
end
