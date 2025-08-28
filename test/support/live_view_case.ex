defmodule AshfolioWeb.LiveViewCase do
  @moduledoc """
  This module defines the test case to be used by
  LiveView tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use AshfolioWeb, :verified_routes

      import Ashfolio.SQLiteHelpers
      import AshfolioWeb.ConnCase
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest
      import Plug.Conn
      # The default endpoint for testing
      @endpoint AshfolioWeb.Endpoint

      # Import conveniences for testing with connections
    end
  end

  setup tags do
    Ashfolio.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
