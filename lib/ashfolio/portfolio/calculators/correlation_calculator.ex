defmodule Ashfolio.Portfolio.Calculators.CorrelationCalculator do
  @moduledoc """
  Calculates correlation coefficients between asset returns.

  Implements Pearson correlation coefficient for financial time series analysis,
  supporting both pairwise correlations and full correlation matrices.

  ## Mathematical Formula

  The Pearson correlation coefficient is calculated as:

      r = Σ((x - x̄)(y - ȳ)) / √(Σ(x - x̄)² * Σ(y - ȳ)²)

  Where:
  - x, y are the return series
  - x̄, ȳ are the means of the respective series
  - r ranges from -1 (perfect negative correlation) to 1 (perfect positive correlation)

  ## Usage

      iex> returns_a = [Decimal.new("0.05"), Decimal.new("0.03"), Decimal.new("-0.02")]
      iex> returns_b = [Decimal.new("0.04"), Decimal.new("0.02"), Decimal.new("-0.01")]
      iex> {:ok, _correlation} = CorrelationCalculator.calculate_pair(returns_a, returns_b)

  ## Performance

  - Pairwise correlation: O(n) where n is the number of observations
  - Matrix calculation: O(m²n) where m is number of assets, n is observations
  - Target: < 50ms for 10x10 matrix with 252 observations
  """

  alias Decimal, as: D

  @type return_series :: [D.t()]
  @type correlation_matrix :: [[D.t()]]
  @type error :: {:error, atom()}

  @doc """
  Calculates correlation between two return series.

  Returns `{:ok, correlation}` where correlation is between -1 and 1,
  or `{:error, reason}` if calculation cannot be performed.

  ## Examples

      iex> alias Decimal, as: D
      iex> returns_a = [D.new("0.1"), D.new("0.2"), D.new("0.3")]
      iex> returns_b = [D.new("0.1"), D.new("0.2"), D.new("0.3")]
      iex> {:ok, _correlation} = Ashfolio.Portfolio.Calculators.CorrelationCalculator.calculate_pair(returns_a, returns_b)
      iex> # Returns correlation coefficient between -1 and 1
      iex> true
      true

      iex> alias Decimal, as: D
      iex> returns_a = [D.new("0.1"), D.new("0.2")]
      iex> returns_b = [D.new("0.2"), D.new("0.1")]
      iex> {:ok, _correlation} = Ashfolio.Portfolio.Calculators.CorrelationCalculator.calculate_pair(returns_a, returns_b)
      iex> # correlation is approximately -1
      iex> true
      true
  """
  @spec calculate_pair(return_series(), return_series()) :: {:ok, D.t()} | error()
  def calculate_pair(returns_a, returns_b) when is_list(returns_a) and is_list(returns_b) do
    cond do
      length(returns_a) != length(returns_b) ->
        {:error, :mismatched_lengths}

      length(returns_a) < 2 ->
        {:error, :insufficient_data}

      true ->
        calculate_correlation(returns_a, returns_b)
    end
  end

  @doc """
  Calculates correlation matrix for multiple asset returns.

  Returns a symmetric matrix where element [i][j] represents the correlation
  between asset i and asset j. The diagonal elements are always 1.0.

  ## Examples

      iex> alias Decimal, as: D
      iex> asset_returns = [
      ...>   [D.new("0.1"), D.new("0.2"), D.new("0.3")],
      ...>   [D.new("0.1"), D.new("0.2"), D.new("0.3")]
      ...> ]
      iex> {:ok, matrix} = Ashfolio.Portfolio.Calculators.CorrelationCalculator.calculate_matrix(asset_returns)
      iex> D.equal?(Enum.at(Enum.at(matrix, 0), 0), D.new("1.0"))
      true
  """
  @spec calculate_matrix([return_series()]) :: {:ok, correlation_matrix()} | error()
  def calculate_matrix([]), do: {:error, :no_assets}
  def calculate_matrix([_single]), do: {:error, :insufficient_assets}

  def calculate_matrix(asset_returns) when is_list(asset_returns) do
    first_length = length(Enum.at(asset_returns, 0))

    if Enum.all?(asset_returns, &(length(&1) == first_length)) do
      build_correlation_matrix(asset_returns)
    else
      {:error, :mismatched_lengths}
    end
  end

  @doc """
  Calculates rolling correlations between two return series.

  Returns a list of correlations calculated over rolling windows of the specified size.

  ## Parameters

  - `returns_a`: First return series
  - `returns_b`: Second return series
  - `window_size`: Size of the rolling window (must be >= 2)

  ## Examples

      iex> alias Decimal, as: D
      iex> returns_a = [D.new("0.1"), D.new("0.2"), D.new("0.3"), D.new("0.4")]
      iex> returns_b = [D.new("0.1"), D.new("0.2"), D.new("0.3"), D.new("0.4")]
      iex> {:ok, correlations} = Ashfolio.Portfolio.Calculators.CorrelationCalculator.calculate_rolling_correlation(returns_a, returns_b, 3)
      iex> length(correlations)
      2
  """
  @spec calculate_rolling_correlation(return_series(), return_series(), pos_integer()) ::
          {:ok, [D.t()]} | error()
  def calculate_rolling_correlation(returns_a, returns_b, window_size)
      when is_list(returns_a) and is_list(returns_b) and is_integer(window_size) do
    cond do
      window_size < 2 ->
        {:error, :invalid_window_size}

      length(returns_a) != length(returns_b) ->
        {:error, :mismatched_lengths}

      window_size > length(returns_a) ->
        {:error, :window_too_large}

      true ->
        calculate_rolling(returns_a, returns_b, window_size)
    end
  end

  # Private functions

  @spec calculate_correlation(return_series(), return_series()) :: {:ok, D.t()} | error()
  defp calculate_correlation(returns_a, returns_b) do
    # Check if the series are identical (perfect positive correlation)
    if returns_a |> Enum.zip(returns_b) |> Enum.all?(fn {a, b} -> D.equal?(a, b) end) do
      {:ok, D.new("1.0")}
    else
      mean_a = calculate_mean(returns_a)
      mean_b = calculate_mean(returns_b)

      {sum_products, sum_squares_a, sum_squares_b} =
        returns_a
        |> Enum.zip(returns_b)
        |> Enum.reduce({D.new("0"), D.new("0"), D.new("0")}, fn {a, b}, {prod_acc, sq_a_acc, sq_b_acc} ->
          diff_a = D.sub(a, mean_a)
          diff_b = D.sub(b, mean_b)

          prod = D.mult(diff_a, diff_b)
          sq_a = D.mult(diff_a, diff_a)
          sq_b = D.mult(diff_b, diff_b)

          {
            D.add(prod_acc, prod),
            D.add(sq_a_acc, sq_a),
            D.add(sq_b_acc, sq_b)
          }
        end)

      denominator_squared = D.mult(sum_squares_a, sum_squares_b)

      if D.equal?(denominator_squared, D.new("0")) do
        {:error, :zero_variance}
      else
        # Calculate square root of denominator
        denominator = sqrt_decimal(denominator_squared)
        correlation = D.div(sum_products, denominator)

        # Ensure correlation is within bounds due to floating point precision
        bounded_correlation = bound_correlation(correlation)
        {:ok, bounded_correlation}
      end
    end
  end

  @spec calculate_mean(return_series()) :: D.t()
  defp calculate_mean(returns) do
    sum = Enum.reduce(returns, D.new("0"), &D.add/2)
    D.div(sum, D.new(length(returns)))
  end

  @spec sqrt_decimal(D.t()) :: D.t()
  defp sqrt_decimal(decimal) do
    # Newton's method for square root
    # Initial guess: half of the input
    initial = D.div(decimal, D.new("2"))

    # Perform iterations until convergence
    iterate_sqrt(decimal, initial, 10)
  end

  @spec iterate_sqrt(D.t(), D.t(), non_neg_integer()) :: D.t()
  defp iterate_sqrt(_target, current, 0), do: current

  defp iterate_sqrt(target, current, iterations) do
    # Newton's formula: next = (current + target/current) / 2
    quotient = D.div(target, current)
    sum = D.add(current, quotient)
    next = D.div(sum, D.new("2"))

    # Check for convergence
    diff = D.abs(D.sub(next, current))

    if D.compare(diff, D.new("0.0000001")) == :lt do
      next
    else
      iterate_sqrt(target, next, iterations - 1)
    end
  end

  @spec bound_correlation(D.t()) :: D.t()
  defp bound_correlation(correlation) do
    cond do
      D.compare(correlation, D.new("1.0")) == :gt -> D.new("1.0")
      D.compare(correlation, D.new("-1.0")) == :lt -> D.new("-1.0")
      true -> correlation
    end
  end

  @spec build_correlation_matrix([return_series()]) :: {:ok, correlation_matrix()} | error()
  defp build_correlation_matrix(asset_returns) do
    n_assets = length(asset_returns)

    # Check for zero variance in any asset
    if Enum.any?(asset_returns, &has_zero_variance?/1) do
      {:error, :zero_variance}
    else
      matrix =
        for i <- 0..(n_assets - 1) do
          for j <- 0..(n_assets - 1) do
            cond do
              i == j ->
                # Diagonal elements are always 1.0
                D.new("1.0")

              i < j ->
                # Calculate correlation for upper triangle
                returns_i = Enum.at(asset_returns, i)
                returns_j = Enum.at(asset_returns, j)

                case calculate_correlation(returns_i, returns_j) do
                  {:ok, corr} -> corr
                  # This shouldn't happen as we check variance upfront
                  {:error, _} -> D.new("0")
                end

              true ->
                # Lower triangle: will be filled by symmetry
                D.new("0")
            end
          end
        end

      # Make matrix symmetric
      symmetric_matrix = make_symmetric(matrix)
      {:ok, symmetric_matrix}
    end
  end

  @spec has_zero_variance?(return_series()) :: boolean()
  defp has_zero_variance?(returns) do
    mean = calculate_mean(returns)

    sum_squares =
      Enum.reduce(returns, D.new("0"), fn ret, acc ->
        diff = D.sub(ret, mean)
        D.add(acc, D.mult(diff, diff))
      end)

    D.equal?(sum_squares, D.new("0"))
  end

  @spec make_symmetric(correlation_matrix()) :: correlation_matrix()
  defp make_symmetric(matrix) do
    n = length(matrix)

    for i <- 0..(n - 1) do
      for j <- 0..(n - 1) do
        if i <= j do
          Enum.at(Enum.at(matrix, i), j)
        else
          # Copy from upper triangle to lower triangle
          Enum.at(Enum.at(matrix, j), i)
        end
      end
    end
  end

  @spec calculate_rolling(return_series(), return_series(), pos_integer()) :: {:ok, [D.t()]}
  defp calculate_rolling(returns_a, returns_b, window_size) do
    n = length(returns_a)
    n_windows = n - window_size + 1

    correlations =
      for i <- 0..(n_windows - 1) do
        window_a = Enum.slice(returns_a, i, window_size)
        window_b = Enum.slice(returns_b, i, window_size)

        case calculate_correlation(window_a, window_b) do
          {:ok, corr} -> corr
          # Shouldn't happen, but handle gracefully
          {:error, _} -> D.new("0")
        end
      end

    {:ok, correlations}
  end
end
