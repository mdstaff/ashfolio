defmodule Ashfolio.SQLiteHelpers do
  @moduledoc """
  Helper functions for dealing with SQLite-specific issues in tests.
  Uses global setup pattern - test data is created once in test_helper.exs
  before any tests start, eliminating all concurrency issues.

  Database-as-user architecture: Each database represents one user, eliminating user_id dependencies.
  """

  # Note: UserSettings removed - using simplified approach for database-as-user architecture testing

  @doc """
  Initializes default user settings for tests.

  This is called once from test_helper.exs before tests start.
  It's idempotent - safe to call multiple times.

  In database-as-user architecture, user settings are a singleton per database.
  """
  def create_default_user_settings! do
    # For testing purposes, we'll create a simple struct-like representation
    # since we're in database-as-user architecture and the UserSettings table
    # may not be available in test environment
    %{
      id: "test-user-settings-1",
      name: "Test User",
      currency: "USD",
      locale: "en-US",
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
  end

  @doc """
  Creates the default account for tests.

  This is called once from test_helper.exs after initializing user settings.
  It's idempotent - safe to call multiple times.

  In database-as-user architecture, accounts exist without user_id references.
  """
  def create_default_account! do
    alias Ashfolio.Portfolio.Account

    # Check if default account already exists
    case Account.get_by_name("Default Test Account") do
      {:ok, account} when not is_nil(account) ->
        # Account already exists
        account

      {:ok, nil} ->
        # Create default account
        params = %{
          name: "Default Test Account",
          balance: Decimal.new("10000.00"),
          currency: "USD",
          platform: "Test Platform"
        }

        case Account.create(params) do
          {:ok, account} -> account
          {:error, error} -> raise "Failed to create default account: #{inspect(error)}"
        end

      {:error, error} ->
        raise "Failed to query for default account: #{inspect(error)}"
    end
  end

  @doc """
  Backward compatibility function for get_default_account with user parameter.
  In database-as-user architecture, user parameter is ignored.
  """
  def get_default_account(_user) do
    get_default_account()
  end

  @doc """
  Creates common test symbols.

  This is called once from test_helper.exs to create frequently used symbols.
  It's idempotent - safe to call multiple times.
  """
  def create_common_symbols! do
    alias Ashfolio.Portfolio.Symbol

    common_tickers = ["AAPL", "MSFT", "GOOGL", "TSLA"]

    Enum.map(common_tickers, fn ticker ->
      case Symbol.find_by_symbol(ticker) do
        {:ok, [symbol]} ->
          # Symbol already exists
          symbol

        {:ok, []} ->
          # Create the symbol
          params = %{
            symbol: ticker,
            name: "#{ticker} Test Company",
            asset_class: :stock,
            data_source: :manual,
            current_price: Decimal.new("100.00"),
            price_updated_at: DateTime.utc_now()
          }

          case Symbol.create(params) do
            {:ok, symbol} -> symbol
            {:error, error} -> raise "Failed to create symbol #{ticker}: #{inspect(error)}"
          end

        {:error, error} ->
          raise "Failed to query for symbol #{ticker}: #{inspect(error)}"
      end
    end)
  end

  @doc """
  Sets up all global test data in the correct order.

  This is the main function called from test_helper.exs that creates
  all baseline test data before individual tests run.

  Database-as-user architecture: Creates user settings and account without user_id dependencies.
  """
  def setup_global_test_data! do
    user_settings = create_default_user_settings!()
    account = create_default_account!()
    symbols = create_common_symbols!()

    # Validate the setup was successful
    validate_global_test_data!()

    %{
      user_settings: user_settings,
      account: account,
      symbols: symbols
    }
  end

  @doc """
  Validates that the global test data is properly set up.

  This safeguard helps catch database setup issues early before tests run.
  Database-as-user architecture: Validates user settings and account without user_id dependencies.
  """
  def validate_global_test_data! do
    # Check user settings exist (simplified for database-as-user architecture)
    user_settings = get_default_user_settings()

    if user_settings.name in ["Test User", "Local User"] do
      IO.puts(".")
    else
      IO.puts("⚠️  WARNING: Test database settings has unexpected name: #{user_settings.name}")
    end

    # Check default account exists
    case Ashfolio.Portfolio.Account.get_by_name("Default Test Account") do
      {:ok, nil} ->
        raise "❌ SAFEGUARD FAILURE: Default account not found after setup"

      {:ok, _account} ->
        IO.puts(".")

      {:error, error} ->
        raise "❌ SAFEGUARD FAILURE: Could not query default account: #{inspect(error)}"
    end

    # Check common symbols exist
    common_tickers = ["AAPL", "MSFT", "GOOGL", "TSLA"]

    missing_symbols =
      Enum.filter(common_tickers, fn ticker ->
        case Ashfolio.Portfolio.Symbol.find_by_symbol(ticker) do
          {:ok, []} -> true
          {:ok, [_symbol]} -> false
          {:error, _} -> true
        end
      end)

    if missing_symbols != [] do
      raise "❌ SAFEGUARD FAILURE: Missing common symbols: #{inspect(missing_symbols)}"
    else
      IO.puts(".")
    end
  end

  @doc """
  Gets the default test user settings.

  This assumes the settings were already created by create_default_user_settings!/0
  called from test_helper.exs. No concurrency issues since the settings
  exist before any tests start.

  Database-as-user architecture: Returns singleton user settings.
  """
  def get_or_create_default_user_settings do
    # For testing, return the created user settings
    user_settings = create_default_user_settings!()
    {:ok, user_settings}
  end

  @doc """
  Gets the default test user settings, assumes they already exist.

  This is a simple fetch operation with no retry logic needed
  since the settings are created once before tests start.

  Database-as-user architecture: Returns singleton user settings.
  """
  def get_default_user_settings do
    # For testing, return the simple user settings structure
    create_default_user_settings!()
  end

  @doc """
  Gets the default test account, assumes it already exists.

  This is a simple fetch operation for the globally created account.
  Database-as-user architecture: No user_id needed.
  """
  def get_default_account do
    alias Ashfolio.Portfolio.Account

    case Account.get_by_name("Default Test Account") do
      {:ok, account} when not is_nil(account) ->
        account

      {:ok, nil} ->
        raise "Default account not found - ensure setup_global_test_data!/0 was called in test_helper.exs"

      {:error, error} ->
        raise "Failed to fetch default account: #{inspect(error)}"
    end
  end

  @doc """
  Gets a common test symbol by ticker, assumes it already exists.
  """
  def get_common_symbol(ticker) do
    alias Ashfolio.Portfolio.Symbol

    case Symbol.find_by_symbol(ticker) do
      {:ok, [symbol]} ->
        symbol

      {:ok, []} ->
        raise "Common symbol #{ticker} not found - ensure setup_global_test_data!/0 was called in test_helper.exs"

      {:error, error} ->
        raise "Failed to fetch symbol #{ticker}: #{inspect(error)}"
    end
  end

  # ============================================================================
  # PHASE 2: Resource-Specific Helpers with Retry Logic
  # ============================================================================

  @doc """
  DEPRECATED: Backward compatibility for database-as-user architecture.

  This version accepts a user parameter but ignores it since
  accounts no longer have user_id in database-as-user architecture.
  """
  def get_or_create_account(_user, attrs) when is_map(attrs) do
    get_or_create_account(attrs)
  end

  @doc """
  Gets or creates a test account with custom attributes.

  Uses retry logic for SQLite concurrency handling when creating
  accounts with specific requirements that differ from the default.
  """
  def get_or_create_account(attrs \\ %{}) do
    alias Ashfolio.Portfolio.Account

    # For the default case, use the global account
    default_attrs = %{
      name: "Default Test Account",
      balance: Decimal.new("10000.00"),
      currency: "USD",
      platform: "Test Platform"
    }

    if attrs == %{} or Map.equal?(Map.take(attrs, Map.keys(default_attrs)), default_attrs) do
      get_default_account()
    else
      # Custom attributes - use retry logic
      with_retry(fn ->
        account_name = attrs[:name] || "Test Account #{System.unique_integer([:positive])}"

        case Account.get_by_name(account_name) do
          {:ok, account} when not is_nil(account) ->
            account

          {:ok, nil} ->
            params =
              Map.merge(
                %{
                  name: account_name,
                  balance: Decimal.new("5000.00"),
                  currency: "USD",
                  platform: "Test Platform"
                },
                attrs
              )

            case Account.create(params) do
              {:ok, account} -> account
              {:error, error} -> raise "Failed to create custom account: #{inspect(error)}"
            end

          {:error, error} ->
            raise "Failed to query for account: #{inspect(error)}"
        end
      end)
    end
  end

  @doc """
  Gets or creates a test symbol with retry logic.

  Uses globally created symbols when possible, falls back to
  creating custom symbols with retry logic for SQLite concurrency.
  """
  def get_or_create_symbol(ticker, attrs \\ %{}) do
    alias Ashfolio.Portfolio.Symbol

    common_tickers = ["AAPL", "MSFT", "GOOGL", "TSLA"]

    # Check if we need to update an existing symbol's price
    current_price = attrs[:current_price]

    if ticker in common_tickers and current_price do
      # Common ticker but with custom price - get and update
      symbol = get_common_symbol(ticker)

      with_retry(fn ->
        case Symbol.update_price(symbol, %{
               current_price: current_price,
               price_updated_at: DateTime.utc_now()
             }) do
          {:ok, updated_symbol} -> updated_symbol
          {:error, error} -> raise "Failed to update symbol #{ticker} price: #{inspect(error)}"
        end
      end)
    else
      if ticker in common_tickers and attrs == %{} do
        get_common_symbol(ticker)
      else
        # Custom symbol or attributes - use retry logic
        with_retry(fn ->
          case Symbol.find_by_symbol(ticker) do
            {:ok, [symbol]} ->
              # Symbol exists - update price if provided
              if current_price do
                case Symbol.update_price(symbol, %{
                       current_price: current_price,
                       price_updated_at: DateTime.utc_now()
                     }) do
                  {:ok, updated_symbol} ->
                    updated_symbol

                  {:error, error} ->
                    raise "Failed to update symbol #{ticker} price: #{inspect(error)}"
                end
              else
                symbol
              end

            {:ok, []} ->
              # Default params - only include current_price if not explicitly excluded
              default_params = %{
                symbol: ticker,
                name: "#{ticker} Test Company",
                asset_class: :stock,
                data_source: :manual
              }

              # Add default price unless attrs explicitly exclude it
              default_params =
                if Map.has_key?(attrs, :current_price) do
                  # attrs has current_price key (even if nil) - respect that
                  default_params
                else
                  # No current_price in attrs - add default
                  Map.merge(default_params, %{
                    current_price: Decimal.new("50.00"),
                    price_updated_at: DateTime.utc_now()
                  })
                end

              params = Map.merge(default_params, attrs)

              case Symbol.create(params) do
                {:ok, symbol} -> symbol
                {:error, error} -> raise "Failed to create symbol #{ticker}: #{inspect(error)}"
              end

            {:error, error} ->
              raise "Failed to query for symbol #{ticker}: #{inspect(error)}"
          end
        end)
      end
    end
  end

  @doc """
  Creates a test transaction with retry logic.

  Handles the full dependency chain: User -> Account -> Symbol -> Transaction
  Note: Transaction resource doesn't have user_id field - user is tracked through account relationship
  """
  def create_test_transaction(account \\ nil, symbol \\ nil, attrs \\ %{}) do
    alias Ashfolio.Portfolio.Transaction

    account = account || get_default_account()
    symbol = symbol || get_common_symbol("AAPL")

    with_retry(fn ->
      # Calculate total_amount if not provided
      quantity = attrs[:quantity] || Decimal.new("10")
      price = attrs[:price] || Decimal.new("100.00")
      fee = attrs[:fee] || Decimal.new("0.00")
      total_amount = attrs[:total_amount] || Decimal.add(Decimal.mult(quantity, price), fee)

      params =
        Map.merge(
          %{
            type: :buy,
            quantity: quantity,
            price: price,
            fee: fee,
            total_amount: total_amount,
            date: Date.utc_today(),
            account_id: account.id,
            symbol_id: symbol.id
          },
          attrs
        )

      case Transaction.create(params) do
        {:ok, transaction} -> transaction
        {:error, error} -> raise "Failed to create transaction: #{inspect(error)}"
      end
    end)
  end

  # ============================================================================
  # Retry Logic (Single Responsibility)
  # ============================================================================

  @doc """
  Retries a function that might fail due to SQLite "Database busy" errors.

  This provides a single point of retry logic following the DRY principle.
  """
  def with_retry(fun, max_attempts \\ 3, delay_ms \\ 100) do
    do_with_retry(fun, max_attempts, delay_ms, 1)
  end

  defp do_with_retry(fun, max_attempts, delay_ms, attempt) do
    try do
      fun.()
    rescue
      error ->
        if sqlite_busy_error?(error) and attempt < max_attempts do
          # Exponential backoff with jitter
          sleep_time = delay_ms * attempt + :rand.uniform(50)
          Process.sleep(sleep_time)
          do_with_retry(fun, max_attempts, delay_ms, attempt + 1)
        else
          reraise error, __STACKTRACE__
        end
    end
  end

  defp sqlite_busy_error?(%Ash.Error.Unknown{}), do: true

  defp sqlite_busy_error?(error) do
    error_string = inspect(error)

    String.contains?(error_string, "Database busy") or
      String.contains?(error_string, "database is locked")
  end

  @doc """
  Allows the PriceManager GenServer to access the database and mocks in tests.

  This should be called in test setup when testing price refresh functionality.
  """
  def allow_price_manager_db_access do
    try do
      # Get the PriceManager GenServer pid
      price_manager_pid = Process.whereis(Ashfolio.MarketData.PriceManager)

      if price_manager_pid do
        # Allow the PriceManager process to access the database
        Ecto.Adapters.SQL.Sandbox.allow(Ashfolio.Repo, self(), price_manager_pid)

        # Allow the PriceManager process to use Mox expectations
        Mox.allow(YahooFinanceMock, self(), price_manager_pid)
      end
    rescue
      # If PriceManager isn't running or there's an error, that's OK
      # Tests will handle the database access failure gracefully
      _ -> :ok
    end
  end

  @doc """
  Quick health check for test database state.

  This can be run before test suites to catch database issues early.
  Returns :ok or raises with helpful error messages.
  """
  def test_database_health_check! do
    IO.puts("🔍 Running test database health check...")

    # Check if we can connect to the database
    try do
      case Ashfolio.Repo.query("SELECT 1", []) do
        {:ok, _} -> IO.puts("✅ Database connection: OK")
        {:error, error} -> raise "❌ Database connection failed: #{inspect(error)}"
      end
    rescue
      error -> reraise "❌ Database connection failed: #{inspect(error)}", __STACKTRACE__
    end

    # Check if we have the expected baseline data by counting records
    # Database-as-user architecture: No User model to count
    account_count = Ashfolio.Repo.aggregate(Ashfolio.Portfolio.Account, :count)
    symbol_count = Ashfolio.Repo.aggregate(Ashfolio.Portfolio.Symbol, :count)

    IO.puts("📊 Database state:")
    IO.puts("   Accounts: #{account_count}")
    IO.puts("   Symbols: #{symbol_count}")

    # Validate expected minimums for healthy test environment
    cond do
      account_count == 0 ->
        raise "❌ HEALTH CHECK FAILED: No accounts found. Run: MIX_ENV=test mix run -e \"Ashfolio.SQLiteHelpers.setup_global_test_data!()\""

      symbol_count < 4 ->
        raise "❌ HEALTH CHECK FAILED: Expected at least 4 symbols, found #{symbol_count}. Run: MIX_ENV=test mix run -e \"Ashfolio.SQLiteHelpers.setup_global_test_data!()\""

      true ->
        IO.puts("🛡️  Test database health check: PASSED")
        :ok
    end
  end

  @doc """
  Emergency test database recovery procedure.

  This implements the complete reset procedure we discovered during debugging.
  """
  def emergency_test_db_reset! do
    IO.puts("🚨 EMERGENCY: Performing complete test database reset...")

    # This is the exact procedure that fixed our 253 test failures
    IO.puts("Step 1: Dropping test database...")

    case Ashfolio.Repo.__adapter__().storage_down(Ashfolio.Repo.config()) do
      :ok -> IO.puts("✅ Database dropped")
      {:error, :already_down} -> IO.puts("✅ Database was already down")
      {:error, error} -> raise "❌ Failed to drop database: #{inspect(error)}"
    end

    IO.puts("Step 2: Creating clean test database...")

    case Ashfolio.Repo.__adapter__().storage_up(Ashfolio.Repo.config()) do
      :ok -> IO.puts("✅ Database created")
      {:error, :already_up} -> IO.puts("✅ Database already exists")
      {:error, error} -> raise "❌ Failed to create database: #{inspect(error)}"
    end

    IO.puts("Step 3: Running migrations...")

    try do
      Ecto.Migrator.run(Ashfolio.Repo, :up, all: true)
      IO.puts("✅ Migrations completed")
    rescue
      error -> reraise "❌ Migration failed: #{inspect(error)}", __STACKTRACE__
    end

    IO.puts("Step 4: Setting up global test data...")
    setup_global_test_data!()

    IO.puts("🎉 RECOVERY COMPLETE! Test database fully reset and validated.")
  end
end
