defmodule Ashfolio.Financial.Mathematical do
  @moduledoc """
  Consolidated mathematical operations for financial calculations.

  Provides consistent mathematical functions for:
  - Power and root calculations
  - Exponential and logarithmic functions  
  - Compound interest calculations
  - Binary search algorithms for financial projections

  All functions maintain Decimal precision and include proper error handling.
  """

  alias Decimal, as: D

  @zero D.new("0")
  @one D.new("1")

  @doc """
  Calculates base^exponent with high precision.

  Uses float conversion for mathematical operations while maintaining 
  Decimal precision in the result.

  ## Examples
      
      iex> Ashfolio.Financial.Mathematical.power(Decimal.new("2"), 3)
      Decimal.new("8.0")
      
      iex> result = Ashfolio.Financial.Mathematical.power(Decimal.new("1.05"), 10)
      iex> Decimal.round(result, 4)
      Decimal.new("1.6289")
  """
  def power(base, exponent) when is_integer(exponent) and exponent >= 0 do
    base = ensure_decimal(base)

    cond do
      D.equal?(base, @zero) ->
        @zero

      exponent == 0 ->
        @one

      exponent == 1 ->
        base

      true ->
        base_float = D.to_float(base)
        result_float = :math.pow(base_float, exponent)
        D.from_float(result_float)
    end
  end

  def power(base, exponent) when is_integer(exponent) and exponent < 0 do
    positive_result = power(base, -exponent)
    D.div(@one, positive_result)
  end

  def power(base, exponent) do
    base = ensure_decimal(base)
    exponent = ensure_decimal(exponent)

    base_float = D.to_float(base)
    exp_float = D.to_float(exponent)
    result_float = :math.pow(base_float, exp_float)
    D.from_float(result_float)
  end

  @doc """
  Calculates the nth root of a number.

  Uses float conversion with high precision algorithms.

  ## Examples
      
      iex> Ashfolio.Financial.Mathematical.nth_root(Decimal.new("8"), 3)
      Decimal.new("2.0")
      
      iex> Ashfolio.Financial.Mathematical.nth_root(Decimal.new("100"), 2)
      Decimal.new("10.0")
  """
  def nth_root(number, n) when is_integer(n) and n > 0 do
    number = ensure_decimal(number)

    cond do
      D.equal?(number, @zero) ->
        @zero

      n == 1 ->
        number

      true ->
        float_num = D.to_float(number)
        float_root = :math.pow(float_num, 1.0 / n)
        D.from_float(float_root)
    end
  end

  @doc """
  Binary search algorithm for nth root calculation.

  Provides more precise calculation for specific financial scenarios
  where float conversion may lose precision.

  ## Examples
      
      iex> result = Ashfolio.Financial.Mathematical.binary_search_nth_root(Decimal.new("8"), 3)
      iex> Decimal.round(result, 2)
      Decimal.new("2.00")
  """
  def binary_search_nth_root(target, n, precision \\ 20) do
    target = ensure_decimal(target)
    decimal_n = D.new(to_string(n))

    # Set search bounds
    low = if D.compare(target, @one) == :lt, do: target, else: @one
    high = if D.compare(target, @one) == :gt, do: target, else: @one

    binary_search_nth_root_recursive(target, decimal_n, low, high, precision)
  end

  defp binary_search_nth_root_recursive(target, n, low, high, iterations_left) do
    if iterations_left <= 0 do
      D.div(D.add(low, high), D.new("2"))
    else
      mid = D.div(D.add(low, high), D.new("2"))
      mid_power_n = power(mid, D.to_integer(n))

      case D.compare(mid_power_n, target) do
        :eq -> mid
        :gt -> binary_search_nth_root_recursive(target, n, low, mid, iterations_left - 1)
        :lt -> binary_search_nth_root_recursive(target, n, mid, high, iterations_left - 1)
      end
    end
  end

  @doc """
  Natural exponential function (e^x).

  ## Examples
      
      iex> result = Ashfolio.Financial.Mathematical.exp(Decimal.new("1"))
      iex> Decimal.round(result, 3)
      Decimal.new("2.718")
  """
  def exp(x) do
    x = ensure_decimal(x)
    float_x = D.to_float(x)
    result = :math.exp(float_x)
    D.from_float(result)
  end

  @doc """
  Natural logarithm function (ln(x)).

  ## Examples
      
      iex> result = Ashfolio.Financial.Mathematical.ln(Decimal.new("2.718"))
      iex> Decimal.round(result, 1)
      Decimal.new("1.0")
  """
  def ln(x) do
    x = ensure_decimal(x)
    float_x = D.to_float(x)
    result = :math.log(float_x)
    D.from_float(result)
  end

  @doc """
  Compound interest calculation: principal * (1 + rate)^periods

  Standardized compound growth formula used across all financial projections.

  ## Examples
      
      iex> result = Ashfolio.Financial.Mathematical.compound_growth(Decimal.new("1000"), Decimal.new("0.05"), 10)
      iex> Decimal.round(result, 2)
      Decimal.new("1628.89")
  """
  def compound_growth(principal, rate, periods) do
    principal = ensure_decimal(principal)
    rate = ensure_decimal(rate)

    if D.equal?(rate, @zero) do
      principal
    else
      multiplier = D.add(@one, rate)
      growth_factor = power(multiplier, periods)
      D.mult(principal, growth_factor)
    end
  end

  @doc """
  Future value of annuity calculation.

  Calculates the future value of regular payments with compound interest.

  ## Examples
      
      iex> result = Ashfolio.Financial.Mathematical.future_value_annuity(Decimal.new("100"), Decimal.new("0.05"), 12)
      iex> Decimal.round(result, 2)
      Decimal.new("1591.71")
  """
  def future_value_annuity(payment, rate, periods) do
    payment = ensure_decimal(payment)
    rate = ensure_decimal(rate)

    if D.equal?(rate, @zero) do
      D.mult(payment, D.new(to_string(periods)))
    else
      numerator = D.sub(power(D.add(@one, rate), periods), @one)
      D.mult(payment, D.div(numerator, rate))
    end
  end

  @doc """
  Present value calculation with compound discounting.

  ## Examples
      
      iex> result = Ashfolio.Financial.Mathematical.present_value(Decimal.new("1000"), Decimal.new("0.05"), 10)
      iex> Decimal.round(result, 2)
      Decimal.new("613.91")
  """
  def present_value(future_value, rate, periods) do
    future_value = ensure_decimal(future_value)
    rate = ensure_decimal(rate)

    if D.equal?(rate, @zero) do
      future_value
    else
      discount_factor = power(D.add(@one, rate), periods)
      D.div(future_value, discount_factor)
    end
  end

  @doc """
  Continuous compounding calculation: principal * e^(rate * time)

  ## Examples
      
      iex> result = Ashfolio.Financial.Mathematical.continuous_compound(Decimal.new("1000"), Decimal.new("0.05"), 10)
      iex> Decimal.round(result, 2)
      Decimal.new("1648.72")
  """
  def continuous_compound(principal, rate, time) do
    principal = ensure_decimal(principal)
    rate = ensure_decimal(rate)
    time = ensure_decimal(time)

    exponent = D.mult(rate, time)
    growth_factor = exp(exponent)
    D.mult(principal, growth_factor)
  end

  @doc """
  Effective annual rate calculation from nominal rate and compounding frequency.

  Formula: (1 + nominal_rate/periods)^periods - 1

  ## Examples
      
      iex> result = Ashfolio.Financial.Mathematical.effective_annual_rate(Decimal.new("0.12"), 12)
      iex> Decimal.round(result, 4)
      Decimal.new("0.1268")
  """
  def effective_annual_rate(nominal_rate, periods) do
    nominal_rate = ensure_decimal(nominal_rate)

    if periods == 0 or D.equal?(nominal_rate, @zero) do
      @zero
    else
      period_rate = D.div(nominal_rate, D.new(to_string(periods)))
      compound_factor = power(D.add(@one, period_rate), periods)
      D.sub(compound_factor, @one)
    end
  end

  @doc """
  Calculates Compound Annual Growth Rate (CAGR).

  Formula: (ending_value / beginning_value)^(1/years) - 1

  ## Examples
      
      iex> result = Ashfolio.Financial.Mathematical.cagr(Decimal.new("1000"), Decimal.new("2000"), 10)
      iex> Decimal.round(result, 4)
      Decimal.new("0.0718")
  """
  def cagr(beginning_value, ending_value, years) do
    beginning_value = ensure_decimal(beginning_value)
    ending_value = ensure_decimal(ending_value)

    if D.equal?(beginning_value, @zero) or years <= 0 do
      @zero
    else
      ratio = D.div(ending_value, beginning_value)
      growth_factor = nth_root(ratio, years)
      D.sub(growth_factor, @one)
    end
  end

  @doc """
  Rule of 72 approximation for doubling time.

  ## Examples
      
      iex> Ashfolio.Financial.Mathematical.rule_of_72(Decimal.new("0.06"))
      Decimal.new("12")
  """
  def rule_of_72(annual_rate) do
    annual_rate = ensure_decimal(annual_rate)
    rate_percent = D.mult(annual_rate, D.new("100"))
    D.div(D.new("72"), rate_percent)
  end

  # Private helper functions

  defp ensure_decimal(%D{} = value), do: value
  defp ensure_decimal(value) when is_binary(value), do: D.new(value)
  defp ensure_decimal(value) when is_integer(value), do: D.new(to_string(value))
  defp ensure_decimal(value) when is_float(value), do: D.from_float(value)
  defp ensure_decimal(_), do: @zero
end
