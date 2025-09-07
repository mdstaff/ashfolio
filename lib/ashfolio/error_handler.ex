defmodule Ashfolio.ErrorHandler do
  @moduledoc """
  Centralized error handling for the Ashfolio application.

  Provides consistent error logging, user-friendly messages, and recovery strategies
  following the simplified Phase 1 approach with basic error handling.
  """

  alias Ashfolio.ErrorCategorizer
  alias Ashfolio.ErrorFormatter

  require Logger

  @doc """
  Handles errors with appropriate logging and user-friendly messages.

  ## Parameters
  - error: The error to handle (can be various types)
  - context: Optional context map for additional logging information

  ## Returns
  - {:error, user_message} tuple with user-friendly error message

  ## Examples
      iex> Ashfolio.ErrorHandler.handle_error({:error, :network_timeout})
      {:error, "Network connection issue. Please try again."}

      iex> Ashfolio.ErrorHandler.handle_error(%Ecto.Changeset{valid?: false})
      {:error, "Please check your input and try again."}
  """
  def handle_error(error, context \\ %{}) do
    error_type = ErrorCategorizer.categorize(error)
    log_error(error, error_type, context)
    user_message = ErrorFormatter.format_message(error_type, error)
    {:error, user_message}
  end

  @doc """
  Logs an error with appropriate severity level.

  ## Parameters
  - error: The error to log
  - context: Optional context for additional information
  """
  def log_error(error, context \\ %{}) do
    error_type = ErrorCategorizer.categorize(error)
    log_error(error, error_type, context)
  end

  @doc """
  Formats validation errors from changesets into user-friendly messages.

  ## Parameters
  - changeset: Ecto.Changeset with validation errors

  ## Returns
  - List of user-friendly error messages
  """
  def format_changeset_errors(%Ecto.Changeset{} = changeset) do
    ErrorFormatter.format_changeset_errors(changeset)
  end

  def format_changeset_errors(_), do: []

  # Private logging coordination

  defp log_error(error, error_type, context) do
    log_level = ErrorCategorizer.log_level(error_type)

    case log_level do
      :error ->
        Logger.error("Error occurred: #{inspect(error)} (type: #{error_type}, context: #{inspect(context)})")

      :warning ->
        Logger.warning("Error occurred: #{inspect(error)} (type: #{error_type}, context: #{inspect(context)})")

      :info ->
        Logger.info("Error occurred: #{inspect(error)} (type: #{error_type}, context: #{inspect(context)})")
    end

    # Add metrics/monitoring hooks here if needed
    record_error_metrics(error_type, context)
  end

  defp record_error_metrics(_error_type, _context) do
    # Placeholder for metrics collection
    # Could integrate with telemetry, statsd, etc.
    :ok
  end
end
