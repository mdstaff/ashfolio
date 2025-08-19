defmodule Ashfolio.Support.LoggerFiltersTest do
  use ExUnit.Case

  alias Ashfolio.Support.LoggerFilters

  describe "filter_sqlite_connection_errors/1" do
    test "suppresses the specific SQLite connection error pattern in natural test environment" do
      # Verify we're actually in test environment (Mix.env() is the correct way)
      assert Mix.env() == :test, "This test should run in test environment"

      # The exact pattern we want to suppress
      log_event = %{
        level: :error,
        msg:
          {:string,
           "Exqlite.Connection (#PID<0.345.0>) disconnected: ** (DBConnection.ConnectionError) client #PID<0.8771.0> exited"}
      }

      result = LoggerFilters.filter_sqlite_connection_errors(log_event)
      assert result == :stop
    end

    test "suppresses the specific SQLite connection error pattern" do
      # The exact pattern we want to suppress
      log_event = %{
        level: :error,
        msg:
          {:string,
           "Exqlite.Connection (#PID<0.345.0>) disconnected: ** (DBConnection.ConnectionError) client #PID<0.8771.0> exited"}
      }

      result = LoggerFilters.filter_sqlite_connection_errors(log_event)
      assert result == :stop
    end

    test "allows other DBConnection errors through" do
      # Different DBConnection error that should NOT be suppressed
      log_event = %{
        level: :error,
        msg: {:string, "DBConnection.ConnectionError: some other database error"}
      }

      result = LoggerFilters.filter_sqlite_connection_errors(log_event)
      assert result == log_event
    end

    test "allows other Exqlite errors through" do
      # Different Exqlite error that should NOT be suppressed
      log_event = %{
        level: :error,
        msg: {:string, "Exqlite error: invalid query syntax"}
      }

      result = LoggerFilters.filter_sqlite_connection_errors(log_event)
      assert result == log_event
    end

    test "allows application errors with similar words through" do
      # Application error that happens to contain some of the same words
      log_event = %{
        level: :error,
        msg: {:string, "User client disconnected unexpectedly"}
      }

      result = LoggerFilters.filter_sqlite_connection_errors(log_event)
      assert result == log_event
    end

    test "allows all errors through in non-test environments" do
      # Test the safety mechanism for production
      original_env = Mix.env()

      try do
        # Simulate production environment
        Mix.env(:prod)

        # Even the exact pattern should pass through in production
        log_event = %{
          level: :error,
          msg:
            {:string,
             "Exqlite.Connection (#PID<0.345.0>) disconnected: ** (DBConnection.ConnectionError) client #PID<0.8771.0> exited"}
        }

        result = LoggerFilters.filter_sqlite_connection_errors(log_event)
        assert result == log_event
      after
        # Restore original environment
        Mix.env(original_env)
      end
    end

    test "respects ASHFOLIO_FILTER_SQLITE_ERRORS environment variable" do
      # Test with filter disabled via environment variable
      original_env_var = System.get_env("ASHFOLIO_FILTER_SQLITE_ERRORS")

      try do
        # Disable filter
        System.put_env("ASHFOLIO_FILTER_SQLITE_ERRORS", "false")

        # Even the exact pattern should pass through when disabled
        log_event = %{
          level: :error,
          msg:
            {:string,
             "Exqlite.Connection (#PID<0.345.0>) disconnected: ** (DBConnection.ConnectionError) client #PID<0.8771.0> exited"}
        }

        result = LoggerFilters.filter_sqlite_connection_errors(log_event)
        assert result == log_event

        # Re-enable filter
        System.put_env("ASHFOLIO_FILTER_SQLITE_ERRORS", "true")

        # Now it should be filtered
        result = LoggerFilters.filter_sqlite_connection_errors(log_event)
        assert result == :stop
      after
        # Restore original environment variable
        if original_env_var do
          System.put_env("ASHFOLIO_FILTER_SQLITE_ERRORS", original_env_var)
        else
          System.delete_env("ASHFOLIO_FILTER_SQLITE_ERRORS")
        end
      end
    end

    test "passes through non-string message formats unchanged" do
      log_event = %{
        level: :error,
        msg: {:report, [error: :some_error]}
      }

      result = LoggerFilters.filter_sqlite_connection_errors(log_event)
      assert result == log_event
    end

    test "passes through info and debug level messages unchanged" do
      log_event = %{
        level: :info,
        msg:
          {:string,
           "Exqlite.Connection (#PID<0.345.0>) disconnected: ** (DBConnection.ConnectionError) client #PID<0.8771.0> exited"}
      }

      result = LoggerFilters.filter_sqlite_connection_errors(log_event)
      assert result == log_event
    end
  end
end
