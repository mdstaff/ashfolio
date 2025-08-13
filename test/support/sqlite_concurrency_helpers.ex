defmodule Ashfolio.SQLiteConcurrencyHelpers do
  @moduledoc """
  Helper functions to address SQLite concurrency issues in tests.

  Provides utilities for:
  - Safe database operations with retry logic
  - Proper test isolation with SQLite constraints
  - Concurrent test execution management
  """

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
        Ash.create(User, %{name: "Test"})
      end)
  """
  def with_retry(operation, retries \\ @max_retries) do
    try do
      operation.()
    rescue
      error ->
        if retries > 0 and sqlite_busy_error?(error) do
          Logger.debug("SQLite busy, retrying... (#{retries} attempts left)")
          Process.sleep(@retry_delay_ms)
          with_retry(operation, retries - 1)
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
    Enum.reduce_while(operations, [], fn operation, acc ->
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
        {Account, %{name: "Test Account", user_id: user.id}}
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
    |> Enum.each(fn {module, filters} ->
      with_retry(fn ->
        case module.list() do
          {:ok, records} ->
            records
            |> Enum.filter(fn record ->
              Enum.all?(filters, fn {key, value} ->
                Map.get(record, key) == value
              end)
            end)
            |> Enum.each(&module.destroy/1)

          _ ->
            :ok
        end
      end)
    end)
  end

  @doc """
  Check if an error is a SQLite busy/locked error.
  """
  def sqlite_busy_error?(error) do
    error_message =
      case error do
        %{message: message} -> String.downcase(message)
        %{reason: reason} when is_binary(reason) -> String.downcase(reason)
        _ -> ""
      end

    String.contains?(error_message, ["database is locked", "database is busy", "sqlite_busy"])
  end

  @doc """
  Execute a test with proper SQLite isolation.

  Ensures proper database checkout and cleanup for the test.
  """
  def with_isolation(test_fun) do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ashfolio.Repo)

    try do
      test_fun.()
    after
      Ecto.Adapters.SQL.Sandbox.checkin(Ashfolio.Repo)
    end
  end
end
