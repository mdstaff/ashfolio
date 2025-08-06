defmodule Ashfolio.Portfolio.SymbolTest do
  use ExUnit.Case, async: true

  alias Ashfolio.Portfolio.Symbol

  setup do
    # Explicitly checkout a connection for this test
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ashfolio.Repo)
    :ok
  end

  describe "Symbol resource" do
    test "can create symbol with required attributes" do
      {:ok, symbol} =
        Ash.create(Symbol, %{
          symbol: "AAPL",
          asset_class: :stock,
          data_source: :yahoo_finance
        })

      assert symbol.symbol == "AAPL"
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

      {:ok, symbol} =
        Ash.create(Symbol, %{
          symbol: "AAPL",
          name: "Apple Inc.",
          asset_class: :stock,
          currency: "USD",
          isin: "US0378331005",
          sectors: ["Technology", "Consumer Electronics"],
          countries: ["United States"],
          data_source: :yahoo_finance,
          current_price: Decimal.new("150.25"),
          price_updated_at: current_time
        })

      assert symbol.symbol == "AAPL"
      assert symbol.name == "Apple Inc."
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
      {:error, changeset} =
        Ash.create(Symbol, %{
          symbol: "AAPL",
          data_source: :yahoo_finance
        })

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :asset_class end)
    end

    test "requires data_source attribute" do
      {:error, changeset} =
        Ash.create(Symbol, %{
          symbol: "AAPL",
          asset_class: :stock
        })

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :data_source end)
    end

    test "validates asset_class is one of allowed values" do
      {:error, changeset} =
        Ash.create(Symbol, %{
          symbol: "AAPL",
          asset_class: :invalid_class,
          data_source: :yahoo_finance
        })

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :asset_class end)
    end

    test "validates data_source is one of allowed values" do
      {:error, changeset} =
        Ash.create(Symbol, %{
          symbol: "AAPL",
          asset_class: :stock,
          data_source: :invalid_source
        })

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :data_source end)
    end

    test "validates currency is USD only in Phase 1" do
      {:error, changeset} =
        Ash.create(Symbol, %{
          symbol: "AAPL",
          asset_class: :stock,
          data_source: :yahoo_finance,
          currency: "EUR"
        })

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :currency end)
    end

    test "validates symbol format" do
      {:error, changeset} =
        Ash.create(Symbol, %{
          symbol: "invalid symbol!",
          asset_class: :stock,
          data_source: :yahoo_finance
        })

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :symbol end)
    end

    test "validates current_price is positive when present" do
      {:error, changeset} =
        Ash.create(Symbol, %{
          symbol: "AAPL",
          asset_class: :stock,
          data_source: :yahoo_finance,
          current_price: Decimal.new("-10.00")
        })

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :current_price end)
    end

    test "allows valid symbol formats" do
      valid_symbols = ["AAPL", "BTC-USD", "SPY", "VTI", "MSFT", "GOOGL", "AMZN.L"]

      for symbol_name <- valid_symbols do
        {:ok, symbol} =
          Ash.create(Symbol, %{
            symbol: symbol_name,
            asset_class: :stock,
            data_source: :yahoo_finance
          })

        assert symbol.symbol == symbol_name
      end
    end
  end

  describe "Symbol actions" do
    setup do
      # Create test symbols
      {:ok, aapl} =
        Ash.create(Symbol, %{
          symbol: "AAPL",
          name: "Apple Inc.",
          asset_class: :stock,
          data_source: :yahoo_finance,
          current_price: Decimal.new("150.00"),
          price_updated_at: DateTime.utc_now()
        })

      {:ok, btc} =
        Ash.create(Symbol, %{
          symbol: "BTC-USD",
          name: "Bitcoin",
          asset_class: :crypto,
          data_source: :coingecko,
          current_price: Decimal.new("45000.00"),
          # 2 hours ago
          price_updated_at: DateTime.utc_now() |> DateTime.add(-7200, :second)
        })

      {:ok, spy} =
        Ash.create(Symbol, %{
          symbol: "SPY",
          name: "SPDR S&P 500 ETF",
          asset_class: :etf,
          data_source: :yahoo_finance
        })

      %{aapl: aapl, btc: btc, spy: spy}
    end

    test "can find symbol by ticker symbol", %{aapl: aapl} do
      {:ok, [found_symbol]} = Symbol.find_by_symbol("AAPL")
      assert found_symbol.id == aapl.id
      assert found_symbol.symbol == "AAPL"
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
      assert length(symbols) == 2
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
      {:ok, symbol} =
        Symbol.create(%{
          symbol: "MSFT",
          name: "Microsoft Corporation",
          asset_class: :stock,
          data_source: :yahoo_finance
        })

      assert symbol.symbol == "MSFT"
      assert symbol.name == "Microsoft Corporation"
    end

    test "list function works" do
      {:ok, _} =
        Symbol.create(%{
          symbol: "GOOGL",
          asset_class: :stock,
          data_source: :yahoo_finance
        })

      {:ok, symbols} = Symbol.list()
      assert length(symbols) >= 1
    end

    test "find_by_symbol function works" do
      {:ok, created_symbol} =
        Symbol.create(%{
          symbol: "AMZN",
          asset_class: :stock,
          data_source: :yahoo_finance
        })

      {:ok, [found_symbol]} = Symbol.find_by_symbol("AMZN")
      assert found_symbol.id == created_symbol.id
    end

    test "by_asset_class function works" do
      {:ok, _} =
        Symbol.create(%{
          symbol: "VTI",
          asset_class: :etf,
          data_source: :yahoo_finance
        })

      {:ok, etf_symbols} = Symbol.by_asset_class(:etf)
      assert length(etf_symbols) >= 1
      assert Enum.all?(etf_symbols, fn s -> s.asset_class == :etf end)
    end

    test "with_prices function works" do
      {:ok, _} =
        Symbol.create(%{
          symbol: "TSLA",
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
