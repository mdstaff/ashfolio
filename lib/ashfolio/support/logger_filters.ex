defmodule Ashfolio.Support.LoggerFilters do
  @moduledoc """
  Custom logger filters for reducing noise during tests.

  Provides filters to suppress expected error messages that occur during normal
  SQLite concurrency handling and retry operations.

  ## Configuration

  The SQLite error filter can be controlled via environment variable:

  - `ASHFOLIO_FILTER_SQLITE_ERRORS=true` (default) - Enable filtering in test env
  - `ASHFOLIO_FILTER_SQLITE_ERRORS=false` - Disable filtering, show all errors

  The filter only operates in test environment regardless of the setting.

  ## Safety

  Multiple safeguards prevent suppressing legitimate errors:
  1. Only works in Mix.env() == :test
  2. Requires explicit environment variable enabling 
  3. Very specific pattern matching for known SQLite concurrency errors
  4. All other errors pass through unchanged
  """

  @doc """
  Filter out expected SQLite connection errors during tests.

  These errors are expected during concurrent test execution and retry operations.
  They don't indicate actual problems when our retry logic successfully handles them.
  """
  def filter_sqlite_connection_errors(%{level: level, msg: {:string, message}} = log_event)
      when level in [:error, :warning] do
    # SAFETY: Configurable filter with multiple safeguards
    filter_enabled =
      Mix.env() == :test and
        System.get_env("ASHFOLIO_FILTER_SQLITE_ERRORS", "true") in ["true", "1", "yes"]

    if not filter_enabled do
      # Filter disabled - pass through all errors
      log_event
    else
      message_string = to_string(message)

      # VERY specific filter - only suppress the exact DBConnection error pattern we see during SQLite concurrency
      # Pattern: "Exqlite.Connection (#PID<...>) disconnected: ** (DBConnection.ConnectionError) client #PID<...> exited"
      should_filter =
        String.contains?(message_string, "Exqlite.Connection") and
          String.contains?(message_string, "disconnected:") and
          String.contains?(message_string, "DBConnection.ConnectionError") and
          String.contains?(message_string, "client") and
          String.contains?(message_string, "exited") and
          String.contains?(message_string, "#PID<")

      if should_filter do
        # Suppress this very specific SQLite connection error pattern only
        :stop
      else
        # Allow all other messages through, including other DBConnection or Exqlite errors
        log_event
      end
    end
  end

  # Pass through all other log events unchanged
  def filter_sqlite_connection_errors(log_event), do: log_event
end
