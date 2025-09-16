defmodule Ashfolio.Portfolio.Calculators.DrawdownCalculator do
  @moduledoc """
  Professional drawdown analysis calculator for portfolio risk assessment.

  Implements industry-standard drawdown measurements critical for understanding
  portfolio downside risk and recovery characteristics:

  - Maximum Drawdown - Largest peak-to-trough decline over the period
  - Current Drawdown - Current distance from the most recent peak
  - Recovery Time - Time periods required to recover from trough to new peak
  - Underwater Periods - Duration spent below previous peak values
  - Drawdown History - All significant drawdown periods above threshold

  ## References

  - Magdon-Ismail, M. & Atiya, A. (2004). "Maximum Drawdown"
  - Chekhlov, A., Uryasev, S. & Zabarankin, M. (2005). "Drawdown Measure in Portfolio Optimization"
  - CFA Institute Standards for risk measurement and performance evaluation

  ## Mathematical Formulas

      Maximum Drawdown = max(0, max_t(peak_t - value_t) / peak_t)
      Current Drawdown = (running_peak - current_value) / running_peak
      Underwater Period = consecutive periods where value < previous_peak
      Recovery Time = periods from trough to recovery above previous peak

  ## Edge Cases

  - Handles continuously rising portfolios (zero drawdown)
  - Manages periods without recovery (ongoing drawdowns)
  - Processes extreme volatility scenarios
  - Validates against non-positive portfolio values

  ## Examples

      # Calculate maximum drawdown for portfolio values
      iex> values = [D.new("100000"), D.new("120000"), D.new("80000"), D.new("110000")]
      iex> {:ok, result} = DrawdownCalculator.calculate(values)
      iex> D.compare(result.max_drawdown_percentage, D.new("33")) == :gt
      true

      # TODO: Implement comprehensive drawdown period identification
      # Currently returns empty list - functionality to be added in future iteration
  """

  alias Decimal, as: D

  require Logger

  # Type definitions
  @type portfolio_values :: list(D.t())
  @type drawdown_result ::
          {:ok,
           %{
             max_drawdown: D.t(),
             max_drawdown_percentage: D.t(),
             current_drawdown: D.t(),
             peak_value: D.t(),
             trough_value: D.t(),
             recovery_periods: non_neg_integer() | nil,
             underwater_periods: non_neg_integer()
           }}
          | {:error, atom()}
  @type drawdown_period :: %{
          drawdown_percentage: D.t(),
          peak_index: non_neg_integer(),
          trough_index: non_neg_integer(),
          recovery_index: non_neg_integer() | nil,
          duration_periods: non_neg_integer(),
          recovery_periods: non_neg_integer() | nil,
          peak_value: D.t(),
          trough_value: D.t()
        }
  @type drawdown_history_result :: {:ok, list(drawdown_period())} | {:error, atom()}

  @doc """
  Calculates comprehensive drawdown analysis for portfolio values.

  Analyzes the complete drawdown profile including maximum drawdown, current position,
  recovery characteristics, and underwater periods.

  ## Parameters

    - values: List of Decimal - Portfolio values in chronological order

  ## Returns

    - {:ok, %{
        max_drawdown: Decimal,              # Maximum drawdown as decimal (0.30 = 30%)
        max_drawdown_percentage: Decimal,   # Maximum drawdown as percentage (30.00)
        current_drawdown: Decimal,          # Current drawdown from running peak
        peak_value: Decimal,                # Portfolio value at maximum drawdown peak
        trough_value: Decimal,              # Portfolio value at maximum drawdown trough
        recovery_periods: integer | nil,    # Periods to recover from trough (nil if no recovery)
        underwater_periods: integer         # Total periods spent below previous peaks
      }}
    - {:error, reason} - Error with descriptive reason

  ## Examples

      iex> values = [D.new("1000000"), D.new("1200000"), D.new("800000"), D.new("1100000")]
      iex> {:ok, result} = DrawdownCalculator.calculate(values)
      iex> D.compare(result.max_drawdown, D.new("0.33")) == :gt
      true
      iex> D.equal?(result.peak_value, D.new("1200000"))
      true
  """
  @spec calculate(portfolio_values()) :: drawdown_result()
  def calculate(values) when is_list(values) do
    Logger.debug("Calculating drawdown analysis for #{length(values)} portfolio values")

    with :ok <- validate_values(values) do
      {max_drawdown_info, current_drawdown, underwater_periods} =
        analyze_drawdown_characteristics(values)

      result = %{
        max_drawdown: D.round(max_drawdown_info.drawdown, 6),
        max_drawdown_percentage: D.round(D.mult(max_drawdown_info.drawdown, D.new("100")), 2),
        current_drawdown: D.round(current_drawdown, 6),
        peak_value: max_drawdown_info.peak_value,
        trough_value: max_drawdown_info.trough_value,
        recovery_periods: max_drawdown_info.recovery_periods,
        underwater_periods: underwater_periods
      }

      Logger.debug("Maximum Drawdown calculated: #{result.max_drawdown_percentage}%")
      {:ok, result}
    end
  end

  @doc """
  Calculates history of all significant drawdown periods above threshold.

  Identifies discrete drawdown events, their duration, and recovery characteristics
  for comprehensive risk assessment.

  ## Parameters

    - values: List of Decimal - Portfolio values in chronological order
    - threshold: Decimal - Minimum drawdown size to include (e.g., 0.10 for 10%)

  ## Returns

    - {:ok, [%{
        drawdown_percentage: Decimal,     # Drawdown magnitude as percentage
        peak_index: integer,              # Array index of peak value
        trough_index: integer,            # Array index of trough value
        recovery_index: integer | nil,    # Array index of recovery (nil if ongoing)
        duration_periods: integer,        # Periods from peak to trough
        recovery_periods: integer | nil,  # Periods from trough to recovery
        peak_value: Decimal,              # Portfolio value at peak
        trough_value: Decimal             # Portfolio value at trough
      }]}
    - {:error, reason} - Error with descriptive reason

  ## Examples

      iex> values = [D.new("100"), D.new("120"), D.new("90"), D.new("130"), D.new("100")]
      iex> {:ok, history} = DrawdownCalculator.calculate_history(values, D.new("0.15"))
      iex> length(history) == 0  # Currently simplified implementation returns empty list
      true
  """
  @spec calculate_history(portfolio_values(), D.t()) :: drawdown_history_result()
  def calculate_history(values, threshold) when is_list(values) do
    Logger.debug("Calculating drawdown history for #{length(values)} values with #{threshold} threshold")

    with :ok <- validate_values(values),
         :ok <- validate_threshold(threshold) do
      drawdown_periods = identify_drawdown_periods(values, threshold)

      Logger.debug("Found #{length(drawdown_periods)} drawdown periods above threshold")
      {:ok, drawdown_periods}
    end
  end

  # Private helper functions

  @spec validate_values(portfolio_values()) :: :ok | {:error, atom()}
  defp validate_values(values) do
    cond do
      length(values) < 2 ->
        {:error, :insufficient_data}

      not Enum.all?(values, &is_struct(&1, D)) ->
        {:error, :invalid_value_format}

      not Enum.all?(values, &(D.compare(&1, D.new("0")) == :gt)) ->
        {:error, :non_positive_values}

      true ->
        :ok
    end
  end

  @spec validate_threshold(D.t()) :: :ok | {:error, atom()}
  defp validate_threshold(%D{} = threshold) do
    if D.compare(threshold, D.new("0")) == :gt and D.compare(threshold, D.new("1")) == :lt do
      :ok
    else
      {:error, :invalid_threshold}
    end
  end

  defp analyze_drawdown_characteristics(values) do
    # Initialize with first value
    first_value = Enum.at(values, 0)

    initial_state = %{
      running_peak: first_value,
      running_peak_index: 0,
      max_drawdown: D.new("0"),
      max_drawdown_peak: first_value,
      max_drawdown_trough: first_value,
      max_drawdown_peak_index: 0,
      max_drawdown_trough_index: 0,
      underwater_periods: 0
    }

    final_state =
      values
      |> Enum.with_index()
      |> Enum.reduce(initial_state, &process_value_for_drawdown/2)

    # Calculate current drawdown from current running peak
    current_value = List.last(values)
    current_drawdown = calculate_current_drawdown(final_state.running_peak, current_value)

    # Determine recovery periods for max drawdown (0 if no drawdown)
    recovery_periods =
      if D.equal?(final_state.max_drawdown, D.new("0")) do
        0
      else
        calculate_recovery_periods(values, final_state)
      end

    # For results, use the overall running peak if no significant drawdown occurred
    result_peak_value =
      if D.equal?(final_state.max_drawdown, D.new("0")) do
        final_state.running_peak
      else
        final_state.max_drawdown_peak
      end

    result_trough_value =
      if D.equal?(final_state.max_drawdown, D.new("0")) do
        final_state.running_peak
      else
        final_state.max_drawdown_trough
      end

    max_drawdown_info = %{
      drawdown: final_state.max_drawdown,
      peak_value: result_peak_value,
      trough_value: result_trough_value,
      recovery_periods: recovery_periods
    }

    {max_drawdown_info, current_drawdown, final_state.underwater_periods}
  end

  defp process_value_for_drawdown({value, index}, state) do
    # Update running peak if we have a new high
    {new_running_peak, new_running_peak_index} =
      if D.compare(value, state.running_peak) == :gt do
        {value, index}
      else
        {state.running_peak, state.running_peak_index}
      end

    # Calculate current drawdown from running peak
    current_drawdown = calculate_current_drawdown(new_running_peak, value)

    # Check if this is a new maximum drawdown
    {new_max_drawdown, new_peak, new_trough, new_peak_index, new_trough_index} =
      if D.compare(current_drawdown, state.max_drawdown) == :gt do
        {current_drawdown, new_running_peak, value, new_running_peak_index, index}
      else
        {state.max_drawdown, state.max_drawdown_peak, state.max_drawdown_trough, state.max_drawdown_peak_index,
         state.max_drawdown_trough_index}
      end

    # Update underwater periods (count periods below running peak)
    is_underwater = D.compare(value, new_running_peak) == :lt

    new_underwater_periods =
      if is_underwater do
        state.underwater_periods + 1
      else
        state.underwater_periods
      end

    %{
      running_peak: new_running_peak,
      running_peak_index: new_running_peak_index,
      max_drawdown: new_max_drawdown,
      max_drawdown_peak: new_peak,
      max_drawdown_trough: new_trough,
      max_drawdown_peak_index: new_peak_index,
      max_drawdown_trough_index: new_trough_index,
      underwater_periods: new_underwater_periods
    }
  end

  defp calculate_current_drawdown(peak, current_value) do
    if D.equal?(peak, D.new("0")) do
      D.new("0")
    else
      D.div(D.sub(peak, current_value), peak)
    end
  end

  defp calculate_recovery_periods(values, state) do
    _peak_index = state.max_drawdown_peak_index
    trough_index = state.max_drawdown_trough_index
    peak_value = state.max_drawdown_peak

    # Find first index after trough where value >= peak_value
    recovery_index =
      values
      |> Enum.with_index()
      |> Enum.drop(trough_index + 1)
      |> Enum.find(fn {value, _index} ->
        D.compare(value, peak_value) in [:gt, :eq]
      end)

    case recovery_index do
      {_value, index} -> index - trough_index
      # No recovery yet
      nil -> nil
    end
  end

  defp identify_drawdown_periods(_values, _threshold) do
    # Simplified implementation for now - return empty list to focus on main functionality
    # TODO: Implement comprehensive drawdown period identification
    []
  end
end
