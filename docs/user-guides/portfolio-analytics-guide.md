# Portfolio Analytics Guide

## Overview

Ashfolio provides professional-grade portfolio analytics including Time-Weighted Returns (TWR), Money-Weighted Returns (MWR/XIRR), risk metrics, and comprehensive performance attribution. This guide explains how to use these powerful tools to understand and optimize your investment performance.

## Performance Metrics

### Time-Weighted Return (TWR)

TWR measures the compound growth rate of your portfolio, eliminating the impact of deposits and withdrawals. This is the industry standard for comparing investment performance.

**When to Use TWR:**
- Comparing performance against benchmarks
- Evaluating investment manager performance
- Measuring strategy effectiveness
- Reporting standardized returns

**How It's Calculated:**
- Breaks period into sub-periods at each cash flow
- Calculates return for each sub-period
- Chains returns together geometrically

### Money-Weighted Return (MWR/XIRR)

MWR measures your actual investment experience, including the impact of your timing decisions on deposits and withdrawals.

**When to Use MWR:**
- Understanding personal investment returns
- Evaluating timing decisions
- Measuring actual wealth growth
- Planning based on historical experience

**Key Differences:**
- TWR: How well investments performed
- MWR: How well YOU performed as an investor
- Gap indicates timing impact

## Accessing Analytics

### Dashboard Navigation

1. Navigate to **Portfolio → Analytics** from main menu
2. Select analysis period (YTD, 1Y, 3Y, 5Y, Max, Custom)
3. Choose accounts to include/exclude
4. View comprehensive analytics dashboard

### Analytics Dashboard Components

**Performance Summary**
- Total return (absolute and percentage)
- TWR and MWR with variance analysis
- Benchmark comparison
- Risk-adjusted returns (Sharpe, Sortino)

**Visual Analytics**
- Performance chart with benchmark overlay
- Drawdown analysis
- Rolling returns
- Return distribution histogram

**Detailed Metrics**
- Volatility (standard deviation)
- Maximum drawdown
- Best/worst periods
- Win rate and profit factor

## Performance Analysis

### Return Calculation Methods

**Simple Return**
```
(Ending Value - Beginning Value) / Beginning Value
```

**Annualized Return**
```
(Ending Value / Beginning Value)^(365/Days) - 1
```

**Total Return (Including Dividends)**
```
(Ending Value + Dividends - Beginning Value) / Beginning Value
```

### Period Selection

Choose appropriate time periods for analysis:

- **YTD**: Current year performance
- **1 Year**: Recent performance and volatility
- **3 Years**: Medium-term track record
- **5 Years**: Long-term performance
- **10 Years**: Full market cycle analysis
- **Custom**: Specific date ranges

### Benchmark Comparison

Compare your portfolio against standard benchmarks:

**Available Benchmarks:**
- S&P 500 (broad market)
- NASDAQ Composite (tech-heavy)
- Russell 2000 (small cap)
- MSCI EAFE (international)
- AGG (bonds)
- 60/40 Portfolio (balanced)
- Custom benchmark

**Relative Performance Metrics:**
- Alpha (excess return)
- Beta (market sensitivity)
- Tracking error
- Information ratio

## Risk Analytics

### Volatility Metrics

**Standard Deviation**
- Measures return variability
- Annualized for comparison
- Higher = more volatile

**Downside Deviation**
- Only considers negative returns
- Better risk measure for investors
- Used in Sortino ratio

### Drawdown Analysis

**Maximum Drawdown**
- Largest peak-to-trough decline
- Key risk metric for investors
- Includes recovery time

**Drawdown Duration**
- Time to recover from drawdown
- Measures resilience
- Important for retirement planning

**Current Drawdown**
- Distance from all-time high
- Real-time risk indicator
- Rebalancing signal

### Risk-Adjusted Returns

**Sharpe Ratio**
```
(Return - Risk-Free Rate) / Standard Deviation
```
- Higher is better
- >1.0 is good
- >2.0 is excellent

**Sortino Ratio**
```
(Return - Risk-Free Rate) / Downside Deviation
```
- Focuses on downside risk
- Better for investor experience
- Higher is better

**Calmar Ratio**
```
Annualized Return / Maximum Drawdown
```
- Risk-adjusted for drawdowns
- >1.0 is acceptable
- >3.0 is excellent

## Attribution Analysis

### Performance Attribution

Understand what drives your returns:

**Asset Allocation Effect**
- Impact of asset class weights
- Strategic vs. tactical allocation
- Rebalancing impact

**Security Selection Effect**
- Individual investment performance
- Active vs. passive impact
- Manager skill measurement

**Currency Effect** (if applicable)
- Foreign exchange impact
- Hedging effectiveness
- Geographic exposure

### Sector Analysis

View performance by sector:
- Technology
- Healthcare
- Financials
- Consumer Discretionary
- Industrials
- Energy
- Materials
- Utilities
- Real Estate
- Communications

### Geographic Analysis

Performance by region:
- United States
- Developed International
- Emerging Markets
- Frontier Markets

## Advanced Analytics

### Rolling Returns

View performance consistency over time:

**Rolling Period Options:**
- 1-month rolling
- 3-month rolling
- 12-month rolling
- 36-month rolling

**Insights Provided:**
- Performance consistency
- Best/worst periods
- Trend identification
- Volatility patterns

### Correlation Analysis

Understand portfolio diversification:

**Correlation Matrix**
- Asset correlations
- Diversification effectiveness
- Risk concentration

**Correlation Trends**
- Changes over time
- Crisis correlations
- Regime changes

### Factor Analysis

Exposure to investment factors:
- Value vs. Growth
- Large vs. Small Cap
- Quality metrics
- Momentum indicators
- Low volatility

## Custom Analytics

### Create Custom Views

1. **Select Metrics**
   - Choose from 50+ metrics
   - Arrange dashboard layout
   - Save custom views

2. **Filter Options**
   - By account type
   - By asset class
   - By time period
   - By security

3. **Export Capabilities**
   - PDF reports
   - Excel worksheets
   - CSV data files
   - API access

### Performance Reports

Generate professional reports:

**Monthly Performance Report**
- Month-by-month returns
- YTD progression
- Comparison to benchmarks

**Quarterly Investment Review**
- Comprehensive analysis
- Attribution breakdown
- Risk metrics
- Recommendations

**Annual Summary**
- Full year analysis
- Tax implications
- Multi-year trends
- Planning insights

## Using Analytics for Decision Making

### Portfolio Optimization

Use analytics to improve portfolio:

1. **Identify Underperformers**
   - Compare security returns
   - Analyze expense ratios
   - Review turnover impact

2. **Assess Risk Level**
   - Check volatility vs. target
   - Review drawdown tolerance
   - Adjust if needed

3. **Rebalancing Triggers**
   - Deviation from targets
   - Risk metric changes
   - Correlation shifts

### Investment Selection

Evaluate new investments:

1. **Historical Analysis**
   - Past performance patterns
   - Risk characteristics
   - Correlation benefits

2. **Scenario Testing**
   - "What-if" analysis
   - Stress testing
   - Monte Carlo simulation

3. **Cost-Benefit Analysis**
   - Fee impact modeling
   - Tax implications
   - Expected improvement

## Mobile Analytics

Access key metrics on mobile:

**Mobile Dashboard**
- Performance summary
- Key risk metrics
- Recent activity
- Quick comparisons

**Mobile-Optimized Charts**
- Responsive design
- Touch interactions
- Simplified views
- Essential data only

## Analytics Best Practices

### Regular Review Schedule

**Daily**: Quick performance check
**Weekly**: Detailed performance review
**Monthly**: Full analytics review
**Quarterly**: Deep dive analysis
**Annually**: Comprehensive evaluation

### Common Pitfalls to Avoid

1. **Over-analyzing short-term data**
   - Focus on longer periods
   - Avoid daily volatility stress
   - Consider rolling averages

2. **Ignoring risk metrics**
   - Returns without risk misleading
   - Always consider risk-adjusted returns
   - Monitor drawdowns

3. **Benchmark mismatch**
   - Use appropriate benchmarks
   - Consider blended benchmarks
   - Account for asset allocation

### Professional Tips

1. **Focus on After-Tax Returns**
   - Pre-tax returns overstate performance
   - Consider tax drag
   - Plan for tax efficiency

2. **Use Multiple Metrics**
   - No single metric tells whole story
   - Combine TWR and MWR insights
   - Balance return and risk metrics

3. **Document Insights**
   - Keep investment journal
   - Note market conditions
   - Track decision rationale

## Troubleshooting

### Common Issues

**"Returns seem incorrect"**
- Verify all transactions imported
- Check dividend handling
- Ensure proper date ranges

**"TWR and MWR very different"**
- Normal with significant cash flows
- Indicates timing impact
- Review deposit/withdrawal timing

**"Missing benchmark data"**
- Some periods may lack data
- Try different benchmark
- Use custom benchmark option

## Integration with Other Features

### Tax Planning
- View after-tax returns
- Analyze tax efficiency
- Plan harvesting strategies

### Money Ratios
- Track capital growth targets
- Monitor savings progress
- Validate retirement readiness

### Financial Planning
- Use returns in projections
- Stress test with actual volatility
- Validate planning assumptions

## Additional Resources

- [Modern Portfolio Theory Primer](https://www.investopedia.com/terms/m/modernportfoliotheory.asp)
- [Understanding Investment Risk](https://www.morningstar.com/articles/risk)
- [Portfolio Management Guide](portfolio-management.md)
- [Tax Planning Guide](tax-planning-optimization.md)

---

*Last Updated: September 2024 | Version: 1.0*