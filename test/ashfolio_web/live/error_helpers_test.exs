defmodule AshfolioWeb.Live.ErrorHelpersTest do
  use ExUnit.Case, async: true

  alias AshfolioWeb.Live.ErrorHelpers

  # Note: ErrorHelpers functions require a LiveView socket which is difficult to test in isolation.
  # These functions are tested through integration tests in the actual LiveView modules.

  describe "module structure" do
    test "module exists and has expected functions" do
      # Verify the module exists
      assert Code.ensure_loaded?(ErrorHelpers)

      # Verify key functions exist
      assert function_exported?(ErrorHelpers, :put_error_flash, 3)
      assert function_exported?(ErrorHelpers, :put_success_flash, 3)
      assert function_exported?(ErrorHelpers, :clear_flash, 1)
      assert function_exported?(ErrorHelpers, :handle_form_errors, 2)
    end

    test "component functions exist" do
      # Verify component functions exist (Phoenix components have arity 1)
      functions = ErrorHelpers.__info__(:functions)

      # Check that component functions are defined
      assert Enum.member?(functions, {:field_errors, 1})
      assert Enum.member?(functions, {:error_list, 1})
      assert Enum.member?(functions, {:success_banner, 1})
      assert Enum.member?(functions, {:warning_banner, 1})
      assert Enum.member?(functions, {:info_banner, 1})
    end
  end

  describe "handle_form_errors/2 with valid changeset" do
    test "ignores valid changeset" do
      # Create a mock valid changeset
      changeset = %Ecto.Changeset{valid?: true, errors: []}

      # Create a mock socket
      socket = %{assigns: %{}}

      # Should return the socket unchanged for valid changesets
      result = ErrorHelpers.handle_form_errors(socket, changeset)
      assert result == socket
    end

    test "ignores non-changeset input" do
      # Create a mock socket
      socket = %{assigns: %{}}

      # Should return the socket unchanged for non-changeset input
      result = ErrorHelpers.handle_form_errors(socket, "not a changeset")
      assert result == socket
    end
  end
end
