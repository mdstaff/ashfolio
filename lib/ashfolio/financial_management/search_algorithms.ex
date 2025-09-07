defmodule Ashfolio.FinancialManagement.SearchAlgorithms do
  @moduledoc """
  Binary search algorithms for financial optimization problems.

  Provides efficient algorithms for finding optimal contributions,
  timelines, and other financial parameters using binary search techniques.
  """

  alias Ashfolio.FinancialManagement.ForecastCalculator

  # Context structs to reduce parameter counts
  defmodule SearchContext do
    @moduledoc "Search context for contribution optimization"
    defstruct [
      :target_amount,
      :current_value,
      :years,
      :growth_rate,
      :min_contribution,
      :mid_contribution,
      :max_contribution,
      :max_iterations
    ]
  end

  defmodule YearsSearchContext do
    @moduledoc "Search context for years optimization"
    defstruct [
      :target_amount,
      :current_value,
      :monthly_contribution,
      :growth_rate,
      :min_years,
      :mid_years,
      :max_years,
      :max_iterations
    ]
  end

  @doc """
  Finds the required monthly contribution to reach a target amount.

  Uses binary search to efficiently find the contribution amount needed
  to achieve the specified target within the given timeframe.
  """
  def find_required_contribution(current_value, target_amount, years, growth_rate) do
    min_contribution = Decimal.new("0")

    # Calculate maximum reasonable contribution (target / years / 12)
    max_contribution =
      target_amount
      |> Decimal.sub(current_value)
      |> Decimal.div(Decimal.new(years))
      |> Decimal.div(Decimal.new("12"))
      # Add buffer
      |> Decimal.mult(Decimal.new("2"))

    binary_search_contribution(
      current_value,
      target_amount,
      years,
      growth_rate,
      min_contribution,
      max_contribution,
      # max iterations
      50
    )
  end

  @doc """
  Finds the required number of years to reach a target with given contribution.
  """
  def find_years_for_contribution(current_value, monthly_contribution, target_amount, growth_rate) do
    min_years = 1
    max_years = 100

    find_required_years(
      current_value,
      monthly_contribution,
      target_amount,
      growth_rate,
      min_years,
      max_years
    )
  end

  # Binary search implementation for contribution optimization

  defp binary_search_contribution(
         current_value,
         target_amount,
         years,
         growth_rate,
         min_contribution,
         max_contribution,
         max_iterations
       ) do
    difference = Decimal.sub(max_contribution, min_contribution)
    tolerance = Decimal.new("0.50")

    if max_iterations <= 0 or Decimal.compare(difference, tolerance) in [:lt, :eq] do
      mid_contribution = min_contribution |> Decimal.add(max_contribution) |> Decimal.div(Decimal.new("2"))
      {:ok, mid_contribution}
    else
      mid_contribution = min_contribution |> Decimal.add(max_contribution) |> Decimal.div(Decimal.new("2"))

      case project_with_contribution(current_value, mid_contribution, years, growth_rate) do
        {:ok, final_value} ->
          context = %SearchContext{
            target_amount: target_amount,
            current_value: current_value,
            years: years,
            growth_rate: growth_rate,
            min_contribution: min_contribution,
            mid_contribution: mid_contribution,
            max_contribution: max_contribution,
            max_iterations: max_iterations
          }

          handle_search_result(final_value, context)

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  # Binary search implementation for timeline optimization

  defp find_required_years(current_value, monthly_contribution, target_amount, growth_rate, min_years, max_years) do
    search_required_years(
      current_value,
      monthly_contribution,
      target_amount,
      growth_rate,
      min_years,
      max_years,
      # max iterations
      50
    )
  end

  defp search_required_years(
         current_value,
         monthly_contribution,
         target_amount,
         growth_rate,
         min_years,
         max_years,
         max_iterations
       ) do
    if max_iterations <= 0 or max_years - min_years <= 1 do
      {:ok, max_years}
    else
      mid_years = div(min_years + max_years, 2)

      case project_with_contribution(current_value, monthly_contribution, mid_years, growth_rate) do
        {:ok, final_value} ->
          context = %YearsSearchContext{
            target_amount: target_amount,
            current_value: current_value,
            monthly_contribution: monthly_contribution,
            growth_rate: growth_rate,
            min_years: min_years,
            mid_years: mid_years,
            max_years: max_years,
            max_iterations: max_iterations
          }

          handle_years_search_result(final_value, context)

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  # Helper functions

  defp project_with_contribution(current_value, monthly_contribution, years, growth_rate) do
    case ForecastCalculator.project_portfolio_growth(current_value, monthly_contribution, years, growth_rate) do
      {:ok, final_value} ->
        {:ok, final_value}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp handle_projection_result(final_value, target_amount) do
    # 0.5% tolerance - reasonable for financial planning purposes
    tolerance = Decimal.mult(target_amount, Decimal.new("0.005"))
    difference = final_value |> Decimal.sub(target_amount) |> Decimal.abs()

    cond do
      Decimal.compare(difference, tolerance) in [:lt, :eq] ->
        :target_reached

      Decimal.compare(final_value, target_amount) == :lt ->
        :under_target

      true ->
        :over_target
    end
  end

  # Helper functions to reduce nesting depth

  defp handle_search_result(final_value, context) do
    case handle_projection_result(final_value, context.target_amount) do
      :target_reached ->
        {:ok, context.mid_contribution}

      :under_target ->
        binary_search_contribution(
          context.current_value,
          context.target_amount,
          context.years,
          context.growth_rate,
          context.mid_contribution,
          context.max_contribution,
          context.max_iterations - 1
        )

      :over_target ->
        binary_search_contribution(
          context.current_value,
          context.target_amount,
          context.years,
          context.growth_rate,
          context.min_contribution,
          context.mid_contribution,
          context.max_iterations - 1
        )
    end
  end

  defp handle_years_search_result(final_value, context) do
    if Decimal.compare(final_value, context.target_amount) in [:gt, :eq] do
      # Target reached, try fewer years
      search_required_years(
        context.current_value,
        context.monthly_contribution,
        context.target_amount,
        context.growth_rate,
        context.min_years,
        context.mid_years,
        context.max_iterations - 1
      )
    else
      # Target not reached, need more years
      search_required_years(
        context.current_value,
        context.monthly_contribution,
        context.target_amount,
        context.growth_rate,
        context.mid_years,
        context.max_years,
        context.max_iterations - 1
      )
    end
  end
end
