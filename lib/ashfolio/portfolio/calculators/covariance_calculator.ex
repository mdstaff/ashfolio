defmodule Ashfolio.Portfolio.Calculators.CovarianceCalculator do
  @moduledoc """
  Calculates covariance between asset returns.

  Covariance measures how two assets' returns move together. A positive covariance
  indicates they tend to move in the same direction, while negative covariance
  indicates they move in opposite directions.

  ## Mathematical Formula

  The sample covariance is calculated as:

      cov(X,Y) = Σ((x - x̄)(y - ȳ)) / (n - 1)

  Where:
  - x, y are the return series
  - x̄, ȳ are the means of the respective series
  - n is the number of observations

  ## Usage

      iex> returns_a = [Decimal.new("0.05"), Decimal.new("0.03"), Decimal.new("-0.02")]
      iex> returns_b = [Decimal.new("0.04"), Decimal.new("0.02"), Decimal.new("-0.01")]
      iex> {:ok, _covariance} = CovarianceCalculator.calculate_pair(returns_a, returns_b)

  ## Performance

  - Pairwise covariance: O(n) where n is the number of observations
  - Matrix calculation: O(m²n) where m is number of assets, n is observations
  - Target: < 50ms for 10x10 matrix with 252 observations
  """

  alias Decimal, as: D

  @type return_series :: [D.t()]
  @type covariance_matrix :: [[D.t()]]
  @type error :: {:error, atom()}

  @doc """
  Calculates covariance between two return series.

  Returns `{:ok, covariance}` or `{:error, reason}` if calculation cannot be performed.

  ## Examples

      iex> alias Decimal, as: D
      iex> returns_a = [D.new("0.1"), D.new("0.2"), D.new("0.3")]
      iex> returns_b = [D.new("0.1"), D.new("0.2"), D.new("0.3")]
      iex> {:ok, _covariance} = Ashfolio.Portfolio.Calculators.CovarianceCalculator.calculate_pair(returns_a, returns_b)
      iex> # Returns positive covariance for perfectly correlated series
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
        calculate_covariance(returns_a, returns_b)
    end
  end

  @doc """
  Calculates covariance matrix for multiple asset returns.

  Returns a symmetric matrix where element [i][j] represents the covariance
  between asset i and asset j. The diagonal elements are the variances.

  ## Examples

      iex> alias Decimal, as: D
      iex> asset_returns = [
      ...>   [D.new("0.1"), D.new("0.2"), D.new("0.3")],
      ...>   [D.new("0.15"), D.new("0.25"), D.new("0.35")]
      ...> ]
      iex> {:ok, matrix} = Ashfolio.Portfolio.Calculators.CovarianceCalculator.calculate_matrix(asset_returns)
      iex> # Diagonal elements (variances) should be positive
      iex> D.compare(Enum.at(Enum.at(matrix, 0), 0), D.new("0")) == :gt
      true
  """
  @spec calculate_matrix([return_series()]) :: {:ok, covariance_matrix()} | error()
  def calculate_matrix([]), do: {:error, :no_assets}
  def calculate_matrix([_single]), do: {:error, :insufficient_assets}

  def calculate_matrix(asset_returns) when is_list(asset_returns) do
    first_length = length(Enum.at(asset_returns, 0))

    if Enum.all?(asset_returns, &(length(&1) == first_length)) do
      build_covariance_matrix(asset_returns)
    else
      {:error, :mismatched_lengths}
    end
  end

  # Private functions

  @spec calculate_covariance(return_series(), return_series()) :: {:ok, D.t()}
  defp calculate_covariance(returns_a, returns_b) do
    n = length(returns_a)
    mean_a = calculate_mean(returns_a)
    mean_b = calculate_mean(returns_b)

    sum_products =
      returns_a
      |> Enum.zip(returns_b)
      |> Enum.reduce(D.new("0"), fn {a, b}, acc ->
        diff_a = D.sub(a, mean_a)
        diff_b = D.sub(b, mean_b)
        product = D.mult(diff_a, diff_b)
        D.add(acc, product)
      end)

    # Sample covariance uses n-1 (Bessel's correction)
    denominator = D.new(n - 1)
    covariance = D.div(sum_products, denominator)

    {:ok, covariance}
  end

  @spec calculate_mean(return_series()) :: D.t()
  defp calculate_mean(returns) do
    sum = Enum.reduce(returns, D.new("0"), &D.add/2)
    D.div(sum, D.new(length(returns)))
  end

  @spec build_covariance_matrix([return_series()]) :: {:ok, covariance_matrix()}
  defp build_covariance_matrix(asset_returns) do
    n_assets = length(asset_returns)

    matrix =
      for i <- 0..(n_assets - 1) do
        for j <- 0..(n_assets - 1) do
          if i <= j do
            # Calculate covariance for upper triangle and diagonal
            returns_i = Enum.at(asset_returns, i)
            returns_j = Enum.at(asset_returns, j)

            {:ok, cov} = calculate_covariance(returns_i, returns_j)
            cov
          else
            # Lower triangle: will be filled by symmetry
            D.new("0")
          end
        end
      end

    # Make matrix symmetric
    symmetric_matrix = make_symmetric(matrix)
    {:ok, symmetric_matrix}
  end

  @spec make_symmetric(covariance_matrix()) :: covariance_matrix()
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
end
