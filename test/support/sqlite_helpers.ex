defmodule Ashfolio.SQLiteHelpers do
  @moduledoc """
  Helper functions for dealing with SQLite-specific issues in tests.
  """

  alias Ashfolio.Portfolio.User

  @doc """
  Gets or creates the default test user.

  This eliminates SQLite concurrency issues by ensuring there's always
  a single default user available for all tests, matching the single-user
  design of the Ashfolio application.
  """
  def get_or_create_default_user do
    case User.get_default_user() do
      {:ok, [user]} ->
        # User already exists
        {:ok, user}

      {:ok, []} ->
        # No user exists, create the default test user
        User.create(%{
          name: "Test User",
          currency: "USD",
          locale: "en-US"
        })

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Retries a function that might fail due to SQLite "Database busy" errors.

  This is kept for backward compatibility but the preferred approach is
  to use get_or_create_default_user/0 instead.
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

  defp sqlite_busy_error?(%Exqlite.Error{message: message}) do
    String.contains?(message, "Database busy")
  end

  defp sqlite_busy_error?(%Ash.Error.Unknown.UnknownError{error: error}) when is_binary(error) do
    String.contains?(error, "Database busy")
  end

  defp sqlite_busy_error?(_), do: false

  @doc """
  Creates a user with retry logic for SQLite busy errors.

  DEPRECATED: Use get_or_create_default_user/0 instead for better concurrency handling.
  """
  def create_user_with_retry(attrs \\ %{}) do
    default_attrs = %{
      name: "Test User",
      currency: "USD",
      locale: "en_US"
    }

    attrs = Map.merge(default_attrs, attrs)

    with_retry(fn ->
      User.create(attrs)
    end)
  end
end
