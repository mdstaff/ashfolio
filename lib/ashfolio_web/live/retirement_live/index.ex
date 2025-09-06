defmodule AshfolioWeb.RetirementLive.Index do
  @moduledoc """
  LiveView for retirement planning calculations.

  Provides interactive forms for retirement planning with:
  - 25x rule calculation (retirement target)
  - 4% safe withdrawal rate calculation
  - Retirement progress tracking
  - Historical expense analysis
  """

  use AshfolioWeb, :live_view

  alias Ashfolio.Financial.Formatters
  alias Ashfolio.FinancialManagement.RetirementCalculator

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Ashfolio.PubSub.subscribe("accounts")
      Ashfolio.PubSub.subscribe("expenses")
    end

    # Set default form values
    default_form_data = %{
      "annual_expenses" => "50000",
      "current_portfolio" => "500000"
    }

    socket =
      socket
      |> assign_current_page(:retirement)
      |> assign(:page_title, "Retirement Planning")
      |> assign(:form_data, default_form_data)
      |> assign(:retirement_target, nil)
      |> assign(:safe_withdrawal, nil)
      |> assign(:progress_analysis, nil)
      |> assign(:historical_analysis, nil)
      |> assign(:loading, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("calculate", %{"annual_expenses" => annual_expenses, "current_portfolio" => current_portfolio}, socket) do
    Logger.debug("Calculating retirement metrics - expenses: #{annual_expenses}, portfolio: #{current_portfolio}")

    socket = assign(socket, :loading, true)

    # Parse input values
    with {:ok, expenses_decimal} <- parse_decimal(annual_expenses),
         {:ok, portfolio_decimal} <- parse_decimal(current_portfolio) do
      # Calculate retirement target (25x rule)
      retirement_target =
        case RetirementCalculator.calculate_retirement_target(expenses_decimal) do
          {:ok, target} -> target
          {:error, _} -> Decimal.new("0")
        end

      # Calculate safe withdrawal (4% rule)
      safe_withdrawal =
        case RetirementCalculator.calculate_safe_withdrawal_amount(portfolio_decimal) do
          {:ok, withdrawal} -> withdrawal
          {:error, _} -> Decimal.new("0")
        end

      # Calculate monthly budget
      monthly_budget =
        case RetirementCalculator.calculate_monthly_withdrawal_budget(portfolio_decimal) do
          {:ok, budget} -> budget
          {:error, _} -> Decimal.new("0")
        end

      # Calculate retirement progress
      progress_analysis =
        case RetirementCalculator.calculate_retirement_progress(expenses_decimal, portfolio_decimal) do
          {:ok, progress} -> progress
          {:error, _} -> nil
        end

      socket =
        socket
        |> assign(:retirement_target, retirement_target)
        |> assign(:safe_withdrawal, %{annual: safe_withdrawal, monthly: monthly_budget})
        |> assign(:progress_analysis, progress_analysis)
        |> assign(:loading, false)

      {:noreply, socket}
    else
      _error ->
        socket =
          socket
          |> assign(:loading, false)
          |> put_flash(:error, "Please enter valid numbers for expenses and portfolio value")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("use_historical_expenses", _params, socket) do
    Logger.debug("Calculating retirement metrics from historical expenses")

    socket = assign(socket, :loading, true)

    # Get current portfolio value
    current_portfolio =
      case parse_decimal(socket.assigns.form_data["current_portfolio"]) do
        {:ok, value} -> value
        # Default fallback
        _ -> Decimal.new("500000")
      end

    # Calculate retirement metrics from historical data
    historical_analysis =
      case RetirementCalculator.calculate_retirement_progress_from_history(current_portfolio) do
        {:ok, analysis} ->
          analysis

        {:error, reason} ->
          Logger.warning("Failed to calculate from history: #{inspect(reason)}")
          nil
      end

    socket =
      socket
      |> assign(:historical_analysis, historical_analysis)
      |> assign(:loading, false)

    if historical_analysis do
      {:noreply, socket}
    else
      socket = put_flash(socket, :error, "Unable to calculate from expense history. Please ensure you have expense data.")
      {:noreply, socket}
    end
  end

  # Helper function to parse decimal inputs
  defp parse_decimal(value) when is_binary(value) do
    case Decimal.parse(value) do
      {decimal, ""} -> {:ok, decimal}
      _ -> {:error, :invalid}
    end
  end

  defp parse_decimal(_), do: {:error, :invalid}
end
