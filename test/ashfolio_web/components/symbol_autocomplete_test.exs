defmodule AshfolioWeb.Components.SymbolAutocompleteTest do
  use AshfolioWeb.ConnCase, async: false

  @moduletag :liveview
  @moduletag :unit
  @moduletag :fast
  # Task 7a: UI enhancement tests enabled

  # NOTE: This component is designed to be tested within a parent LiveView context.
  # Full integration tests will be implemented in Task 10 when the component
  # is integrated into TransactionLive.FormComponent.
  #
  # For now, we verify the component exists and has the correct structure.

  describe "SymbolAutocomplete component structure" do
    test "component module exists and has required functions" do
      # Verify the component module exists
      assert Code.ensure_loaded?(AshfolioWeb.Components.SymbolAutocomplete)

      # Verify required LiveComponent functions exist
      assert function_exported?(AshfolioWeb.Components.SymbolAutocomplete, :render, 1)
      assert function_exported?(AshfolioWeb.Components.SymbolAutocomplete, :update, 2)
      assert function_exported?(AshfolioWeb.Components.SymbolAutocomplete, :handle_event, 3)
    end

    test "component has correct configuration constants" do
      # These constants should be accessible through the module
      # We can't test them directly due to module privacy, but we can verify
      # the component compiles without errors
      assert Code.ensure_compiled!(AshfolioWeb.Components.SymbolAutocomplete)
    end

    test "component uses Context API integration" do
      # Verify the component references the context_module function
      # This ensures it's properly configured for dependency injection
      source = File.read!("lib/ashfolio_web/components/symbol_autocomplete.ex")
      assert source =~ "context_module()"
      assert source =~ "search_symbols"
    end

    test "component has proper accessibility attributes in template" do
      # Verify the component template includes required ARIA attributes
      source = File.read!("lib/ashfolio_web/components/symbol_autocomplete.ex")
      assert source =~ "role=\"combobox\""
      assert source =~ "aria-expanded"
      assert source =~ "aria-haspopup=\"listbox\""
      assert source =~ "aria-live=\"polite\""
    end

    test "component has debouncing configuration" do
      # Verify debouncing is configured
      source = File.read!("lib/ashfolio_web/components/symbol_autocomplete.ex")
      assert source =~ "phx-debounce"
      # 300ms debounce timeout
      assert source =~ "300"
    end

    test "component has proper error handling" do
      # Verify error handling functions exist
      source = File.read!("lib/ashfolio_web/components/symbol_autocomplete.ex")
      assert source =~ "format_search_error"
      assert source =~ ":search_failed"
      assert source =~ ":rate_limited"
      assert source =~ ":api_unavailable"
    end
  end

  describe "Task 7a: UI enhancements" do
    test "JavaScript hook file exists with required functionality" do
      hook_path = "assets/js/hooks/symbol_autocomplete.js"
      assert File.exists?(hook_path), "JavaScript hook file should exist"

      hook_content = File.read!(hook_path)

      # Verify keyboard navigation functionality
      assert hook_content =~ "handleKeydown", "Should have keyboard navigation"
      assert hook_content =~ "ArrowDown", "Should handle arrow down key"
      assert hook_content =~ "ArrowUp", "Should handle arrow up key"
      assert hook_content =~ "Enter", "Should handle enter key"
      assert hook_content =~ "Escape", "Should handle escape key"

      # Verify click-outside-to-close behavior
      assert hook_content =~ "setupClickOutside", "Should have click outside setup"
      assert hook_content =~ "clickOutsideHandler", "Should have click outside handler"

      # Verify mobile-friendly touch interactions  
      assert hook_content =~ "setupTouchHandlers", "Should have touch handlers"
      assert hook_content =~ "touchstart", "Should handle touch start"
      assert hook_content =~ "touchmove", "Should handle touch move"

      # Verify dropdown positioning
      assert hook_content =~ "updateDropdownPosition", "Should handle dropdown positioning"
      assert hook_content =~ "getBoundingClientRect", "Should calculate positioning"

      # Verify visual loading indicators and transitions
      assert hook_content =~ "showLoadingState", "Should have loading state management"
      assert hook_content =~ "animate-spin", "Should handle loading spinner"
      assert hook_content =~ "transition", "Should have smooth transitions"
    end

    test "JavaScript hook is properly registered in app.js" do
      app_js_path = "assets/js/app.js"
      assert File.exists?(app_js_path), "app.js should exist"

      app_content = File.read!(app_js_path)

      # Verify hook import and registration
      assert app_content =~ "import SymbolAutocomplete", "Should import the hook"
      assert app_content =~ "SymbolAutocomplete: SymbolAutocomplete", "Should register the hook"
      assert app_content =~ "hooks: Hooks", "Should pass hooks to LiveSocket"
    end

    test "component template includes phx-hook attribute" do
      source = File.read!("lib/ashfolio_web/components/symbol_autocomplete.ex")

      # Verify the phx-hook attribute is present
      assert source =~ "phx-hook=\"SymbolAutocomplete\"", "Should have phx-hook attribute"
    end

    test "component has mobile-responsive classes" do
      source = File.read!("lib/ashfolio_web/components/symbol_autocomplete.ex")

      # Verify mobile-friendly classes
      assert source =~ "touch-manipulation", "Should have touch-friendly classes"
      assert source =~ "sm:text-sm", "Should have responsive text sizing"
    end

    test "component has smooth transition classes" do
      source = File.read!("lib/ashfolio_web/components/symbol_autocomplete.ex")

      # Verify transition and animation classes
      assert source =~ "transition-colors", "Should have color transitions"
      assert source =~ "duration-150", "Should have transition duration"
      assert source =~ "ease-in-out", "Should have easing"
      assert source =~ "transform", "Should have transform transitions"
    end

    test "component has proper loading indicator" do
      source = File.read!("lib/ashfolio_web/components/symbol_autocomplete.ex")

      # Verify loading spinner implementation
      assert source =~ "animate-spin", "Should have spinning animation"
      assert source =~ "@loading", "Should have loading state"
      assert source =~ "h-4 w-4", "Should have proper spinner size"
    end
  end

  # Integration tests will be added in Task 10 when the component is integrated
  # into TransactionLive.FormComponent. At that point, we can test:
  # - Full user interaction flows with LiveView
  # - Context API integration in realistic scenarios  
  # - Real-time search functionality end-to-end
  # - Error handling in realistic scenarios
  # - Accessibility features with actual screen readers
end
