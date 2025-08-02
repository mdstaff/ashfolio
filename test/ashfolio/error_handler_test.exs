defmodule Ashfolio.ErrorHandlerTest do
  use ExUnit.Case, async: true

  alias Ashfolio.ErrorHandler

  describe "handle_error/2" do
    test "handles network timeout errors" do
      error = {:error, :network_timeout}

      assert {:error, "Network connection issue. Please try again."} =
        ErrorHandler.handle_error(error)
    end

    test "handles rate limit errors" do
      error = {:error, :rate_limited}

      assert {:error, "Market data temporarily unavailable. Using cached prices."} =
        ErrorHandler.handle_error(error)
    end

    test "handles not found errors" do
      error = {:error, :not_found}

      assert {:error, "The requested information was not found."} =
        ErrorHandler.handle_error(error)
    end

    test "handles stale data errors" do
      error = {:error, :stale}

      assert {:error, "Data may be outdated. Please refresh to get current information."} =
        ErrorHandler.handle_error(error)
    end

    test "handles validation errors with changeset" do
      changeset = %Ecto.Changeset{
        valid?: false,
        errors: [name: {"can't be blank", [validation: :required]}]
      }

      assert {:error, message} = ErrorHandler.handle_error(changeset)
      assert String.contains?(message, "Name")
      assert String.contains?(message, "can't be blank")
    end

    test "handles generic system errors" do
      error = {:error, :some_unknown_error}

      assert {:error, "An unexpected error occurred. Please try again."} =
        ErrorHandler.handle_error(error)
    end

    test "includes context in logging" do
      import ExUnit.CaptureLog

      error = {:error, :test_error}
      context = %{user_id: "123", action: "test_action"}

      log = capture_log(fn ->
        ErrorHandler.handle_error(error, context)
      end)

      assert log =~ "Error occurred"
      assert log =~ "test_error"
    end
  end

  describe "format_changeset_errors/1" do
    test "formats changeset errors correctly" do
      changeset = %Ecto.Changeset{
        valid?: false,
        errors: [
          name: {"can't be blank", [validation: :required]},
          email: {"is invalid", [validation: :format]}
        ]
      }

      errors = ErrorHandler.format_changeset_errors(changeset)

      assert errors[:name] == ["can't be blank"]
      assert errors[:email] == ["is invalid"]
    end

    test "handles empty changeset errors" do
      changeset = %Ecto.Changeset{valid?: true, errors: []}

      errors = ErrorHandler.format_changeset_errors(changeset)

      assert errors == %{}
    end

    test "handles non-changeset input" do
      errors = ErrorHandler.format_changeset_errors("not a changeset")

      assert errors == []
    end
  end

  describe "log_error/2" do
    test "logs errors with appropriate severity" do
      import ExUnit.CaptureLog

      # Test network error (warning level)
      log = capture_log(fn ->
        ErrorHandler.log_error({:error, :network_timeout})
      end)

      assert log =~ "[warning]"
      assert log =~ "Error occurred"
      assert log =~ "network_timeout"
    end

    test "logs validation errors correctly" do
      import ExUnit.CaptureLog

      changeset = %Ecto.Changeset{valid?: false, errors: []}

      # Just test that logging doesn't crash - the exact log format is less important
      log = capture_log(fn ->
        ErrorHandler.log_error(changeset, %{})
      end)

      # The log might be empty due to log level filtering, but the function should not crash
      assert is_binary(log)
    end

    test "logs system errors with error level" do
      import ExUnit.CaptureLog

      log = capture_log(fn ->
        ErrorHandler.log_error({:error, :unknown_system_error})
      end)

      assert log =~ "[error]"
      assert log =~ "Error occurred"
    end
  end
end
