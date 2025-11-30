defmodule AshfolioWeb.Mcp.Tools do
  @moduledoc """
  MCP tool implementations with privacy filtering.

  This resource provides custom actions that wrap Ash queries with privacy
  filtering based on the configured privacy mode.
  """

  use Ash.Resource, domain: Ashfolio.Portfolio

  alias Ashfolio.Portfolio.Account
  alias AshfolioWeb.Mcp.ParserToolExecutor
  alias AshfolioWeb.Mcp.PrivacyFilter
  alias AshfolioWeb.Mcp.ToolSearch

  actions do
    action :list_accounts_filtered, {:array, :map} do
      description("List all investment and cash accounts with privacy filtering applied")

      run(fn _input, _context ->
        accounts = Ash.read!(Account)

        filtered =
          accounts
          |> Enum.map(&account_to_map/1)
          |> PrivacyFilter.filter_result(:list_accounts)

        {:ok, filtered}
      end)
    end

    action :list_transactions_filtered, {:array, :map} do
      description("Query transactions with privacy filtering applied")

      argument :limit, :integer do
        default(100)
      end

      run(fn input, _context ->
        query =
          Ashfolio.Portfolio.Transaction
          |> Ash.Query.limit(input.arguments[:limit] || 100)
          |> Ash.Query.load([:account, :symbol])

        transactions = Ash.read!(query)

        filtered =
          transactions
          |> Enum.map(&transaction_to_map/1)
          |> PrivacyFilter.filter_result(:list_transactions)

        {:ok, filtered}
      end)
    end

    action :list_symbols_filtered, {:array, :map} do
      description("List all available securities/symbols")

      run(fn _input, _context ->
        # Symbols are generally not sensitive, pass through with minimal filtering
        symbols = Ash.read!(Ashfolio.Portfolio.Symbol)

        result =
          Enum.map(symbols, fn s ->
            %{
              symbol: s.symbol,
              name: s.name,
              asset_class: s.asset_class
            }
          end)

        {:ok, result}
      end)
    end

    action :get_portfolio_summary, :map do
      description("Get aggregate portfolio metrics including total value tier, allocation, and risk assessment")

      run(fn _input, _context ->
        accounts = Ash.read!(Account)

        total_value =
          accounts
          |> Enum.map(& &1.balance)
          |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

        account_count = length(accounts)

        allocation =
          accounts
          |> Enum.group_by(& &1.account_type)
          |> Map.new(fn {type, accs} ->
            type_total =
              accs
              |> Enum.map(& &1.balance)
              |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

            weight =
              if Decimal.compare(total_value, 0) == :gt do
                type_total |> Decimal.div(total_value) |> Decimal.to_float() |> Float.round(2)
              else
                0.0
              end

            {type, weight}
          end)

        summary = %{
          total_value: total_value,
          account_count: account_count,
          allocation: allocation,
          ytd_return: 0.0,
          diversification: calculate_diversification(accounts, total_value),
          risk_level: assess_risk_level(allocation),
          savings_rate: 0.0,
          debt_to_income: 0.0,
          expense_ratio: 0.0
        }

        # Apply privacy filtering
        filtered = PrivacyFilter.filter_result(summary, :get_portfolio_summary)
        {:ok, filtered}
      end)
    end

    # ==========================================================================
    # Parseable Tools (two-phase: guidance -> execution)
    # ==========================================================================

    action :add_expense, :map do
      description("""
      Add an expense record. Supports two-phase input:

      Phase 1 (guidance): Pass {"text": "description"} to get the expected schema.
      Phase 2 (execute): Pass {"expense": {amount, category, date, description}} to create.

      Amounts can be in various formats: "$100", "85.50", "1.5k", "EUR 500".
      Dates can be ISO format (YYYY-MM-DD) or relative ("today", "yesterday").
      """)

      argument :text, :string do
        description("Natural language expense description (triggers schema guidance)")
      end

      argument :expense, :map do
        description("Structured expense data with amount, category, date, description")
      end

      run(fn input, _context ->
        args =
          %{
            "text" => input.arguments[:text],
            "expense" => input.arguments[:expense]
          }
          |> Enum.reject(fn {_k, v} -> is_nil(v) end)
          |> Map.new()

        case ParserToolExecutor.execute(:add_expense, args) do
          {:guidance, guidance} -> {:ok, guidance}
          {:ok, expense} -> {:ok, expense_to_map(expense)}
          {:error, errors} -> {:error, format_errors(errors)}
        end
      end)
    end

    action :add_transaction, :map do
      description("""
      Add a portfolio transaction. Supports two-phase input:

      Phase 1 (guidance): Pass {"text": "description"} to get the expected schema.
      Phase 2 (execute): Pass {"transaction": {type, symbol, quantity, price, date}} to create.

      Types: buy, sell, dividend, fee, interest, liability, deposit, withdrawal.
      Amounts can be in various formats: "$150", "1.5k".
      Dates must be ISO format (YYYY-MM-DD).
      """)

      argument :text, :string do
        description("Natural language transaction description (triggers schema guidance)")
      end

      argument :transaction, :map do
        description("Structured transaction data with type, symbol, quantity, price, date")
      end

      run(fn input, _context ->
        args =
          %{
            "text" => input.arguments[:text],
            "transaction" => input.arguments[:transaction]
          }
          |> Enum.reject(fn {_k, v} -> is_nil(v) end)
          |> Map.new()

        case ParserToolExecutor.execute(:add_transaction, args) do
          {:guidance, guidance} -> {:ok, guidance}
          {:ok, txn} -> {:ok, transaction_to_map(txn)}
          {:error, errors} -> {:error, format_errors(errors)}
        end
      end)
    end

    # ==========================================================================
    # Tool Search (reduces token usage by ~85%)
    # ==========================================================================

    action :search_tools, :map do
      description("""
      Search for available tools by keyword, category, or description.
      Use this to find the right tool before calling it directly.
      Returns matching tool definitions with names and descriptions.

      This follows Anthropic's "tool search" pattern for reducing token usage.
      """)

      argument :query, :string do
        allow_nil?(false)
        description("Search query (keywords, tool name, or description)")
      end

      argument :limit, :integer do
        default(5)
        description("Maximum number of results (default: 5)")
      end

      run(fn input, _context ->
        args = %{
          "query" => input.arguments[:query],
          "limit" => input.arguments[:limit] || 5
        }

        ToolSearch.execute(args)
      end)
    end
  end

  # Private helpers

  defp account_to_map(account) do
    %{
      id: account.id,
      name: account.name,
      type: account.account_type,
      balance: account.balance,
      holdings: []
    }
  end

  defp transaction_to_map(txn) do
    %{
      id: txn.id,
      type: txn.type,
      symbol: (txn.symbol && txn.symbol.symbol) || txn.symbol_id,
      quantity: txn.quantity,
      price: txn.price,
      total_amount: txn.total_amount,
      date: txn.date,
      account_name: txn.account && txn.account.name
    }
  end

  defp expense_to_map(expense) do
    %{
      id: expense.id,
      amount: expense.amount,
      description: expense.description,
      date: expense.date,
      merchant: expense.merchant,
      category_id: expense.category_id
    }
  end

  defp format_errors(errors) when is_list(errors), do: Enum.join(errors, "; ")
  defp format_errors(errors) when is_binary(errors), do: errors
  defp format_errors(errors), do: inspect(errors)

  defp calculate_diversification(accounts, total_value) do
    if Decimal.compare(total_value, 0) == :gt do
      # Simple Herfindahl-Hirschman Index
      hhi =
        accounts
        |> Enum.map(fn a ->
          w =
            a.balance
            |> Decimal.div(total_value)
            |> Decimal.to_float()

          w * w
        end)
        |> Enum.sum()

      Float.round(1 - hhi, 2)
    else
      0.0
    end
  end

  defp assess_risk_level(allocation) do
    equity_pct = Map.get(allocation, :investment, 0.0)

    cond do
      equity_pct > 0.8 -> :aggressive
      equity_pct > 0.6 -> :moderate
      equity_pct > 0.4 -> :balanced
      true -> :conservative
    end
  end
end
