defmodule Ashfolio.FinancialManagement.ValidationHelpers do
  @moduledoc """
  Common validation functions for financial parameters.

  Provides consistent validation logic used across financial calculators
  for contributions, growth rates, timeframes, and target amounts.
  """

  alias Ashfolio.Financial.DecimalHelpers

  @doc """
  Validates that current value is a positive number.
  """
  def validate_current_value(value) when is_struct(value, Decimal) do
    if DecimalHelpers.positive?(value) do
      :ok
    else
      {:error, "Current value must be positive"}
    end
  end

  def validate_current_value(_), do: {:error, "Current value must be a valid decimal"}

  @doc """
  Validates that monthly contribution is non-negative.
  """
  def validate_monthly_contribution(value) when is_struct(value, Decimal) do
    if Decimal.compare(value, Decimal.new("0")) in [:gt, :eq] do
      :ok
    else
      {:error, "Monthly contribution must be non-negative"}
    end
  end

  def validate_monthly_contribution(_), do: {:error, "Monthly contribution must be a valid decimal"}

  @doc """
  Validates that years is a positive integer within reasonable bounds.
  """
  def validate_years(years) when is_integer(years) do
    cond do
      years <= 0 -> {:error, "Years must be positive"}
      years > 100 -> {:error, "Years must be 100 or less"}
      true -> :ok
    end
  end

  def validate_years(_), do: {:error, "Years must be a positive integer"}

  @doc """
  Validates that growth rate is within reasonable bounds.
  """
  def validate_growth_rate(rate) when is_struct(rate, Decimal) do
    # -50%
    min_rate = Decimal.new("-0.5")
    # 100%
    max_rate = Decimal.new("1.0")

    cond do
      Decimal.compare(rate, min_rate) == :lt ->
        {:error, "Growth rate cannot be less than -50%"}

      Decimal.compare(rate, max_rate) == :gt ->
        {:error, "Growth rate cannot exceed 100%"}

      true ->
        :ok
    end
  end

  def validate_growth_rate(_), do: {:error, "Growth rate must be a valid decimal"}

  @doc """
  Validates that target amount is positive and greater than current value.
  """
  def validate_target_amount(target_amount, current_value)
      when is_struct(target_amount, Decimal) and is_struct(current_value, Decimal) do
    cond do
      not DecimalHelpers.positive?(target_amount) ->
        {:error, "Target amount must be positive"}

      Decimal.compare(target_amount, current_value) != :gt ->
        {:error, "Target amount must be greater than current value"}

      true ->
        :ok
    end
  end

  def validate_target_amount(_, _), do: {:error, "Target amount and current value must be valid decimals"}

  @doc """
  Validates all common financial parameters in one call.
  """
  def validate_financial_params(params) do
    with :ok <- validate_current_value(params.current_value),
         :ok <- validate_monthly_contribution(params.monthly_contribution),
         :ok <- validate_years(params.years) do
      validate_growth_rate(params.growth_rate)
    end
  end

  @doc """
  Validates parameters for goal optimization calculations.
  """
  def validate_goal_params(params) do
    with :ok <- validate_current_value(params.current_value),
         :ok <- validate_target_amount(params.target_amount, params.current_value),
         :ok <- validate_years(params.years) do
      validate_growth_rate(params.growth_rate)
    end
  end
end
