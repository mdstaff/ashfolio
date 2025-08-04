defmodule AshfolioWeb.AccountLive.Index do
  use AshfolioWeb, :live_view

  alias Ashfolio.Portfolio.Account

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_current_page(:accounts)
     |> assign(:page_title, "Investment Accounts")
     |> assign(:page_subtitle, "Manage your investment accounts and balances")
     |> assign(:accounts, list_accounts())}
  end

  defp list_accounts do
    Account.list!()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.table id="accounts-table" rows={@accounts}>
        <:col :let={account} label="Name">{account.name}</:col>
        <:col :let={account} label="Platform">{account.platform}</:col>
        <:col :let={account} label="Balance">{account.balance}</:col>
        <:col :let={account} label="Excluded">{account.is_excluded}</:col>
      </.table>
    </div>
    """
  end
end
