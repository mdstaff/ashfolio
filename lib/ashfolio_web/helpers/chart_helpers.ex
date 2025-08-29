defmodule AshfolioWeb.Helpers.ChartHelpers do
  @moduledoc """
  General chart formatting utilities for financial data visualization.

  Provides reusable functions for:
  - Number formatting (currency, percentages, y-axis labels)
  - Chart period optimization
  - Financial calculations for projections
  """

  @doc """
  Formats a decimal growth rate as a percentage string.

  ## Examples

      iex> format_growth_rate(Decimal.new("0.07"))
      "7%"
      
      iex> format_growth_rate(Decimal.new("0.105"))
      "10.5%"
  """
  def format_growth_rate(%Decimal{} = rate) do
    formatted =
      rate
      |> Decimal.mult(Decimal.new("100"))
      |> Decimal.round(1)
      |> Decimal.to_string()

    # Remove trailing .0 for whole numbers
    formatted = if String.ends_with?(formatted, ".0"), do: String.replace_suffix(formatted, ".0", ""), else: formatted
    formatted <> "%"
  end

  def format_growth_rate(rate) when is_float(rate) do
    formatted =
      rate
      |> Kernel.*(100)
      |> Float.round(1)

    # Format as integer if it's a whole number
    if formatted == trunc(formatted) do
      "#{trunc(formatted)}%"
    else
      "#{formatted}%"
    end
  end

  def format_growth_rate(rate) when is_binary(rate) do
    case Decimal.parse(rate) do
      {decimal, _} -> format_growth_rate(decimal)
      :error -> "0%"
    end
  end

  @doc """
  Formats Y-axis values with proper notation (K, M, B).

  ## Examples

      iex> format_y_axis(1_000_000)
      "$1M"
      
      iex> format_y_axis(2_500_000)
      "$2.5M"
      
      iex> format_y_axis(500_000)
      "$500K"
  """
  def format_y_axis(value) when is_number(value) do
    cond do
      value >= 1_000_000_000 ->
        formatted = Float.round(value / 1_000_000_000, 1)

        if formatted == trunc(formatted) do
          "$#{trunc(formatted)}B"
        else
          "$#{formatted}B"
        end

      value >= 1_000_000 ->
        formatted = Float.round(value / 1_000_000, 1)

        if formatted == trunc(formatted) do
          "$#{trunc(formatted)}M"
        else
          "$#{formatted}M"
        end

      value >= 1_000 ->
        formatted = Float.round(value / 1_000, 1)

        if formatted == trunc(formatted) do
          "$#{trunc(formatted)}K"
        else
          "$#{formatted}K"
        end

      true ->
        "$#{trunc(value)}"
    end
  end

  def format_y_axis(%Decimal{} = value) do
    format_y_axis(Decimal.to_float(value))
  end

  @doc """
  Generates optimal chart periods based on total years.

  Returns more frequent periods for shorter timeframes.
  """
  def generate_chart_periods(total_years) when total_years <= 10, do: 0..total_years
  def generate_chart_periods(total_years) when total_years <= 20, do: Enum.take_every(0..total_years, 2)
  def generate_chart_periods(total_years), do: Enum.take_every(0..total_years, max(1, div(total_years, 10)))

  @doc """
  Builds compound growth projection for a single scenario.

  Uses financial formulas for accurate compound growth with contributions.
  """
  def build_scenario_projection(initial_value, params, years, growth_rate) do
    monthly_contribution = Map.get(params, :monthly_contribution, Decimal.new("0"))
    periods = generate_chart_periods(years)

    Enum.map(periods, fn year ->
      if year == 0 do
        initial_value
      else
        calculate_future_value(initial_value, monthly_contribution, growth_rate, year)
      end
    end)
  end

  @doc """
  Formats currency values for display.
  """
  def format_currency(%Decimal{} = value) do
    # Use basic currency formatting without external dependency
    value
    |> Decimal.to_float()
    |> format_currency()
  end

  def format_currency(value) when is_number(value) do
    # Basic currency formatting - convert to float first
    float_value = if is_integer(value), do: value * 1.0, else: value

    float_value
    |> :erlang.float_to_binary([{:decimals, 2}])
    |> then(&("$" <> &1))
  end

  def format_currency(_), do: "$0.00"

  # Private helper function for compound growth calculations
  defp calculate_future_value(initial, monthly_contrib, rate, years) do
    # FV = P(1 + r)^t + PMT × (((1 + r)^t - 1) / r)
    # Where P = initial value, r = annual rate, t = years, PMT = annual contribution

    annual_contrib = Decimal.mult(monthly_contrib || Decimal.new("0"), Decimal.new("12"))

    # Convert rate to Decimal if it's a float
    rate_decimal =
      case rate do
        %Decimal{} -> rate
        rate when is_float(rate) -> Decimal.from_float(rate)
        rate when is_integer(rate) -> Decimal.new(to_string(rate))
        _ -> Decimal.new("0")
      end

    if Decimal.equal?(rate_decimal, Decimal.new("0")) do
      # No growth case
      contrib_total = Decimal.mult(annual_contrib, Decimal.new(to_string(years)))
      Decimal.add(initial, contrib_total)
    else
      # Calculate (1 + r)^t
      growth_factor = :math.pow(1 + Decimal.to_float(rate_decimal), years)
      growth_factor_decimal = Decimal.from_float(growth_factor)

      # Future value of initial investment
      fv_initial = Decimal.mult(initial, growth_factor_decimal)

      # Future value of contributions
      if Decimal.equal?(annual_contrib, Decimal.new("0")) do
        fv_initial
      else
        annuity_factor = (growth_factor - 1) / Decimal.to_float(rate_decimal)
        fv_contributions = Decimal.mult(annual_contrib, Decimal.from_float(annuity_factor))
        Decimal.add(fv_initial, fv_contributions)
      end
    end
  end
end
