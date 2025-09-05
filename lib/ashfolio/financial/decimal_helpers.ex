defmodule Ashfolio.Financial.DecimalHelpers do
  @moduledoc """
  Helper functions for common Decimal operations in financial calculations.

  Provides ergonomic, chainable operations for working with Decimal values
  while maintaining precision and consistent error handling.
  """

  alias Decimal, as: D

  @zero D.new("0")
  @one D.new("1")
  @hundred D.new("100")
  @twelve D.new("12")

  @doc """
  Ensures the input is a Decimal. Converts from various types.

  ## Examples
      
      iex> ensure_decimal(42)
      Decimal.new("42")
      
      iex> ensure_decimal("100.50")
      Decimal.new("100.50")
      
      iex> ensure_decimal(Decimal.new("10"))
      Decimal.new("10")
  """
  def ensure_decimal(%D{} = decimal), do: decimal
  def ensure_decimal(nil), do: @zero
  def ensure_decimal(value) when is_integer(value), do: D.new(value)
  def ensure_decimal(value) when is_float(value), do: D.from_float(value)
  def ensure_decimal(value) when is_binary(value), do: D.new(value)

  @doc """
  Converts a decimal to percentage (multiplies by 100).

  ## Examples
      
      iex> to_percentage(Decimal.new("0.075"))
      Decimal.new("7.5")
  """
  def to_percentage(value) do
    value
    |> ensure_decimal()
    |> D.mult(@hundred)
  end

  @doc """
  Converts from percentage to decimal (divides by 100).

  ## Examples
      
      iex> from_percentage(Decimal.new("7.5"))
      Decimal.new("0.075")
  """
  def from_percentage(value) do
    value
    |> ensure_decimal()
    |> D.div(@hundred)
  end

  @doc """
  Converts monthly amount to annual (multiplies by 12).

  ## Examples
      
      iex> monthly_to_annual(Decimal.new("1000"))
      Decimal.new("12000")
  """
  def monthly_to_annual(value) do
    value
    |> ensure_decimal()
    |> D.mult(@twelve)
  end

  @doc """
  Converts annual amount to monthly (divides by 12).

  ## Examples
      
      iex> annual_to_monthly(Decimal.new("12000"))
      Decimal.new("1000")
  """
  def annual_to_monthly(value) do
    value
    |> ensure_decimal()
    |> D.div(@twelve)
  end

  @doc """
  Checks if a decimal value is positive (> 0).
  """
  def positive?(value) do
    D.compare(ensure_decimal(value), @zero) == :gt
  end

  @doc """
  Checks if a decimal value is negative (< 0).
  """
  def negative?(value) do
    D.compare(ensure_decimal(value), @zero) == :lt
  end

  @doc """
  Checks if a decimal value is zero.
  """
  def zero?(value) do
    D.compare(ensure_decimal(value), @zero) == :eq
  end

  @doc """
  Checks if a decimal value is non-zero.
  """
  def non_zero?(value) do
    !zero?(value)
  end

  @doc """
  Safely divides two decimals, returning zero if divisor is zero.

  ## Examples
      
      iex> safe_divide(Decimal.new("10"), Decimal.new("2"))
      Decimal.new("5")
      
      iex> safe_divide(Decimal.new("10"), Decimal.new("0"))
      Decimal.new("0")
  """
  def safe_divide(dividend, divisor) do
    dividend = ensure_decimal(dividend)
    divisor = ensure_decimal(divisor)

    if zero?(divisor) do
      @zero
    else
      D.div(dividend, divisor)
    end
  end

  @doc """
  Calculates percentage change between two values.

  ## Examples
      
      iex> percentage_change(Decimal.new("100"), Decimal.new("110"))
      Decimal.new("10")
      
      iex> percentage_change(Decimal.new("100"), Decimal.new("90"))
      Decimal.new("-10")
  """
  def percentage_change(from, to) do
    from = ensure_decimal(from)
    to = ensure_decimal(to)

    if zero?(from) do
      @zero
    else
      to
      |> D.sub(from)
      |> D.div(from)
      |> to_percentage()
    end
  end

  @doc """
  Sums a list of decimal values.

  ## Examples
      
      iex> sum([Decimal.new("10"), Decimal.new("20"), Decimal.new("30")])
      Decimal.new("60")
  """
  def sum(values) when is_list(values) do
    Enum.reduce(values, @zero, fn value, acc ->
      D.add(acc, ensure_decimal(value))
    end)
  end

  def sum(_), do: @zero

  @doc """
  Calculates the average of a list of decimal values.

  ## Examples
      
      iex> average([Decimal.new("10"), Decimal.new("20"), Decimal.new("30")])
      Decimal.new("20")
  """
  def average(values) when is_list(values) and length(values) > 0 do
    total = sum(values)
    count = D.new(length(values))
    D.div(total, count)
  end

  def average(_), do: @zero

  @doc """
  Calculates power using float conversion for mathematical operations.
  Maintains precision by converting back to Decimal.

  ## Examples
      
      iex> safe_power(Decimal.new("2"), 3)
      Decimal.new("8")
  """
  def safe_power(base, exponent) do
    base = ensure_decimal(base)

    cond do
      zero?(base) ->
        @zero

      exponent == 0 ->
        @one

      exponent == 1 ->
        base

      true ->
        base_float = D.to_float(base)
        result = :math.pow(base_float, exponent)
        D.from_float(result)
    end
  end

  @doc """
  Calculates nth root using float conversion.

  ## Examples
      
      iex> safe_nth_root(Decimal.new("8"), 3)
      Decimal.new("2")
  """
  def safe_nth_root(value, n) do
    value = ensure_decimal(value)

    if zero?(value) or n == 0 do
      @zero
    else
      value_float = D.to_float(value)
      result = :math.pow(value_float, 1.0 / n)
      D.from_float(result)
    end
  end

  @doc """
  Calculates compound growth: principal * (1 + rate)^periods

  ## Examples
      
      iex> compound(Decimal.new("1000"), Decimal.new("0.05"), 10)
      # Returns 1000 * (1.05)^10 = 1628.89...
  """
  def compound(principal, rate, periods) do
    principal = ensure_decimal(principal)
    rate = ensure_decimal(rate)

    multiplier = D.add(@one, rate)
    growth_factor = safe_power(multiplier, periods)

    D.mult(principal, growth_factor)
  end

  @doc """
  Rounds a decimal to specified decimal places.

  ## Examples
      
      iex> round_to(Decimal.new("10.12345"), 2)
      Decimal.new("10.12")
  """
  def round_to(value, decimal_places \\ 2) do
    value
    |> ensure_decimal()
    |> D.round(decimal_places)
  end

  @doc """
  Returns the maximum of two decimal values.
  """
  def decimal_max(a, b) do
    a = ensure_decimal(a)
    b = ensure_decimal(b)

    case D.compare(a, b) do
      :gt -> a
      _ -> b
    end
  end

  @doc """
  Returns the minimum of two decimal values.
  """
  def decimal_min(a, b) do
    a = ensure_decimal(a)
    b = ensure_decimal(b)

    case D.compare(a, b) do
      :lt -> a
      _ -> b
    end
  end

  @doc """
  Clamps a value between min and max bounds.
  """
  def clamp(value, min_val, max_val) do
    value
    |> ensure_decimal()
    |> decimal_max(min_val)
    |> decimal_min(max_val)
  end

  @doc """
  Converts a decimal to a float, useful for charting libraries.
  Returns 0.0 if value is nil or invalid.
  """
  def to_float_safe(value) do
    value
    |> ensure_decimal()
    |> D.to_float()
  rescue
    _ -> 0.0
  end
end
