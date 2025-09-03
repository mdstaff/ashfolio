defmodule AshfolioWeb.Helpers.FormatHelper do
  @moduledoc """
  Formatting helpers for displaying financial data in charts and UI components.
  Handles percentage formatting, currency abbreviations, and number formatting.
  """

  @doc """
  Formats a decimal growth rate as a percentage string.

  ## Examples
      
      iex> format_growth_rate(Decimal.new("0.07"))
      "7%"
      
      iex> format_growth_rate(Decimal.new("0.125"))
      "12.5%"
      
      iex> format_growth_rate(Decimal.new("-0.05"))
      "-5%"
  """
  def format_growth_rate(decimal_rate) when is_struct(decimal_rate, Decimal) do
    # Convert to percentage (multiply by 100)
    percentage = Decimal.mult(decimal_rate, Decimal.new("100"))

    # Round to 2 decimal places
    rounded = Decimal.round(percentage, 2)

    # Convert to string and clean up formatting
    formatted = Decimal.to_string(rounded)

    # Remove trailing zeros and decimal point if not needed
    formatted =
      formatted
      |> String.trim_trailing("0")
      |> String.trim_trailing(".")

    "#{formatted}%"
  end

  def format_growth_rate(nil), do: "0%"

  def format_growth_rate(rate) when is_number(rate) do
    format_growth_rate(Decimal.from_float(rate))
  end

  @doc """
  Formats numbers for chart axes with appropriate abbreviations (K, M, B).

  ## Examples

      iex> format_chart_axis(1_000_000)
      "$1M"
      
      iex> format_chart_axis(2_500_000)
      "$2.5M"
      
      iex> format_chart_axis(500_000)
      "$500K"
      
      iex> format_chart_axis(2_000_000_000)
      "$2B"
  """
  def format_chart_axis(value) when is_struct(value, Decimal) do
    # Convert Decimal to float for formatting
    float_value = Decimal.to_float(value)
    format_chart_axis(float_value)
  end

  def format_chart_axis(value) when is_number(value) do
    cond do
      value >= 1_000_000_000 ->
        formatted = Float.round(value / 1_000_000_000, 1)
        # Remove .0 for whole numbers
        if formatted == trunc(formatted) do
          "$#{trunc(formatted)}B"
        else
          "$#{formatted}B"
        end

      value >= 1_000_000 ->
        formatted = Float.round(value / 1_000_000, 1)
        # Remove .0 for whole numbers
        if formatted == trunc(formatted) do
          "$#{trunc(formatted)}M"
        else
          "$#{formatted}M"
        end

      value >= 1_000 ->
        formatted = Float.round(value / 1_000, 1)
        # Remove .0 for whole numbers
        if formatted == trunc(formatted) do
          "$#{trunc(formatted)}K"
        else
          "$#{formatted}K"
        end

      true ->
        "$#{round(value)}"
    end
  end

  def format_chart_axis(nil), do: "$0"

  @doc """
  Formats currency values for display in the UI.

  ## Examples

      iex> format_currency(Decimal.new("1234567.89"))
      "$1,234,567.89"
      
      iex> format_currency(1000)
      "$1,000.00"
  """
  def format_currency(value) when is_struct(value, Decimal) do
    # Format with commas and 2 decimal places
    formatted =
      value
      |> Decimal.round(2)
      |> Decimal.to_string()
      |> add_commas()

    "$#{formatted}"
  end

  def format_currency(value) when is_number(value) do
    format_currency(Decimal.from_float(value * 1.0))
  end

  def format_currency(nil), do: "$0.00"

  # Helper function to add commas to number strings
  defp add_commas(number_string) do
    [integer_part | decimal_parts] = String.split(number_string, ".")

    formatted_integer =
      integer_part
      |> String.graphemes()
      |> Enum.reverse()
      |> Enum.chunk_every(3)
      |> Enum.map(&Enum.reverse/1)
      |> Enum.reverse()
      |> Enum.map_join(",", &Enum.join/1)

    case decimal_parts do
      [] -> formatted_integer
      [decimals] -> "#{formatted_integer}.#{decimals}"
    end
  end

  @doc """
  Formats percentage values for display (already as percentage, not decimal).

  ## Examples

      iex> format_percentage(7.5)
      "7.5%"
      
      iex> format_percentage(100)
      "100%"
  """
  def format_percentage(value) when is_number(value) do
    if value == trunc(value) do
      "#{trunc(value)}%"
    else
      "#{Float.round(value, 2)}%"
    end
  end

  def format_percentage(value) when is_struct(value, Decimal) do
    format_percentage(Decimal.to_float(value))
  end

  def format_percentage(nil), do: "0%"
end
