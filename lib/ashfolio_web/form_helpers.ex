defmodule AshfolioWeb.FormHelpers do
  @moduledoc """
  Common form handling utilities for Phoenix LiveView forms.

  Provides consistent patterns for:
  - Decimal parsing and validation
  - Date parsing and formatting
  - Changeset error handling
  - Form validation workflows
  - Field normalization
  """

  @doc """
  Parses a string value into a Decimal, with comprehensive error handling.

  ## Examples

      iex> AshfolioWeb.FormHelpers.parse_decimal("100.50")
      {:ok, Decimal.new("100.50")}
      
      iex> AshfolioWeb.FormHelpers.parse_decimal("")
      {:ok, nil}
      
      iex> AshfolioWeb.FormHelpers.parse_decimal("invalid")
      {:error, :invalid_decimal}
      
      iex> AshfolioWeb.FormHelpers.parse_decimal(nil)
      {:ok, nil}
  """
  def parse_decimal(nil), do: {:ok, nil}
  def parse_decimal(""), do: {:ok, nil}

  def parse_decimal(value) when is_binary(value) do
    # Clean common formatting (commas, currency symbols)
    cleaned =
      value
      |> String.replace(",", "")
      |> String.replace("$", "")
      |> String.trim()

    if cleaned == "" do
      {:ok, nil}
    else
      case Decimal.parse(cleaned) do
        {decimal, ""} -> {:ok, decimal}
        _ -> {:error, :invalid_decimal}
      end
    end
  end

  def parse_decimal(%Decimal{} = value), do: {:ok, value}
  def parse_decimal(_), do: {:error, :invalid_decimal}

  @doc """
  Parses a decimal value, returning nil on error (safe for direct assignment).

  ## Examples

      iex> AshfolioWeb.FormHelpers.parse_decimal_unsafe("100.50")
      Decimal.new("100.50")
      
      iex> AshfolioWeb.FormHelpers.parse_decimal_unsafe("invalid")
      nil
  """
  def parse_decimal_unsafe(value) do
    case parse_decimal(value) do
      {:ok, decimal} -> decimal
      {:error, _} -> nil
    end
  end

  @doc """
  Parses multiple decimal fields in a params map.

  ## Examples

      iex> params = %{"amount" => "100.50", "fee" => "5", "other" => "text"}
      iex> AshfolioWeb.FormHelpers.parse_decimal_fields(params, ["amount", "fee"])
      %{"amount" => Decimal.new("100.50"), "fee" => Decimal.new("5"), "other" => "text"}
  """
  def parse_decimal_fields(params, fields) when is_map(params) and is_list(fields) do
    Enum.reduce(fields, params, fn field, acc ->
      case Map.get(acc, field) do
        nil -> acc
        value -> parse_and_update_field(acc, field, value)
      end
    end)
  end

  defp parse_and_update_field(params, field, value) do
    case parse_decimal(value) do
      {:ok, decimal} -> Map.put(params, field, decimal)
      {:error, _} -> params
    end
  end

  @doc """
  Parses a date string in various formats.

  ## Examples

      iex> AshfolioWeb.FormHelpers.parse_date("2024-01-15")
      {:ok, ~D[2024-01-15]}
      
      iex> AshfolioWeb.FormHelpers.parse_date("")
      {:ok, nil}
      
      iex> AshfolioWeb.FormHelpers.parse_date("invalid")
      {:error, :invalid_date}
  """
  def parse_date(nil), do: {:ok, nil}
  def parse_date(""), do: {:ok, nil}

  def parse_date(value) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> {:ok, date}
      {:error, _} -> {:error, :invalid_date}
    end
  end

  def parse_date(%Date{} = date), do: {:ok, date}
  def parse_date(_), do: {:error, :invalid_date}

  @doc """
  Parses a date value, returning nil on error (safe for direct assignment).
  """
  def parse_date_unsafe(value) do
    case parse_date(value) do
      {:ok, date} -> date
      {:error, _} -> nil
    end
  end

  @doc """
  Parses a percentage string (handles % symbol).

  ## Examples

      iex> AshfolioWeb.FormHelpers.parse_percentage("7.5%")
      {:ok, Decimal.new("0.075")}
      
      iex> AshfolioWeb.FormHelpers.parse_percentage("7.5")
      {:ok, Decimal.new("0.075")}
      
      iex> AshfolioWeb.FormHelpers.parse_percentage("0.075")
      {:ok, Decimal.new("0.075")}
  """
  def parse_percentage(nil), do: {:ok, nil}
  def parse_percentage(""), do: {:ok, nil}

  def parse_percentage(value) when is_binary(value) do
    cleaned =
      value
      |> String.replace("%", "")
      |> String.trim()

    case parse_decimal(cleaned) do
      {:ok, nil} ->
        {:ok, nil}

      {:ok, decimal} ->
        # If value is greater than 1, assume it's a percentage (e.g., 7.5 -> 0.075)
        if Decimal.compare(decimal, Decimal.new("1")) == :gt do
          {:ok, Decimal.div(decimal, Decimal.new("100"))}
        else
          {:ok, decimal}
        end

      error ->
        error
    end
  end

  def parse_percentage(%Decimal{} = value), do: {:ok, value}
  def parse_percentage(_), do: {:error, :invalid_percentage}

  @doc """
  Parses an integer string.

  ## Examples

      iex> AshfolioWeb.FormHelpers.parse_integer("42")
      {:ok, 42}
      
      iex> AshfolioWeb.FormHelpers.parse_integer("")
      {:ok, nil}
      
      iex> AshfolioWeb.FormHelpers.parse_integer("invalid")
      {:error, :invalid_integer}
  """
  def parse_integer(nil), do: {:ok, nil}
  def parse_integer(""), do: {:ok, nil}

  def parse_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} -> {:ok, integer}
      _ -> {:error, :invalid_integer}
    end
  end

  def parse_integer(value) when is_integer(value), do: {:ok, value}
  def parse_integer(_), do: {:error, :invalid_integer}

  @doc """
  Validates that a decimal value is positive.

  ## Examples

      iex> AshfolioWeb.FormHelpers.validate_positive(Decimal.new("100"))
      :ok
      
      iex> AshfolioWeb.FormHelpers.validate_positive(Decimal.new("-10"))
      {:error, "must be positive"}
      
      iex> AshfolioWeb.FormHelpers.validate_positive(nil)
      {:error, "is required"}
  """
  def validate_positive(nil), do: {:error, "is required"}

  def validate_positive(%Decimal{} = value) do
    if Decimal.compare(value, Decimal.new("0")) == :gt do
      :ok
    else
      {:error, "must be positive"}
    end
  end

  def validate_positive(_), do: {:error, "must be a valid number"}

  @doc """
  Validates that a decimal value is non-negative.

  ## Examples

      iex> AshfolioWeb.FormHelpers.validate_non_negative(Decimal.new("0"))
      :ok
      
      iex> AshfolioWeb.FormHelpers.validate_non_negative(Decimal.new("-10"))
      {:error, "cannot be negative"}
  """
  def validate_non_negative(nil), do: {:ok, nil}

  def validate_non_negative(%Decimal{} = value) do
    if Decimal.compare(value, Decimal.new("0")) in [:gt, :eq] do
      :ok
    else
      {:error, "cannot be negative"}
    end
  end

  def validate_non_negative(_), do: {:error, "must be a valid number"}

  @doc """
  Normalizes empty strings to nil for optional fields.

  ## Examples

      iex> AshfolioWeb.FormHelpers.empty_to_nil("")
      nil
      
      iex> AshfolioWeb.FormHelpers.empty_to_nil("   ")
      nil
      
      iex> AshfolioWeb.FormHelpers.empty_to_nil("value")
      "value"
  """
  def empty_to_nil(value) when is_binary(value) do
    if String.trim(value) == "" do
      nil
    else
      value
    end
  end

  def empty_to_nil(value), do: value

  @doc """
  Builds a validation error message map for form display.

  ## Examples

      iex> errors = [amount: {"must be positive", []}, date: {"is required", []}]
      iex> AshfolioWeb.FormHelpers.build_error_messages(errors)
      %{amount: "must be positive", date: "is required"}
  """
  def build_error_messages(errors) when is_list(errors) do
    Enum.reduce(errors, %{}, fn
      {field, {message, _opts}}, acc ->
        Map.put(acc, field, message)

      {field, message}, acc when is_binary(message) ->
        Map.put(acc, field, message)

      _, acc ->
        acc
    end)
  end

  def build_error_messages(_), do: %{}

  @doc """
  Extracts and formats all errors from a changeset or form.

  Returns a list of formatted error messages suitable for display.
  """
  def format_form_errors(%Ecto.Changeset{} = changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, errors} ->
      field_name = field |> to_string() |> String.replace("_", " ") |> String.capitalize()
      Enum.map(errors, fn error -> "#{field_name} #{error}" end)
    end)
    |> List.flatten()
  end

  def format_form_errors(_), do: []

  @doc """
  Validates required fields in a params map.

  ## Examples

      iex> params = %{"name" => "Test", "amount" => ""}
      iex> AshfolioWeb.FormHelpers.validate_required_fields(params, ["name", "amount"])
      {:error, ["Amount is required"]}
      
      iex> params = %{"name" => "Test", "amount" => "100"}
      iex> AshfolioWeb.FormHelpers.validate_required_fields(params, ["name", "amount"])
      :ok
  """
  def validate_required_fields(params, required_fields) when is_map(params) and is_list(required_fields) do
    missing_fields =
      required_fields
      |> Enum.filter(fn field ->
        value = Map.get(params, field)
        is_nil(value) || value == ""
      end)
      |> Enum.map(fn field ->
        field_name = field |> String.replace("_", " ") |> String.capitalize()
        "#{field_name} is required"
      end)

    case missing_fields do
      [] -> :ok
      errors -> {:error, errors}
    end
  end

  @doc """
  Common validation workflow for forms.

  Validates required fields and applies custom validators.
  Returns a tuple of {valid?, errors, field_messages}.

  ## Examples

      iex> params = %{"amount" => "100", "date" => "2024-01-15"}
      iex> validators = %{
      ...>   "amount" => fn value ->
      ...>     decimal = AshfolioWeb.FormHelpers.parse_decimal_unsafe(value)
      ...>     AshfolioWeb.FormHelpers.validate_positive(decimal)
      ...>   end
      ...> }
      iex> AshfolioWeb.FormHelpers.validate_form(params, ["amount", "date"], validators)
      {true, [], %{}}
  """
  def validate_form(params, required_fields, validators \\ %{}) do
    # Check required fields
    required_errors =
      case validate_required_fields(params, required_fields) do
        :ok -> []
        {:error, errors} -> errors
      end

    # Run field validators
    {field_errors, field_messages} =
      Enum.reduce(validators, {[], %{}}, fn {field, validator}, {errors, messages} ->
        value = Map.get(params, field)

        case validator.(value) do
          :ok ->
            {errors, messages}

          {:error, message} ->
            field_name = field |> String.replace("_", " ") |> String.capitalize()
            {["#{field_name} #{message}" | errors], Map.put(messages, String.to_atom(field), message)}
        end
      end)

    all_errors = required_errors ++ field_errors
    {Enum.empty?(all_errors), all_errors, field_messages}
  end

  @doc """
  Safely calculates a total from quantity, price, and optional fee.

  ## Examples

      iex> AshfolioWeb.FormHelpers.calculate_transaction_total("10", "50.25", "2.50")
      Decimal.new("505.00")
      
      iex> AshfolioWeb.FormHelpers.calculate_transaction_total("10", "50.25", nil)
      Decimal.new("502.50")
  """
  def calculate_transaction_total(quantity, price, fee \\ nil) do
    qty = parse_decimal_unsafe(quantity) || Decimal.new("0")
    prc = parse_decimal_unsafe(price) || Decimal.new("0")
    fee_amount = parse_decimal_unsafe(fee) || Decimal.new("0")

    qty
    |> Decimal.mult(prc)
    |> Decimal.add(fee_amount)
  end

  @doc """
  Formats a decimal value as currency.

  ## Examples

      iex> AshfolioWeb.FormHelpers.format_currency(Decimal.new("1234.56"))
      "$1,234.56"
      
      iex> AshfolioWeb.FormHelpers.format_currency(nil)
      "$0.00"
  """
  def format_currency(nil), do: "$0.00"

  def format_currency(%Decimal{} = value) do
    number = Decimal.to_float(value)

    number
    |> :erlang.float_to_binary(decimals: 2)
    |> add_commas()
    |> then(&"$#{&1}")
  end

  def format_currency(_), do: "$0.00"

  # Helper to add thousands separators
  defp add_commas(number_string) do
    [int_part | decimal_part] = String.split(number_string, ".")

    formatted_int =
      int_part
      |> String.graphemes()
      |> Enum.reverse()
      |> Enum.chunk_every(3)
      |> Enum.map(&Enum.reverse/1)
      |> Enum.reverse()
      |> Enum.join(",")

    case decimal_part do
      [] -> formatted_int
      [decimals] -> "#{formatted_int}.#{decimals}"
    end
  end

  @doc """
  Formats a decimal value as a percentage.

  ## Examples

      iex> AshfolioWeb.FormHelpers.format_percentage(Decimal.new("0.075"))
      "7.50%"
      
      iex> AshfolioWeb.FormHelpers.format_percentage(nil)
      "0.00%"
  """
  def format_percentage(nil), do: "0.00%"

  def format_percentage(%Decimal{} = value) do
    value
    |> Decimal.mult(Decimal.new("100"))
    |> Decimal.round(2)
    |> Decimal.to_string()
    |> then(&"#{&1}%")
  end

  def format_percentage(_), do: "0.00%"
end
