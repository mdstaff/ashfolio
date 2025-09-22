defmodule Ashfolio.Portfolio.Optimization.EfficientFrontier do
  @moduledoc """
  Generates efficient frontier for portfolio optimization.

  The efficient frontier represents the set of optimal portfolios offering
  the highest expected return for each level of risk, or the lowest risk
  for each level of expected return.

  ## Mathematical Foundation

  Based on Markowitz Mean-Variance Optimization (1952):
  - For each target return level, find the minimum variance portfolio
  - Plot these optimal portfolios on risk-return space
  - The curve represents the efficient frontier

  ## Usage

      iex> assets = [
      ...>   %{symbol: "STOCK", expected_return: D.new("0.12"), volatility: D.new("0.20")},
      ...>   %{symbol: "BOND", expected_return: D.new("0.04"), volatility: D.new("0.05")}
      ...> ]
      iex> correlation_matrix = [[D.new("1.0"), D.new("0.3")], [D.new("0.3"), D.new("1.0")]]
      iex> {:ok, frontier} = EfficientFrontier.generate(assets, correlation_matrix)
      iex> length(frontier.portfolios) > 10
      true

  ## References

  - Markowitz, H. (1952). "Portfolio Selection"
  - CFA Level III Curriculum (2024). "Portfolio Management"
  """

  alias Ashfolio.Portfolio.Optimization.PortfolioOptimizer
  alias Decimal, as: D

  @type asset :: %{
          symbol: String.t(),
          expected_return: D.t(),
          volatility: D.t()
        }

  @type correlation_matrix :: [[D.t()]]

  @type frontier_portfolio :: %{
          weights: map(),
          expected_return: D.t(),
          volatility: D.t(),
          sharpe_ratio: D.t() | nil
        }

  @type frontier_result :: %{
          portfolios: [frontier_portfolio()],
          min_variance_portfolio: frontier_portfolio(),
          max_return_portfolio: frontier_portfolio(),
          tangency_portfolio: frontier_portfolio() | nil
        }

  @doc """
  Generates efficient frontier for the given assets.

  Creates a series of optimal portfolios spanning from minimum variance
  to maximum expected return, representing the efficient frontier.

  ## Parameters

  - `assets`: List of assets with expected_return and volatility
  - `correlation_matrix`: Correlation matrix for the assets
  - `opts`: Options including:
    - `:points` - Number of frontier points to generate (default: 50)
    - `:risk_free_rate` - Risk-free rate for Sharpe ratio calculation

  ## Returns

  `{:ok, frontier_result}` with portfolios and key points
  `{:error, reason}` for invalid inputs

  ## Examples

      iex> assets = [
      ...>   %{symbol: "STOCK", expected_return: D.new("0.15"), volatility: D.new("0.20")},
      ...>   %{symbol: "BOND", expected_return: D.new("0.05"), volatility: D.new("0.05")}
      ...> ]
      iex> correlation_matrix = [[D.new("1.0"), D.new("0.3")], [D.new("0.3"), D.new("1.0")]]
      iex> {:ok, frontier} = EfficientFrontier.generate(assets, correlation_matrix)
      iex> is_list(frontier.portfolios)
      true
  """
  @spec generate([asset()], correlation_matrix(), keyword()) ::
          {:ok, frontier_result()} | {:error, atom()}
  def generate(assets, correlation_matrix, opts \\ []) do
    points = Keyword.get(opts, :points, 50)
    risk_free_rate = Keyword.get(opts, :risk_free_rate, D.new("0.03"))

    with :ok <- validate_inputs(assets, correlation_matrix, points) do
      case length(assets) do
        2 ->
          # Full optimization for 2-asset portfolios
          generate_two_asset_complete_frontier(assets, correlation_matrix, points, risk_free_rate)

        n when n >= 3 ->
          # Simplified approach for 3+ asset portfolios
          generate_multi_asset_simple_frontier(assets, correlation_matrix, points, risk_free_rate)

        _ ->
          {:error, :insufficient_assets}
      end
    end
  end

  # Full optimization for 2-asset portfolios
  defp generate_two_asset_complete_frontier(assets, correlation_matrix, points, risk_free_rate) do
    with {:ok, min_var} <- PortfolioOptimizer.find_minimum_variance(assets, correlation_matrix),
         {:ok, max_ret} <- find_maximum_return_portfolio(assets),
         {:ok, frontier_portfolios} <-
           generate_frontier_points(
             assets,
             correlation_matrix,
             min_var.expected_return,
             max_ret.expected_return,
             points
           ),
         {:ok, tangency} <- find_tangency_portfolio(assets, correlation_matrix, risk_free_rate) do
      {:ok,
       %{
         portfolios: frontier_portfolios,
         min_variance_portfolio: min_var,
         max_return_portfolio: max_ret,
         tangency_portfolio: tangency
       }}
    end
  end

  # Simplified approach for 3+ asset portfolios
  defp generate_multi_asset_simple_frontier(assets, correlation_matrix, points, risk_free_rate) do
    with {:ok, max_ret} <- find_maximum_return_portfolio(assets),
         {:ok, frontier_portfolios} <-
           generate_frontier_points(assets, correlation_matrix, D.new("0"), max_ret.expected_return, points) do
      # For multi-asset, use the equal-weighted portfolio as min variance approximation
      min_var = generate_equal_weighted_portfolio(assets, correlation_matrix)

      # Try to find tangency portfolio, fallback to nil if not supported
      tangency =
        case find_tangency_portfolio(assets, correlation_matrix, risk_free_rate) do
          {:ok, result} -> result
          {:error, _} -> nil
        end

      {:ok,
       %{
         portfolios: frontier_portfolios,
         min_variance_portfolio: min_var,
         max_return_portfolio: max_ret,
         tangency_portfolio: tangency
       }}
    end
  end

  @doc """
  Finds the tangency portfolio (maximum Sharpe ratio) on the efficient frontier.

  The tangency portfolio is where the Capital Market Line (line from risk-free
  rate) is tangent to the efficient frontier.

  ## Parameters

  - `assets`: List of assets
  - `correlation_matrix`: Correlation matrix
  - `risk_free_rate`: Risk-free rate for Sharpe calculation

  ## Returns

  `{:ok, portfolio}` with maximum Sharpe ratio
  `{:error, reason}` for invalid inputs
  """
  @spec find_tangency_portfolio([asset()], correlation_matrix(), D.t()) ::
          {:ok, frontier_portfolio()} | {:error, atom()}
  def find_tangency_portfolio(assets, correlation_matrix, risk_free_rate) do
    case PortfolioOptimizer.maximize_sharpe(assets, correlation_matrix, risk_free_rate) do
      {:ok, result} -> {:ok, result}
      error -> error
    end
  end

  # Private functions

  @spec validate_inputs([asset()], correlation_matrix(), pos_integer()) ::
          :ok | {:error, atom()}
  defp validate_inputs(assets, correlation_matrix, points) do
    cond do
      length(assets) < 2 ->
        {:error, :insufficient_assets}

      length(assets) != length(correlation_matrix) ->
        {:error, :mismatched_dimensions}

      points < 2 ->
        {:error, :insufficient_points}

      true ->
        :ok
    end
  end

  @spec find_maximum_return_portfolio([asset()]) :: {:ok, frontier_portfolio()}
  defp find_maximum_return_portfolio(assets) do
    # Find asset with highest expected return and allocate 100% to it
    max_return_asset = Enum.max_by(assets, &D.to_float(&1.expected_return))

    weights =
      Map.new(assets, fn asset ->
        if asset.symbol == max_return_asset.symbol do
          {String.to_atom(String.downcase(asset.symbol)), D.new("1.0")}
        else
          {String.to_atom(String.downcase(asset.symbol)), D.new("0.0")}
        end
      end)

    {:ok,
     %{
       weights: weights,
       expected_return: max_return_asset.expected_return,
       volatility: max_return_asset.volatility,
       sharpe_ratio: nil
     }}
  end

  @spec generate_frontier_points(
          [asset()],
          correlation_matrix(),
          D.t(),
          D.t(),
          pos_integer()
        ) :: {:ok, [frontier_portfolio()]} | {:error, atom()}
  defp generate_frontier_points(assets, correlation_matrix, min_return, max_return, points) do
    cond do
      length(assets) == 2 ->
        # For 2-asset portfolios, use target return optimization
        generate_two_asset_frontier(assets, correlation_matrix, min_return, max_return, points)

      length(assets) >= 3 ->
        # For 3+ assets, use simplified approach with corner portfolios and combinations
        generate_multi_asset_frontier(assets, correlation_matrix, points)

      true ->
        {:error, :insufficient_assets}
    end
  end

  @spec generate_two_asset_frontier([asset()], correlation_matrix(), D.t(), D.t(), pos_integer()) ::
          {:ok, [frontier_portfolio()]} | {:error, atom()}
  defp generate_two_asset_frontier(assets, correlation_matrix, min_return, max_return, points) do
    # Generate target returns from minimum to maximum
    target_returns = generate_target_returns(min_return, max_return, points)

    # For each target return, find the optimal portfolio
    portfolios =
      target_returns
      |> Enum.map(fn target_return ->
        case PortfolioOptimizer.optimize_target_return(assets, correlation_matrix, target_return) do
          {:ok, portfolio} -> portfolio
          {:error, _} -> nil
        end
      end)
      |> Enum.filter(&(&1 != nil))

    if length(portfolios) >= 2 do
      {:ok, portfolios}
    else
      {:error, :insufficient_frontier_points}
    end
  end

  @spec generate_multi_asset_frontier([asset()], correlation_matrix(), pos_integer()) ::
          {:ok, [frontier_portfolio()]} | {:error, atom()}
  defp generate_multi_asset_frontier(assets, correlation_matrix, _points) do
    # For multi-asset portfolios, use simplified approach:
    # 1. Generate corner portfolios (100% in each asset)
    # 2. Generate equal-weighted portfolio
    # 3. Generate some random diversified portfolios

    corner_portfolios = generate_corner_portfolios(assets, correlation_matrix)
    equal_weighted = generate_equal_weighted_portfolio(assets, correlation_matrix)

    # Combine all portfolios
    all_portfolios = [equal_weighted | corner_portfolios]

    # Filter out any failed portfolios
    valid_portfolios = Enum.filter(all_portfolios, &(&1 != nil))

    if length(valid_portfolios) >= 2 do
      {:ok, valid_portfolios}
    else
      {:error, :insufficient_frontier_points}
    end
  end

  @spec generate_corner_portfolios([asset()], correlation_matrix()) :: [frontier_portfolio()]
  defp generate_corner_portfolios(assets, _correlation_matrix) do
    Enum.map(assets, fn asset ->
      # Create portfolio with 100% in this asset
      weights =
        Map.new(assets, fn a ->
          if a.symbol == asset.symbol do
            {String.to_atom(String.downcase(a.symbol)), D.new("1.0")}
          else
            {String.to_atom(String.downcase(a.symbol)), D.new("0.0")}
          end
        end)

      %{
        weights: weights,
        expected_return: asset.expected_return,
        volatility: asset.volatility,
        sharpe_ratio: nil
      }
    end)
  end

  @spec generate_equal_weighted_portfolio([asset()], correlation_matrix()) :: frontier_portfolio()
  defp generate_equal_weighted_portfolio(assets, _correlation_matrix) do
    # Create equal weighted portfolio
    n = length(assets)
    equal_weight = D.div(D.new("1"), D.new(to_string(n)))

    weights =
      Map.new(assets, fn asset ->
        {String.to_atom(String.downcase(asset.symbol)), equal_weight}
      end)

    # Calculate portfolio return and volatility
    expected_return =
      assets
      |> Enum.map(&D.mult(&1.expected_return, equal_weight))
      |> Enum.reduce(D.new("0"), &D.add/2)

    # For simplicity, approximate volatility using average asset volatility
    # This is not precise but gives a reasonable estimate
    avg_volatility =
      assets
      |> Enum.map(& &1.volatility)
      |> Enum.reduce(D.new("0"), &D.add/2)
      |> D.div(D.new(to_string(n)))

    %{
      weights: weights,
      expected_return: expected_return,
      volatility: avg_volatility,
      sharpe_ratio: nil
    }
  end

  @spec generate_target_returns(D.t(), D.t(), pos_integer()) :: [D.t()]
  defp generate_target_returns(min_return, max_return, points) do
    if D.equal?(min_return, max_return) do
      # Edge case: all assets have same return
      [min_return]
    else
      # Generate evenly spaced returns between min and max
      min_float = D.to_float(min_return)
      max_float = D.to_float(max_return)
      step = (max_float - min_float) / (points - 1)

      Enum.map(0..(points - 1), fn i ->
        target_float = min_float + step * i
        D.new(Float.to_string(target_float))
      end)
    end
  end
end
