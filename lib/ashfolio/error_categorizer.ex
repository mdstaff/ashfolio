defmodule Ashfolio.ErrorCategorizer do
  @moduledoc """
  Error categorization utilities for consistent error type classification.

  Categorizes errors by domain (network, validation, financial, etc.) to enable
  appropriate error handling strategies and user message formatting.
  """

  alias Ash.Error.Invalid

  @doc """
  Categorizes an error into a domain-specific type.

  ## Examples

      iex> ErrorCategorizer.categorize({:error, :network_timeout})
      :network

      iex> ErrorCategorizer.categorize(%Ecto.Changeset{valid?: false})
      :validation
  """
  def categorize(error) do
    case error do
      # Network errors
      {:error, error_atom} when error_atom in [:network_timeout, :timeout, :econnrefused, :nxdomain] ->
        :network

      {:error, :rate_limited} ->
        :api_rate_limit

      # System errors
      {:error, :not_found} ->
        :not_found

      {:error, :stale} ->
        :stale_data

      # Validation errors
      %Ecto.Changeset{valid?: false} ->
        :validation

      %Invalid{} ->
        :validation

      {:error, %Invalid{}} ->
        :validation

      # Financial domain errors
      {:error, error_atom}
      when error_atom in [:insufficient_balance, :negative_balance_not_allowed, :balance_update_failed] ->
        :balance_management

      {:error, error_atom} when error_atom in [:account_not_found, :not_cash_account] ->
        :account_management

      {:error, error_atom}
      when error_atom in [
             :symbol_api_unavailable,
             :symbol_not_found,
             :symbol_creation_failed,
             :symbol_search_rate_limited
           ] ->
        :symbol_search

      {:error, error_atom}
      when error_atom in [
             :system_category_protected,
             :category_required,
             :category_not_found,
             :invalid_category_color
           ] ->
        :category_management

      {:error, error_atom} when error_atom in [:net_worth_calculation_failed, :mixed_account_calculation_error] ->
        :calculation

      {:error, error_atom} when error_atom in [:context_operation_failed, :cross_domain_operation_failed] ->
        :context_api

      # System fallback
      _ ->
        :system
    end
  end

  @doc """
  Checks if an error category requires immediate user attention.
  """
  def urgent?(category) when category in [:system, :context_api, :calculation], do: true
  def urgent?(_category), do: false

  @doc """
  Checks if an error category is user-recoverable.
  """
  def recoverable?(category) when category in [:network, :validation, :stale_data], do: true
  def recoverable?(_category), do: false

  @doc """
  Gets the log severity level for an error category.
  """
  def log_level(:system), do: :error
  def log_level(:context_api), do: :error
  def log_level(:calculation), do: :error
  def log_level(:validation), do: :info
  def log_level(:network), do: :warning
  def log_level(:api_rate_limit), do: :warning
  def log_level(:balance_management), do: :warning
  def log_level(:account_management), do: :warning
  def log_level(:symbol_search), do: :warning
  def log_level(:category_management), do: :info
  def log_level(_category), do: :info
end
