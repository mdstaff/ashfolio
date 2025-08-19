defmodule Ashfolio.ContextBehaviour do
  @moduledoc """
  Behaviour for the Context API to enable mocking in tests.
  """

  @callback search_symbols(query :: String.t(), opts :: keyword()) ::
              {:ok, list()} | {:error, atom()}

  @callback create_symbol_from_external(symbol_data :: map()) ::
              {:ok, struct()} | {:error, atom()}

  @callback get_user_dashboard_data() ::
              {:ok, map()} | {:error, atom()}

  @callback get_account_with_transactions(account_id :: String.t(), limit :: integer()) ::
              {:ok, map()} | {:error, atom()}

  @callback get_portfolio_summary() ::
              {:ok, map()} | {:error, atom()}

  @callback get_recent_transactions(limit :: integer()) ::
              {:ok, list()} | {:error, atom()}

  @callback get_net_worth() ::
              {:ok, map()} | {:error, atom()}

  @callback update_cash_balance(
              account_id :: String.t(),
              new_balance :: Decimal.t(),
              notes :: String.t() | nil
            ) ::
              {:ok, struct()} | {:error, atom()}

  @callback get_balance_history(account_id :: String.t()) ::
              {:ok, list()} | {:error, atom()}

  @callback validate_account_constraints(
              form_params :: map(),
              current_account_id :: String.t() | nil
            ) ::
              {:ok, map()} | {:error, atom()}
end
