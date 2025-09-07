defmodule Ashfolio.ErrorFormatter do
  @moduledoc """
  Error formatting utilities for user-friendly error messages.

  Provides domain-specific error message formatting with appropriate
  user guidance and recovery suggestions.
  """

  @doc """
  Formats an error into a user-friendly message based on its category.

  ## Examples

      iex> ErrorFormatter.format_message(:network, {:error, :timeout})
      "Network connection issue. Please try again."
  """
  def format_message(category, error) do
    case category do
      :network -> "Network connection issue. Please try again."
      :api_rate_limit -> "Market data temporarily unavailable. Using cached prices."
      :not_found -> "The requested information was not found."
      :stale_data -> "Data may be outdated. Please refresh to get current information."
      :validation -> format_validation_message(error)
      :system -> "An unexpected error occurred. Please try again."
      :balance_management -> format_balance_message(error)
      :account_management -> format_account_message(error)
      :symbol_search -> format_symbol_message(error)
      :category_management -> format_category_message(error)
      :calculation -> format_calculation_message(error)
      :context_api -> format_context_message(error)
      _ -> "An unexpected error occurred. Please try again."
    end
  end

  @doc """
  Formats validation errors from changesets into user-friendly messages.
  """
  def format_changeset_errors(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  def format_changeset_errors(_), do: []

  # Private formatting functions for specific domains

  defp format_validation_message(%Ecto.Changeset{} = changeset) do
    errors = format_changeset_errors(changeset)

    case errors do
      errors when map_size(errors) == 0 ->
        "Please check your input and try again."

      errors ->
        errors
        |> Enum.map(fn {field, messages} ->
          field_name = field |> to_string() |> String.replace("_", " ") |> String.capitalize()
          "#{field_name}: #{Enum.join(messages, ", ")}"
        end)
        |> Enum.map_join("; ", & &1)
    end
  end

  defp format_validation_message(_error) do
    "Please check your input and try again."
  end

  defp format_balance_message({:error, :insufficient_balance}) do
    "Insufficient funds for this transaction."
  end

  defp format_balance_message({:error, :negative_balance_not_allowed}) do
    "Balance cannot be negative for this account type."
  end

  defp format_balance_message({:error, :balance_update_failed}) do
    "Unable to update account balance. Please try again."
  end

  defp format_account_message({:error, :account_not_found}) do
    "Account not found."
  end

  defp format_account_message({:error, :not_cash_account}) do
    "This operation is only available for cash accounts."
  end

  defp format_symbol_message({:error, :symbol_api_unavailable}) do
    "Symbol search is temporarily unavailable. Using local symbols only."
  end

  defp format_symbol_message({:error, :symbol_not_found}) do
    "Symbol not found. Please check the ticker symbol and try again."
  end

  defp format_symbol_message({:error, :symbol_creation_failed}) do
    "Unable to add new symbol. Please try again later."
  end

  defp format_symbol_message({:error, :symbol_search_rate_limited}) do
    "Too many search requests. Please wait a moment and try again."
  end

  defp format_category_message({:error, :system_category_protected}) do
    "System categories cannot be modified or deleted."
  end

  defp format_category_message({:error, :category_required}) do
    "Please select a category for this transaction."
  end

  defp format_category_message({:error, :category_not_found}) do
    "Category not found."
  end

  defp format_category_message({:error, :invalid_category_color}) do
    "Please select a valid color for the category."
  end

  defp format_calculation_message({:error, :net_worth_calculation_failed}) do
    "Unable to calculate net worth. Please refresh and try again."
  end

  defp format_calculation_message({:error, :mixed_account_calculation_error}) do
    "Unable to calculate combined portfolio value. Please check account data."
  end

  defp format_context_message({:error, :context_operation_failed}) do
    "Data operation failed. Please refresh and try again."
  end

  defp format_context_message({:error, :cross_domain_operation_failed}) do
    "Unable to complete operation across accounts. Please try again."
  end

  @doc """
  Adds recovery suggestions to error messages based on category.
  """
  def add_recovery_suggestion(message, :network) do
    message <> " Check your internet connection."
  end

  def add_recovery_suggestion(message, :validation) do
    message <> " Review the highlighted fields."
  end

  def add_recovery_suggestion(message, :stale_data) do
    message <> " Click refresh to get the latest data."
  end

  def add_recovery_suggestion(message, _category), do: message
end
