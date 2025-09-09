defmodule AshfolioWeb.Components.ChartGeometry do
  @moduledoc """
  Chart geometry and SVG path building utilities.

  Handles coordinate transformations, scaling, and SVG path generation
  for various chart visualization types.
  """

  @doc """
  Builds an SVG line path from coordinate data.

  ## Examples

      iex> ChartGeometry.build_line_path([1, 2, 3], [100, 200, 150])
      "M 50 300 L 150 100 L 250 200"
  """
  def build_line_path([], []), do: ""

  def build_line_path(years, values) do
    coordinates =
      years
      |> Enum.zip(values)
      |> Enum.with_index()
      |> Enum.map(fn {{year, value}, index} ->
        x = scale_x_coordinate(year, years, index)
        y = scale_y_coordinate(value, values)
        "#{x} #{y}"
      end)

    case coordinates do
      [] ->
        ""

      [first | rest] ->
        "M #{first}" <>
          Enum.map_join(rest, "", &(" L " <> &1))
    end
  end

  @doc """
  Builds an SVG area path with upper and lower bounds.
  """
  def build_area_path(_years, [], []), do: ""

  def build_area_path(years, lower, upper) do
    upper_path = build_line_path(years, upper)

    lower_coordinates =
      years
      |> Enum.zip(lower)
      |> Enum.reverse()
      |> Enum.with_index()
      |> Enum.map(fn {{year, value}, index} ->
        x = scale_x_coordinate(year, Enum.reverse(years), index)
        y = scale_y_coordinate(value, lower ++ upper)
        "#{x} #{y}"
      end)

    lower_path = Enum.map_join(lower_coordinates, "", &(" L " <> &1))

    upper_path <> lower_path <> " Z"
  end

  @doc """
  Builds a stacked area path with base values.
  """
  def build_stacked_area_path(years, values, base_values) do
    top_values =
      values
      |> Enum.zip(base_values)
      |> Enum.map(fn {val, base} -> val + base end)

    build_area_path(years, base_values, top_values)
  end

  @doc """
  Scales X coordinate based on data range.
  """
  def scale_x_coordinate(value, data_range, _index \\ nil) when is_list(data_range) do
    if Enum.empty?(data_range) do
      0
    else
      min_val = Enum.min(data_range)
      max_val = Enum.max(data_range)
      range = max_val - min_val

      if range == 0 do
        chart_width() / 2
      else
        chart_margin() + (value - min_val) / range * chart_content_width()
      end
    end
  end

  @doc """
  Scales Y coordinate based on data range.
  """
  def scale_y_coordinate(value, data_range) when is_list(data_range) do
    if Enum.empty?(data_range) do
      chart_height() / 2
    else
      min_val = Enum.min(data_range)
      max_val = Enum.max(data_range)
      range = max_val - min_val

      if range == 0 do
        chart_height() / 2
      else
        chart_margin() + (max_val - value) / range * chart_content_height()
      end
    end
  end

  @doc """
  Generates grid line coordinates for chart axes.
  """
  def generate_grid_lines(data_range, axis_type) when axis_type in [:x, :y] do
    if Enum.empty?(data_range) do
      []
    else
      min_val = Enum.min(data_range)
      max_val = Enum.max(data_range)
      # 5 grid lines
      step = (max_val - min_val) / 5

      0..5
      |> Enum.map(fn i -> min_val + i * step end)
      |> Enum.map(fn value -> create_grid_line(axis_type, value, data_range) end)
    end
  end

  defp create_grid_line(:x, value, data_range) do
    %{value: value, position: scale_x_coordinate(value, data_range)}
  end

  defp create_grid_line(:y, value, data_range) do
    %{value: value, position: scale_y_coordinate(value, data_range)}
  end

  # Chart dimension constants
  defp chart_width, do: 800
  defp chart_height, do: 400
  defp chart_margin, do: 60
  defp chart_content_width, do: chart_width() - 2 * chart_margin()
  defp chart_content_height, do: chart_height() - 2 * chart_margin()
end
