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
end
