defmodule Ashfolio.Validation do
  @moduledoc """
  Common validation functions for the Ashfolio application.

  Provides reusable validation logic that can be used across different
  resources and forms, with consistent error handling.
  """

  import Ecto.Changeset

  @doc """
  Validates that a decimal value is positive.

  ## Parameters
  - changeset: Ecto.Changeset to validate
  - field: Field name to validate
  - opts: Options (currently unused but kept for consistency)

  ## Examples
      changeset
      |> validate_positive_decimal(:price)
  """
  def validate_positive_decimal(changeset, field, _opts \\ []) do
    validate_change(changeset, field, fn field, value ->
      case Decimal.compare(value, Decimal.new(0)) do
        :gt -> []
        _ -> [{field, "must be greater than 0"}]
      end
    end)
  end

  @doc """
  Validates that a decimal value is not negative.

  ## Parameters
  - changeset: Ecto.Changeset to validate
  - field: Field name to validate
  - opts: Options (currently unused but kept for consistency)

  ## Examples
      changeset
      |> validate_non_negative_decimal(:quantity)
  """
  def validate_non_negative_decimal(changeset, field, _opts \\ []) do
    validate_change(changeset, field, fn field, value ->
      case Decimal.compare(value, Decimal.new(0)) do
        :lt -> [{field, "cannot be negative"}]
        _ -> []
      end
    end)
  end

  @doc """
  Validates that a date is not in the future.

  ## Parameters
  - changeset: Ecto.Changeset to validate
  - field: Field name to validate
  - opts: Options (currently unused but kept for consistency)

  ## Examples
      changeset
      |> validate_not_future_date(:transaction_date)
  """
  def validate_not_future_date(changeset, field, _opts \\ []) do
    validate_change(changeset, field, fn field, value ->
      today = Date.utc_today()

      case Date.compare(value, today) do
        :gt -> [{field, "cannot be in the future"}]
        _ -> []
      end
    end)
  end

  @doc """
  Validates that a date is reasonable (not before 1900).

  ## Parameters
  - changeset: Ecto.Changeset to validate
  - field: Field name to validate
  - opts: Options (currently unused but kept for consistency)

  ## Examples
      changeset
      |> validate_reasonable_date(:transaction_date)
  """
  def validate_reasonable_date(changeset, field, _opts \\ []) do
    validate_change(changeset, field, fn field, value ->
      min_date = ~D[1900-01-01]

      case Date.compare(value, min_date) do
        :lt -> [{field, "must be after January 1, 1900"}]
        _ -> []
      end
    end)
  end

  @doc """
  Validates that a string looks like a valid stock symbol.

  ## Parameters
  - changeset: Ecto.Changeset to validate
  - field: Field name to validate
  - opts: Options (currently unused but kept for consistency)

  ## Examples
      changeset
      |> validate_symbol_format(:symbol)
  """
  def validate_symbol_format(changeset, field, _opts \\ []) do
    validate_change(changeset, field, fn field, value ->
      # Enhanced symbol validation with stricter security rules
      cond do
        String.length(value) > 10 ->
          [{field, "must be 10 characters or less"}]

        String.length(value) < 1 ->
          [{field, "must be at least 1 character"}]

        not Regex.match?(~r/^[A-Z0-9.-]{1,10}$/, String.upcase(value)) ->
          [{field, "must contain only uppercase letters, numbers, dots, and dashes"}]

        # Additional security: prevent suspicious patterns
        Regex.match?(~r/^\.+$|^-+$/, value) ->
          [{field, "cannot consist only of dots or dashes"}]

        # Prevent common injection patterns
        String.contains?(String.downcase(value), ["script", "select", "drop", "insert"]) ->
          [{field, "contains invalid characters or patterns"}]

        true ->
          []
      end
    end)
  end

  @doc """
  Validates that a currency code is supported (USD only for Phase 1).

  ## Parameters
  - changeset: Ecto.Changeset to validate
  - field: Field name to validate
  - opts: Options (currently unused but kept for consistency)

  ## Examples
      changeset
      |> validate_supported_currency(:currency)
  """
  def validate_supported_currency(changeset, field, _opts \\ []) do
    validate_inclusion(changeset, field, ["USD"], message: "only USD is supported in Phase 1")
  end

  @doc """
  Validates required fields with custom error messages.

  ## Parameters
  - changeset: Ecto.Changeset to validate
  - fields: List of required field names
  - opts: Options including custom messages

  ## Examples
      changeset
      |> validate_required_fields([:name, :email])
  """
  def validate_required_fields(changeset, fields, opts \\ []) do
    message = Keyword.get(opts, :message, "is required")
    validate_required(changeset, fields, message: message)
  end

  @doc """
  Comprehensive validation for transaction data.

  ## Parameters
  - changeset: Ecto.Changeset to validate
  - opts: Options for validation

  ## Examples
      changeset
      |> validate_transaction_data()
  """
  def validate_transaction_data(changeset, _opts \\ []) do
    changeset
    |> validate_required_fields([:type, :quantity, :unit_price, :date])
    |> validate_positive_decimal(:quantity)
    |> validate_positive_decimal(:unit_price)
    |> validate_non_negative_decimal(:fee)
    |> validate_not_future_date(:date)
    |> validate_reasonable_date(:date)
    |> validate_supported_currency(:currency)
  end

  @doc """
  Comprehensive validation for account data.

  ## Parameters
  - changeset: Ecto.Changeset to validate
  - opts: Options for validation

  ## Examples
      changeset
      |> validate_account_data()
  """
  def validate_account_data(changeset, _opts \\ []) do
    changeset
    |> validate_required_fields([:name])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:platform, max: 50)
    |> validate_non_negative_decimal(:balance)
    |> validate_supported_currency(:currency)
  end

  @doc """
  Comprehensive validation for symbol data.

  ## Parameters
  - changeset: Ecto.Changeset to validate
  - opts: Options for validation

  ## Examples
      changeset
      |> validate_symbol_data()
  """
  def validate_symbol_data(changeset, _opts \\ []) do
    changeset
    |> validate_required_fields([:symbol, :asset_class])
    |> validate_symbol_format(:symbol)
    |> validate_length(:name, max: 200)
    |> validate_inclusion(:asset_class, [:stock, :etf, :crypto, :bond, :commodity])
    |> validate_supported_currency(:currency)
    |> validate_positive_decimal(:current_price)
  end
end
