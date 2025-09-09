defmodule Ashfolio.TaxPlanning.TaxLossHarvesterTest do
  use Ashfolio.DataCase, async: false

  alias Ashfolio.SQLiteHelpers
  alias Ashfolio.TaxPlanning.TaxLossHarvester

  @moduletag :ash_resources
  @moduletag :unit
  @moduletag :calculations
  @moduletag :fast

  describe "identify_opportunities/3" do
    setup do
      account =
        SQLiteHelpers.get_or_create_account(%{
          name: "Tax Loss Test Account",
          platform: "Test Platform"
        })

      %{account: account}
    end

    test "returns error with stub implementation", %{account: account} do
      loss_threshold = Decimal.new("100.00")

      # Test with real account but stub position data that returns :no_positions error
      assert {:error, :no_positions} = TaxLossHarvester.identify_opportunities(account.id, loss_threshold)
    end
  end

  describe "recommend_replacements/3" do
    test "provides replacement suggestions structure" do
      symbol = "AAPL"

      assert {:ok, replacements} = TaxLossHarvester.recommend_replacements(symbol)

      assert is_list(replacements)
      # Should return some replacements even with stub implementation
      assert length(replacements) > 0

      for replacement <- replacements do
        assert Map.has_key?(replacement, :symbol)
        assert Map.has_key?(replacement, :suitability_score)
      end
    end
  end

  describe "check_wash_sale_compliance/4" do
    test "validates wash sale compliance structure" do
      sell_symbol = "AAPL"
      buy_symbol = "MSFT"
      transaction_date = Date.utc_today()

      assert {:ok, compliance} =
               TaxLossHarvester.check_wash_sale_compliance(
                 sell_symbol,
                 buy_symbol,
                 transaction_date
               )

      assert Map.has_key?(compliance, :is_compliant)
      assert Map.has_key?(compliance, :risk_factors)
      assert Map.has_key?(compliance, :safe_date)
      assert Map.has_key?(compliance, :similarity_assessment)

      assert is_boolean(compliance.is_compliant)
      assert is_list(compliance.risk_factors)
      assert %Date{} = compliance.safe_date
    end
  end

  describe "optimize_harvest_strategy/3" do
    test "returns error with stub implementation" do
      portfolio_targets = %{
        "stocks" => Decimal.new("70.0"),
        "bonds" => Decimal.new("30.0")
      }

      tax_rate = Decimal.new("0.22")

      # Returns error because identify_opportunities returns :no_positions
      assert {:error, :no_positions} =
               TaxLossHarvester.optimize_harvest_strategy(portfolio_targets, tax_rate)
    end
  end
end
