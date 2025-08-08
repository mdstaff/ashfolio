defmodule AshfolioWeb.LiveViewCase do
  @moduledoc """
  This module defines the test case to be used by
  LiveView tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint AshfolioWeb.Endpoint

      use AshfolioWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest
      import AshfolioWeb.ConnCase
      import Ashfolio.SQLiteHelpers
    end
  end

  setup tags do
    Ashfolio.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end