defmodule AshfolioWeb.Components.ChartData do
  @moduledoc """
  Chart data processing and validation utilities.

  Handles data transformation, validation, and preparation for various
  chart types in the ForecastChart component.
  """

  @doc """
  Processes chart data based on the specified chart type.

  ## Examples

      iex> ChartData.process(%{data: %{years: [1, 2], values: [100, 200]}, type: :single_projection})
      %{processed: true, type: :single_projection, ...}
  """
  def process(%{data: data, type: type}) do
    cond do
      empty_data?(data) -> {:error, :empty_data}
      has_invalid_data?(data) -> {:error, :invalid_data}
      true -> {:ok, build_data_for_type(data, type)}
    end
  end

  @doc """
  Builds processed data for a specific chart type.
  """
  def build_data_for_type(data, :single_projection), do: build_single_projection_data(data)
  def build_data_for_type(data, :scenario_comparison), do: build_scenario_comparison_data(data)
  def build_data_for_type(data, :confidence_band), do: build_confidence_band_data(data)
  def build_data_for_type(data, :stacked_breakdown), do: build_stacked_breakdown_data(data)
  def build_data_for_type(data, _type), do: data

  @doc """
  Checks if the chart data is empty.
  """
  def empty_data?(%{years: years, values: values}) when is_list(years) and is_list(values) do
    Enum.empty?(years) or Enum.empty?(values)
  end

  def empty_data?(_data), do: false

  @doc """
  Checks if the chart data contains invalid values.
  """
  def has_invalid_data?(%{values: values}) when is_list(values) do
    Enum.any?(values, &is_nil/1)
  end

  def has_invalid_data?(_data), do: false

  # Private data building functions

  defp build_single_projection_data(data) do
    %{
      years: data.years || [],
      values: data.values || []
    }
  end

  defp build_scenario_comparison_data(data) do
    %{
      years: data.years || [],
      pessimistic: data.pessimistic || [],
      realistic: data.realistic || [],
      optimistic: data.optimistic || []
    }
  end

  defp build_confidence_band_data(data) do
    %{
      years: data.years || [],
      median: data.median || [],
      lower_bound: data.lower_bound || [],
      upper_bound: data.upper_bound || []
    }
  end

  defp build_stacked_breakdown_data(data) do
    %{
      years: data.years || [],
      principal: data.principal || [],
      contributions: data.contributions || [],
      growth: data.growth || []
    }
  end
end
