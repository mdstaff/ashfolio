defmodule AshfolioWeb.LayoutRegressionDemoTest do
  @moduledoc """
  Demonstration test showing what happens with incorrect layout configuration.

  This test is designed to be run manually to verify that our regression tests
  would catch the layout duplication issue if it were reintroduced.

  To test the regression detection:
  1. Temporarily change ashfolio_web.ex to use :root layout
  2. Run this test - it should fail  
  3. Change back to :app layout
  4. Run this test - it should pass

  This validates our regression tests are working.
  """
  use ExUnit.Case

  @moduletag :manual

  test "demonstrates how to test for layout configuration regression" do
    # This test documents how to manually verify our regression detection works

    # Step 1: Check current configuration is correct
    ashfolio_web_content = File.read!("lib/ashfolio_web.ex")
    correct_config = ashfolio_web_content =~ ~r/layout:\s*\{AshfolioWeb\.Layouts,\s*:app\}/

    if correct_config do
      IO.puts("""
      ✅ Current configuration is CORRECT: LiveView uses :app layout

      To test regression detection:
      1. Change ashfolio_web.ex line ~56 to: layout: {AshfolioWeb.Layouts, :root}
      2. Run: mix test test/ashfolio_web/layout_*test.exs
      3. You should see failures detecting duplicate IDs
      4. Change back to: layout: {AshfolioWeb.Layouts, :app}
      5. Run tests again - they should pass

      This validates the regression tests work correctly.
      """)
    else
      IO.puts("""
      ❌ INCORRECT configuration detected: LiveView NOT using :app layout!

      This should cause the layout regression tests to fail.
      Fix by changing ashfolio_web.ex to use :app layout.
      """)
    end

    assert correct_config, "Layout configuration should be correct for this test to pass"
  end

  test "shows the difference between correct and incorrect configurations" do
    correct_config = """
    # ✅ CORRECT - What we have now
    use Phoenix.LiveView,
      layout: {AshfolioWeb.Layouts, :app}
    """

    incorrect_config = """
    # ❌ INCORRECT - What caused the issue
    use Phoenix.LiveView,
      layout: {AshfolioWeb.Layouts, :root}
    """

    IO.puts("Configuration examples:")
    IO.puts(correct_config)
    IO.puts(incorrect_config)

    # This test always passes - it's just documentation
    assert true
  end
end
