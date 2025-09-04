defmodule Ashfolio.SQLiteConcurrencyHelpers do
  @moduledoc """
  Helper functions to address SQLite concurrency issues in tests.

  Provides utilities for:
  - Safe database operations with retry logic
  - Proper test isolation with SQLite constraints
  - Concurrent test execution management
  """

  alias Ecto.Adapters.SQL.Sandbox

  require Logger

  @max_retries 3
  @retry_delay_ms 10

  @doc """
  Execute a database operation with retry logic for SQLite busy errors.

  ## Parameters
  - operation: Function to execute
  - retries: Number of retries (default: 3)

  ## Examples
      SQLiteConcurrencyHelpers.with_retry(fn ->
        Ashfolio.Portfolio.User.create(%{name: "Test"})
      end)
  """
  def with_retry(operation, retries \\ @max_retries) do
    operation.()
  rescue
    error ->
      if retries > 0 and sqlite_busy_error?(error) do
        # Temporarily suppress error logging during retries by capturing logs
        # Only log debug message if we're going to retry
        Logger.debug("SQLite busy, retrying... (#{retries} attempts left)")
        Process.sleep(@retry_delay_ms)
        with_retry(operation, retries - 1)
      else
        reraise error, __STACKTRACE__
      end
  end

  @doc """
  Execute operation with retry logic and suppressed connection error logging.

  This version attempts to reduce log noise from expected SQLite connection errors
  during test runs by temporarily adjusting log levels during retries.
  """
  def with_retry_quiet(operation, retries \\ @max_retries) do
    # Store original log level
    original_level = Logger.level()

    try do
      operation.()
    rescue
      error ->
        if retries > 0 and sqlite_busy_error?(error) do
          # Temporarily increase log level to suppress connection error logs
          # Only during retries - restore original level after
          Logger.configure(level: :critical)
          Process.sleep(@retry_delay_ms)

          try do
            with_retry_quiet(operation, retries - 1)
          after
            Logger.configure(level: original_level)
          end
        else
          reraise error, __STACKTRACE__
        end
    end
  end

  @doc """
  Execute multiple database operations in sequence with proper isolation.

  Useful for test setup that requires multiple related database operations.
  """
  def sequential_operations(operations) when is_list(operations) do
    operations
    |> Enum.reduce_while([], fn operation, acc ->
      case with_retry(operation) do
        {:ok, result} -> {:cont, [result | acc]}
        {:error, reason} -> {:halt, {:error, reason}}
        result -> {:cont, [result | acc]}
      end
    end)
    |> case do
      {:error, reason} -> {:error, reason}
      results -> {:ok, Enum.reverse(results)}
    end
  end

  @doc """
  Create test data with proper SQLite concurrency handling.

  ## Parameters
  - data_specs: List of {module, attrs} tuples for creation

  ## Examples
      SQLiteConcurrencyHelpers.create_test_data([
        {User, %{name: "Test User"}},
        {Account, %{name: "Test Account"}}
      ])
  """
  def create_test_data(data_specs) do
    operations =
      Enum.map(data_specs, fn {module, attrs} ->
        fn -> module.create(attrs) end
      end)

    sequential_operations(operations)
  end

  @doc """
  Clean up test data with proper ordering to avoid foreign key constraints.

  ## Parameters
  - cleanup_specs: List of {module, filters} tuples for deletion
  """
  def cleanup_test_data(cleanup_specs) do
    # Reverse order for proper foreign key cleanup
    cleanup_specs
    |> Enum.reverse()
    |> Enum.each(&cleanup_module_data/1)
  end

  defp cleanup_module_data({module, filters}) do
    with_retry(fn ->
      case module.list() do
        {:ok, records} -> delete_filtered_records(records, filters, module)
        _ -> :ok
      end
    end)
  end

  defp delete_filtered_records(records, filters, module) do
    records
    |> Enum.filter(&record_matches_filters?(&1, filters))
    |> Enum.each(&module.destroy/1)
  end

  defp record_matches_filters?(record, filters) do
    Enum.all?(filters, fn {key, value} ->
      Map.get(record, key) == value
    end)
  end

  @doc """
  Check if an error is a SQLite busy/locked error or connection error that should be retried.
  """
  def sqlite_busy_error?(error) do
    error_message =
      case error do
        %{message: message} -> String.downcase(message)
        %{reason: reason} when is_binary(reason) -> String.downcase(reason)
        %DBConnection.ConnectionError{message: message} -> String.downcase(message)
        _ -> ""
      end

    String.contains?(error_message, [
      "database is locked",
      "database is busy",
      "sqlite_busy",
      "client",
      "exited",
      "connection",
      "disconnected"
    ])
  end

  @doc """
  Execute a test with proper SQLite isolation.

  Ensures proper database checkout and cleanup for the test.
  """
  def with_isolation(test_fun) do
    :ok = Sandbox.checkout(Ashfolio.Repo)

    try do
      test_fun.()
    after
      Sandbox.checkin(Ashfolio.Repo)
    end
  end
end
