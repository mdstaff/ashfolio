defmodule Ashfolio.Financial.Formatters do
  @moduledoc """
  Unified currency and financial value formatting for consistent display across Ashfolio.

  Consolidates all currency formatting logic from helpers, LiveViews, and components
  into a single, feature-complete API.  

  ## Examples
      iex> Ashfolio.Financial.Formatters.currency(Decimal.new("1234.56"))
      "$1,234.56"
      
      iex> Ashfolio.Financial.Formatters.currency(Decimal.new("1234.56"), show_cents: false)  
      "$1,235"
      
      iex> Ashfolio.Financial.Formatters.currency(Decimal.new("-123.45"))
      "-$123.45"
      
      iex> Ashfolio.Financial.Formatters.currency(nil)
      "$0.00"
  """

  @doc """
  Formats currency values with comprehensive options support.

  ## Options
    * `:show_cents` - boolean, display cents (default: true)
    * `:comma_formatting` - boolean, add thousands separators (default: true)  
    * `:handle_negative` - boolean, format negative values with sign (default: true)
    * `:currency_symbol` - string, currency symbol (default: "$")
    * `:fallback` - string, value for nil/invalid inputs (default: "$0.00")

  ## Examples
      iex> Formatters.currency(Decimal.new("1234.56"))
      "$1,234.56"
      
      iex> Formatters.currency(Decimal.new("1234.56"), show_cents: false)
      "$1,235"
      
      iex> Formatters.currency(Decimal.new("-123.45"))
      "-$123.45"
      
      iex> Formatters.currency(nil)
      "$0.00"
  """
  def currency(value, opts \\ [])

  def currency(value, opts) when is_struct(value, Decimal) do
    options = build_options(opts)

    value
    |> handle_negative_value(options)
    |> format_decimal_value(options)
    |> add_currency_symbol(options)
  end

  def currency(value, opts) when is_number(value) do
    currency(Decimal.from_float(value * 1.0), opts)
  end

  def currency(nil, opts) do
    options = build_options(opts)
    options.fallback
  end

  def currency(_, opts) do
    currency(nil, opts)
  end

  @doc """
  Backward compatibility for format_helper.ex usage pattern.
  Always shows cents with comma formatting.
  """
  def format_currency_classic(value) do
    currency(value, show_cents: true, comma_formatting: true)
  end

  @doc """
  Backward compatibility for format_helpers.ex usage pattern.
  Supports show_cents parameter.
  """
  def format_currency_with_cents(value, show_cents \\ true) do
    currency(value, show_cents: show_cents, comma_formatting: true, handle_negative: true)
  end

  @doc """
  Backward compatibility for chart_helpers.ex usage pattern.  
  Minimal formatting without commas, uses special negative format ($-123.45).
  """
  def format_currency_simple(value) do
    # Chart helpers has a unique negative format: $-123.45 instead of -$123.45
    case value do
      %Decimal{} = decimal_value ->
        if Decimal.negative?(decimal_value) do
          abs_value = Decimal.abs(decimal_value)
          formatted = currency(abs_value, show_cents: true, comma_formatting: false, handle_negative: false)
          String.replace(formatted, "$", "$-")
        else
          currency(decimal_value, show_cents: true, comma_formatting: false, handle_negative: false)
        end

      num when is_number(num) ->
        format_currency_simple(Decimal.from_float(num * 1.0))

      nil ->
        "$0.00"

      _ ->
        "$0.00"
    end
  end

  # Private implementation functions

  defp build_options(opts) do
    %{
      show_cents: Keyword.get(opts, :show_cents, true),
      comma_formatting: Keyword.get(opts, :comma_formatting, true),
      handle_negative: Keyword.get(opts, :handle_negative, true),
      currency_symbol: Keyword.get(opts, :currency_symbol, "$"),
      fallback: Keyword.get(opts, :fallback, "$0.00")
    }
  end

  defp handle_negative_value(value, %{handle_negative: true}) do
    if Decimal.negative?(value) do
      {"-", Decimal.abs(value)}
    else
      {"", value}
    end
  end

  defp handle_negative_value(value, %{handle_negative: false}) do
    {"", Decimal.abs(value)}
  end

  defp format_decimal_value({sign, value}, options) do
    formatted =
      if options.show_cents do
        value
        |> Decimal.round(2)
        |> Decimal.to_string()
      else
        value
        |> Decimal.round(0)
        |> Decimal.to_string()
      end

    formatted_with_commas =
      if options.comma_formatting do
        add_thousands_separator(formatted)
      else
        formatted
      end

    {sign, formatted_with_commas}
  end

  defp add_currency_symbol({sign, formatted}, options) do
    "#{sign}#{options.currency_symbol}#{formatted}"
  end

  defp add_thousands_separator(number_string) do
    case String.split(number_string, ".", parts: 2) do
      [whole] ->
        add_commas_to_whole(whole)

      [whole, decimal] ->
        "#{add_commas_to_whole(whole)}.#{decimal}"
    end
  end

  defp add_commas_to_whole(whole_part) do
    whole_part
    |> String.reverse()
    |> String.graphemes()
    |> Enum.chunk_every(3)
    |> Enum.map_join(",", &Enum.join/1)
    |> String.reverse()
  end

  @doc """
  Formats percentage values with customizable decimal places.

  ## Examples
      iex> Formatters.format_percentage(Decimal.new("15.25"))
      "15.25%"
      
      iex> Formatters.format_percentage(Decimal.new("15.25678"), 1)
      "15.3%"
  """
  def format_percentage(value, decimal_places \\ 2)

  def format_percentage(value, decimal_places) when is_struct(value, Decimal) do
    formatted = value |> Decimal.round(decimal_places) |> Decimal.to_string()
    "#{formatted}%"
  end

  def format_percentage(value, decimal_places) when is_number(value) do
    format_percentage(Decimal.from_float(value * 1.0), decimal_places)
  end

  def format_percentage(nil, _decimal_places), do: "0.00%"
  def format_percentage(_, _decimal_places), do: "0.00%"

  @doc """
  Formats relative time from a datetime to "X time ago".

  ## Examples
      iex> past_time = ~U[2025-01-28 10:25:00Z]
      iex> current_time = ~U[2025-01-28 10:30:00Z]  
      iex> Formatters.format_relative_time(past_time, current_time)
      "5 minutes ago"
  """
  def format_relative_time(datetime, reference_time \\ nil)

  def format_relative_time(%DateTime{} = datetime, reference_time) do
    reference = reference_time || DateTime.utc_now()

    case DateTime.diff(reference, datetime) do
      diff when diff < 60 ->
        "#{diff} second#{if diff == 1, do: "", else: "s"} ago"

      diff when diff < 3600 ->
        minutes = div(diff, 60)
        "#{minutes} minute#{if minutes == 1, do: "", else: "s"} ago"

      diff when diff < 86_400 ->
        hours = div(diff, 3600)
        "#{hours} hour#{if hours == 1, do: "", else: "s"} ago"

      diff ->
        days = div(diff, 86_400)
        "#{days} day#{if days == 1, do: "", else: "s"} ago"
    end
  end

  def format_relative_time(%Date{} = date, reference_time) do
    # Convert Date to DateTime at midnight UTC
    datetime = DateTime.new!(date, ~T[00:00:00], "Etc/UTC")
    format_relative_time(datetime, reference_time)
  end

  def format_relative_time(nil, _reference_time), do: "Never"
  def format_relative_time(_, _reference_time), do: "Unknown"

  @doc """
  Returns CSS class for positive/negative/neutral values.

  ## Examples
      iex> Formatters.value_color_class(Decimal.new("15.25"))
      "text-green-700"
      
      iex> Formatters.value_color_class(Decimal.new("-15.25"))
      "text-red-700"
      
      iex> Formatters.value_color_class(Decimal.new("0"))
      "text-gray-600"
  """
  def value_color_class(
        value,
        positive_class \\ "text-green-700",
        negative_class \\ "text-red-700",
        neutral_class \\ "text-gray-600"
      )

  def value_color_class(value, positive_class, negative_class, neutral_class) when is_struct(value, Decimal) do
    case Decimal.compare(value, Decimal.new("0")) do
      :gt -> positive_class
      :lt -> negative_class
      :eq -> neutral_class
    end
  end

  def value_color_class(value, positive_class, negative_class, neutral_class) when is_number(value) do
    value_color_class(Decimal.from_float(value * 1.0), positive_class, negative_class, neutral_class)
  end

  def value_color_class(_, _positive_class, _negative_class, neutral_class), do: neutral_class

  @doc """
  Formats date values to readable format.

  ## Examples
      iex> Formatters.format_date(~D[2023-12-25])
      "Dec 25, 2023"
  """
  def format_date(%Date{} = date) do
    Calendar.strftime(date, "%b %d, %Y")
  end

  def format_date(nil), do: "N/A"
  def format_date(_), do: "Invalid Date"

  @doc """
  Formats quantity values (for shares, etc.) with trailing zero removal.

  ## Examples
      iex> Formatters.format_quantity(Decimal.new("123.456"))
      "123.456"
      
      iex> Formatters.format_quantity(Decimal.new("100.000"))
      "100"
  """
  def format_quantity(value)

  def format_quantity(value) when is_struct(value, Decimal) do
    value
    |> Decimal.round(6)
    |> Decimal.to_string()
    |> String.replace(~r/\.?0+$/, "")
  end

  def format_quantity(value) when is_number(value) do
    format_quantity(Decimal.from_float(value * 1.0))
  end

  def format_quantity(nil), do: "0"
  def format_quantity(_), do: "0"

  @doc """
  Checks if a value is positive (> 0).
  Handles both Decimal values and formatted currency strings.
  """
  def positive?(value) when is_struct(value, Decimal) do
    Ashfolio.Financial.DecimalHelpers.positive?(value)
  end
  
  def positive?(formatted_currency) when is_binary(formatted_currency) do
    # Handle formatted currency strings like "$123.45" or "-$45.67"
    case formatted_currency do
      <<"-", _rest::binary>> -> false
      <<"$0.00">> -> false
      <<"$", _rest::binary>> -> true
      _ -> false
    end
  end
  
  def positive?(nil), do: false
  def positive?(_), do: false
end
