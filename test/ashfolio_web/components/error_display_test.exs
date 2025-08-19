defmodule AshfolioWeb.Components.ErrorDisplayTest do
  use AshfolioWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import Phoenix.Component

  @moduletag :liveview
  @moduletag :unit
  @moduletag :fast

  alias AshfolioWeb.Components.ErrorDisplay

  describe "error_message/1" do
    test "renders basic error message" do
      assigns = %{error: "Something went wrong"}

      html = rendered_to_string(~H"<ErrorDisplay.error_message error={@error} />")

      assert html =~ "Something went wrong"
      assert html =~ "text-red-800"
      assert html =~ "bg-red-50"
      assert html =~ "role=\"alert\""
    end

    test "renders error tuple with ErrorHandler formatting" do
      assigns = %{error: {:error, :insufficient_balance}}

      html = rendered_to_string(~H"<ErrorDisplay.error_message error={@error} />")

      assert html =~ "Insufficient funds for this transaction"
      assert html =~ "text-red-800"
    end

    test "renders dismissible error message" do
      assigns = %{error: "Test error", dismissible: true}

      html =
        rendered_to_string(
          ~H"<ErrorDisplay.error_message error={@error} dismissible={@dismissible} />"
        )

      assert html =~ "Test error"
      assert html =~ "phx-click=\"dismiss_error\""
      assert html =~ "Dismiss error"
    end

    test "renders error with context" do
      assigns = %{error: "Update failed", context: "balance update"}

      html =
        rendered_to_string(~H"<ErrorDisplay.error_message error={@error} context={@context} />")

      assert html =~ "Update failed"
      assert html =~ "Context: balance update"
    end
  end

  describe "warning_message/1" do
    test "renders basic warning message" do
      assigns = %{message: "This is a warning"}

      html = rendered_to_string(~H"<ErrorDisplay.warning_message message={@message} />")

      assert html =~ "This is a warning"
      assert html =~ "text-yellow-800"
      assert html =~ "bg-yellow-50"
    end

    test "renders dismissible warning message" do
      assigns = %{message: "Warning message", dismissible: true}

      html =
        rendered_to_string(
          ~H"<ErrorDisplay.warning_message message={@message} dismissible={@dismissible} />"
        )

      assert html =~ "phx-click=\"dismiss_warning\""
    end
  end

  describe "inline_error/1" do
    test "renders inline error for form fields" do
      assigns = %{error: "Field is required"}

      html = rendered_to_string(~H"<ErrorDisplay.inline_error error={@error} />")

      assert html =~ "Field is required"
      assert html =~ "text-red-600"
      assert html =~ "role=\"alert\""
    end
  end

  describe "success_message/1" do
    test "renders basic success message" do
      assigns = %{message: "Operation completed successfully"}

      html = rendered_to_string(~H"<ErrorDisplay.success_message message={@message} />")

      assert html =~ "Operation completed successfully"
      assert html =~ "text-green-800"
      assert html =~ "bg-green-50"
    end

    test "renders success message with dismiss by default" do
      assigns = %{message: "Success"}

      html = rendered_to_string(~H"<ErrorDisplay.success_message message={@message} />")

      assert html =~ "phx-click=\"dismiss_success\""
    end
  end

  describe "async_error_boundary/1" do
    test "renders loading state" do
      assigns = %{loading: true, error: nil}

      html =
        rendered_to_string(~H"""
        <ErrorDisplay.async_error_boundary loading={@loading} error={@error}>
          <p>Content loaded</p>
        </ErrorDisplay.async_error_boundary>
        """)

      assert html =~ "Loading..."
      assert html =~ "animate-spin"
      refute html =~ "Content loaded"
    end

    test "renders error state with retry button" do
      assigns = %{loading: false, error: {:error, :net_worth_calculation_failed}}

      html =
        rendered_to_string(~H"""
        <ErrorDisplay.async_error_boundary loading={@loading} error={@error}>
          <p>Content loaded</p>
        </ErrorDisplay.async_error_boundary>
        """)

      assert html =~ "Unable to calculate net worth"
      assert html =~ "Try Again"
      assert html =~ "phx-click=\"retry\""
      refute html =~ "Content loaded"
    end

    test "renders success content when no loading or error" do
      assigns = %{loading: false, error: nil}

      html =
        rendered_to_string(~H"""
        <ErrorDisplay.async_error_boundary loading={@loading} error={@error}>
          <p>Content loaded</p>
        </ErrorDisplay.async_error_boundary>
        """)

      assert html =~ "Content loaded"
      refute html =~ "Loading..."
      refute html =~ "Try Again"
    end

    test "supports custom retry event" do
      assigns = %{
        loading: false,
        error: {:error, :context_operation_failed},
        retry_event: "reload_data"
      }

      html =
        rendered_to_string(~H"""
        <ErrorDisplay.async_error_boundary loading={@loading} error={@error} retry_event={@retry_event}>
          <p>Content loaded</p>
        </ErrorDisplay.async_error_boundary>
        """)

      assert html =~ "phx-click=\"reload_data\""
    end
  end

  describe "accessibility" do
    test "all error components include proper ARIA attributes" do
      assigns = %{
        error: "Test error",
        message: "Test message",
        inline_error: "Inline error"
      }

      # Test error_message
      error_html = rendered_to_string(~H"<ErrorDisplay.error_message error={@error} />")
      assert error_html =~ "role=\"alert\""
      assert error_html =~ "aria-live=\"polite\""

      # Test warning_message  
      warning_html = rendered_to_string(~H"<ErrorDisplay.warning_message message={@message} />")
      assert warning_html =~ "role=\"alert\""
      assert warning_html =~ "aria-live=\"polite\""

      # Test inline_error
      inline_html = rendered_to_string(~H"<ErrorDisplay.inline_error error={@inline_error} />")
      assert inline_html =~ "role=\"alert\""

      # Test success_message
      success_html = rendered_to_string(~H"<ErrorDisplay.success_message message={@message} />")
      assert success_html =~ "role=\"alert\""
      assert success_html =~ "aria-live=\"polite\""
    end

    test "dismiss buttons include proper aria-label" do
      assigns = %{error: "Test", message: "Test"}

      error_html =
        rendered_to_string(~H"<ErrorDisplay.error_message error={@error} dismissible={true} />")

      assert error_html =~ "aria-label=\"Dismiss error\""

      warning_html =
        rendered_to_string(
          ~H"<ErrorDisplay.warning_message message={@message} dismissible={true} />"
        )

      assert warning_html =~ "aria-label=\"Dismiss warning\""

      success_html =
        rendered_to_string(
          ~H"<ErrorDisplay.success_message message={@message} dismissible={true} />"
        )

      assert success_html =~ "aria-label=\"Dismiss success message\""
    end
  end

  describe "v0.2.0 error integration" do
    test "handles all v0.2.0 error types correctly" do
      v0_2_0_errors = [
        {:error, :insufficient_balance},
        {:error, :symbol_api_unavailable},
        {:error, :category_required},
        {:error, :net_worth_calculation_failed}
      ]

      Enum.each(v0_2_0_errors, fn error ->
        assigns = %{error: error}

        html = rendered_to_string(~H"<ErrorDisplay.error_message error={@error} />")

        # Should render without crashing and include error content
        assert html =~ "text-red-800"
        # Should have substantial content
        assert String.length(html) > 100
      end)
    end
  end
end
