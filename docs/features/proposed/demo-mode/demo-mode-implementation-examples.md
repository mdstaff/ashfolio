# Demo Mode Implementation Examples

## Table of Contents

1. [Demo Data Generation](#demo-data-generation)
2. [Tutorial System Components](#tutorial-system-components)
3. [Phoenix LiveView Implementation](#phoenix-liveview-implementation)
4. [JavaScript Tutorial Overlay](#javascript-tutorial-overlay)
5. [Playwright Automation Scripts](#playwright-automation-scripts)
6. [Analytics & Tracking](#analytics--tracking)

## Demo Data Generation

### Persona Generator Module

```elixir
defmodule Ashfolio.DemoMode.PersonaGenerator do
  @moduledoc """
  Generates realistic demo data for different investor personas.
  Each persona represents a different life stage and investment strategy.
  """

  alias Ashfolio.Portfolio.{User, Account, Transaction, Symbol}
  alias Ashfolio.FinancialManagement.{TransactionCategory, CategorySeeder}

  @personas %{
    sarah_starter: %{
      name: "Sarah Chen",
      age: 25,
      bio: "Software engineer, 2 years into career, learning to invest",
      net_worth: 15_000,
      risk_tolerance: :moderate,
      accounts: [
        %{name: "Robinhood", type: :investment, balance: 5_000, platform: "Robinhood"},
        %{name: "Chase Checking", type: :checking, balance: 3_000, platform: "Chase"},
        %{name: "Ally Savings", type: :savings, balance: 7_000, platform: "Ally", interest_rate: 4.25}
      ],
      portfolio_allocation: %{
        stocks: 0.60,
        etfs: 0.30,
        cash: 0.10
      },
      transactions_per_month: 2..4
    },

    mike_family: %{
      name: "Mike & Jennifer Walsh",
      age: 35,
      bio: "Married couple with 2 kids, balancing multiple financial goals",
      net_worth: 285_000,
      risk_tolerance: :moderate_conservative,
      accounts: [
        %{name: "Fidelity 401k", type: :investment, balance: 180_000, platform: "Fidelity"},
        %{name: "Vanguard IRA", type: :investment, balance: 45_000, platform: "Vanguard"},
        %{name: "529 College Fund", type: :investment, balance: 15_000, platform: "Vanguard"},
        %{name: "BofA Checking", type: :checking, balance: 20_000, platform: "Bank of America"},
        %{name: "Emergency Fund", type: :savings, balance: 25_000, platform: "Marcus", interest_rate: 4.50}
      ],
      portfolio_allocation: %{
        stocks: 0.40,
        etfs: 0.40,
        bonds: 0.15,
        cash: 0.05
      },
      transactions_per_month: 5..8
    },

    patricia_planner: %{
      name: "Patricia Thompson",
      age: 58,
      bio: "7 years from retirement, shifting to wealth preservation",
      net_worth: 1_250_000,
      risk_tolerance: :conservative,
      accounts: [
        %{name: "Schwab Trading", type: :investment, balance: 400_000, platform: "Charles Schwab"},
        %{name: "Fidelity IRA", type: :investment, balance: 500_000, platform: "Fidelity"},
        %{name: "TD Taxable", type: :investment, balance: 200_000, platform: "TD Ameritrade"},
        %{name: "Wells Checking", type: :checking, balance: 25_000, platform: "Wells Fargo"},
        %{name: "Marcus HYSA", type: :savings, balance: 100_000, platform: "Marcus", interest_rate: 4.40},
        %{name: "CD Ladder", type: :cd, balance: 25_000, platform: "Ally", interest_rate: 5.00}
      ],
      portfolio_allocation: %{
        stocks: 0.30,
        bonds: 0.40,
        dividend_stocks: 0.20,
        cash: 0.10
      },
      transactions_per_month: 8..12
    }
  }

  @popular_symbols %{
    stocks: [
      %{symbol: "AAPL", name: "Apple Inc.", category: "Growth"},
      %{symbol: "MSFT", name: "Microsoft Corporation", category: "Growth"},
      %{symbol: "GOOGL", name: "Alphabet Inc.", category: "Growth"},
      %{symbol: "JNJ", name: "Johnson & Johnson", category: "Income"},
      %{symbol: "JPM", name: "JPMorgan Chase", category: "Income"},
      %{symbol: "BRK.B", name: "Berkshire Hathaway", category: "Value"},
      %{symbol: "V", name: "Visa Inc.", category: "Growth"},
      %{symbol: "PG", name: "Procter & Gamble", category: "Income"},
      %{symbol: "NVDA", name: "NVIDIA Corporation", category: "Speculative"},
      %{symbol: "TSLA", name: "Tesla Inc.", category: "Speculative"}
    ],
    etfs: [
      %{symbol: "VOO", name: "Vanguard S&P 500 ETF", category: "Index"},
      %{symbol: "VTI", name: "Vanguard Total Stock Market ETF", category: "Index"},
      %{symbol: "VNQ", name: "Vanguard Real Estate ETF", category: "Real Estate"},
      %{symbol: "VXUS", name: "Vanguard International Stock ETF", category: "International"},
      %{symbol: "BND", name: "Vanguard Total Bond Market ETF", category: "Bonds"},
      %{symbol: "QQQ", name: "Invesco QQQ Trust", category: "Growth"},
      %{symbol: "SPY", name: "SPDR S&P 500 ETF", category: "Index"},
      %{symbol: "AGG", name: "iShares Core US Aggregate Bond ETF", category: "Bonds"}
    ],
    dividend_stocks: [
      %{symbol: "T", name: "AT&T Inc.", category: "Income"},
      %{symbol: "VZ", name: "Verizon Communications", category: "Income"},
      %{symbol: "KO", name: "Coca-Cola Company", category: "Income"},
      %{symbol: "PEP", name: "PepsiCo Inc.", category: "Income"},
      %{symbol: "MRK", name: "Merck & Co.", category: "Income"}
    ]
  }

  def generate_persona(persona_key, user_id) do
    persona = Map.fetch!(@personas, persona_key)

    with {:ok, accounts} <- create_demo_accounts(persona.accounts),
         {:ok, categories} <- seed_demo_categories(),
         {:ok, symbols} <- ensure_demo_symbols(),
         {:ok, transactions} <- generate_historical_transactions(
           user_id,
           accounts,
           symbols,
           categories,
           persona
         ) do

      {:ok, %{
        persona: persona,
        accounts: accounts,
        categories: categories,
        symbols: symbols,
        transactions: transactions,
        summary: calculate_demo_summary(accounts, transactions)
      }}
    end
  end

  defp create_demo_accounts(account_specs) do
    accounts = Enum.map(account_specs, fn spec ->
      {:ok, account} = Account.create(%{

        name: "#{spec.name} (Demo)",
        platform: spec.platform,
        account_type: spec.type,
        balance: Decimal.new(spec.balance),
        interest_rate: Map.get(spec, :interest_rate),
        currency: "USD",
        is_demo: true  # Custom field to identify demo data
      })
      account
    end)

    {:ok, accounts}
  end

  defp generate_historical_transactions(accounts, symbols, categories, persona) do
    # Generate 12 months of historical transactions
    today = Date.utc_today()

    transactions = for month_offset <- 0..11 do
      month_date = Date.add(today, -month_offset * 30)
      tx_count = Enum.random(persona.transactions_per_month)

      for _ <- 1..tx_count do
        generate_single_transaction(
          Enum.random(accounts),
          Enum.random(symbols),
          Enum.random(categories),
          month_date,
          persona.portfolio_allocation
        )
      end
    end
    |> List.flatten()

    {:ok, transactions}
  end

  defp generate_single_transaction(account, symbol, category, base_date, allocation) do
    # Generate realistic transaction based on allocation strategy
    transaction_type = weighted_random([:buy, :sell, :dividend], [0.70, 0.20, 0.10])

    quantity = case transaction_type do
      :buy -> Enum.random(1..100)
      :sell -> -Enum.random(1..50)
      :dividend -> Enum.random(10..200)
    end

    price = generate_realistic_price(symbol.symbol)

    {:ok, transaction} = Transaction.create(%{
      account_id: account.id,
      symbol_id: symbol.id,
      category_id: category.id,
      type: transaction_type,
      quantity: Decimal.new(quantity),
      price: price,
      total_amount: Decimal.mult(Decimal.new(quantity), price),
      date: Date.add(base_date, Enum.random(-15..15)),
      notes: generate_transaction_note(transaction_type)
    })

    transaction
  end

  defp generate_realistic_price(symbol) do
    # Generate realistic prices based on symbol
    base_prices = %{
      "AAPL" => 175.0,
      "MSFT" => 380.0,
      "GOOGL" => 140.0,
      "VOO" => 430.0,
      "VTI" => 230.0,
      "BND" => 75.0,
      "NVDA" => 480.0,
      "TSLA" => 240.0
    }

    base = Map.get(base_prices, symbol, 100.0)
    # Add some random variation (±10%)
    variation = base * (0.9 + :rand.uniform() * 0.2)
    Decimal.from_float(variation) |> Decimal.round(2)
  end

  defp generate_transaction_note(type) do
    notes = %{
      buy: [
        "Monthly investment",
        "Dip buying opportunity",
        "Rebalancing portfolio",
        "Dollar cost averaging",
        "Adding to position"
      ],
      sell: [
        "Taking profits",
        "Rebalancing",
        "Tax loss harvesting",
        "Need liquidity",
        "Reducing position"
      ],
      dividend: [
        "Quarterly dividend",
        "Dividend reinvestment",
        "Special dividend",
        "Annual dividend",
        "DRIP"
      ]
    }

    Enum.random(notes[type])
  end

  defp weighted_random(choices, weights) do
    total = Enum.sum(weights)
    threshold = :rand.uniform() * total

    weights
    |> Enum.zip(choices)
    |> Enum.reduce_while({0, nil}, fn {weight, choice}, {sum, _} ->
      new_sum = sum + weight
      if new_sum >= threshold do
        {:halt, {new_sum, choice}}
      else
        {:cont, {new_sum, nil}}
      end
    end)
    |> elem(1)
  end
end
```

## Tutorial System Components

### Tutorial Controller LiveView

```elixir
defmodule AshfolioWeb.TutorialLive do
  use AshfolioWeb, :live_view

  @tutorial_steps [
    %{
      id: :welcome,
      title: "Welcome to Ashfolio! 👋",
      content: "Let's take a quick tour of your new financial command center.",
      target: nil,
      action: :none,
      position: :center,
      can_skip: true
    },
    %{
      id: :dashboard_overview,
      title: "Your Financial Dashboard",
      content: "This is where you'll see your complete financial picture at a glance.",
      target: ".dashboard-container",
      action: :highlight,
      position: :bottom,
      can_skip: true
    },
    %{
      id: :net_worth,
      title: "Track Your Net Worth",
      content: "Your total net worth combines all investment and cash accounts. Watch it grow over time!",
      target: ".net-worth-card",
      action: :pulse,
      position: :bottom,
      demo_action: {:animate_number, "$125,000", "$126,543"}
    },
    %{
      id: :accounts_overview,
      title: "All Your Accounts",
      content: "Manage investment accounts, checking, savings, and more in one place.",
      target: ".accounts-grid",
      action: :highlight,
      position: :top
    },
    %{
      id: :add_transaction,
      title: "Recording Transactions",
      content: "Click here to add a new transaction. Try our smart symbol search!",
      target: ".add-transaction-btn",
      action: :pulse,
      position: :left,
      interactive: true,
      completion_event: "transaction_form_opened"
    },
    %{
      id: :symbol_search,
      title: "Smart Symbol Search",
      content: "Just start typing any ticker or company name. We'll find it instantly!",
      target: "[data-testid=symbol-search]",
      action: :focus,
      position: :bottom,
      demo_action: {:type_animation, "APP", ["AAPL - Apple Inc.", "APP - AppLovin"]}
    },
    %{
      id: :categories,
      title: "Organize with Categories",
      content: "Categories help you track different investment strategies: Growth, Income, Speculative, and more.",
      target: ".category-selector",
      action: :highlight,
      position: :top
    },
    %{
      id: :filtering,
      title: "Powerful Filtering",
      content: "Filter transactions by date, category, account, or amount. Find exactly what you need.",
      target: ".filter-controls",
      action: :highlight,
      position: :bottom,
      demo_action: {:apply_filter, :category, "Growth"}
    },
    %{
      id: :cash_accounts,
      title: "Cash Account Management",
      content: "Track your liquid assets alongside investments. Update balances manually or link accounts.",
      target: ".cash-accounts-section",
      action: :expand,
      position: :top
    },
    %{
      id: :recent_activity,
      title: "Recent Activity Feed",
      content: "See your latest transactions and account updates in real-time.",
      target: ".recent-activity",
      action: :scroll_to,
      position: :top
    },
    %{
      id: :completion,
      title: "You're All Set! 🎉",
      content: "You've learned the basics! Explore at your own pace, or switch to a real account when ready.",
      target: nil,
      action: :confetti,
      position: :center,
      buttons: [
        %{label: "Continue Exploring", action: :close},
        %{label: "Start Fresh", action: :reset_demo},
        %{label: "Create Real Account", action: :convert_to_real}
      ]
    }
  ]

  def mount(_params, session, socket) do
    {:ok,
     socket
     |> assign(:tutorial_active, false)
     |> assign(:current_step, 0)
     |> assign(:completed_steps, MapSet.new())
     |> assign(:tutorial_steps, @tutorial_steps)
     |> assign(:demo_mode, Map.get(session, "demo_mode", false))
     |> assign(:features_discovered, MapSet.new())
     |> assign(:skip_count, 0)}
  end

  def handle_event("start_tutorial", _params, socket) do
    {:noreply,
     socket
     |> assign(:tutorial_active, true)
     |> assign(:current_step, 0)
     |> push_event("tutorial:start", %{step: Enum.at(@tutorial_steps, 0)})}
  end

  def handle_event("tutorial:next", _params, socket) do
    next_step = socket.assigns.current_step + 1

    if next_step < length(@tutorial_steps) do
      step_data = Enum.at(@tutorial_steps, next_step)

      {:noreply,
       socket
       |> assign(:current_step, next_step)
       |> update(:completed_steps, &MapSet.put(&1, socket.assigns.current_step))
       |> push_event("tutorial:show_step", %{step: step_data})}
    else
      {:noreply, complete_tutorial(socket)}
    end
  end

  def handle_event("tutorial:previous", _params, socket) do
    previous_step = max(0, socket.assigns.current_step - 1)
    step_data = Enum.at(@tutorial_steps, previous_step)

    {:noreply,
     socket
     |> assign(:current_step, previous_step)
     |> push_event("tutorial:show_step", %{step: step_data})}
  end

  def handle_event("tutorial:skip", _params, socket) do
    {:noreply,
     socket
     |> update(:skip_count, &(&1 + 1))
     |> complete_tutorial()
     |> put_flash(:info, "Tutorial skipped. You can restart it anytime from the help menu.")}
  end

  def handle_event("feature_discovered", %{"feature" => feature}, socket) do
    {:noreply,
     socket
     |> update(:features_discovered, &MapSet.put(&1, feature))
     |> maybe_show_achievement(feature)}
  end

  defp complete_tutorial(socket) do
    socket
    |> assign(:tutorial_active, false)
    |> push_event("tutorial:complete", %{
      completed_steps: MapSet.size(socket.assigns.completed_steps),
      total_steps: length(@tutorial_steps),
      features_discovered: MapSet.to_list(socket.assigns.features_discovered)
    })
    |> track_tutorial_completion()
  end

  defp maybe_show_achievement(socket, feature) do
    achievements = %{
      "category_filter" => %{
        title: "Organization Master",
        description: "You've discovered category filtering!",
        icon: "🏷️",
        points: 10
      },
      "symbol_search" => %{
        title: "Search Wizard",
        description: "Smart symbol search unlocked!",
        icon: "🔍",
        points: 15
      },
      "balance_update" => %{
        title: "Balance Keeper",
        description: "Manual balance updates mastered!",
        icon: "💰",
        points: 20
      }
    }

    if achievement = achievements[feature] do
      push_event(socket, "achievement:show", achievement)
    else
      socket
    end
  end

  defp track_tutorial_completion(socket) do
    # Analytics tracking
    :telemetry.execute(
      [:ashfolio, :tutorial, :completed],
      %{
        duration: DateTime.utc_now(),
        steps_completed: MapSet.size(socket.assigns.completed_steps),
        steps_total: length(@tutorial_steps),
        features_discovered: MapSet.size(socket.assigns.features_discovered),
        skip_count: socket.assigns.skip_count
      }
    )

    socket
  end
end
```

## JavaScript Tutorial Overlay

### Tutorial Overlay Hook

```javascript
// assets/js/hooks/tutorial_overlay.js

export const TutorialOverlay = {
  mounted() {
    this.overlay = null;
    this.tooltip = null;
    this.spotlight = null;
    this.currentStep = null;

    this.handleEvent("tutorial:start", (payload) => {
      this.startTutorial(payload.step);
    });

    this.handleEvent("tutorial:show_step", (payload) => {
      this.showStep(payload.step);
    });

    this.handleEvent("tutorial:complete", (payload) => {
      this.completeTutorial(payload);
    });

    this.handleEvent("achievement:show", (payload) => {
      this.showAchievement(payload);
    });
  },

  startTutorial(step) {
    // Create overlay elements
    this.createOverlay();
    this.showStep(step);
  },

  createOverlay() {
    // Create semi-transparent overlay
    this.overlay = document.createElement("div");
    this.overlay.className = "tutorial-overlay";
    this.overlay.innerHTML = `
      <div class="tutorial-backdrop"></div>
      <div class="tutorial-spotlight"></div>
      <div class="tutorial-tooltip">
        <div class="tutorial-tooltip-arrow"></div>
        <div class="tutorial-tooltip-content">
          <h3 class="tutorial-title"></h3>
          <p class="tutorial-content"></p>
          <div class="tutorial-demo-area"></div>
          <div class="tutorial-actions">
            <button class="tutorial-skip">Skip</button>
            <div class="tutorial-navigation">
              <button class="tutorial-previous">Previous</button>
              <span class="tutorial-progress"></span>
              <button class="tutorial-next">Next</button>
            </div>
          </div>
        </div>
      </div>
    `;

    document.body.appendChild(this.overlay);

    // Bind events
    this.overlay
      .querySelector(".tutorial-skip")
      .addEventListener("click", () => {
        this.pushEvent("tutorial:skip", {});
      });

    this.overlay
      .querySelector(".tutorial-previous")
      .addEventListener("click", () => {
        this.pushEvent("tutorial:previous", {});
      });

    this.overlay
      .querySelector(".tutorial-next")
      .addEventListener("click", () => {
        this.pushEvent("tutorial:next", {});
      });
  },

  showStep(step) {
    this.currentStep = step;

    // Update content
    this.overlay.querySelector(".tutorial-title").textContent = step.title;
    this.overlay.querySelector(".tutorial-content").textContent = step.content;

    // Handle targeting and positioning
    if (step.target) {
      const targetElement = document.querySelector(step.target);
      if (targetElement) {
        this.highlightElement(targetElement, step.action);
        this.positionTooltip(targetElement, step.position);

        // Handle interactive steps
        if (step.interactive) {
          this.setupInteractiveStep(targetElement, step);
        }
      }
    } else {
      // Center the tooltip for non-targeted steps
      this.centerTooltip();
    }

    // Handle demo actions
    if (step.demo_action) {
      this.performDemoAction(step.demo_action);
    }

    // Update progress
    this.updateProgress(step);
  },

  highlightElement(element, action) {
    const rect = element.getBoundingClientRect();
    const spotlight = this.overlay.querySelector(".tutorial-spotlight");

    // Position spotlight
    spotlight.style.left = `${rect.left - 10}px`;
    spotlight.style.top = `${rect.top - 10}px`;
    spotlight.style.width = `${rect.width + 20}px`;
    spotlight.style.height = `${rect.height + 20}px`;
    spotlight.style.display = "block";

    // Apply action animation
    switch (action) {
      case "pulse":
        spotlight.classList.add("tutorial-pulse");
        break;
      case "highlight":
        spotlight.classList.add("tutorial-highlight");
        break;
      case "focus":
        element.focus();
        break;
      case "expand":
        element.classList.add("tutorial-expand");
        break;
      case "scroll_to":
        element.scrollIntoView({ behavior: "smooth", block: "center" });
        break;
    }
  },

  positionTooltip(targetElement, position) {
    const tooltip = this.overlay.querySelector(".tutorial-tooltip");
    const rect = targetElement.getBoundingClientRect();
    const tooltipRect = tooltip.getBoundingClientRect();

    let top, left;

    switch (position) {
      case "top":
        top = rect.top - tooltipRect.height - 20;
        left = rect.left + (rect.width - tooltipRect.width) / 2;
        break;
      case "bottom":
        top = rect.bottom + 20;
        left = rect.left + (rect.width - tooltipRect.width) / 2;
        break;
      case "left":
        top = rect.top + (rect.height - tooltipRect.height) / 2;
        left = rect.left - tooltipRect.width - 20;
        break;
      case "right":
        top = rect.top + (rect.height - tooltipRect.height) / 2;
        left = rect.right + 20;
        break;
      default:
        this.centerTooltip();
        return;
    }

    // Ensure tooltip stays within viewport
    top = Math.max(
      10,
      Math.min(top, window.innerHeight - tooltipRect.height - 10)
    );
    left = Math.max(
      10,
      Math.min(left, window.innerWidth - tooltipRect.width - 10)
    );

    tooltip.style.top = `${top}px`;
    tooltip.style.left = `${left}px`;
  },

  centerTooltip() {
    const tooltip = this.overlay.querySelector(".tutorial-tooltip");
    tooltip.style.top = "50%";
    tooltip.style.left = "50%";
    tooltip.style.transform = "translate(-50%, -50%)";
  },

  performDemoAction(action) {
    const [actionType, ...params] = action;

    switch (actionType) {
      case "animate_number":
        this.animateNumber(...params);
        break;
      case "type_animation":
        this.typeAnimation(...params);
        break;
      case "apply_filter":
        this.applyFilterDemo(...params);
        break;
    }
  },

  animateNumber(from, to) {
    const demoArea = this.overlay.querySelector(".tutorial-demo-area");
    demoArea.innerHTML = `<div class="number-animation">${from}</div>`;

    setTimeout(() => {
      const numberEl = demoArea.querySelector(".number-animation");
      numberEl.style.transform = "scale(1.2)";
      numberEl.textContent = to;

      setTimeout(() => {
        numberEl.style.transform = "scale(1)";
      }, 300);
    }, 1000);
  },

  typeAnimation(text, suggestions) {
    const demoArea = this.overlay.querySelector(".tutorial-demo-area");
    demoArea.innerHTML = `
      <div class="type-animation">
        <input type="text" class="demo-input" placeholder="Start typing..." />
        <div class="demo-suggestions"></div>
      </div>
    `;

    const input = demoArea.querySelector(".demo-input");
    const suggestionsEl = demoArea.querySelector(".demo-suggestions");

    // Simulate typing
    let index = 0;
    const typeInterval = setInterval(() => {
      if (index < text.length) {
        input.value = text.substring(0, index + 1);
        index++;

        // Show suggestions after 2 characters
        if (index === 2) {
          suggestionsEl.innerHTML = suggestions
            .map((s) => `<div class="suggestion-item">${s}</div>`)
            .join("");
          suggestionsEl.style.display = "block";
        }
      } else {
        clearInterval(typeInterval);
      }
    }, 200);
  },

  setupInteractiveStep(element, step) {
    // Make element interactive during tutorial
    element.classList.add("tutorial-interactive");

    const handler = (e) => {
      // Track interaction
      this.pushEvent("feature_discovered", { feature: step.id });

      // Continue to next step if completion event matches
      if (step.completion_event) {
        element.removeEventListener("click", handler);
        this.pushEvent("tutorial:next", {});
      }
    };

    element.addEventListener("click", handler);
  },

  updateProgress(step) {
    // Update progress indicator
    const progress = this.overlay.querySelector(".tutorial-progress");
    // Implementation would depend on having step index/total
  },

  completeTutorial(payload) {
    // Show completion celebration
    this.showCompletionScreen(payload);

    // Clean up after delay
    setTimeout(() => {
      this.cleanup();
    }, 5000);
  },

  showCompletionScreen(payload) {
    const content = this.overlay.querySelector(".tutorial-tooltip-content");
    content.innerHTML = `
      <div class="tutorial-complete">
        <div class="complete-icon">🎉</div>
        <h2>Tutorial Complete!</h2>
        <div class="complete-stats">
          <div class="stat">
            <span class="stat-value">${payload.completed_steps}</span>
            <span class="stat-label">Steps Completed</span>
          </div>
          <div class="stat">
            <span class="stat-value">${payload.features_discovered.length}</span>
            <span class="stat-label">Features Discovered</span>
          </div>
        </div>
        <button class="btn-primary" onclick="window.location.reload()">
          Start Exploring
        </button>
      </div>
    `;

    // Trigger confetti
    if (typeof confetti !== "undefined") {
      confetti({
        particleCount: 100,
        spread: 70,
        origin: { y: 0.6 },
      });
    }
  },

  showAchievement(achievement) {
    const achievementEl = document.createElement("div");
    achievementEl.className = "achievement-popup";
    achievementEl.innerHTML = `
      <div class="achievement-icon">${achievement.icon}</div>
      <div class="achievement-content">
        <h4>${achievement.title}</h4>
        <p>${achievement.description}</p>
        <div class="achievement-points">+${achievement.points} points</div>
      </div>
    `;

    document.body.appendChild(achievementEl);

    // Animate in
    setTimeout(() => achievementEl.classList.add("show"), 100);

    // Remove after delay
    setTimeout(() => {
      achievementEl.classList.remove("show");
      setTimeout(() => achievementEl.remove(), 300);
    }, 3000);
  },

  cleanup() {
    if (this.overlay) {
      this.overlay.remove();
      this.overlay = null;
    }

    // Remove any tutorial classes
    document.querySelectorAll(".tutorial-interactive").forEach((el) => {
      el.classList.remove("tutorial-interactive");
    });

    document.querySelectorAll(".tutorial-expand").forEach((el) => {
      el.classList.remove("tutorial-expand");
    });
  },
};
```

### Tutorial Styles

```css
/* assets/css/tutorial.css */

.tutorial-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 10000;
}

.tutorial-backdrop {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.7);
  backdrop-filter: blur(2px);
}

.tutorial-spotlight {
  position: absolute;
  border-radius: 8px;
  box-shadow: 0 0 0 9999px rgba(0, 0, 0, 0.7), 0 0 20px rgba(255, 255, 255, 0.5);
  pointer-events: none;
  transition: all 0.3s ease;
  display: none;
}

.tutorial-spotlight.tutorial-pulse {
  animation: pulse 2s infinite;
}

.tutorial-spotlight.tutorial-highlight {
  box-shadow: 0 0 0 9999px rgba(0, 0, 0, 0.7), 0 0 30px rgba(59, 130, 246, 0.8),
    inset 0 0 20px rgba(59, 130, 246, 0.2);
}

@keyframes pulse {
  0% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.02);
  }
  100% {
    transform: scale(1);
  }
}

.tutorial-tooltip {
  position: absolute;
  background: white;
  border-radius: 12px;
  padding: 24px;
  max-width: 400px;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  z-index: 10001;
  animation: slideIn 0.3s ease;
}

@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.tutorial-tooltip-arrow {
  position: absolute;
  width: 12px;
  height: 12px;
  background: white;
  transform: rotate(45deg);
}

.tutorial-title {
  font-size: 20px;
  font-weight: 600;
  margin: 0 0 12px 0;
  color: #1a1a1a;
}

.tutorial-content {
  font-size: 15px;
  line-height: 1.6;
  color: #4a4a4a;
  margin: 0 0 20px 0;
}

.tutorial-demo-area {
  margin: 16px 0;
  padding: 16px;
  background: #f8f9fa;
  border-radius: 8px;
}

.tutorial-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.tutorial-skip {
  background: none;
  border: none;
  color: #9ca3af;
  cursor: pointer;
  font-size: 14px;
  padding: 8px;
}

.tutorial-skip:hover {
  color: #6b7280;
}

.tutorial-navigation {
  display: flex;
  align-items: center;
  gap: 16px;
}

.tutorial-previous,
.tutorial-next {
  padding: 8px 16px;
  border-radius: 6px;
  border: 1px solid #e5e7eb;
  background: white;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  transition: all 0.2s;
}

.tutorial-next {
  background: #3b82f6;
  color: white;
  border-color: #3b82f6;
}

.tutorial-next:hover {
  background: #2563eb;
}

.tutorial-progress {
  font-size: 14px;
  color: #6b7280;
}

/* Achievement Popup */
.achievement-popup {
  position: fixed;
  top: 20px;
  right: 20px;
  background: white;
  border-radius: 12px;
  padding: 16px 20px;
  display: flex;
  align-items: center;
  gap: 16px;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
  transform: translateX(400px);
  transition: transform 0.3s ease;
  z-index: 10002;
}

.achievement-popup.show {
  transform: translateX(0);
}

.achievement-icon {
  font-size: 32px;
}

.achievement-content h4 {
  margin: 0 0 4px 0;
  font-size: 16px;
  font-weight: 600;
}

.achievement-content p {
  margin: 0 0 8px 0;
  font-size: 14px;
  color: #6b7280;
}

.achievement-points {
  font-size: 14px;
  font-weight: 600;
  color: #10b981;
}

/* Interactive Elements */
.tutorial-interactive {
  position: relative;
  z-index: 10002;
  cursor: pointer;
  animation: glow 2s infinite;
}

@keyframes glow {
  0%,
  100% {
    box-shadow: 0 0 5px rgba(59, 130, 246, 0.5);
  }
  50% {
    box-shadow: 0 0 20px rgba(59, 130, 246, 0.8);
  }
}

/* Demo Animations */
.number-animation {
  font-size: 32px;
  font-weight: bold;
  color: #10b981;
  transition: all 0.3s ease;
  text-align: center;
}

.type-animation .demo-input {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid #e5e7eb;
  border-radius: 6px;
  font-size: 14px;
}

.demo-suggestions {
  margin-top: 8px;
  border: 1px solid #e5e7eb;
  border-radius: 6px;
  background: white;
  display: none;
}

.suggestion-item {
  padding: 8px 12px;
  font-size: 14px;
  cursor: pointer;
  transition: background 0.2s;
}

.suggestion-item:hover {
  background: #f3f4f6;
}

/* Completion Screen */
.tutorial-complete {
  text-align: center;
}

.complete-icon {
  font-size: 64px;
  margin-bottom: 16px;
}

.complete-stats {
  display: flex;
  justify-content: center;
  gap: 32px;
  margin: 24px 0;
}

.stat {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.stat-value {
  font-size: 32px;
  font-weight: bold;
  color: #3b82f6;
}

.stat-label {
  font-size: 14px;
  color: #6b7280;
  margin-top: 4px;
}

.btn-primary {
  background: #3b82f6;
  color: white;
  padding: 12px 24px;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 500;
  cursor: pointer;
  transition: background 0.2s;
}

.btn-primary:hover {
  background: #2563eb;
}
```

## Playwright Automation Scripts

### Demo Mode Showcase Script

```javascript
// test/e2e/demo_showcase.spec.js

const { test, expect } = require("@playwright/test");

test.describe("Demo Mode Showcase", () => {
  test("Complete investor journey - Sarah Starter", async ({
    page,
    browser,
  }) => {
    // Start recording for demo video
    const context = await browser.newContext({
      recordVideo: {
        dir: "./demo-videos/",
        size: { width: 1920, height: 1080 },
      },
    });

    const page = await context.newPage();

    // Navigate to app and start demo mode
    await page.goto("http://localhost:4000");
    await page.click("text=Try Demo Mode");
    await page.click("text=Sarah Chen - Starting Investor");

    // Wait for demo data to load
    await page.waitForSelector(".demo-banner");

    // Take screenshot of dashboard
    await page.screenshot({
      path: "screenshots/sarah-dashboard.png",
      fullPage: true,
    });

    // Showcase net worth display
    await page.hover(".net-worth-card");
    await page.waitForTimeout(1000);

    // Navigate to accounts
    await page.click("text=Accounts");
    await page.waitForSelector(".accounts-grid");
    await page.screenshot({
      path: "screenshots/sarah-accounts.png",
    });

    // Demonstrate adding a transaction
    await page.click(".add-transaction-btn");
    await page.waitForSelector("[data-testid=transaction-form]");

    // Use symbol search
    await page.fill("[data-testid=symbol-search]", "APP");
    await page.waitForSelector(".autocomplete-results");
    await page.screenshot({
      path: "screenshots/symbol-search-demo.png",
    });

    await page.click("text=AAPL - Apple Inc.");

    // Fill transaction details
    await page.fill("[name=quantity]", "10");
    await page.fill("[name=price]", "175.50");
    await page.selectOption("[name=category]", "Growth");
    await page.fill("[name=notes]", "Monthly investment - DCA strategy");

    await page.screenshot({
      path: "screenshots/transaction-form-filled.png",
    });

    await page.click('button:has-text("Save Transaction")');

    // Show success state
    await page.waitForSelector(".flash-success");

    // Navigate to transactions with filtering
    await page.click("text=Transactions");
    await page.waitForSelector(".transactions-list");

    // Demonstrate filtering
    await page.click(".filter-toggle");
    await page.selectOption("[name=category_filter]", "Growth");
    await page.click('button:has-text("Apply Filters")');

    await page.screenshot({
      path: "screenshots/filtered-transactions.png",
    });

    // Show cash account balance update
    await page.click("text=Accounts");
    await page.click("text=Chase Checking");
    await page.click('button:has-text("Update Balance")');
    await page.fill("[name=new_balance]", "3500.00");
    await page.fill("[name=notes]", "Paycheck deposit");
    await page.click('button:has-text("Save")');

    // Return to dashboard to show updated net worth
    await page.click("text=Dashboard");
    await page.waitForSelector(".net-worth-card");

    // Final screenshot
    await page.screenshot({
      path: "screenshots/sarah-final-dashboard.png",
      fullPage: true,
    });

    // Close context to save video
    await context.close();
  });

  test("Power user journey - Patricia Planner", async ({ page }) => {
    await page.goto("http://localhost:4000");
    await page.click("text=Try Demo Mode");
    await page.click("text=Patricia Thompson - Pre-Retirement");

    // Complex filtering scenario
    await page.click("text=Transactions");
    await page.click(".filter-toggle");

    // Multiple filters
    await page.selectOption("[name=account_filter]", "Fidelity IRA");
    await page.selectOption("[name=category_filter]", "Income");
    await page.fill("[name=date_from]", "2024-01-01");
    await page.fill("[name=date_to]", "2024-12-31");
    await page.click('button:has-text("Apply Filters")');

    await page.screenshot({
      path: "screenshots/patricia-complex-filter.png",
    });

    // Show category breakdown
    await page.click("text=Dashboard");
    await page.waitForSelector(".category-breakdown");
    await page.screenshot({
      path: "screenshots/patricia-allocation.png",
    });
  });

  test("Tutorial flow recording", async ({ page }) => {
    const context = await browser.newContext({
      recordVideo: {
        dir: "./tutorial-videos/",
        size: { width: 1920, height: 1080 },
      },
    });

    const page = await context.newPage();

    await page.goto("http://localhost:4000");
    await page.click("text=Start Tutorial");

    // Step through entire tutorial
    for (let i = 0; i < 11; i++) {
      await page.waitForSelector(".tutorial-tooltip");
      await page.waitForTimeout(2000); // Let user see the step
      await page.click(".tutorial-next");
    }

    // Complete tutorial
    await page.waitForSelector(".tutorial-complete");
    await page.waitForTimeout(3000);

    await context.close();
  });
});

// Utility to generate realistic user behavior
async function simulateRealisticUserBehavior(page) {
  // Random delays between actions
  const delay = () => page.waitForTimeout(Math.random() * 2000 + 500);

  // Realistic mouse movements
  const moveToElement = async (selector) => {
    const element = await page.$(selector);
    const box = await element.boundingBox();
    await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2, {
      steps: 10,
    });
    await delay();
  };

  // Realistic typing
  const typeRealistic = async (selector, text) => {
    await page.focus(selector);
    for (const char of text) {
      await page.keyboard.type(char);
      await page.waitForTimeout(Math.random() * 200 + 50);
    }
  };

  return { delay, moveToElement, typeRealistic };
}
```

## Analytics & Tracking

### Analytics Module

```elixir
defmodule Ashfolio.DemoMode.Analytics do
  @moduledoc """
  Track demo mode usage and conversion metrics
  """

  use GenServer
  require Logger

  @metrics_table :demo_analytics_metrics

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    :ets.new(@metrics_table, [:named_table, :public, :set])
    {:ok, %{}}
  end

  # Track demo session start
  def track_demo_start(persona) do
    event = %{
      event: "demo_mode_started",

      persona: persona,
      timestamp: DateTime.utc_now(),
      session_id: generate_session_id()
    }

    GenServer.cast(__MODULE__, {:track, event})

    # Also track in telemetry
    :telemetry.execute(
      [:ashfolio, :demo_mode, :started],
      %{count: 1},
      %{persona: persona}
    )
  end

  # Track tutorial progress
  def track_tutorial_step(step_id, action) do
    event = %{
      event: "tutorial_step",

      step_id: step_id,
      action: action, # :completed, :skipped, :repeated
      timestamp: DateTime.utc_now()
    }

    GenServer.cast(__MODULE__, {:track, event})
  end

  # Track feature discovery
  def track_feature_discovery(feature, context) do
    event = %{
      event: "feature_discovered",

      feature: feature,
      context: context,
      timestamp: DateTime.utc_now()
    }

    GenServer.cast(__MODULE__, {:track, event})

    :telemetry.execute(
      [:ashfolio, :demo_mode, :feature_discovered],
      %{count: 1},
      %{feature: feature}
    )
  end

  # Track conversion from demo to real
  def track_conversion(demo_duration_seconds) do
    event = %{
      event: "demo_to_real_conversion",

      demo_duration: demo_duration_seconds,
      timestamp: DateTime.utc_now()
    }

    GenServer.cast(__MODULE__, {:track, event})

    :telemetry.execute(
      [:ashfolio, :demo_mode, :converted],
      %{duration: demo_duration_seconds},
      %{}
    )
  end

  # Get analytics summary
  def get_summary do
    GenServer.call(__MODULE__, :get_summary)
  end

  # GenServer callbacks

  def handle_cast({:track, event}, state) do
    # Store in ETS for quick access
    :ets.insert(@metrics_table, {event.timestamp, event})

    # Log for debugging
    Logger.info("Demo Analytics: #{event.event} - #{inspect(event)}")

    # Could also persist to database here
    persist_event(event)

    {:noreply, state}
  end

  def handle_call(:get_summary, _from, state) do
    events = :ets.tab2list(@metrics_table)

    summary = %{
      total_sessions: count_unique_sessions(events),
      tutorial_completion_rate: calculate_completion_rate(events),
      popular_features: get_popular_features(events),
      conversion_rate: calculate_conversion_rate(events),
      average_session_duration: calculate_avg_duration(events),
      persona_breakdown: get_persona_breakdown(events)
    }

    {:reply, summary, state}
  end

  defp generate_session_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16()
  end

  defp persist_event(event) do
    # Store in database for long-term analytics
    # This would integrate with your existing Ecto repo
    Task.start(fn ->
      # Ashfolio.Repo.insert!(event)
    end)
  end

  defp count_unique_sessions(events) do
    events
    |> Enum.filter(fn {_, e} -> e.event == "demo_mode_started" end)
    |> length()
  end

  defp calculate_completion_rate(events) do
    started = Enum.count(events, fn {_, e} ->
      e.event == "tutorial_step" and e.step_id == :welcome
    end)

    completed = Enum.count(events, fn {_, e} ->
      e.event == "tutorial_step" and e.step_id == :completion
    end)

    if started > 0 do
      (completed / started * 100) |> Float.round(1)
    else
      0.0
    end
  end

  defp get_popular_features(events) do
    events
    |> Enum.filter(fn {_, e} -> e.event == "feature_discovered" end)
    |> Enum.map(fn {_, e} -> e.feature end)
    |> Enum.frequencies()
    |> Enum.sort_by(fn {_, count} -> count end, :desc)
    |> Enum.take(5)
  end

  defp calculate_conversion_rate(events) do
    demo_starts = Enum.count(events, fn {_, e} ->
      e.event == "demo_mode_started"
    end)

    conversions = Enum.count(events, fn {_, e} ->
      e.event == "demo_to_real_conversion"
    end)

    if demo_starts > 0 do
      (conversions / demo_starts * 100) |> Float.round(1)
    else
      0.0
    end
  end

  defp calculate_avg_duration(events) do
    durations = events
    |> Enum.filter(fn {_, e} -> e.event == "demo_to_real_conversion" end)
    |> Enum.map(fn {_, e} -> e.demo_duration end)

    if length(durations) > 0 do
      Enum.sum(durations) / length(durations)
    else
      0
    end
  end

  defp get_persona_breakdown(events) do
    events
    |> Enum.filter(fn {_, e} -> e.event == "demo_mode_started" end)
    |> Enum.map(fn {_, e} -> e.persona end)
    |> Enum.frequencies()
  end
end
```

### Analytics Dashboard LiveView

```elixir
defmodule AshfolioWeb.DemoAnalyticsLive do
  use AshfolioWeb, :live_view

  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Refresh every 30 seconds
      :timer.send_interval(30_000, self(), :refresh)
    end

    {:ok,
     socket
     |> assign(:summary, Ashfolio.DemoMode.Analytics.get_summary())
     |> assign(:last_updated, DateTime.utc_now())}
  end

  def handle_info(:refresh, socket) do
    {:noreply,
     socket
     |> assign(:summary, Ashfolio.DemoMode.Analytics.get_summary())
     |> assign(:last_updated, DateTime.utc_now())}
  end

  def render(assigns) do
    ~H"""
    <div class="analytics-dashboard">
      <h1>Demo Mode Analytics</h1>
      <p class="last-updated">Last updated: <%= format_datetime(@last_updated) %></p>

      <div class="metrics-grid">
        <div class="metric-card">
          <h3>Total Demo Sessions</h3>
          <div class="metric-value"><%= @summary.total_sessions %></div>
        </div>

        <div class="metric-card">
          <h3>Tutorial Completion Rate</h3>
          <div class="metric-value"><%= @summary.tutorial_completion_rate %>%</div>
        </div>

        <div class="metric-card">
          <h3>Conversion Rate</h3>
          <div class="metric-value"><%= @summary.conversion_rate %>%</div>
        </div>

        <div class="metric-card">
          <h3>Avg Session Duration</h3>
          <div class="metric-value"><%= format_duration(@summary.average_session_duration) %></div>
        </div>
      </div>

      <div class="charts-section">
        <div class="chart-container">
          <h3>Popular Features</h3>
          <.feature_chart features={@summary.popular_features} />
        </div>

        <div class="chart-container">
          <h3>Persona Usage</h3>
          <.persona_chart personas={@summary.persona_breakdown} />
        </div>
      </div>
    </div>
    """
  end

  defp feature_chart(assigns) do
    ~H"""
    <div class="feature-chart">
      <%= for {feature, count} <- @features do %>
        <div class="feature-bar">
          <span class="feature-name"><%= feature %></span>
          <div class="bar" style={"width: #{count * 10}px"}>
            <span class="count"><%= count %></span>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp persona_chart(assigns) do
    ~H"""
    <div class="persona-chart">
      <%= for {persona, count} <- @personas do %>
        <div class="persona-segment">
          <span class="persona-name"><%= format_persona_name(persona) %></span>
          <span class="persona-count"><%= count %></span>
        </div>
      <% end %>
    </div>
    """
  end

  defp format_datetime(datetime) do
    Calendar.strftime(datetime, "%B %d, %Y at %I:%M %p")
  end

  defp format_duration(seconds) when seconds < 60, do: "#{seconds}s"
  defp format_duration(seconds) when seconds < 3600 do
    minutes = div(seconds, 60)
    "#{minutes}m"
  end
  defp format_duration(seconds) do
    hours = div(seconds, 3600)
    minutes = rem(div(seconds, 60), 60)
    "#{hours}h #{minutes}m"
  end

  defp format_persona_name(persona) do
    persona
    |> to_string()
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
end
```
