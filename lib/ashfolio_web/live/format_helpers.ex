defmodule AshfolioWeb.Live.FormatHelpers do
  @moduledoc """
  Helper functions for formatting financial data in LiveView components.

  Provides consistent formatting for currency values, percentages, and timestamps
  for the Ashfolio application.
  """

  @doc """
  Formats a Decimal value as USD currency.

  ## Parameters
  - value: Decimal value to format
  - show_cents: Whether to show cents (defaults to true)

  ## Returns
  - Formatted currency string (e.g., "$1,234.56")

  ## Examples
      iex> format_currency(Decimal.new("1234.56"))
      "$1,234.56"

      iex> format_currency(Decimal.new("1234"))
      "$1,234.00"

      iex> format_currency(Decimal.new("-500.25"))
      "-$500.25"
  """
  def format_currency(value, show_cents \\ true)

  def format_currency(nil, _show_cents), do: "$0.00"

  def format_currency(value, show_cents) when is_struct(value, Decimal) do
    # Convert to float for formatting
    float_value = Decimal.to_float(value)

    # Handle negative values
    {sign, abs_value} =
      if float_value < 0 do
        {"-", abs(float_value)}
      else
        {"", float_value}
      end

    # Format with commas and appropriate decimal places
    formatted =
      if show_cents do
        :erlang.float_to_binary(abs_value, decimals: 2)
      else
        :erlang.float_to_binary(abs_value, decimals: 0)
      end

    # Add commas for thousands
    formatted_with_commas = add_commas(formatted)

    "#{sign}$#{formatted_with_commas}"
  end

  def format_currency(value, show_cents) when is_integer(value) do
    format_currency(Decimal.new(value), show_cents)
  end

  def format_currency(value, show_cents) when is_float(value) do
    format_currency(Decimal.from_float(value), show_cents)
  end

  def format_currency(_value, _show_cents), do: "$0.00"

  @doc """
  Formats a Decimal value as a percentage.

  ## Parameters
  - value: Decimal percentage value (e.g., 15.25 for 15.25%)
  - decimal_places: Number of decimal places (defaults to 2)

  ## Returns
  - Formatted percentage string (e.g., "15.25%")

  ## Examples
      iex> format_percentage(Decimal.new("15.25"))
      "15.25%"

      iex> format_percentage(Decimal.new("-5.5"))
      "-5.50%"
  """
  def format_percentage(value, decimal_places \\ 2)

  def format_percentage(nil, _decimal_places), do: "0.00%"

  def format_percentage(value, decimal_places) when is_struct(value, Decimal) do
    float_value = Decimal.to_float(value)
    formatted = :erlang.float_to_binary(float_value, decimals: decimal_places)
    "#{formatted}%"
  end

  def format_percentage(value, decimal_places) when is_integer(value) do
    format_percentage(Decimal.new(value), decimal_places)
  end

  def format_percentage(value, decimal_places) when is_float(value) do
    format_percentage(Decimal.from_float(value), decimal_places)
  end

  def format_percentage(_value, _decimal_places), do: "0.00%"

  @doc """
  Formats a DateTime as a relative time string.

  ## Parameters
  - datetime: DateTime to format
  - current_time: Current time for comparison (defaults to now)

  ## Returns
  - Relative time string (e.g., "5 minutes ago", "2 hours ago")

  ## Examples
      iex> format_relative_time(~U[2025-01-28 10:25:00Z])
      "5 minutes ago"
  """
  def format_relative_time(datetime, current_time \\ DateTime.utc_now())

  def format_relative_time(nil, _current_time), do: "Never"

  def format_relative_time(datetime, current_time) when is_struct(datetime, DateTime) do
    diff_seconds = DateTime.diff(current_time, datetime, :second)

    cond do
      diff_seconds < 60 ->
        "#{diff_seconds} seconds ago"

      diff_seconds < 3600 ->
        minutes = div(diff_seconds, 60)
        "#{minutes} minute#{if minutes == 1, do: "", else: "s"} ago"

      diff_seconds < 86400 ->
        hours = div(diff_seconds, 3600)
        "#{hours} hour#{if hours == 1, do: "", else: "s"} ago"

      true ->
        days = div(diff_seconds, 86400)
        "#{days} day#{if days == 1, do: "", else: "s"} ago"
    end
  end

  def format_relative_time(_datetime, _current_time), do: "Unknown"

  @doc """
  Determines if a value is positive for color coding.

  ## Parameters
  - value: Decimal or numeric value to check

  ## Returns
  - Boolean indicating if value is positive

  ## Examples
      iex> is_positive?(Decimal.new("15.25"))
      true

      iex> is_positive?(Decimal.new("-5.5"))
      false
  """
  def is_positive?(value)

  def is_positive?(nil), do: false

  def is_positive?(value) when is_struct(value, Decimal) do
    Decimal.positive?(value)
  end

  def is_positive?(value) when is_number(value) do
    value > 0
  end

  def is_positive?(_value), do: false

  @doc """
  Gets CSS classes for positive/negative value styling.

  ## Parameters
  - value: Decimal or numeric value to check
  - positive_class: CSS class for positive values (defaults to "text-green-600")
  - negative_class: CSS class for negative values (defaults to "text-red-600")
  - neutral_class: CSS class for zero/neutral values (defaults to "text-gray-600")

  ## Returns
  - CSS class string

  ## Examples
      iex> value_color_class(Decimal.new("15.25"))
      "text-green-600"

      iex> value_color_class(Decimal.new("-5.5"))
      "text-red-600"
  """
  def value_color_class(
        value,
        positive_class \\ "text-green-700",
        negative_class \\ "text-red-700",
        neutral_class \\ "text-gray-600"
      )

  def value_color_class(nil, _positive_class, _negative_class, neutral_class), do: neutral_class

  def value_color_class(value, positive_class, negative_class, neutral_class)
      when is_struct(value, Decimal) do
    cond do
      Decimal.positive?(value) -> positive_class
      Decimal.negative?(value) -> negative_class
      true -> neutral_class
    end
  end

  def value_color_class(value, positive_class, negative_class, neutral_class)
      when is_number(value) do
    cond do
      value > 0 -> positive_class
      value < 0 -> negative_class
      true -> neutral_class
    end
  end

  def value_color_class(_value, _positive_class, _negative_class, neutral_class),
    do: neutral_class

  # Private helper functions

  defp add_commas(number_string) do
    # Split on decimal point if present
    case String.split(number_string, ".") do
      [integer_part] ->
        add_commas_to_integer(integer_part)

      [integer_part, decimal_part] ->
        "#{add_commas_to_integer(integer_part)}.#{decimal_part}"
    end
  end

  defp add_commas_to_integer(integer_string) do
    integer_string
    |> String.reverse()
    |> String.graphemes()
    |> Enum.chunk_every(3)
    |> Enum.map(&Enum.join/1)
    |> Enum.join(",")
    |> String.reverse()
  end

  @doc """
  Formats a Date as a readable string.

  ## Examples
      iex> format_date(~D[2023-12-25])
      "Dec 25, 2023"
  """
  def format_date(nil), do: "N/A"

  def format_date(%Date{} = date) do
    Calendar.strftime(date, "%b %d, %Y")
  end

  def format_date(_date), do: "Invalid Date"

  @doc """
  Formats a quantity as a decimal number.

  ## Examples
      iex> format_quantity(Decimal.new("123.456"))
      "123.456"
  """
  def format_quantity(nil), do: "0"

  def format_quantity(value) when is_struct(value, Decimal) do
    Decimal.to_string(value)
  end

  def format_quantity(value) when is_number(value) do
    :erlang.float_to_binary(value * 1.0, decimals: 3)
  end

  def format_quantity(_value), do: "0"
end
