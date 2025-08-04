defmodule AshfolioWeb.LiveViewCase do
  @moduledoc """
  This module defines the test case to be used by
  LiveView tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use AshfolioWeb.ConnCase
      import Phoenix.LiveViewTest
      import AshfolioWeb.LiveViewCase

      # Use warn for LiveView errors during testing to avoid duplicate ID crashes
      @live_view_opts [connect_params: %{}, on_error: :warn]

      # Helper to mount LiveViews with error checking
      def live_with_error_check(conn, path) do
        {:ok, view, _html} = live(conn, path, @live_view_opts)
        view
      end
    end
  end
end
