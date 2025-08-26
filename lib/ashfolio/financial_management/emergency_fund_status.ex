defmodule Ashfolio.FinancialManagement.EmergencyFundStatus do
  @moduledoc """
  Centralized emergency fund status mapping and formatting utilities.

  Provides consistent status colors, labels, and dots across all UI components
  for both legacy status levels and new readiness levels from EmergencyFundCalculator.
  """

  @doc """
  Returns the CSS color class for a given emergency fund status.

  Supports both legacy statuses (:adequate, :partial, :insufficient, :no_goal)
  and new readiness levels (:fully_funded, :mostly_funded, :partially_funded, :underfunded).
  """
  def status_color(status)

  # Legacy status levels (for backwards compatibility)
  def status_color(:adequate), do: "text-green-600"
  def status_color(:partial), do: "text-yellow-600"
  def status_color(:insufficient), do: "text-red-600"
  def status_color(:no_goal), do: "text-gray-600"

  # New readiness levels from EmergencyFundCalculator
  def status_color(:fully_funded), do: "text-green-600"
  def status_color(:mostly_funded), do: "text-green-500"
  def status_color(:partially_funded), do: "text-yellow-600"
  def status_color(:underfunded), do: "text-red-600"

  @doc """
  Returns the background color class for status indicator dots.
  """
  def dot_color(status)

  # Legacy status levels
  def dot_color(:adequate), do: "bg-green-500"
  def dot_color(:partial), do: "bg-yellow-500"
  def dot_color(:insufficient), do: "bg-red-500"
  def dot_color(:no_goal), do: "bg-gray-400"

  # New readiness levels from EmergencyFundCalculator
  def dot_color(:fully_funded), do: "bg-green-500"
  def dot_color(:mostly_funded), do: "bg-green-400"
  def dot_color(:partially_funded), do: "bg-yellow-500"
  def dot_color(:underfunded), do: "bg-red-500"

  @doc """
  Returns the human-readable label for a given status.
  """
  def status_label(status)

  # Legacy status levels
  def status_label(:adequate), do: "Ready"
  def status_label(:partial), do: "Building"
  def status_label(:insufficient), do: "At Risk"
  def status_label(:no_goal), do: "Not Started"

  # New readiness levels from EmergencyFundCalculator
  def status_label(:fully_funded), do: "Fully Funded"
  def status_label(:mostly_funded), do: "Well Funded"
  def status_label(:partially_funded), do: "Building"
  def status_label(:underfunded), do: "Underfunded"

  @doc """
  Lists all supported legacy status levels.
  """
  def legacy_statuses do
    [:adequate, :partial, :insufficient, :no_goal]
  end

  @doc """
  Lists all supported readiness levels from EmergencyFundCalculator.
  """
  def readiness_levels do
    [:fully_funded, :mostly_funded, :partially_funded, :underfunded]
  end

  @doc """
  Lists all supported status levels (both legacy and readiness levels).
  """
  def all_statuses do
    legacy_statuses() ++ readiness_levels()
  end
end
