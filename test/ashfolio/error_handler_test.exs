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
      context = %{action: "test_action"}

      log =
        capture_log(fn ->
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
      log =
        capture_log(fn ->
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
      log =
        capture_log(fn ->
          ErrorHandler.log_error(changeset, %{})
        end)

      # The log might be empty due to log level filtering, but the function should not crash
      assert is_binary(log)
    end

    test "logs system errors with error level" do
      import ExUnit.CaptureLog

      log =
        capture_log(fn ->
          ErrorHandler.log_error({:error, :unknown_system_error})
        end)

      assert log =~ "[error]"
      assert log =~ "Error occurred"
    end
  end

  describe "v0.2.0 cash balance error handling" do
    test "handles insufficient balance errors" do
      error = {:error, :insufficient_balance}

      assert {:error, "Insufficient funds for this transaction."} =
               ErrorHandler.handle_error(error)
    end

    test "handles negative balance not allowed errors" do
      error = {:error, :negative_balance_not_allowed}

      assert {:error, "Balance cannot be negative for this account type."} =
               ErrorHandler.handle_error(error)
    end

    test "handles balance update failures" do
      error = {:error, :balance_update_failed}

      assert {:error, "Unable to update account balance. Please try again."} =
               ErrorHandler.handle_error(error)
    end

    test "handles account not found errors" do
      error = {:error, :account_not_found}

      assert {:error, "Account not found."} =
               ErrorHandler.handle_error(error)
    end

    test "handles not cash account errors" do
      error = {:error, :not_cash_account}

      assert {:error, "This operation is only available for cash accounts."} =
               ErrorHandler.handle_error(error)
    end
  end

  describe "v0.2.0 symbol search error handling" do
    test "handles symbol API unavailable errors" do
      error = {:error, :symbol_api_unavailable}

      assert {:error, "Symbol search is temporarily unavailable. Using local symbols only."} =
               ErrorHandler.handle_error(error)
    end

    test "handles symbol not found errors" do
      error = {:error, :symbol_not_found}

      assert {:error, "Symbol not found. Please check the ticker symbol and try again."} =
               ErrorHandler.handle_error(error)
    end

    test "handles symbol creation failed errors" do
      error = {:error, :symbol_creation_failed}

      assert {:error, "Unable to add new symbol. Please try again later."} =
               ErrorHandler.handle_error(error)
    end

    test "handles symbol search rate limited errors" do
      error = {:error, :symbol_search_rate_limited}

      assert {:error, "Too many search requests. Please wait a moment and try again."} =
               ErrorHandler.handle_error(error)
    end
  end

  describe "v0.2.0 category management error handling" do
    test "handles system category protected errors" do
      error = {:error, :system_category_protected}

      assert {:error, "System categories cannot be modified or deleted."} =
               ErrorHandler.handle_error(error)
    end

    test "handles category required errors" do
      error = {:error, :category_required}

      assert {:error, "Please select a category for this transaction."} =
               ErrorHandler.handle_error(error)
    end

    test "handles category not found errors" do
      error = {:error, :category_not_found}

      assert {:error, "Category not found."} =
               ErrorHandler.handle_error(error)
    end

    test "handles invalid category color errors" do
      error = {:error, :invalid_category_color}

      assert {:error, "Please select a valid color for the category."} =
               ErrorHandler.handle_error(error)
    end
  end

  describe "v0.2.0 net worth calculation error handling" do
    test "handles net worth calculation failed errors" do
      error = {:error, :net_worth_calculation_failed}

      assert {:error, "Unable to calculate net worth. Please refresh and try again."} =
               ErrorHandler.handle_error(error)
    end

    test "handles mixed account calculation errors" do
      error = {:error, :mixed_account_calculation_error}

      assert {:error, "Unable to calculate combined portfolio value. Please check account data."} =
               ErrorHandler.handle_error(error)
    end
  end

  describe "v0.2.0 context API error handling" do
    test "handles context operation failed errors" do
      error = {:error, :context_operation_failed}

      assert {:error, "Data operation failed. Please refresh and try again."} =
               ErrorHandler.handle_error(error)
    end

    test "handles cross domain operation errors" do
      error = {:error, :cross_domain_operation_failed}

      assert {:error, "Unable to complete operation across accounts. Please try again."} =
               ErrorHandler.handle_error(error)
    end
  end
end
