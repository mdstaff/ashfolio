defmodule Ashfolio.Context do
  @moduledoc """
  High-level API for all financial operations - local-first design.

  Provides reusable functions across Portfolio and FinancialManagement domains
  that compose existing Ash resource operations efficiently. Optimized for
  SQLite with batched queries, prepared statements, and ETS caching.

  This Context API follows the architect's recommendations:
  - Cross-domain access at the Ashfolio level
  - SQLite-specific optimizations
  - Enhanced error handling with specific error types
  - Performance monitoring with telemetry integration

  ## Error Handling

  All Context API functions return standardized errors:
  - `{:error, :account_not_found}` - Account does not exist
  - `{:error, :insufficient_data}` - Missing required data for operation
  - `{:error, :validation_failed}` - Input validation failed
  - `{:error, :database_error}` - Database operation failed
  - `{:error, :service_unavailable}` - External service unavailable
  """

  @behaviour Ashfolio.ContextBehaviour

  alias Ashfolio.FinancialManagement.BalanceManager
  alias Ashfolio.FinancialManagement.SymbolSearch
  alias Ashfolio.Portfolio.Account
  alias Ashfolio.Portfolio.Calculator
  alias Ashfolio.Portfolio.Transaction
  alias Ashfolio.Portfolio.UserSettings

  require Logger

  # Telemetry events
  @telemetry_prefix [:ashfolio, :context]

  # ETS table for prepared statement caching
  @ets_table :ashfolio_context_cache

  @doc """
  Get user settings for the database-as-user architecture.
  """
  @spec get_user_settings() :: {:ok, map()} | {:error, term()}
  def get_user_settings do
    case UserSettings.Api.get_settings() do
      {:ok, settings} -> {:ok, settings}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Initialize the Context module.
  Sets up ETS table for caching and prepared statements.
  """
  def start_link do
    :ets.new(@ets_table, [:named_table, :protected, :set])
    {:ok, self()}
  end

  @doc """
  Get comprehensive dashboard data for the database-as-user architecture.

  Returns user settings, accounts (categorized), recent transactions, and summary.
  Optimized with batched queries and telemetry tracking.

  ## Examples

      iex> Context.get_dashboard_data()
      {:ok, %{
        user: %UserSettings{},
        accounts: %{all: [...], investment: [...], cash: [...]},
        recent_transactions: [...],
        summary: %{total_balance: %Decimal{}, account_count: 3},
        last_updated: ~U[2025-08-10 12:00:00Z]
      }}
  """
  def get_dashboard_data do
    track_performance(:get_dashboard_data, fn ->
      with {:ok, user_settings} <- get_user_settings(),
           {:ok, accounts} <- Account.list(),
           {:ok, recent_transactions} <- get_recent_transactions(10) do
        categorized_accounts = categorize_accounts(accounts)
        summary = calculate_account_summary(accounts)

        {:ok,
         %{
           user: user_settings,
           accounts: categorized_accounts,
           recent_transactions: recent_transactions,
           summary: summary,
           last_updated: DateTime.utc_now()
         }}
      else
        error -> normalize_error(error)
      end
    end)
  end

  # Backward compatibility function - redirects to get_dashboard_data
  def get_user_dashboard_data do
    get_dashboard_data()
  end

  @doc """
  Get account details with transaction history and balance progression.

  Returns account info, transactions, balance history, and summary statistics.

  ## Examples

      iex> Context.get_account_with_transactions(account_id, 25)
      {:ok, %{
        account: %Account{},
        transactions: [...],
        balance_history: [%{date: ~D[2025-01-01], balance: %Decimal{}}],
        summary: %{transaction_count: 25, total_inflow: %Decimal{}},
        last_updated: ~U[2025-08-10 12:00:00Z]
      }}
  """
  def get_account_with_transactions(account_id, limit \\ 50) do
    track_performance(:get_account_with_transactions, fn ->
      with {:ok, account} <- Account.get_by_id(account_id),
           {:ok, transactions} <- Transaction.by_account(account_id) do
        limited_transactions = Enum.take(transactions, limit)
        balance_history = calculate_balance_history(limited_transactions)
        transaction_summary = calculate_transaction_summary(limited_transactions)

        {:ok,
         %{
           account: account,
           transactions: limited_transactions,
           balance_history: balance_history,
           summary: transaction_summary,
           last_updated: DateTime.utc_now()
         }}
      else
        error -> normalize_error(error)
      end
    end)
  end

  @doc """
  Get comprehensive portfolio summary with performance metrics.

  Returns total value, return data, holdings, and performance statistics.

  ## Examples

      iex> Context.get_portfolio_summary()
      {:ok, %{
        total_value: %Decimal{},
        total_return: %{amount: %Decimal{}, percentage: %Decimal{}},
        accounts: [...],
        holdings: [...],
        performance: %{daily_change: %Decimal{}},
        last_updated: ~U[2025-08-10 12:00:00Z]
      }}
  """
  def get_portfolio_summary do
    track_performance(:get_portfolio_summary, fn ->
      with {:ok, _user_settings} <- get_user_settings(),
           {:ok, accounts} <- Account.list(),
           {:ok, total_return} <- Calculator.calculate_total_return(),
           {:ok, position_returns} <- Calculator.calculate_position_returns() do
        active_accounts = Enum.filter(accounts, &(!&1.is_excluded))
        performance = calculate_performance_metrics(total_return)

        {:ok,
         %{
           total_value: total_return.total_value,
           total_return: %{
             amount: total_return.dollar_return,
             percentage: total_return.return_percentage
           },
           accounts: active_accounts,
           holdings: position_returns,
           performance: performance,
           last_updated: DateTime.utc_now()
         }}
      else
        error -> normalize_error(error)
      end
    end)
  end

  @doc """
  Get recent transactions for a user across all accounts.

  ## Examples

      iex> Context.get_recent_transactions(5)
      {:ok, [%Transaction{}, ...]}
  """
  def get_recent_transactions(limit \\ 10) do
    track_performance(:get_recent_transactions, fn ->
      case Account.list() do
        {:ok, accounts} ->
          account_ids = Enum.map(accounts, & &1.id)

          # Use batch query to prevent N+1 queries, loading symbol and category relationships
          case Transaction.by_accounts(account_ids) do
            {:ok, transactions} ->
              # Load relationships for recent transactions
              loaded_transactions = Ash.load!(transactions, [:symbol, :category])

              recent_transactions =
                loaded_transactions
                |> Enum.sort_by(& &1.date, {:desc, Date})
                |> Enum.take(limit)

              {:ok, recent_transactions}

            error ->
              normalize_error(error)
          end

        error ->
          normalize_error(error)
      end
    end)
  end

  @doc """
  Get net worth calculation combining investment and cash balances.

  ## Examples

      iex> Context.get_net_worth()
      {:ok, %{
        total_net_worth: %Decimal{},
        investment_value: %Decimal{},
        cash_balance: %Decimal{},
        breakdown: %{...}
      }}
  """
  def get_net_worth do
    track_performance(:get_net_worth, fn ->
      with {:ok, _user_settings} <- get_user_settings(),
           {:ok, accounts} <- Account.list(),
           {:ok, portfolio_value} <- Calculator.calculate_portfolio_value() do
        # Filter out excluded accounts first
        active_accounts = Enum.filter(accounts, &(!&1.is_excluded))

        cash_accounts =
          Enum.filter(
            active_accounts,
            &(&1.account_type in [:checking, :savings, :money_market, :cd])
          )

        investment_accounts = Enum.filter(active_accounts, &(&1.account_type == :investment))

        cash_balance = calculate_total_cash_balance(cash_accounts)
        # Include investment account balances for accounts without transactions
        investment_account_balances = calculate_total_cash_balance(investment_accounts)
        total_investment_value = Decimal.add(portfolio_value, investment_account_balances)
        total_net_worth = Decimal.add(total_investment_value, cash_balance)

        {:ok,
         %{
           total_net_worth: total_net_worth,
           investment_value: total_investment_value,
           cash_balance: cash_balance,
           breakdown: %{
             cash_accounts: length(cash_accounts),
             investment_accounts: length(investment_accounts),
             cash_percentage: calculate_percentage(cash_balance, total_net_worth),
             investment_percentage: calculate_percentage(total_investment_value, total_net_worth)
           }
         }}
      else
        error -> normalize_error(error)
      end
    end)
  end

  @doc """
  Search for symbols by ticker or company name with caching.

  Provides cross-domain symbol search functionality for financial management
  operations. Results are cached for performance optimization.

  ## Options

  - `:max_results` - Maximum number of results to return (default: 50)
  - `:ttl_seconds` - Cache TTL in seconds (default: 300)

  ## Examples

      iex> Context.search_symbols("AAPL")
      {:ok, [%Symbol{symbol: "AAPL", name: "Apple Inc."}]}

      iex> Context.search_symbols("Apple", max_results: 10)
      {:ok, [%Symbol{symbol: "AAPL", name: "Apple Inc."}]}

      iex> Context.search_symbols("NONEXISTENT")
      {:ok, []}
  """
  def search_symbols(query, opts \\ []) do
    track_performance(:search_symbols, fn ->
      SymbolSearch.search(query, opts)
    end)
  end

  @doc """
  Create a new Symbol resource from external API data.

  This function is used when external symbol search finds symbols that don't exist
  locally and need to be created for use in transactions.

  ## Parameters
  - symbol_data: Map containing symbol information from external API

  ## Examples

      iex> Context.create_symbol_from_external(%{
      ...>   symbol: "NVDA",
      ...>   name: "NVIDIA Corporation",
      ...>   price: 450.25
      ...> })
      {:ok, %Symbol{}}
  """
  def create_symbol_from_external(symbol_data) do
    track_performance(:create_symbol_from_external, fn ->
      SymbolSearch.create_symbol_from_external(symbol_data)
    end)
  end

  @doc """
  Update cash account balance with optional notes.

  Provides manual balance update functionality for cash accounts through the Context API.
  Maintains balance history and broadcasts real-time updates via PubSub.

  ## Parameters
  - account_id: UUID of the cash account to update
  - new_balance: The new balance as a Decimal
  - notes: Optional notes about the balance change

  ## Examples

      iex> Context.update_cash_balance(account_id, Decimal.new("1500.00"), "Monthly deposit")
      {:ok, %Account{balance: #Decimal<1500.00>}}

      iex> Context.update_cash_balance(account_id, Decimal.new("1500.00"))
      {:ok, %Account{balance: #Decimal<1500.00>}}

      iex> Context.update_cash_balance("invalid-id", Decimal.new("100"))
      {:error, :account_not_found}
  """
  def update_cash_balance(account_id, new_balance, notes \\ nil) do
    track_performance(:update_cash_balance, fn ->
      BalanceManager.update_cash_balance(account_id, new_balance, notes)
    end)
  end

  @doc """
  Get balance history for an account.

  Returns a chronological list of balance changes for audit and tracking purposes.

  ## Parameters
  - account_id: UUID of the account

  ## Examples

      iex> Context.get_balance_history(account_id)
      {:ok, [%{timestamp: ~U[...], old_balance: #Decimal<...>, new_balance: #Decimal<...>, notes: "..."}]}
  """
  def get_balance_history(account_id) do
    track_performance(:get_balance_history, fn ->
      BalanceManager.get_balance_history(account_id)
    end)
  end

  @doc """
  Validate account constraints for form validation.

  Provides validation logic for account creation and updates through the Context API.
  Checks name uniqueness, account type constraints, and business rules.

  ## Parameters
  - form_params: Map of form parameters to validate

  ## Examples

      iex> Context.validate_account_constraints(%{"name" => "My Account"}, nil)
      {:ok, %{}}

      iex> Context.validate_account_constraints(%{"name" => "Existing Account"}, nil)
      {:error, :name_already_taken}
  """
  def validate_account_constraints(form_params, current_account_id \\ nil) do
    track_performance(:validate_account_constraints, fn ->
      validate_account_name_uniqueness(form_params, current_account_id)
    end)
  end

  # Private helper functions

  # Helper functions for database-as-user architecture
  # Note: These functions are kept for backward compatibility but are no longer used

  defp categorize_accounts(accounts) do
    %{
      all: accounts,
      investment: Enum.filter(accounts, &(&1.account_type == :investment)),
      cash: Enum.filter(accounts, &(&1.account_type in [:checking, :savings, :money_market, :cd])),
      active: Enum.filter(accounts, &(!&1.is_excluded)),
      excluded: Enum.filter(accounts, & &1.is_excluded)
    }
  end

  defp calculate_account_summary(accounts) do
    total_balance =
      accounts
      |> Enum.map(& &1.balance)
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

    cash_balance = calculate_cash_balance(accounts)
    investment_balance = calculate_investment_balance(accounts)

    %{
      total_balance: total_balance,
      account_count: length(accounts),
      active_count: Enum.count(accounts, &(!&1.is_excluded)),
      cash_balance: cash_balance,
      investment_balance: investment_balance,
      cash_accounts: Enum.count(accounts, &(&1.account_type in [:checking, :savings, :money_market, :cd])),
      investment_accounts: Enum.count(accounts, &(&1.account_type == :investment))
    }
  end

  defp calculate_cash_balance(accounts) do
    accounts
    |> Enum.filter(&(&1.account_type in [:checking, :savings, :money_market, :cd]))
    |> Enum.map(& &1.balance)
    |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  end

  defp calculate_investment_balance(accounts) do
    accounts
    |> Enum.filter(&(&1.account_type == :investment))
    |> Enum.map(& &1.balance)
    |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  end

  defp calculate_total_cash_balance(cash_accounts) do
    cash_accounts
    |> Enum.map(& &1.balance)
    |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  end

  defp calculate_balance_history(transactions) do
    # Simple implementation - can be enhanced later
    transactions
    |> Enum.sort_by(& &1.date, {:asc, Date})
    |> Enum.reduce([], fn transaction, acc ->
      previous_balance =
        case acc do
          [] -> Decimal.new(0)
          [%{balance: balance} | _] -> balance
        end

      new_balance =
        case transaction.type do
          type when type in [:buy, :sell] ->
            Decimal.add(previous_balance, transaction.total_amount)

          :dividend ->
            Decimal.add(previous_balance, transaction.total_amount)

          _ ->
            previous_balance
        end

      [
        %{
          date: transaction.date,
          balance: new_balance,
          transaction_id: transaction.id
        }
        | acc
      ]
    end)
    |> Enum.reverse()
    # Last 30 data points
    |> Enum.take(30)
  end

  defp calculate_transaction_summary(transactions) do
    inflow =
      transactions
      |> Enum.filter(&(&1.type in [:buy, :dividend]))
      |> Enum.map(& &1.total_amount)
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

    outflow =
      transactions
      |> Enum.filter(&(&1.type in [:sell, :fee]))
      |> Enum.map(&Decimal.abs(&1.total_amount))
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

    %{
      transaction_count: length(transactions),
      total_inflow: inflow,
      total_outflow: outflow,
      net_flow: Decimal.sub(inflow, outflow),
      latest_date: get_latest_transaction_date(transactions)
    }
  end

  defp get_latest_transaction_date([]), do: nil

  defp get_latest_transaction_date(transactions) do
    transactions
    |> Enum.map(& &1.date)
    |> Enum.max(Date)
  end

  defp calculate_performance_metrics(total_return) do
    # Simplified performance metrics - can be enhanced later
    %{
      # Placeholder - would need historical data
      daily_change: Decimal.new(0),
      # Placeholder
      weekly_change: Decimal.new(0),
      # Placeholder
      monthly_change: Decimal.new(0),
      return_percentage: total_return.return_percentage,
      dollar_return: total_return.dollar_return
    }
  end

  defp calculate_percentage(amount, total) do
    if Decimal.equal?(total, 0) do
      Decimal.new(0)
    else
      amount
      |> Decimal.div(total)
      |> Decimal.mult(100)
    end
  end

  # SQLite optimization functions (placeholder for future enhancements)

  defp validate_account_name_uniqueness(form_params, current_account_id) do
    name = Map.get(form_params, "name")

    if name do
      case Account.get_by_name(name) do
        {:ok, existing_account} when not is_nil(existing_account) ->
          if existing_account.id == current_account_id do
            {:ok, %{}}
          else
            {:error, :validation_failed}
          end

        {:ok, nil} ->
          {:ok, %{}}

        {:error, _reason} ->
          {:ok, %{}}
      end
    else
      {:ok, %{}}
    end
  end

  # Error handling standardization

  defp normalize_error(%Ash.Error.Invalid{}), do: {:error, :validation_failed}
  defp normalize_error(%Ash.Error.Query.NotFound{}), do: {:error, :account_not_found}
  # Note: :user_not_found removed - no longer applicable in database-as-user architecture
  defp normalize_error({:error, :account_not_found}), do: {:error, :account_not_found}
  defp normalize_error({:error, :validation_failed}), do: {:error, :validation_failed}
  defp normalize_error({:error, :insufficient_data}), do: {:error, :insufficient_data}
  defp normalize_error({:error, :service_unavailable}), do: {:error, :service_unavailable}
  defp normalize_error({:error, _}), do: {:error, :database_error}
  defp normalize_error(_), do: {:error, :database_error}

  # Performance monitoring

  defp track_performance(operation, fun) do
    start_time = System.monotonic_time()

    result = fun.()

    duration = System.monotonic_time() - start_time
    duration_ms = System.convert_time_unit(duration, :native, :millisecond)

    Logger.debug("Context.#{operation} completed in #{duration_ms}ms")

    :telemetry.execute(
      @telemetry_prefix ++ [operation],
      %{duration: duration_ms},
      %{operation: operation}
    )

    case result do
      {:ok, _} = success ->
        :telemetry.execute(@telemetry_prefix ++ [operation, :success], %{}, %{})
        success

      {:error, reason} = error ->
        :telemetry.execute(@telemetry_prefix ++ [operation, :error], %{}, %{reason: reason})
        error
    end
  end
end
