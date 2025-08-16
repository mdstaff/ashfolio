defmodule AshfolioWeb.ResponsiveDesignTest do
  use AshfolioWeb.ConnCase

  setup do
    # Use the global default user - no need for complex race condition handling
    user = Ashfolio.SQLiteHelpers.get_default_user()
    {:ok, user: user}
  end

  describe "responsive design compliance" do
    test "dashboard template contains responsive classes" do
      # Test the template directly to avoid LiveView mounting issues
      dashboard_content = File.read!("lib/ashfolio_web/live/dashboard_live.ex")

      assert dashboard_content =~ "flex-col sm:flex-row",
             "Dashboard missing responsive flex classes"

      assert dashboard_content =~ "w-full sm:w-auto", "Dashboard missing responsive width classes"
      assert dashboard_content =~ "overflow-x-auto", "Dashboard missing responsive table overflow"
      assert dashboard_content =~ "min-w-full", "Dashboard missing responsive table width"
    end

    test "accounts template contains responsive elements" do
      # Test the template directly to avoid LiveView mounting issues
      accounts_content = File.read!("lib/ashfolio_web/live/account_live/index.ex")

      assert accounts_content =~ "flex-col sm:flex-row",
             "Accounts missing responsive flex classes"

      assert accounts_content =~ "account-actions", "Accounts missing account-actions class"
    end

    test "navigation template has accessibility attributes" do
      # Test the top_bar component directly
      topbar_content = File.read!("lib/ashfolio_web/components/top_bar.ex")

      assert topbar_content =~ "aria-label", "TopBar missing ARIA labels"
      assert topbar_content =~ ~s(role="navigation"), "TopBar missing navigation role"
    end

    test "navigation template has focus states" do
      # Test the top_bar component directly
      topbar_content = File.read!("lib/ashfolio_web/components/top_bar.ex")

      assert topbar_content =~ "focus:ring-2", "TopBar missing focus ring classes"
      assert topbar_content =~ "focus:ring-blue-500", "TopBar missing focus ring color classes"
    end
  end
end
