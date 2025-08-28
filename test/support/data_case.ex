defmodule Ashfolio.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use Ashfolio.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      import Ashfolio.DataCase
      import Ashfolio.SQLiteHelpers
      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      alias Ashfolio.Repo
    end
  end

  setup tags do
    Ashfolio.DataCase.setup_sandbox(tags)
    :ok
  end

  @doc """
  Sets up the sandbox based on the test tags.
  """
  def setup_sandbox(tags) do
    # Use shared mode for tests that need GenServer access
    # but still provide proper isolation
    pid =
      Sandbox.start_owner!(Ashfolio.Repo, shared: not (tags[:async] || false))

    on_exit(fn -> Sandbox.stop_owner(pid) end)
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  # Handle Ash errors
  def errors_on(%Ash.Error.Invalid{errors: errors}) do
    Enum.reduce(errors, %{}, fn error, acc ->
      field = Map.get(error, :field, :base)
      message = Map.get(error, :message, "is invalid")
      Map.update(acc, field, [message], &[message | &1])
    end)
  end

  def errors_on(error) do
    %{base: ["Unknown error: #{inspect(error)}"]}
  end
end
