defmodule AshfolioWeb.AccountLive.IndexTest do
  use AshfolioWeb.LiveViewCase

  describe "AccountLive.Index" do
    @describetag :live_view
    test "displays a list of accounts", %{conn: conn} do
      view = live_with_error_check(conn, "/accounts")
      html = render(view)

      assert html =~ "Accounts"
    end
  end
end
