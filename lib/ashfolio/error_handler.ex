defmodule Ashfolio.ErrorHandler do
  @moduledoc """
  Centralized error handling for the Ashfolio application.

  Provides consistent error logging, user-friendly messages, and recovery strategies
  following the simplified Phase 1 approach with basic error handling.
  """

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
    error_type = categorize_error(error)
    log_error(error, error_type, context)
    user_message = format_user_message(error_type, error)
    {:error, user_message}
  end

  @doc """
  Logs an error with appropriate severity level.

  ## Parameters
  - error: The error to log
  - context: Optional context for additional information
  """
  def log_error(error, context \\ %{}) do
    error_type = categorize_error(error)
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
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  def format_changeset_errors(_), do: []

  # Private functions

  # Categorize different types of errors
  defp categorize_error({:error, :network_timeout}), do: :network
  defp categorize_error({:error, :timeout}), do: :network
  defp categorize_error({:error, :econnrefused}), do: :network
  defp categorize_error({:error, :nxdomain}), do: :network
  defp categorize_error({:error, :rate_limited}), do: :api_rate_limit
  defp categorize_error({:error, :not_found}), do: :not_found
  defp categorize_error({:error, :stale}), do: :stale_data
  defp categorize_error(%Ecto.Changeset{valid?: false}), do: :validation
  defp categorize_error(%Ash.Error.Invalid{}), do: :validation
  defp categorize_error({:error, %Ash.Error.Invalid{}}), do: :validation
  defp categorize_error(_), do: :system

  # Log errors with appropriate severity
  defp log_error(error, error_type, context) do
    severity = get_log_severity(error_type)

    Logger.log(severity, "Error occurred: #{inspect(error)} (type: #{error_type}, context: #{inspect(context)})")
  end

  # Get appropriate log severity for error type
  defp get_log_severity(:network), do: :warning
  defp get_log_severity(:api_rate_limit), do: :info
  defp get_log_severity(:not_found), do: :debug
  defp get_log_severity(:stale_data), do: :debug
  defp get_log_severity(:validation), do: :info
  defp get_log_severity(:system), do: :error

  # Format user-friendly messages based on error type
  defp format_user_message(:network, _error) do
    "Network connection issue. Please try again."
  end

  defp format_user_message(:api_rate_limit, _error) do
    "Market data temporarily unavailable. Using cached prices."
  end

  defp format_user_message(:not_found, _error) do
    "The requested information was not found."
  end

  defp format_user_message(:stale_data, _error) do
    "Data may be outdated. Please refresh to get current information."
  end

  defp format_user_message(:validation, %Ecto.Changeset{} = changeset) do
    errors = format_changeset_errors(changeset)

    case errors do
      errors when map_size(errors) == 0 ->
        "Please check your input and try again."

      errors ->
        errors
        |> Enum.map(fn {field, messages} ->
          "#{humanize_field(field)}: #{Enum.join(messages, ", ")}"
        end)
        |> Enum.join("; ")
    end
  end

  defp format_user_message(:validation, _error) do
    "Please check your input and try again."
  end

  defp format_user_message(:system, _error) do
    "An unexpected error occurred. Please try again."
  end

  # Helper to humanize field names for better user experience
  defp humanize_field(field) when is_atom(field) do
    field
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp humanize_field(field), do: to_string(field)
end
