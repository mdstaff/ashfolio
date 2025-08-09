defmodule AshfolioWeb.PageControllerTest do
  use AshfolioWeb.ConnCase

  test "GET / redirects to dashboard", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Portfolio Dashboard"
    assert html_response(conn, 200) =~ "Ashfolio"
  end
end
