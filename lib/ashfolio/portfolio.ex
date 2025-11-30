defmodule Ashfolio.Portfolio do
  @moduledoc """
  Ash domain for portfolio management resources.

  Contains resources for managing user settings, accounts, symbols, and transactions
  in the portfolio system.
  """
  use Ash.Domain, extensions: [AshAi]

  alias AshfolioWeb.Mcp.Tools

  resources do
    resource(Ashfolio.Portfolio.UserSettings)
    resource(Ashfolio.Portfolio.Account)
    resource(Ashfolio.Portfolio.Symbol)
    resource(Ashfolio.Portfolio.Transaction)
    resource(Ashfolio.Portfolio.CorporateAction)
    resource(Ashfolio.Portfolio.TransactionAdjustment)
    resource(Tools)
  end

  tools do
    tool :list_accounts, Tools, :list_accounts_filtered do
      description("""
      List all investment and cash accounts with privacy filtering applied.

      Returns accounts with IDs, types, and relative weights. In anonymized mode,
      account names become letter IDs (A, B, C) and balances become portfolio weights.
      Use this to understand the user's account structure and allocation.
      """)
    end

    tool :list_transactions, Tools, :list_transactions_filtered do
      description("""
      Query transaction history with privacy filtering applied.

      Accepts optional 'limit' parameter (default: 100). Returns transactions with
      type, symbol, quantity, and date. In anonymized mode, exact amounts are hidden
      and dates become relative strings. Useful for analyzing trading patterns.
      """)
    end

    tool :list_symbols, Tools, :list_symbols_filtered do
      description("""
      List all securities/symbols in the portfolio.

      Returns ticker symbols, names, and asset classes (stock, etf, mutual_fund, etc.).
      Symbol data is not considered sensitive and passes through all privacy modes.
      Useful for understanding portfolio composition by security type.
      """)
    end

    tool :get_portfolio_summary, Tools, :get_portfolio_summary do
      description("""
      Get aggregate portfolio metrics for financial analysis.

      Returns: value_tier (not exact amount), allocation percentages by account type,
      diversification score (0-1), and risk_level (conservative/balanced/moderate/aggressive).
      Percentages and ratios are exact; only absolute values are anonymized.
      Use for retirement planning, risk assessment, and allocation analysis.
      """)
    end

    tool :add_expense, Tools, :add_expense do
      description("""
      Add an expense record with two-phase input support.

      Phase 1: Pass {"text": "description"} to receive expected schema and example.
      Phase 2: Pass {"expense": {amount, category, date, description}} to create.

      Amounts support flexible formats: "$100", "85.50", "1.5k", "EUR 500".
      Dates can be ISO format or relative ("today", "yesterday").
      """)
    end

    tool :add_transaction, Tools, :add_transaction do
      description("""
      Add a portfolio transaction with two-phase input support.

      Phase 1: Pass {"text": "description"} to receive expected schema and example.
      Phase 2: Pass {"transaction": {type, symbol, quantity, price, date}} to create.

      Types: buy, sell, dividend, fee, interest, liability, deposit, withdrawal.
      Symbol must exist in the database. Amounts support flexible formats.
      """)
    end

    tool :search_tools, Tools, :search_tools do
      description("""
      Search for available tools by keyword or description.

      Use this to find the right tool before calling it directly. Returns matching
      tool names and descriptions. Follows Anthropic's tool search pattern for
      ~85% token reduction in systems with many tools.
      """)
    end
  end
end
