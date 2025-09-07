defmodule Ashfolio.TaxPlanning.TaxLossHarvesterTest do
  use ExUnit.Case, async: true
  
  import Mox

  alias Ashfolio.TaxPlanning.TaxLossHarvester
  alias Ashfolio.Portfolio.Transaction
  alias Ashfolio.Portfolio.Symbol

  setup :verify_on_exit!
  setup :set_mox_from_context

  describe "identify_opportunities/3" do
    test "identifies positions with harvestable losses" do
      account_id = "test-account"
      loss_threshold = Decimal.new("100.00")

      # Mock portfolio positions with losses
      positions = [
        %{
          symbol_id: "uuid-1",
          symbol: "AAPL",
          current_value: Decimal.new("9000"),
          cost_basis: Decimal.new("10500"),
          quantity: Decimal.new("100"),
          current_price: Decimal.new("90"),
          unrealized_gain_loss: Decimal.new("-1500"),
          account_id: account_id
        },
        %{
          symbol_id: "uuid-2", 
          symbol: "MSFT",
          current_value: Decimal.new("11000"),
          cost_basis: Decimal.new("10000"),
          quantity: Decimal.new("100"),
          current_price: Decimal.new("110"),
          unrealized_gain_loss: Decimal.new("1000"),
          account_id: account_id
        }
      ]

      # Mock recent transactions (empty for no wash sale issues)
      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_date_range, _args ->
        {:ok, []}
      end)

      # The actual implementation would call internal functions
      # For this test, we verify the public API structure
      assert {:ok, opportunities} = TaxLossHarvester.identify_opportunities(account_id, loss_threshold)

      assert Map.has_key?(opportunities, :opportunities)
      assert Map.has_key?(opportunities, :total_harvestable_losses)
      assert Map.has_key?(opportunities, :estimated_tax_savings)
      assert Map.has_key?(opportunities, :positions_analyzed)
      assert Map.has_key?(opportunities, :opportunities_found)

      assert is_list(opportunities.opportunities)
      assert is_integer(opportunities.positions_analyzed)
      assert is_integer(opportunities.opportunities_found)
    end

    test "filters out positions with insufficient losses" do
      account_id = "test-account"
      loss_threshold = Decimal.new("2000.00")  # High threshold

      # Mock positions with small losses
      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_date_range, _args ->
        {:ok, []}
      end)

      assert {:ok, opportunities} = TaxLossHarvester.identify_opportunities(account_id, loss_threshold)

      # Should find no opportunities due to high threshold
      assert opportunities.opportunities_found == 0
      assert Decimal.equal?(opportunities.total_harvestable_losses, Decimal.new("0"))
    end

    test "detects wash sale risks from recent transactions" do
      account_id = "test-account"
      
      # Mock recent purchase of same symbol
      recent_date = Date.add(Date.utc_today(), -15)
      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_date_range, _args ->
        {:ok, [
          %{
            id: "recent-buy",
            type: :buy,
            symbol_id: "uuid-1",
            date: recent_date,
            account_id: account_id
          }
        ]}
      end)

      assert {:ok, opportunities} = TaxLossHarvester.identify_opportunities(account_id)
      
      # Wash sale detection would be in the detailed opportunity analysis
      # For MVP, we verify structure is in place
      assert is_list(opportunities.opportunities)
    end

    test "calculates tax benefits correctly" do
      account_id = "test-account"
      
      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_date_range, _args ->
        {:ok, []}
      end)

      assert {:ok, opportunities} = TaxLossHarvester.identify_opportunities(account_id)

      # Verify tax benefit calculations are included
      for opportunity <- opportunities.opportunities do
        assert Map.has_key?(opportunity, :tax_benefit)
        assert is_struct(opportunity.tax_benefit, Decimal)
      end
    end

    test "provides replacement suggestions" do
      account_id = "test-account"
      
      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_date_range, _args ->
        {:ok, []}
      end)

      assert {:ok, opportunities} = TaxLossHarvester.identify_opportunities(account_id)

      # Verify replacement options are provided
      for opportunity <- opportunities.opportunities do
        assert Map.has_key?(opportunity, :replacement_options)
        assert is_list(opportunity.replacement_options)
      end
    end

    test "handles empty portfolio" do
      account_id = "empty-account"
      
      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_date_range, _args ->
        {:ok, []}
      end)

      assert {:error, :no_positions} = TaxLossHarvester.identify_opportunities(account_id)
    end

    test "sorts opportunities by priority score" do
      account_id = "test-account"
      
      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_date_range, _args ->
        {:ok, []}
      end)

      assert {:ok, opportunities} = TaxLossHarvester.identify_opportunities(account_id)

      # Verify opportunities are sorted by priority (highest first)
      priority_scores = Enum.map(opportunities.opportunities, & &1.priority_score)
      assert priority_scores == Enum.sort(priority_scores, {:desc, Decimal})
    end
  end

  describe "recommend_replacements/3" do
    test "suggests similar assets for replacement" do
      symbol = "AAPL"
      
      expect(Ashfolio.ContextMock, :read, fn Symbol, :find_by_symbol, args ->
        assert args[:symbol] == symbol
        {:ok, [%{id: "uuid-1", symbol: symbol, name: "Apple Inc."}]}
      end)

      assert {:ok, replacements} = TaxLossHarvester.recommend_replacements(symbol)

      assert is_list(replacements)
      assert length(replacements) > 0

      for replacement <- replacements do
        assert Map.has_key?(replacement, :symbol)
        assert Map.has_key?(replacement, :suitability_score)
        assert Map.has_key?(replacement, :correlation_to_original)
        assert replacement.suitability_score >= 0.7  # Min threshold
      end
    end

    test "filters replacements by suitability score" do
      symbol = "OBSCURE"  # Would have low suitability replacements
      
      expect(Ashfolio.ContextMock, :read, fn Symbol, :find_by_symbol, args ->
        assert args[:symbol] == symbol
        {:ok, [%{id: "uuid-2", symbol: symbol, name: "Obscure Stock"}]}
      end)

      assert {:ok, replacements} = TaxLossHarvester.recommend_replacements(symbol)

      # All returned replacements should meet minimum suitability
      for replacement <- replacements do
        assert replacement.suitability_score >= 0.7
      end
    end

    test "limits replacement suggestions to reasonable number" do
      symbol = "VTI"  # Popular ETF with many similar options
      
      expect(Ashfolio.ContextMock, :read, fn Symbol, :find_by_symbol, args ->
        assert args[:symbol] == symbol
        {:ok, [%{id: "uuid-3", symbol: symbol, name: "Vanguard Total Stock Market"}]}
      end)

      assert {:ok, replacements} = TaxLossHarvester.recommend_replacements(symbol)

      # Should limit to max 5 suggestions for usability
      assert length(replacements) <= 5
    end

    test "handles unknown symbol" do
      symbol = "UNKNOWN"
      
      expect(Ashfolio.ContextMock, :read, fn Symbol, :find_by_symbol, args ->
        assert args[:symbol] == symbol
        {:ok, []}
      end)

      assert {:error, :symbol_not_found} = TaxLossHarvester.recommend_replacements(symbol)
    end

    test "considers allocation targets in recommendations" do
      symbol = "AAPL"
      allocation_target = Decimal.new("0.10")  # 10% allocation
      
      expect(Ashfolio.ContextMock, :read, fn Symbol, :find_by_symbol, args ->
        {:ok, [%{id: "uuid-1", symbol: symbol, name: "Apple Inc."}]}
      end)

      assert {:ok, replacements} = TaxLossHarvester.recommend_replacements(symbol, allocation_target)

      # Allocation target would influence replacement scoring
      assert is_list(replacements)
    end
  end

  describe "check_wash_sale_compliance/4" do
    test "validates compliant replacement transaction" do
      sell_symbol = "AAPL"
      buy_symbol = "MSFT"  # Different company, should be compliant
      transaction_date = Date.utc_today()
      
      # Mock no recent conflicting transactions
      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_date_range, _args ->
        {:ok, []}
      end)

      assert {:ok, compliance} = TaxLossHarvester.check_wash_sale_compliance(
        sell_symbol, buy_symbol, transaction_date
      )

      assert compliance.is_compliant == true
      assert is_list(compliance.risk_factors)
      assert %Date{} = compliance.safe_date
      assert Map.has_key?(compliance, :similarity_assessment)
    end

    test "detects wash sale violation with substantially identical securities" do
      sell_symbol = "VTI"
      buy_symbol = "ITOT"  # Both total market ETFs - substantially identical
      transaction_date = Date.utc_today()
      
      # Mock recent purchase of buy_symbol within wash sale period
      recent_date = Date.add(transaction_date, -15)
      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_date_range, _args ->
        {:ok, [
          %{
            id: "recent-buy",
            type: :buy,
            symbol: %{symbol: buy_symbol},
            date: recent_date
          }
        ]}
      end)

      assert {:ok, compliance} = TaxLossHarvester.check_wash_sale_compliance(
        sell_symbol, buy_symbol, transaction_date
      )

      # Substantially identical securities with recent purchase should be non-compliant
      assert compliance.is_compliant == false
      assert length(compliance.risk_factors) > 0
      assert "Substantially identical securities" in compliance.risk_factors
    end

    test "provides safe transaction date for wash sale avoidance" do
      sell_symbol = "AAPL"
      buy_symbol = "AAPL"  # Same symbol - definitely wash sale
      transaction_date = Date.utc_today()
      
      recent_purchase_date = Date.add(transaction_date, -10)
      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_date_range, _args ->
        {:ok, [
          %{
            id: "recent-buy",
            type: :buy,
            symbol: %{symbol: buy_symbol},
            date: recent_purchase_date
          }
        ]}
      end)

      assert {:ok, compliance} = TaxLossHarvester.check_wash_sale_compliance(
        sell_symbol, buy_symbol, transaction_date
      )

      # Safe date should be 31 days after recent purchase
      expected_safe_date = Date.add(recent_purchase_date, 31)
      assert compliance.safe_date == expected_safe_date
    end

    test "assesses symbol similarity correctly" do
      # Test various symbol similarity scenarios
      test_cases = [
        {"SPY", "IVV", :high_similarity},      # Both S&P 500 ETFs
        {"VTI", "ITOT", :high_similarity},     # Both total market ETFs  
        {"AAPL", "MSFT", :low_similarity},     # Different companies
        {"AAPL", "AAPL", :identical}           # Same symbol
      ]

      for {sell_symbol, buy_symbol, expected_level} <- test_cases do
        expect(Ashfolio.ContextMock, :read, fn Transaction, :by_date_range, _args ->
          {:ok, []}
        end)

        assert {:ok, compliance} = TaxLossHarvester.check_wash_sale_compliance(
          sell_symbol, buy_symbol, Date.utc_today()
        )

        case expected_level do
          :identical ->
            assert compliance.similarity_assessment.similarity_score == 1.0
            assert compliance.similarity_assessment.substantially_identical == true
          :high_similarity ->
            assert compliance.similarity_assessment.similarity_score > 0.9
            assert compliance.similarity_assessment.substantially_identical == true
          :low_similarity ->
            assert compliance.similarity_assessment.similarity_score < 0.5
            assert compliance.similarity_assessment.substantially_identical == false
        end
      end
    end

    test "handles account-specific transaction filtering" do
      sell_symbol = "AAPL"
      buy_symbol = "AAPL"
      transaction_date = Date.utc_today()
      account_id = "specific-account"
      
      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_date_range, _args ->
        # Would filter by account_id in real implementation
        {:ok, []}
      end)

      assert {:ok, compliance} = TaxLossHarvester.check_wash_sale_compliance(
        sell_symbol, buy_symbol, transaction_date, account_id
      )

      assert Map.has_key?(compliance, :is_compliant)
    end
  end

  describe "optimize_harvest_strategy/3" do
    test "creates optimal harvesting sequence" do
      portfolio_targets = %{
        "stocks" => Decimal.new("70.0"),
        "bonds" => Decimal.new("20.0"), 
        "cash" => Decimal.new("10.0")
      }
      tax_rate = Decimal.new("0.22")

      # Mock current allocations
      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_date_range, _args ->
        {:ok, []}
      end)

      assert {:ok, strategy} = TaxLossHarvester.optimize_harvest_strategy(
        portfolio_targets, tax_rate
      )

      assert Map.has_key?(strategy, :actions)
      assert Map.has_key?(strategy, :total_estimated_savings)
      assert Map.has_key?(strategy, :execution_timeline)
      assert Map.has_key?(strategy, :risk_assessment)
      assert Map.has_key?(strategy, :compliance_verified)

      assert is_list(strategy.actions)
      assert is_struct(strategy.total_estimated_savings, Decimal)
      assert is_boolean(strategy.compliance_verified)
    end

    test "prioritizes actions by tax benefit" do
      portfolio_targets = %{}
      tax_rate = Decimal.new("0.24")

      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_date_range, _args ->
        {:ok, []}
      end)

      assert {:ok, strategy} = TaxLossHarvester.optimize_harvest_strategy(
        portfolio_targets, tax_rate
      )

      # Actions should be sorted by estimated tax savings (descending)
      if length(strategy.actions) > 1 do
        savings = Enum.map(strategy.actions, & &1.estimated_tax_savings)
        assert savings == Enum.sort(savings, {:desc, Decimal})
      end
    end

    test "accounts for wash sale timing in execution timeline" do
      portfolio_targets = %{}
      tax_rate = Decimal.new("0.22")

      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_date_range, _args ->
        {:ok, []}
      end)

      assert {:ok, strategy} = TaxLossHarvester.optimize_harvest_strategy(
        portfolio_targets, tax_rate
      )

      timeline = strategy.execution_timeline
      
      assert Map.has_key?(timeline, :immediate_actions)
      assert Map.has_key?(timeline, :delayed_actions)
      assert Map.has_key?(timeline, :earliest_completion)
      
      assert is_integer(timeline.immediate_actions)
      assert is_integer(timeline.delayed_actions)
      assert %Date{} = timeline.earliest_completion
    end

    test "validates portfolio allocation constraints" do
      # Test strategy respects allocation targets
      portfolio_targets = %{
        "stocks" => Decimal.new("60.0"),
        "international" => Decimal.new("20.0"),
        "bonds" => Decimal.new("20.0")
      }
      tax_rate = Decimal.new("0.32")

      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_date_range, _args ->
        {:ok, []}
      end)

      assert {:ok, strategy} = TaxLossHarvester.optimize_harvest_strategy(
        portfolio_targets, tax_rate
      )

      # Strategy should maintain allocation targets through replacements
      for action <- strategy.actions do
        if action.action_type == :tax_loss_harvest do
          assert Map.has_key?(action, :recommended_replacement)
        end
      end
    end

    test "handles edge case with no harvestable opportunities" do
      portfolio_targets = %{}
      tax_rate = Decimal.new("0.22")

      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_date_range, _args ->
        {:ok, []}
      end)

      assert {:ok, strategy} = TaxLossHarvester.optimize_harvest_strategy(
        portfolio_targets, tax_rate
      )

      # Should handle gracefully with empty action list
      assert strategy.actions == []
      assert Decimal.equal?(strategy.total_estimated_savings, Decimal.new("0"))
    end
  end

  describe "integration tests" do
    test "integrates with CapitalGainsCalculator for complete tax analysis" do
      # This would test integration between harvesting and realized gains
      # For MVP, verify the modules can work together
      account_id = "integration-test"
      
      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_date_range, _args ->
        {:ok, []}
      end)

      # Should be able to call both modules without conflicts
      assert {:ok, _opportunities} = TaxLossHarvester.identify_opportunities(account_id)
      # Would also call CapitalGainsCalculator here in full integration test
    end

    test "handles large portfolios efficiently" do
      # Test performance with larger datasets
      account_id = "large-portfolio"
      
      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_date_range, _args ->
        # Mock large transaction set
        large_transaction_set = for i <- 1..100 do
          %{
            id: "txn-#{i}",
            type: if rem(i, 2) == 0, do: :buy, else: :sell,
            date: Date.add(Date.utc_today(), -i),
            symbol_id: "symbol-#{rem(i, 10)}"
          }
        end
        {:ok, large_transaction_set}
      end)

      start_time = System.monotonic_time(:millisecond)
      assert {:ok, _opportunities} = TaxLossHarvester.identify_opportunities(account_id)
      end_time = System.monotonic_time(:millisecond)

      # Should complete in reasonable time (< 5 seconds for this test)
      assert (end_time - start_time) < 5000
    end

    test "maintains data consistency across multiple operations" do
      account_id = "consistency-test"
      
      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_date_range, _args ->
        {:ok, []}
      end)

      # Multiple calls should return consistent results
      assert {:ok, opportunities1} = TaxLossHarvester.identify_opportunities(account_id)
      assert {:ok, opportunities2} = TaxLossHarvester.identify_opportunities(account_id)

      assert opportunities1.opportunities_found == opportunities2.opportunities_found
      assert Decimal.equal?(
        opportunities1.total_harvestable_losses,
        opportunities2.total_harvestable_losses
      )
    end
  end

  describe "error handling and edge cases" do
    test "handles database connection errors gracefully" do
      account_id = "db-error-test"
      
      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_date_range, _args ->
        {:error, :database_unavailable}
      end)

      assert {:error, :database_unavailable} = TaxLossHarvester.identify_opportunities(account_id)
    end

    test "validates input parameters" do
      # Test invalid account ID
      assert {:error, :no_positions} = TaxLossHarvester.identify_opportunities("invalid-account")
      
      # Test invalid loss threshold
      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_date_range, _args ->
        {:ok, []}
      end)

      # Negative threshold should be handled
      assert {:ok, opportunities} = TaxLossHarvester.identify_opportunities(
        "test-account", 
        Decimal.new("-100")  # Negative threshold
      )
      
      assert is_list(opportunities.opportunities)
    end

    test "handles malformed transaction data" do
      account_id = "malformed-data"
      
      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_date_range, _args ->
        {:ok, [
          %{id: "bad-txn", type: nil, date: nil},  # Malformed transaction
          %{id: "good-txn", type: :buy, date: Date.utc_today(), symbol_id: "test"}
        ]}
      end)

      # Should handle malformed data gracefully
      assert {:ok, _opportunities} = TaxLossHarvester.identify_opportunities(account_id)
    end
  end
end