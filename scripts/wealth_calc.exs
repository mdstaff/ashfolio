defmodule WealthCalculator do
  @moduledoc """
  Calculates Wealth Scores (PAW), FI Timeline, and Sabbatical Impacts.
  """

  # --- Constants ---
  @safe_withdrawal_rate 0.04
  @investment_return 0.07 # Inflation-adjusted real return

  def run do
    IO.puts IO.ANSI.green() <> "\n--- 💰 ELIXIR WEALTH CALCULATOR ---" <> IO.ANSI.reset()

    # --- INPUTS ---
    age = get_input("Current Age")
    income = get_input("Annual Pre-Tax Income")
    net_worth = get_input("Total Value of Investments Today (Portfolio Value)")
    annual_spend = get_input("Target Annual Retirement Spend")
    current_savings = get_input("Annual Cash Contributions (New Savings per Year)")
    lifetime_earnings = get_input("Approximate Total Lifetime Earnings")

    # --- 1. WEALTH SCORES ---
    IO.puts IO.ANSI.cyan() <> "\n--- 🏆 WEALTH SCORES ---" <> IO.ANSI.reset()

    # PAW Score (Millionaire Next Door)
    expected_nw = (age * income) / 10
    paw_score = safe_div(net_worth, expected_nw)

    paw_status = cond do
      paw_score < 0.5 -> "Under Accumulator"
      paw_score < 2.0 -> "Average Accumulator"
      true -> "Prodigious Accumulator"
    end

    IO.puts "Expected Net Worth (PAW): #{format_money(expected_nw)}"
    IO.puts "PAW Score: #{Float.round(paw_score, 2)} (#{paw_status})"

    # Lifetime Wealth Ratio
    lwr = safe_div(net_worth, lifetime_earnings) * 100
    IO.puts "Lifetime Wealth Ratio: #{Float.round(lwr, 1)}% (Saved #{Float.round(lwr, 1)} cents of every dollar earned)"

    # --- 2. RETIREMENT TIMELINE ---
    fi_number = safe_div(annual_spend, @safe_withdrawal_rate)
    
    # Calculate Years to FI (NPER Logic)
    # Formula: n = ln((FV * r + c) / (PV * r + c)) / ln(1 + r)
    # Where c = annual contribution
    years_to_fi = calculate_years_to_target(net_worth, current_savings, fi_number, @investment_return)
    retire_age = age + years_to_fi

    IO.puts IO.ANSI.cyan() <> "\n--- 📅 EARLIEST RETIREMENT ---" <> IO.ANSI.reset()
    IO.puts "FI Number Needed: #{format_money(fi_number)}"
    
    if years_to_fi <= 0 do
      IO.puts "Status: You are Financially Independent today!"
    else
      IO.puts "Years to FI: #{Float.round(years_to_fi, 1)} years"
      IO.puts "Earliest Retirement Age: #{Float.round(retire_age, 1)}"
    end

    # --- 3. SABBATICAL IMPACT ---
    IO.puts IO.ANSI.cyan() <> "\n--- 🏝️ SABBATICAL SCENARIO (1 Year Off) ---" <> IO.ANSI.reset()
    sabbatical_cost = get_input("Total Cost of Sabbatical (Living + Travel)")

    # Scenario A: Baseline (No Sabbatical) wealth at T+1
    nw_baseline_next_year = (net_worth * (1 + @investment_return)) + current_savings

    # Scenario B: Sabbatical wealth at T+1
    # Assumption: You spend the cash (reducing principal) and add $0 savings.
    nw_sabbatical_next_year = (net_worth - sabbatical_cost) * (1 + @investment_return)

    # The Gap
    gap = nw_baseline_next_year - nw_sabbatical_next_year
    
    # Recovery Time
    recovery_years = safe_div(gap, current_savings)
    total_delay = 1 + recovery_years
    new_retire_age = retire_age + total_delay

    IO.puts "Cost of Sabbatical (Cash Out): #{format_money(sabbatical_cost)}"
    IO.puts "Opportunity Cost (Lost Growth + Lost Savings): #{format_money(gap)}"
    IO.puts IO.ANSI.red() <> "Total Retirement Delay: #{Float.round(total_delay, 1)} years" <> IO.ANSI.reset()
    IO.puts "New Retirement Age: #{Float.round(new_retire_age, 1)}"
  end

  # --- HELPERS ---

  defp calculate_years_to_target(pv, pmt, fv, r) do
    # Prevents log of negative numbers if you are already wealthy enough
    numerator = fv * r + pmt
    denominator = pv * r + pmt
    
    if denominator == 0 or numerator / denominator <= 0 do
      0.0
    else
      :math.log(numerator / denominator) / :math.log(1 + r)
    end
  end

  defp get_input(prompt) do
    IO.write("#{prompt}: ")
    input = IO.gets("") |> String.trim()
    
    case Float.parse(input) do
      {num, _} -> num
      :error -> 
        # Handle integer inputs elegantly
        case Integer.parse(input) do
          {num, _} -> num / 1
          :error -> 0.0
        end
    end
  end

  defp safe_div(_, d) when d == 0, do: 0.0
  defp safe_div(n, d), do: n / d

  defp format_money(amount) do
    "$" <> (:erlang.float_to_binary(amount, [decimals: 0]) |> separate_thousands())
  end

  # Regex helper to add commas to numbers
  defp separate_thousands(str) do
    str
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
    |> String.reverse()
  end
end

# Execute
WealthCalculator.run()
