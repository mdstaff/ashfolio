defmodule Ashfolio.TaxPlanning.TaxLossHarvester do
  @moduledoc """
  Tax-loss harvesting opportunity identification and optimization.

  Identifies opportunities to realize losses for tax benefits while maintaining
  portfolio allocation targets through intelligent replacement strategies.

  Key features:
  - Loss opportunity identification with threshold analysis
  - Wash sale rule compliance (30-day rule)
  - Similar asset replacement recommendations
  - Portfolio rebalancing integration
  - Tax efficiency optimization
  """

  alias Ashfolio.Financial.DecimalHelpers, as: DH
  alias Ashfolio.Portfolio.Symbol
  alias Ashfolio.Portfolio.Transaction

  require Logger

  @wash_sale_days 30
  @minimum_loss_threshold Decimal.new("100.00")

  @doc """
  Identifies tax-loss harvesting opportunities across portfolio.

  Analyzes all positions for unrealized losses that could be harvested
  for tax benefits while considering wash sale rules and replacement strategies.

  ## Parameters

    - account_id: UUID - Account to analyze (optional, analyzes all if nil)
    - loss_threshold: Decimal - Minimum loss amount to consider (default: $100)
    - options: keyword - Additional analysis options

  ## Returns

    - {:ok, harvest_opportunities} - List of actionable opportunities
    - {:error, reason} - Error tuple with descriptive reason

  ## Examples

      iex> TaxLossHarvester.identify_opportunities("account-uuid")
      {:ok, %{
        opportunities: [
          %{
            symbol: "AAPL",
            unrealized_loss: Decimal.new("1500.50"),
            tax_benefit: Decimal.new("450.15"),
            wash_sale_risk: false,
            replacement_options: ["VTI", "ITOT"]
          }
        ],
        total_harvestable_losses: Decimal.new("3250.75"),
        estimated_tax_savings: Decimal.new("975.23")
      }}
  """
  def identify_opportunities(account_id \\ nil, loss_threshold \\ @minimum_loss_threshold, options \\ []) do
    Logger.debug("Identifying tax-loss harvesting opportunities#{if account_id, do: " for account #{account_id}"}")

    with {:ok, positions} <- get_portfolio_positions(account_id),
         {:ok, recent_transactions} <- get_recent_transactions(account_id) do
      case positions do
        [] ->
          Logger.info("No positions found for tax loss harvesting")
          {:error, :no_positions}

        _ ->
          opportunities =
            positions
            |> Enum.map(&analyze_position_for_harvesting(&1, recent_transactions, loss_threshold, options))
            |> Enum.filter(&harvestable_opportunity?/1)
            |> Enum.sort_by(& &1.tax_benefit, {:desc, Decimal})

          summary = calculate_harvest_summary(opportunities)

          result = %{
            opportunities: opportunities,
            total_harvestable_losses: summary.total_losses,
            estimated_tax_savings: summary.tax_savings,
            positions_analyzed: length(positions),
            opportunities_found: length(opportunities)
          }

          Logger.debug(
            "Tax-loss harvesting analysis complete: #{length(opportunities)} opportunities, #{summary.total_losses} potential losses"
          )

          {:ok, result}
      end
    else
      {:error, reason} ->
        Logger.warning("Tax-loss harvesting analysis failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Recommends replacement assets to maintain portfolio allocation.

  Suggests similar ETFs or securities to replace harvested positions
  while avoiding wash sale violations and maintaining target allocations.

  ## Parameters

    - symbol: string - Original symbol being harvested
    - allocation_target: Decimal - Target allocation percentage
    - options: keyword - Replacement criteria options

  ## Returns

    - {:ok, replacement_recommendations} - List of suitable replacements
    - {:error, reason} - Error tuple with descriptive reason
  """
  def recommend_replacements(symbol, allocation_target \\ nil, options \\ []) do
    Logger.debug("Recommending replacements for #{symbol}")

    with {:ok, symbol_data} <- get_symbol_details(symbol),
         {:ok, similar_assets} <- find_similar_assets(symbol_data, options) do
      replacements =
        similar_assets
        |> Enum.map(&evaluate_replacement(&1, symbol_data, allocation_target))
        |> Enum.filter(&(&1.suitability_score >= 0.7))
        |> Enum.sort_by(& &1.suitability_score, :desc)
        |> Enum.take(5)

      Logger.debug("Found #{length(replacements)} suitable replacements for #{symbol}")
      {:ok, replacements}
    else
      {:error, reason} ->
        Logger.warning("Replacement recommendation failed for #{symbol}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Checks wash sale rule compliance for proposed transactions.

  Validates that selling a position and buying a replacement doesn't
  violate the 30-day wash sale rule that would disallow the tax loss.

  ## Parameters

    - sell_symbol: string - Symbol being sold
    - buy_symbol: string - Replacement symbol being purchased
    - transaction_date: Date - Proposed transaction date
    - account_id: UUID - Account identifier (optional)

  ## Returns

    - {:ok, compliance_check} - Wash sale compliance analysis
    - {:error, reason} - Error tuple with descriptive reason
  """
  def check_wash_sale_compliance(sell_symbol, buy_symbol, transaction_date, account_id \\ nil) do
    Logger.debug("Checking wash sale compliance: #{sell_symbol} -> #{buy_symbol} on #{transaction_date}")

    with {:ok, recent_transactions} <- get_transactions_around_date(transaction_date, account_id),
         {:ok, symbol_similarity} <- assess_symbol_similarity(sell_symbol, buy_symbol) do
      compliance_check = %{
        is_compliant:
          assess_wash_sale_compliance(
            sell_symbol,
            buy_symbol,
            transaction_date,
            recent_transactions,
            symbol_similarity
          ),
        risk_factors: identify_wash_sale_risks(sell_symbol, buy_symbol, recent_transactions, symbol_similarity),
        safe_date: calculate_safe_transaction_date(sell_symbol, recent_transactions),
        similarity_assessment: symbol_similarity
      }

      Logger.debug(
        "Wash sale compliance check complete: #{if compliance_check.is_compliant, do: "COMPLIANT", else: "NON-COMPLIANT"}"
      )

      {:ok, compliance_check}
    else
      {:error, reason} ->
        Logger.warning("Wash sale compliance check failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Calculates optimal tax-loss harvesting strategy for portfolio.

  Develops comprehensive strategy to maximize tax benefits while maintaining
  portfolio diversification and target allocations.

  ## Parameters

    - portfolio_targets: map - Target allocations by asset class
    - tax_rate: Decimal - Marginal tax rate for benefit calculation
    - options: keyword - Strategy optimization options

  ## Returns

    - {:ok, harvest_strategy} - Optimized harvesting plan
    - {:error, reason} - Error tuple with descriptive reason
  """
  def optimize_harvest_strategy(portfolio_targets, tax_rate, options \\ []) do
    Logger.debug("Optimizing tax-loss harvesting strategy with #{tax_rate} tax rate")

    with {:ok, opportunities} <- identify_opportunities(nil, @minimum_loss_threshold, options),
         {:ok, current_allocations} <- get_current_allocations() do
      strategy =
        calculate_optimal_harvest_sequence(
          opportunities.opportunities,
          portfolio_targets,
          current_allocations,
          tax_rate,
          options
        )

      Logger.debug("Harvest strategy optimization complete: #{length(strategy.actions)} recommended actions")
      {:ok, strategy}
    else
      {:error, reason} ->
        Logger.warning("Harvest strategy optimization failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Private helper functions

  defp get_portfolio_positions(_account_id) do
    # For MVP, return stub data to test the structure
    # Real implementation would calculate current positions from transactions
    # and include unrealized gain/loss calculations
    {:ok, []}
  end

  defp get_recent_transactions(account_id) do
    # Get transactions from last 60 days for wash sale analysis
    start_date = Date.add(Date.utc_today(), -60)
    end_date = Date.utc_today()

    case Transaction.by_date_range(start_date, end_date) do
      {:ok, transactions} ->
        filtered_transactions =
          if account_id do
            Enum.filter(transactions, &(&1.account_id == account_id))
          else
            transactions
          end

        {:ok, filtered_transactions}

      {:error, reason} ->
        {:error, reason}

      [] ->
        {:ok, []}
    end
  end

  defp analyze_position_for_harvesting(position, recent_transactions, loss_threshold, _options) do
    if Decimal.compare(position.unrealized_gain_loss, Decimal.negate(loss_threshold)) == :lt do
      # Position has harvestable loss
      wash_sale_risk = check_position_wash_sale_risk(position, recent_transactions)
      tax_benefit = calculate_tax_benefit(position.unrealized_gain_loss)

      %{
        symbol_id: position.symbol_id,
        symbol: position.symbol,
        current_value: position.current_value,
        cost_basis: position.cost_basis,
        unrealized_loss: Decimal.abs(position.unrealized_gain_loss),
        tax_benefit: tax_benefit,
        wash_sale_risk: wash_sale_risk,
        harvestable: not wash_sale_risk,
        replacement_options: get_replacement_suggestions(position.symbol),
        priority_score: calculate_priority_score(position, tax_benefit, wash_sale_risk)
      }
    else
      # Position doesn't have sufficient loss
      %{
        symbol_id: position.symbol_id,
        symbol: position.symbol,
        harvestable: false,
        unrealized_loss: Decimal.new("0"),
        reason: :insufficient_loss
      }
    end
  end

  defp harvestable_opportunity?(opportunity) do
    Map.get(opportunity, :harvestable, false)
  end

  defp check_position_wash_sale_risk(position, recent_transactions) do
    # Check if position was purchased within last 30 days
    cutoff_date = Date.add(Date.utc_today(), -@wash_sale_days)

    recent_purchases =
      Enum.filter(
        recent_transactions,
        &(&1.symbol_id == position.symbol_id and &1.type == :buy and Date.after?(&1.date, cutoff_date))
      )

    length(recent_purchases) > 0
  end

  defp calculate_tax_benefit(unrealized_loss) do
    # Assume 22% marginal tax rate for simplicity
    loss_amount = Decimal.abs(unrealized_loss)
    Decimal.mult(loss_amount, Decimal.new("0.22"))
  end

  defp get_replacement_suggestions(symbol) do
    # Mock replacement suggestions based on asset class
    case symbol do
      "AAPL" -> ["VTI", "ITOT", "IVV"]
      "MSFT" -> ["VTI", "QQQ", "IVV"]
      "TSLA" -> ["VTI", "XLK", "ARKQ"]
      _ -> ["VTI", "IVV", "SCHB"]
    end
  end

  defp calculate_priority_score(position, tax_benefit, wash_sale_risk) do
    base_score = DH.safe_divide(tax_benefit, position.current_value)

    if wash_sale_risk do
      # Reduce score for wash sale risk
      Decimal.mult(base_score, Decimal.new("0.5"))
    else
      base_score
    end
  end

  defp calculate_harvest_summary(opportunities) do
    total_losses =
      opportunities
      |> Enum.map(& &1.unrealized_loss)
      |> Enum.reduce(Decimal.new("0"), &Decimal.add/2)

    tax_savings =
      opportunities
      |> Enum.map(& &1.tax_benefit)
      |> Enum.reduce(Decimal.new("0"), &Decimal.add/2)

    %{total_losses: total_losses, tax_savings: tax_savings}
  end

  defp get_symbol_details(symbol) do
    case Symbol.find_by_symbol(symbol) do
      {:ok, symbol_record} -> {:ok, symbol_record}
      {:error, reason} -> {:error, reason}
    end
  end

  defp find_similar_assets(symbol_data, _options) do
    # Mock implementation for finding similar assets
    # Real implementation would use asset class, sector, or correlation data
    # symbol_data is a list, take the first element
    symbol_record = List.first(symbol_data)

    similar_assets =
      case symbol_record.symbol do
        "AAPL" -> ["MSFT", "GOOGL", "VTI", "QQQ"]
        "MSFT" -> ["AAPL", "GOOGL", "VTI", "QQQ"]
        _ -> ["VTI", "IVV", "SCHB"]
      end

    {:ok, similar_assets}
  end

  defp evaluate_replacement(replacement_symbol, _original_symbol, _allocation_target) do
    # Mock evaluation of replacement suitability
    # Real implementation would consider correlation, expense ratio, liquidity, etc.
    %{
      symbol: replacement_symbol,
      suitability_score: 0.85,
      correlation_to_original: 0.75,
      expense_ratio: Decimal.new("0.0015"),
      liquidity_score: 0.9,
      tax_efficiency: 0.8
    }
  end

  defp get_transactions_around_date(transaction_date, account_id) do
    start_date = Date.add(transaction_date, -@wash_sale_days)
    end_date = Date.add(transaction_date, @wash_sale_days)

    case Transaction.by_date_range(start_date, end_date) do
      {:ok, transactions} ->
        filtered_transactions =
          if account_id do
            Enum.filter(transactions, &(&1.account_id == account_id))
          else
            transactions
          end

        {:ok, filtered_transactions}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp assess_symbol_similarity(symbol1, symbol2) do
    # Mock similarity assessment
    # Real implementation would consider:
    # - Same issuer
    # - Similar underlying assets
    # - Correlation analysis
    # - Asset class overlap

    similarity_score =
      if symbol1 == symbol2 do
        1.0
      else
        case {symbol1, symbol2} do
          # Both total market ETFs
          {"VTI", "ITOT"} -> 0.95
          # Both S&P 500 ETFs
          {"SPY", "IVV"} -> 0.98
          # Different companies, lower similarity
          {"AAPL", "MSFT"} -> 0.3
          _ -> 0.1
        end
      end

    {:ok,
     %{
       similarity_score: similarity_score,
       substantially_identical: similarity_score > 0.9
     }}
  end

  defp assess_wash_sale_compliance(_sell_symbol, buy_symbol, transaction_date, recent_transactions, similarity) do
    # Check if buying substantially identical security within 30 days
    if similarity.substantially_identical do
      # Check for recent purchases of the buy_symbol
      cutoff_date_before = Date.add(transaction_date, -@wash_sale_days)
      cutoff_date_after = Date.add(transaction_date, @wash_sale_days)

      conflicting_transactions =
        Enum.filter(recent_transactions, fn txn ->
          txn.type == :buy and
            get_symbol_string(txn) == buy_symbol and
            Date.after?(txn.date, cutoff_date_before) and
            Date.before?(txn.date, cutoff_date_after)
        end)

      Enum.empty?(conflicting_transactions)
    else
      # Different securities, no wash sale issue
      true
    end
  end

  defp identify_wash_sale_risks(_sell_symbol, buy_symbol, recent_transactions, similarity) do
    risks = []

    risks =
      if similarity.substantially_identical do
        ["Substantially identical securities" | risks]
      else
        risks
      end

    # Check for recent activity in buy_symbol
    recent_buy_activity =
      Enum.filter(recent_transactions, fn txn ->
        txn.type == :buy and get_symbol_string(txn) == buy_symbol
      end)

    risks =
      if length(recent_buy_activity) > 0 do
        ["Recent purchase activity in replacement security" | risks]
      else
        risks
      end

    risks
  end

  defp calculate_safe_transaction_date(sell_symbol, recent_transactions) do
    # Find most recent purchase of the symbol and add 31 days
    recent_purchase =
      recent_transactions
      |> Enum.filter(fn txn ->
        txn.type == :buy and get_symbol_string(txn) == sell_symbol
      end)
      |> Enum.sort_by(& &1.date, {:desc, Date})
      |> List.first()

    if recent_purchase do
      Date.add(recent_purchase.date, @wash_sale_days + 1)
    else
      # Safe to trade immediately
      Date.utc_today()
    end
  end

  defp get_symbol_string(transaction) do
    # Helper to get symbol string from transaction
    case transaction do
      %{symbol: %{symbol: symbol}} ->
        symbol

      %{symbol_id: symbol_id} when is_binary(symbol_id) ->
        case Symbol.get_by_id(symbol_id) do
          {:ok, symbol_record} -> symbol_record.symbol
          {:error, _} -> "UNKNOWN"
        end

      _ ->
        "UNKNOWN"
    end
  end

  defp get_current_allocations do
    # Mock current portfolio allocations
    # Real implementation would calculate from current holdings
    {:ok,
     %{
       "stocks" => Decimal.new("60.0"),
       "bonds" => Decimal.new("30.0"),
       "cash" => Decimal.new("10.0")
     }}
  end

  defp calculate_optimal_harvest_sequence(opportunities, _portfolio_targets, _current_allocations, tax_rate, _options) do
    # Simplified strategy: prioritize by tax benefit and wash sale risk
    prioritized_actions =
      opportunities
      |> Enum.filter(& &1.harvestable)
      |> Enum.sort_by(& &1.priority_score, {:desc, Decimal})
      |> Enum.map(&create_harvest_action(&1, tax_rate))

    total_tax_savings =
      prioritized_actions
      |> Enum.map(& &1.estimated_tax_savings)
      |> Enum.reduce(Decimal.new("0"), &Decimal.add/2)

    %{
      actions: prioritized_actions,
      total_estimated_savings: total_tax_savings,
      execution_timeline: calculate_execution_timeline(prioritized_actions),
      risk_assessment: "Low",
      compliance_verified: true
    }
  end

  defp create_harvest_action(opportunity, tax_rate) do
    %{
      action_type: :tax_loss_harvest,
      sell_symbol: opportunity.symbol,
      sell_amount: opportunity.current_value,
      estimated_loss: opportunity.unrealized_loss,
      estimated_tax_savings: Decimal.mult(opportunity.unrealized_loss, tax_rate),
      recommended_replacement: List.first(opportunity.replacement_options || []),
      priority: opportunity.priority_score,
      wash_sale_compliant: not opportunity.wash_sale_risk,
      execution_date: if(opportunity.wash_sale_risk, do: Date.add(Date.utc_today(), 31), else: Date.utc_today())
    }
  end

  defp calculate_execution_timeline(actions) do
    immediate_actions = Enum.filter(actions, & &1.wash_sale_compliant)
    delayed_actions = Enum.filter(actions, &(not &1.wash_sale_compliant))

    %{
      immediate_actions: length(immediate_actions),
      delayed_actions: length(delayed_actions),
      earliest_completion: if(Enum.empty?(delayed_actions), do: Date.utc_today(), else: Date.add(Date.utc_today(), 31))
    }
  end
end
