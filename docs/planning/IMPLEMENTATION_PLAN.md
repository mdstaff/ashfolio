# v0.8.0 Implementation Plan - Estate Planning & Advanced Tax Strategies

> Status: PLANNING PHASE 📋 | Target Branch: feature/v0.8.0-estate-planning
> Start Date: October 2025 | Target Completion: Q1 2026 (12 weeks)
>
> **Planning**: Estate Planning Foundation, Multi-Broker Risk Management, Alternative Minimum Tax, Cryptocurrency Tax Compliance

## Executive Summary

Build comprehensive estate planning and advanced tax strategy capabilities extending the existing tax planning foundation with sophisticated wealth transfer optimization, multi-broker coordination, and cryptocurrency compliance. Focus on CFP/CPA professional standards with emphasis on regulatory compliance and audit-ready documentation. All development follows strict TDD methodology with performance benchmarks of <2s for complex tax calculations.

## v0.7.0 Achievement Summary (Completed September 21, 2025)

### ✅ Advanced Portfolio Analytics - COMPLETE

**Total Implementation**: 124+ new tests, all 4 stages complete with comprehensive LiveView integration

#### Stage 1: Risk Metrics Suite ✅
- **BetaCalculator** - Portfolio systematic risk (20 tests, <25ms)
- **DrawdownCalculator** - Maximum drawdown analysis (24 tests, <15ms)
- **Enhanced RiskMetricsCalculator** - Calmar & Sterling ratios (13 new tests)

#### Stage 2: Correlation & Covariance ✅
- **CorrelationCalculator** - Pearson correlation, matrices, rolling windows (27 tests)
- **CovarianceCalculator** - Pairwise and matrix calculations (16 tests)

#### Stage 3: Portfolio Optimization ✅
- **PortfolioOptimizer** - Two-asset analytical optimization with Markowitz formulas (12 tests, <100ms)
- **EfficientFrontier** - Complete frontier generator with analytical and simplified approaches (12 tests, <200ms)

#### Stage 4: Advanced Analytics LiveView Dashboard ✅
- **Interactive UI** - Efficient frontier visualization with portfolio allocations
- **Real-time Integration** - Performance cache and PubSub updates
- **Professional Styling** - Color-coded portfolio cards and comprehensive help documentation

---

## 🎯 v0.8.0 Value-Driven Success Criteria

### Professional Estate Planning Standards
- [ ] **Beneficiary Management** - Complete primary/contingent tracking with legal compliance
- [ ] **Step-Up Basis Modeling** - Accurate estate tax planning calculations
- [ ] **Gift Tax Integration** - Annual exclusion monitoring with multi-year planning
- [ ] **Trust Account Foundation** - Revocable/irrevocable trust basics

### Advanced Tax Compliance
- [ ] **Multi-Broker Coordination** - Cross-platform wash sale prevention and position tracking
- [ ] **Alternative Minimum Tax** - Complete AMT calculation engine with ISO optimization
- [ ] **Cryptocurrency Compliance** - FIFO/LIFO cost basis with DeFi transaction support
- [ ] **Professional Documentation** - Audit-ready tax reports and compliance documentation

### Technical Integration Excellence
- [ ] **Seamless Integration** with existing TaxPlanningLive and portfolio modules
- [ ] **Performance Standards** - <2s for complex estate calculations, <500ms for standard tax ops
- [ ] **Zero Compilation Warnings** and full Decimal precision throughout
- [ ] **Comprehensive Testing** - 200+ new tests with estate planning and tax edge cases

---

## Stage 1: Estate Planning Foundation [12 WEEKS] 📋

**Deliverable**: Complete beneficiary management and step-up basis calculation system

### 🎯 Sprint 1: Beneficiary Management System (Weeks 1-3)

#### Task 1.1: Beneficiary Resource & Management (Week 1)
**TDD Test Specifications**:
```elixir
test "creates primary and contingent beneficiaries" do
  account = create_test_account()

  primary = create_beneficiary(%{
    account_id: account.id,
    name: "Jane Doe",
    relationship: "spouse",
    percentage: 100.0,
    beneficiary_type: "primary"
  })

  contingent = create_beneficiary(%{
    account_id: account.id,
    name: "John Doe Jr",
    relationship: "child",
    percentage: 50.0,
    beneficiary_type: "contingent"
  })

  assert primary.percentage == 100.0
  assert contingent.percentage == 50.0
  assert primary.beneficiary_type == "primary"
end

test "validates beneficiary percentage totals" do
  account = create_test_account()

  create_beneficiary(%{account_id: account.id, percentage: 60.0, beneficiary_type: "primary"})

  # Should fail - exceeds 100%
  assert {:error, _} = create_beneficiary(%{
    account_id: account.id,
    percentage: 50.0,
    beneficiary_type: "primary"
  })
end
```

#### Task 1.2: Step-Up Basis Calculator (Week 2)
**TDD Test Specifications**:
```elixir
test "calculates step-up basis for inherited assets" do
  # Asset bought at $50, dies when worth $100
  inherited_position = %{
    original_cost_basis: D.new("50.00"),
    fair_market_value_at_death: D.new("100.00"),
    date_of_death: ~D[2025-06-15],
    acquisition_date: ~D[2020-01-01]
  }

  {:ok, step_up} = StepUpBasisCalculator.calculate(inherited_position)

  assert D.equal?(step_up.new_cost_basis, D.new("100.00"))
  assert step_up.step_up_amount == D.new("50.00")
  assert step_up.eliminated_gain == D.new("50.00")
end

test "handles alternate valuation date election" do
  # Can elect 6 months after death if lower value
  inherited_position = %{
    fair_market_value_at_death: D.new("100.00"),
    fair_market_value_6_months_later: D.new("85.00"),
    date_of_death: ~D[2025-06-15]
  }

  {:ok, election} = StepUpBasisCalculator.alternate_valuation_election(inherited_position)

  # Should elect alternate date for lower basis
  assert election.should_elect == true
  assert D.equal?(election.elected_basis, D.new("85.00"))
  assert election.tax_savings > D.new("0")
end
```

#### Task 1.3: Gift Tax Tracking (Week 3)
**TDD Test Specifications**:
```elixir
test "tracks annual exclusion limits" do
  # 2025 annual exclusion: $18,000 per recipient
  gift = %{
    donor: "John Doe",
    recipient: "Jane Doe",
    gift_date: ~D[2025-03-15],
    fair_market_value: D.new("15000.00"),
    gift_type: "cash"
  }

  {:ok, tracking} = GiftTaxCalculator.track_gift(gift)

  assert tracking.annual_exclusion_used == D.new("15000.00")
  assert tracking.remaining_exclusion == D.new("3000.00")  # 18,000 - 15,000
  assert tracking.taxable_gift == D.new("0")
end

test "calculates gift tax on excess over exclusion" do
  large_gift = %{
    donor: "John Doe",
    recipient: "Jane Doe",
    gift_date: ~D[2025-03-15],
    fair_market_value: D.new("25000.00"),
    gift_type: "cash"
  }

  {:ok, tracking} = GiftTaxCalculator.track_gift(large_gift)

  assert tracking.taxable_gift == D.new("7000.00")  # 25,000 - 18,000
  assert tracking.lifetime_exemption_used > D.new("0")
end
```

### 🎯 Sprint 2: Trust Account Support (Weeks 4-6)

#### Task 1.4: Trust Account Foundation
**Focus**: Basic revocable/irrevocable trust account types with grantor trust rules

#### Task 1.5: Inherited Asset Tracking
**Focus**: Basis tracking and date maintenance for inherited positions

### 🎯 Sprint 3: Estate Tax Calculator (Weeks 7-9)

#### Task 1.6: Federal Estate Tax
**Focus**: Federal exemption tracking and estate tax estimation

#### Task 1.7: State Estate Tax
**Focus**: State-specific estate tax rules and calculations

---

## Stage 2: Multi-Broker Risk Management [8 WEEKS] 📋

**Deliverable**: Cross-broker wash sale detection and consolidated position tracking

### 🎯 Sprint 1: Cross-Broker Wash Sale Prevention (Weeks 1-4)

#### Task 2.1: Multi-Broker Transaction Coordination
**TDD Test Specifications**:
```elixir
test "detects wash sale across multiple brokers" do
  # Sell AAPL at loss in Broker A
  sale_broker_a = create_transaction(%{
    symbol: "AAPL",
    transaction_type: "sell",
    quantity: 100,
    price: D.new("150.00"),
    date: ~D[2025-01-15],
    broker: "Fidelity"
  })

  # Buy AAPL in Broker B within 30 days
  purchase_broker_b = create_transaction(%{
    symbol: "AAPL",
    transaction_type: "buy",
    quantity: 50,
    price: D.new("148.00"),
    date: ~D[2025-02-01],  # 17 days later
    broker: "Schwab"
  })

  {:ok, wash_sale} = WashSaleDetector.analyze_cross_broker([sale_broker_a, purchase_broker_b])

  assert wash_sale.violation_detected == true
  assert wash_sale.disallowed_loss > D.new("0")
  assert wash_sale.affected_quantity == 50  # Partial wash sale
end
```

#### Task 2.2: Consolidated Position Tracking
**Focus**: Total exposure calculation across all brokers

### 🎯 Sprint 2: Historical Data Recovery (Weeks 5-8)

#### Task 2.3: Basis Reconstruction Tools
**Focus**: Rebuild cost basis from partial data and transfers

---

## Stage 3: Alternative Minimum Tax (AMT) [6 WEEKS] 📋

**Deliverable**: Complete AMT calculation engine with ISO optimization

### 🎯 Sprint 1: AMT Calculation Engine (Weeks 1-3)

#### Task 3.1: ISO Exercise Planning
**TDD Test Specifications**:
```elixir
test "optimizes ISO exercise to minimize AMT" do
  iso_grant = %{
    grant_date: ~D[2023-01-01],
    exercise_price: D.new("10.00"),
    current_fair_value: D.new("50.00"),
    shares_available: 1000,
    vesting_schedule: "25% yearly"
  }

  {:ok, optimization} = ISOOptimizer.calculate_exercise_strategy(iso_grant)

  # Should recommend partial exercise to stay under AMT threshold
  assert optimization.recommended_shares < 1000
  assert optimization.amt_triggered == false
  assert optimization.regular_tax < optimization.amt_if_full_exercise
end
```

#### Task 3.2: AMT Credit Tracking
**Focus**: Carryforward management and utilization optimization

### 🎯 Sprint 2: Multi-Year AMT Planning (Weeks 4-6)

#### Task 3.3: Strategic Timing Optimization
**Focus**: Multi-year exercise and timing strategies

---

## Stage 4: Cryptocurrency Tax Compliance [6 WEEKS] 📋

**Deliverable**: Complete crypto tax engine with DeFi support

### 🎯 Sprint 1: Crypto Cost Basis Engine (Weeks 1-3)

#### Task 4.1: Multi-Method Cost Basis
**TDD Test Specifications**:
```elixir
test "calculates FIFO cost basis for crypto sales" do
  purchases = [
    %{date: ~D[2024-01-01], amount: D.new("1.0"), price: D.new("40000.00"), symbol: "BTC"},
    %{date: ~D[2024-02-01], amount: D.new("0.5"), price: D.new("45000.00"), symbol: "BTC"}
  ]

  sale = %{
    date: ~D[2024-06-01],
    amount: D.new("0.8"),
    price: D.new("60000.00"),
    symbol: "BTC"
  }

  {:ok, tax_result} = CryptoCostBasisCalculator.calculate_fifo(purchases, sale)

  # Should use first 0.8 BTC (0.8 from first purchase)
  assert D.equal?(tax_result.cost_basis, D.new("32000.00"))  # 0.8 * 40000
  assert D.equal?(tax_result.proceeds, D.new("48000.00"))    # 0.8 * 60000
  assert D.equal?(tax_result.capital_gain, D.new("16000.00"))
end
```

#### Task 4.2: DeFi Transaction Classification
**Focus**: Yield farming, liquidity provision, and staking income classification

### 🎯 Sprint 2: Mining & NFT Support (Weeks 4-6)

#### Task 4.3: Mining Income Tracking
**Focus**: Ordinary income recognition and basis calculations

#### Task 4.4: NFT Collectibles Tax
**Focus**: 28% collectibles rate and like-kind restrictions

---

## LiveView Integration Requirements

### Estate Planning LiveView
```elixir
test "displays beneficiary management interface" do
  {:ok, view, html} = live(conn, ~p"/estate-planning")

  assert html =~ "Beneficiary Management"
  assert html =~ "Primary Beneficiaries"
  assert html =~ "Contingent Beneficiaries"
  assert html =~ "Step-Up Basis Calculator"
end

test "validates beneficiary percentage allocation" do
  {:ok, view, _} = live(conn, ~p"/estate-planning/beneficiaries")

  # Add beneficiary exceeding 100%
  html = render_submit(view, :add_beneficiary, %{
    "beneficiary" => %{"percentage" => "60", "name" => "John Doe"}
  })

  assert html =~ "Total allocation cannot exceed 100%"
end
```

### Advanced Tax Planning Integration
```elixir
test "integrates AMT calculations with existing tax planning" do
  {:ok, view, _} = live(conn, ~p"/tax-planning")

  html = render_click(view, :calculate_amt, %{})

  assert html =~ "Alternative Minimum Tax"
  assert html =~ "AMT vs Regular Tax"
  assert html =~ "ISO Exercise Optimization"
end
```

---

## Performance Benchmarks

All new calculations must meet these performance targets:

```elixir
test "estate tax calculation under 2 seconds" do
  large_estate = generate_complex_estate(assets: 50, beneficiaries: 10)

  {time, {:ok, _result}} = :timer.tc(fn ->
    EstateTaxCalculator.calculate_full_estate(large_estate)
  end)

  assert time < 2_000_000  # 2 seconds in microseconds
end

test "crypto tax analysis under 1 second" do
  crypto_portfolio = generate_crypto_transactions(count: 1000)

  {time, {:ok, _analysis}} = :timer.tc(fn ->
    CryptoTaxAnalyzer.analyze_full_year(crypto_portfolio)
  end)

  assert time < 1_000_000  # 1 second
end
```

---

## Module Architecture

```
lib/ashfolio/estate_planning/
├── beneficiaries/
│   ├── beneficiary.ex
│   ├── beneficiary_manager.ex
│   └── percentage_validator.ex
├── calculators/
│   ├── step_up_basis_calculator.ex
│   ├── gift_tax_calculator.ex
│   └── estate_tax_calculator.ex
├── trusts/
│   ├── trust_account.ex
│   └── grantor_trust_rules.ex
└── inheritance/
    ├── inherited_asset.ex
    └── alternate_valuation.ex

lib/ashfolio/multi_broker/
├── wash_sale_detector.ex
├── position_consolidator.ex
└── transaction_coordinator.ex

lib/ashfolio/amt/
├── amt_calculator.ex
├── iso_optimizer.ex
└── amt_credit_tracker.ex

lib/ashfolio/crypto_tax/
├── cost_basis_calculator.ex
├── defi_classifier.ex
├── mining_tracker.ex
└── nft_tax_handler.ex

lib/ashfolio_web/live/estate_planning_live/
├── index.ex
├── beneficiaries.ex
├── trust_management.ex
└── step_up_calculator.ex
```

---

## Risk Mitigation Strategy

1. **Regulatory Complexity**: Implement modular tax engine for easy rule updates
2. **Multi-State Issues**: Configurable state-specific calculations
3. **Crypto Volatility**: Robust price tracking and basis calculations
4. **Estate Law Changes**: Flexible beneficiary and trust structures
5. **Integration Complexity**: Extensive integration testing with existing modules

---

## Documentation Requirements

Each calculator must include:
- IRS regulation references and compliance notes
- Mathematical formulas with tax code citations
- Example calculations with real-world scenarios
- Edge case handling for tax law complexities
- State-specific variations and considerations

---

## Completion Criteria

- [ ] All 4 primary stages complete with comprehensive tests
- [ ] 200+ new tests added, 100% passing
- [ ] Performance benchmarks met (<2s for estate calculations)
- [ ] LiveView integration complete with professional UI
- [ ] Documentation includes IRS references and compliance notes
- [ ] Code GPS shows proper integration with existing tax modules
- [ ] Ready for v0.8.0 release

---

## Success Validation Checklist

Before marking any stage complete:
- [ ] All tests written first (TDD)
- [ ] Tests include tax law edge cases
- [ ] Performance benchmarks met
- [ ] LiveView integration tested
- [ ] Documentation includes IRS references
- [ ] Code GPS shows integration
- [ ] No compilation warnings
- [ ] Mix format applied
- [ ] CFP/CPA review completed

---

*This plan builds on the successful v0.7.0 portfolio analytics foundation and extends Ashfolio's capabilities into sophisticated estate planning and advanced tax strategies, maintaining the highest professional standards for financial planning software.*