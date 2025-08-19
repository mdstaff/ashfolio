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

  test "layout configuration should use :app layout (not :root)" do
    # Check current configuration is correct
    ashfolio_web_content = File.read!("lib/ashfolio_web.ex")
    correct_config = ashfolio_web_content =~ ~r/layout:\s*\{AshfolioWeb\.Layouts,\s*:app\}/

    assert correct_config, """
    ❌ INCORRECT layout configuration detected!

    Expected: layout: {AshfolioWeb.Layouts, :app}

    To test regression detection manually:
    1. Change ashfolio_web.ex line ~56 to: layout: {AshfolioWeb.Layouts, :root}
    2. Run: mix test test/ashfolio_web/layout_*test.exs
    3. You should see failures detecting duplicate IDs
    4. Change back to: layout: {AshfolioWeb.Layouts, :app}
    5. Run tests again - they should pass

    This validates the regression tests work correctly.
    """
  end

  test "layout configuration examples are documented in code" do
    # This test ensures we have proper documentation of correct vs incorrect configs
    # The examples are now in the failure message above, not cluttering test output

    # Verify the configuration patterns exist in our codebase
    ashfolio_web_content = File.read!("lib/ashfolio_web.ex")

    # Should use :app layout (correct)
    assert ashfolio_web_content =~ ~r/layout:\s*\{AshfolioWeb\.Layouts,\s*:app\}/

    # Should NOT use :root layout (incorrect)
    refute ashfolio_web_content =~ ~r/layout:\s*\{AshfolioWeb\.Layouts,\s*:root\}/
  end
end
