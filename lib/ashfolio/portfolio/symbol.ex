defmodule Ashfolio.Portfolio.Symbol do
  @moduledoc """
  Symbol resource for Ashfolio portfolio management.

  Represents financial symbols (stocks, ETFs, crypto, etc.) with market data.
  Supports multiple data sources (Yahoo Finance, CoinGecko, Manual entry).
  """

  use Ash.Resource,
    domain: Ashfolio.Portfolio,
    data_layer: AshSqlite.DataLayer

  require Ash.Query

  sqlite do
    table("symbols")
    repo(Ashfolio.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :symbol, :string do
      allow_nil?(false)
      description("Symbol ticker (e.g., 'AAPL', 'BTC-USD')")
    end

    attribute :name, :string do
      description("Full name of the security (e.g., 'Apple Inc.')")
    end

    attribute :asset_class, :atom do
      constraints(one_of: [:stock, :etf, :crypto, :bond, :commodity])
      allow_nil?(false)
      description("Asset class classification")
    end

    attribute :currency, :string do
      default("USD")
      allow_nil?(false)
      description("Currency for price data (USD-only in Phase 1)")
    end

    attribute :isin, :string do
      description("International Securities Identification Number")
    end

    attribute :sectors, {:array, :string} do
      default([])
      description("List of sectors this symbol belongs to")
    end

    attribute :countries, {:array, :string} do
      default([])
      description("List of countries this symbol is associated with")
    end

    attribute :data_source, :atom do
      constraints(one_of: [:yahoo_finance, :coingecko, :manual])
      allow_nil?(false)
      description("Primary data source for market data")
    end

    attribute :current_price, :decimal do
      description("Current market price")
    end

    attribute :price_updated_at, :utc_datetime do
      description("Timestamp when price was last updated")
    end

    timestamps()
  end

  relationships do
    has_many :transactions, Ashfolio.Portfolio.Transaction do
      description("Transactions involving this symbol")
    end

    # Price history will be implemented in future phases
    # has_many :price_histories, Ashfolio.Portfolio.PriceHistory
  end

  validations do
    validate(present(:symbol), message: "Symbol is required")
    validate(present(:asset_class), message: "Asset class is required")
    validate(present(:data_source), message: "Data source is required")
    validate(present(:currency), message: "Currency is required")

    # Phase 1: USD-only validation
    validate(match(:currency, ~r/^USD$/), message: "Only USD currency is supported in Phase 1")

    # Symbol format validation - basic alphanumeric with dashes
    validate(match(:symbol, ~r/^[A-Z0-9\-\.]+$/),
      message: "Symbol must contain only uppercase letters, numbers, dashes, and dots"
    )

    # Validate current_price is positive if present
    validate(compare(:current_price, greater_than: 0),
      message: "Current price must be positive",
      where: present(:current_price)
    )
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      description("Create a new symbol")

      accept([
        :symbol,
        :name,
        :asset_class,
        :currency,
        :isin,
        :sectors,
        :countries,
        :data_source,
        :current_price,
        :price_updated_at
      ])

      primary?(true)
    end

    update :update do
      description("Update symbol attributes")
      accept([:name, :asset_class, :currency, :isin, :sectors, :countries, :data_source])
      primary?(true)
    end

    update :update_price do
      description("Update current price and timestamp")
      accept([:current_price, :price_updated_at])
    end

    read :by_symbol do
      description("Find symbol by ticker symbol")
      argument(:symbol, :string, allow_nil?: false)
      filter(expr(symbol == ^arg(:symbol)))
    end

    read :by_asset_class do
      description("Find symbols by asset class")
      argument(:asset_class, :atom, allow_nil?: false)
      filter(expr(asset_class == ^arg(:asset_class)))
    end

    read :by_data_source do
      description("Find symbols by data source")
      argument(:data_source, :atom, allow_nil?: false)
      filter(expr(data_source == ^arg(:data_source)))
    end

    read :with_prices do
      description("Find symbols that have current price data")
      filter(expr(not is_nil(current_price)))
    end

    read :by_ids do
      description("Batch fetch symbols by list of IDs - eliminates N+1 queries")
      argument(:ids, {:array, :string}, allow_nil?: false)
      filter(expr(id in ^arg(:ids)))
    end

    read :stale_prices do
      description("Find symbols with stale price data (older than 1 hour)")
      argument(:stale_threshold, :utc_datetime, allow_nil?: true)

      prepare(fn query, _context ->
        # Get the argument from the query
        threshold =
          case Ash.Query.get_argument(query, :stale_threshold) do
            # 1 hour ago
            nil -> DateTime.utc_now() |> DateTime.add(-3600, :second)
            datetime -> datetime
          end

        Ash.Query.filter(query, expr(price_updated_at < ^threshold))
      end)
    end
  end

  code_interface do
    domain(Ashfolio.Portfolio)

    define(:create, action: :create)
    define(:list, action: :read)
    define(:get_by_id, action: :read, get_by: [:id])
    define(:get_by_ids, action: :by_ids, args: [:ids])
    define(:find_by_symbol, action: :by_symbol, args: [:symbol])
    define(:by_asset_class, action: :by_asset_class, args: [:asset_class])
    define(:by_data_source, action: :by_data_source, args: [:data_source])
    define(:with_prices, action: :with_prices)
    define(:stale_prices, action: :stale_prices, args: [{:optional, :stale_threshold}])
    define(:update, action: :update)
    define(:update_price, action: :update_price)
    define(:destroy, action: :destroy)
  end
end
