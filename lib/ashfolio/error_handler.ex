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

  # v0.2.0 Cash Balance Management errors
  defp categorize_error({:error, :insufficient_balance}), do: :balance_management
  defp categorize_error({:error, :negative_balance_not_allowed}), do: :balance_management
  defp categorize_error({:error, :balance_update_failed}), do: :balance_management
  defp categorize_error({:error, :account_not_found}), do: :account_management
  defp categorize_error({:error, :not_cash_account}), do: :account_management

  # v0.2.0 Symbol Search errors
  defp categorize_error({:error, :symbol_api_unavailable}), do: :symbol_search
  defp categorize_error({:error, :symbol_not_found}), do: :symbol_search
  defp categorize_error({:error, :symbol_creation_failed}), do: :symbol_search
  defp categorize_error({:error, :symbol_search_rate_limited}), do: :symbol_search

  # v0.2.0 Category Management errors
  defp categorize_error({:error, :system_category_protected}), do: :category_management
  defp categorize_error({:error, :category_required}), do: :category_management
  defp categorize_error({:error, :category_not_found}), do: :category_management
  defp categorize_error({:error, :invalid_category_color}), do: :category_management

  # v0.2.0 Net Worth Calculation errors
  defp categorize_error({:error, :net_worth_calculation_failed}), do: :calculation
  defp categorize_error({:error, :mixed_account_calculation_error}), do: :calculation

  # v0.2.0 Context API errors
  defp categorize_error({:error, :context_operation_failed}), do: :context_api
  defp categorize_error({:error, :cross_domain_operation_failed}), do: :context_api

  defp categorize_error(_), do: :system

  # Log errors with appropriate severity
  defp log_error(error, error_type, context) do
    severity = get_log_severity(error_type)

    Logger.log(
      severity,
      "Error occurred: #{inspect(error)} (type: #{error_type}, context: #{inspect(context)})"
    )
  end

  # Get appropriate log severity for error type
  defp get_log_severity(:network), do: :warning
  defp get_log_severity(:api_rate_limit), do: :info
  defp get_log_severity(:not_found), do: :debug
  defp get_log_severity(:stale_data), do: :debug
  defp get_log_severity(:validation), do: :info
  defp get_log_severity(:system), do: :error

  # v0.2.0 error severities
  defp get_log_severity(:balance_management), do: :warning
  defp get_log_severity(:account_management), do: :info
  defp get_log_severity(:symbol_search), do: :warning
  defp get_log_severity(:category_management), do: :info
  defp get_log_severity(:calculation), do: :warning
  defp get_log_severity(:context_api), do: :error

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

  # v0.2.0 Balance Management error messages
  defp format_user_message(:balance_management, {:error, :insufficient_balance}) do
    "Insufficient funds for this transaction."
  end

  defp format_user_message(:balance_management, {:error, :negative_balance_not_allowed}) do
    "Balance cannot be negative for this account type."
  end

  defp format_user_message(:balance_management, {:error, :balance_update_failed}) do
    "Unable to update account balance. Please try again."
  end

  # v0.2.0 Account Management error messages
  defp format_user_message(:account_management, {:error, :account_not_found}) do
    "Account not found."
  end

  defp format_user_message(:account_management, {:error, :not_cash_account}) do
    "This operation is only available for cash accounts."
  end

  # v0.2.0 Symbol Search error messages
  defp format_user_message(:symbol_search, {:error, :symbol_api_unavailable}) do
    "Symbol search is temporarily unavailable. Using local symbols only."
  end

  defp format_user_message(:symbol_search, {:error, :symbol_not_found}) do
    "Symbol not found. Please check the ticker symbol and try again."
  end

  defp format_user_message(:symbol_search, {:error, :symbol_creation_failed}) do
    "Unable to add new symbol. Please try again later."
  end

  defp format_user_message(:symbol_search, {:error, :symbol_search_rate_limited}) do
    "Too many search requests. Please wait a moment and try again."
  end

  # v0.2.0 Category Management error messages
  defp format_user_message(:category_management, {:error, :system_category_protected}) do
    "System categories cannot be modified or deleted."
  end

  defp format_user_message(:category_management, {:error, :category_required}) do
    "Please select a category for this transaction."
  end

  defp format_user_message(:category_management, {:error, :category_not_found}) do
    "Category not found."
  end

  defp format_user_message(:category_management, {:error, :invalid_category_color}) do
    "Please select a valid color for the category."
  end

  # v0.2.0 Calculation error messages
  defp format_user_message(:calculation, {:error, :net_worth_calculation_failed}) do
    "Unable to calculate net worth. Please refresh and try again."
  end

  defp format_user_message(:calculation, {:error, :mixed_account_calculation_error}) do
    "Unable to calculate combined portfolio value. Please check account data."
  end

  # v0.2.0 Context API error messages
  defp format_user_message(:context_api, {:error, :context_operation_failed}) do
    "Data operation failed. Please refresh and try again."
  end

  defp format_user_message(:context_api, {:error, :cross_domain_operation_failed}) do
    "Unable to complete operation across accounts. Please try again."
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
