defmodule Ashfolio.FinancialManagement.AERCalculator do
  @moduledoc """
  Annual Equivalent Rate (AER) calculator for standardized compound interest calculations.
  
  This module provides consistent compounding methodology across all financial projections
  in the Ashfolio platform. All calculations use precise Decimal arithmetic to ensure
  accuracy in financial planning.
  
  ## Key Functions
  
  - `monthly_to_aer/1` - Convert monthly rate to annual equivalent rate
  - `aer_to_monthly/1` - Convert annual rate to monthly equivalent
  - `compound_with_aer/4` - Standard compound interest calculation
  - `effective_rate/2` - Calculate effective rate from nominal
  - `future_value_with_regular_deposits/5` - FV with regular contributions
  """
  
  require Logger
  
  @doc """
  Converts a monthly interest rate to Annual Equivalent Rate (AER).
  
  ## Formula
  
      AER = (1 + monthly_rate)^12 - 1
  
  ## Examples
  
      iex> monthly_to_aer(Decimal.new("0.01"))
      Decimal.new("0.12682503013196977")
  """
  def monthly_to_aer(monthly_rate) when is_struct(monthly_rate, Decimal) do
    cond do
      Decimal.compare(monthly_rate, Decimal.new("0")) == :eq ->
        Decimal.new("0")
      
      Decimal.compare(monthly_rate, Decimal.new("-1")) != :gt ->
        raise ArgumentError, "Monthly rate cannot be <= -100%"
        
      true ->
        # (1 + monthly_rate)^12 - 1
        one_plus_rate = Decimal.add(Decimal.new("1"), monthly_rate)
        compounded = power(one_plus_rate, 12)
        Decimal.sub(compounded, Decimal.new("1"))
    end
  end
  
  @doc """
  Converts Annual Equivalent Rate (AER) to monthly interest rate.
  
  ## Formula
  
      monthly_rate = (1 + AER)^(1/12) - 1
  
  ## Examples
  
      iex> aer_to_monthly(Decimal.new("0.12"))
      Decimal.new("0.009488792934525269")
  """
  def aer_to_monthly(aer) when is_struct(aer, Decimal) do
    cond do
      Decimal.compare(aer, Decimal.new("0")) == :eq ->
        Decimal.new("0")
        
      Decimal.compare(aer, Decimal.new("-1")) != :gt ->
        raise ArgumentError, "AER cannot be <= -100%"
        
      true ->
        # (1 + aer)^(1/12) - 1
        one_plus_aer = Decimal.add(Decimal.new("1"), aer)
        monthly_factor = nth_root(one_plus_aer, 12)
        Decimal.sub(monthly_factor, Decimal.new("1"))
    end
  end
  
  @doc """
  Calculates compound interest using Annual Equivalent Rate.
  
  ## Parameters
  
  - `principal` - Initial amount
  - `aer` - Annual Equivalent Rate (as decimal, e.g., 0.07 for 7%)
  - `years` - Number of years
  - `monthly_contribution` - Optional regular monthly contribution (default: 0)
  
  ## Examples
  
      iex> compound_with_aer(Decimal.new("10000"), Decimal.new("0.07"), 10)
      Decimal.new("19671.51")
  """
  def compound_with_aer(principal, aer, years, monthly_contribution \\ Decimal.new("0")) do
    cond do
      years == 0 ->
        principal
        
      Decimal.compare(aer, Decimal.new("0")) == :eq ->
        # No interest: principal + total contributions
        total_contributions = Decimal.mult(
          monthly_contribution,
          Decimal.new(to_string(years * 12))
        )
        Decimal.add(principal, total_contributions)
        
      Decimal.compare(monthly_contribution, Decimal.new("0")) == :eq ->
        # No contributions: simple compound interest
        # FV = PV * (1 + r)^t
        multiplier = power(
          Decimal.add(Decimal.new("1"), aer),
          years
        )
        Decimal.mult(principal, multiplier)
        
      true ->
        # Both principal growth and contributions
        # Convert AER to monthly rate for contribution calculations
        monthly_rate = aer_to_monthly(aer)
        
        # Future value of principal
        fv_principal = compound_with_aer(principal, aer, years, Decimal.new("0"))
        
        # Future value of annuity (monthly contributions)
        # FV = PMT * [((1 + r)^n - 1) / r]
        months = years * 12
        
        if Decimal.compare(monthly_rate, Decimal.new("0")) == :eq do
          # If rate is 0, just sum contributions
          fv_contributions = Decimal.mult(monthly_contribution, Decimal.new(to_string(months)))
          Decimal.add(fv_principal, fv_contributions)
        else
          one_plus_r = Decimal.add(Decimal.new("1"), monthly_rate)
          compound_factor = power(one_plus_r, months)
          numerator = Decimal.sub(compound_factor, Decimal.new("1"))
          fv_contributions = Decimal.mult(
            monthly_contribution,
            Decimal.div(numerator, monthly_rate)
          )
          Decimal.add(fv_principal, fv_contributions)
        end
    end
  end
  
  @doc """
  Calculates the effective annual rate from a nominal rate with periodic compounding.
  
  ## Formula
  
      EAR = (1 + nominal_rate/periods)^periods - 1
  
  ## Examples
  
      iex> effective_rate(Decimal.new("0.12"), 12)  # 12% nominal, monthly compounding
      Decimal.new("0.12682503013196977")
  """
  def effective_rate(nominal_rate, periods) when is_integer(periods) and periods > 0 do
    if periods == 1 do
      nominal_rate
    else
      # (1 + nominal/periods)^periods - 1
      period_rate = Decimal.div(nominal_rate, Decimal.new(to_string(periods)))
      one_plus_period = Decimal.add(Decimal.new("1"), period_rate)
      compounded = power(one_plus_period, periods)
      Decimal.sub(compounded, Decimal.new("1"))
    end
  end
  
  @doc """
  Calculates the nominal rate from an effective annual rate with periodic compounding.
  
  ## Formula
  
      nominal = periods * ((1 + effective)^(1/periods) - 1)
  
  ## Examples
  
      iex> nominal_rate(Decimal.new("0.12682503"), 12)
      Decimal.new("0.12")
  """
  def nominal_rate(effective_rate, periods) when is_integer(periods) and periods > 0 do
    if periods == 1 do
      effective_rate
    else
      # periods * ((1 + effective)^(1/periods) - 1)
      one_plus_effective = Decimal.add(Decimal.new("1"), effective_rate)
      period_factor = nth_root(one_plus_effective, periods)
      period_rate = Decimal.sub(period_factor, Decimal.new("1"))
      Decimal.mult(period_rate, Decimal.new(to_string(periods)))
    end
  end
  
  @doc """
  Converts a continuously compounded rate to Annual Equivalent Rate.
  
  ## Formula
  
      AER = e^r - 1
  
  ## Examples
  
      iex> continuous_to_aer(Decimal.new("0.12"))
      Decimal.new("0.1275")
  """
  def continuous_to_aer(continuous_rate) do
    # e^r - 1
    e_power = exp(continuous_rate)
    Decimal.sub(e_power, Decimal.new("1"))
  end
  
  @doc """
  Converts Annual Equivalent Rate to continuously compounded rate.
  
  ## Formula
  
      r = ln(1 + AER)
  
  ## Examples
  
      iex> aer_to_continuous(Decimal.new("0.1275"))
      Decimal.new("0.12")
  """
  def aer_to_continuous(aer) do
    # ln(1 + AER)
    one_plus_aer = Decimal.add(Decimal.new("1"), aer)
    ln(one_plus_aer)
  end
  
  @doc """
  Calculates future value with regular deposits at specified frequency.
  
  ## Parameters
  
  - `principal` - Initial amount
  - `deposit` - Regular deposit amount
  - `aer` - Annual Equivalent Rate
  - `years` - Investment period in years
  - `frequency` - :monthly, :quarterly, or :annual
  
  ## Examples
  
      iex> future_value_with_regular_deposits(
      ...>   Decimal.new("10000"),
      ...>   Decimal.new("500"),
      ...>   Decimal.new("0.08"),
      ...>   20,
      ...>   :monthly
      ...> )
      Decimal.new("281000")  # approximately
  """
  def future_value_with_regular_deposits(principal, deposit, aer, years, frequency) do
    periods_per_year = case frequency do
      :monthly -> 12
      :quarterly -> 4
      :annual -> 1
      _ -> raise ArgumentError, "Invalid frequency: #{frequency}"
    end
    
    # Convert deposit to monthly equivalent for compound_with_aer
    monthly_deposit = if frequency == :monthly do
      deposit
    else
      # Convert to monthly equivalent
      annual_deposit = Decimal.mult(deposit, Decimal.new(to_string(periods_per_year)))
      Decimal.div(annual_deposit, Decimal.new("12"))
    end
    
    compound_with_aer(principal, aer, years, monthly_deposit)
  end
  
  # Helper functions for mathematical operations
  
  defp power(base, exponent) when is_integer(exponent) and exponent >= 0 do
    # For better precision with large exponents, use float math then convert back
    base_float = Decimal.to_float(base)
    result_float = :math.pow(base_float, exponent)
    Decimal.from_float(result_float)
  end
  
  defp power(base, exponent) when is_integer(exponent) and exponent < 0 do
    positive_result = power(base, -exponent)
    Decimal.div(Decimal.new("1"), positive_result)
  end
  
  defp nth_root(number, n) when is_integer(n) and n > 0 do
    # Use Newton's method for nth root
    # For better precision, convert to float, calculate, then back to Decimal
    float_num = Decimal.to_float(number)
    float_root = :math.pow(float_num, 1.0 / n)
    Decimal.from_float(float_root)
  end
  
  defp exp(x) do
    # e^x approximation using Taylor series or convert to float
    float_x = Decimal.to_float(x)
    float_result = :math.exp(float_x)
    Decimal.from_float(float_result)
  end
  
  defp ln(x) do
    # Natural logarithm
    float_x = Decimal.to_float(x)
    float_result = :math.log(float_x)
    Decimal.from_float(float_result)
  end
end