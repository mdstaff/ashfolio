defmodule AshfolioWeb.CategoryLive.FormComponentTest do
  use AshfolioWeb.LiveViewCase, async: false

  import Phoenix.LiveViewTest
  import Ashfolio.SQLiteHelpers

  alias Ashfolio.FinancialManagement.TransactionCategory
  alias AshfolioWeb.CategoryLive.FormComponent

  @moduletag :liveview

  describe "FormComponent" do
    setup do
      # Use global test user following documented SQLite patterns
      user = get_default_user()

      # Create existing categories for validation testing with retry logic
      existing_category = with_retry(fn ->
        case TransactionCategory.create(%{
          name: "Existing Category",
          color: "#22C55E",
          user_id: user.id,
          is_system: false
        }, actor: user) do
          {:ok, category} -> category
          {:error, error} -> raise "Failed to create existing category: #{inspect(error)}"
        end
      end)

      %{
        user: user,
        existing_category: existing_category
      }
    end

    test "renders new category form with suggestions", %{user: user} do
      component_html =
        render_component(FormComponent,
          id: "test-form",
          action: :new,
          category: nil,
          user_id: user.id,
          categories: []
        )

      assert component_html =~ "New Investment Category"
      assert component_html =~ "Popular Investment Categories"
      assert component_html =~ "Growth"
      assert component_html =~ "Income"
      assert component_html =~ "Speculative"
      assert component_html =~ "Index"
    end

    test "renders edit category form without suggestions", %{user: user, existing_category: existing_category} do
      component_html =
        render_component(FormComponent,
          id: "test-form",
          action: :edit,
          category: existing_category,
          user_id: user.id,
          categories: [existing_category]
        )

      assert component_html =~ "Edit Category"
      assert component_html =~ existing_category.name
      assert component_html =~ existing_category.color
      refute component_html =~ "Popular Investment Categories"
    end

    test "validates category name", %{user: user} do
      {view, _html} =
        live_component_isolated(FormComponent, %{
          id: "test-form",
          action: :new,
          category: nil,
          user_id: user.id,
          categories: []
        })

      # Hide suggestions to show the form
      view |> element("button", "Create custom category instead") |> render_click()

      # Test empty name
      view
      |> element("#category-form")
      |> render_change(%{"name" => "", "color" => "#3B82F6"})

      assert has_element?(view, "li", "Category name is required")

      # Test short name
      view
      |> element("#category-form")
      |> render_change(%{"name" => "A", "color" => "#3B82F6"})

      assert has_element?(view, "li", "Category name must be at least 2 characters")

      # Test long name
      long_name = String.duplicate("A", 51)
      view
      |> element("#category-form")
      |> render_change(%{"name" => long_name, "color" => "#3B82F6"})

      assert has_element?(view, "li", "Category name must be less than 50 characters")

      # Test valid name
      view
      |> element("#category-form")
      |> render_change(%{"name" => "Valid Name", "color" => "#3B82F6"})

      refute has_element?(view, "li", "Category name")
    end

    test "validates category name uniqueness", %{user: user, existing_category: existing_category} do
      {view, _html} =
        live_component_isolated(FormComponent, %{
          id: "test-form",
          action: :new,
          category: nil,
          user_id: user.id,
          categories: [existing_category]
        })

      # Hide suggestions to show the form
      view |> element("button", "Create custom category instead") |> render_click()

      # Test duplicate name
      view
      |> element("#category-form")
      |> render_change(%{"name" => existing_category.name, "color" => "#3B82F6"})

      assert has_element?(view, "li", "Category name must be unique")

      # Test unique name
      view
      |> element("#category-form")
      |> render_change(%{"name" => "Unique Name", "color" => "#3B82F6"})

      refute has_element?(view, "li", "unique")
    end

    test "validates color format", %{user: user} do
      {view, _html} =
        live_component_isolated(FormComponent, %{
          id: "test-form",
          action: :new,
          category: nil,
          user_id: user.id,
          categories: []
        })

      # Hide suggestions to show the form
      view |> element("button", "Create custom category instead") |> render_click()

      # Test empty color
      view
      |> element("#category-form")
      |> render_change(%{"name" => "Test", "color" => ""})

      assert has_element?(view, "li", "Category color is required")

      # Test invalid color format
      view
      |> element("#category-form")
      |> render_change(%{"name" => "Test", "color" => "blue"})

      assert has_element?(view, "li", "Color must be a valid hex color code")

      # Test invalid hex format
      view
      |> element("#category-form")
      |> render_change(%{"name" => "Test", "color" => "#GGG"})

      assert has_element?(view, "li", "Color must be a valid hex color code")

      # Test valid color
      view
      |> element("#category-form")
      |> render_change(%{"name" => "Test", "color" => "#3B82F6"})

      refute has_element?(view, "li", "Color must be a valid hex color")
    end

    test "color picker functionality", %{user: user} do
      {view, _html} =
        live_component_isolated(FormComponent, %{
          id: "test-form",
          action: :new,
          category: nil,
          user_id: user.id,
          categories: []
        })

      # Test color selection
      view
      |> element("button[phx-value-color='#EF4444']")
      |> render_click()

      # Should update the selected color
      html = render(view)
      assert html =~ "background-color: #EF4444"
    end

    test "suggestion selection functionality", %{user: user} do
      {view, _html} =
        live_component_isolated(FormComponent, %{
          id: "test-form",
          action: :new,
          category: nil,
          user_id: user.id,
          categories: []
        })

      # Click on Growth suggestion
      view
      |> element("button[phx-value-name='Growth']")
      |> render_click()

      # Should populate form with suggestion data
      html = render(view)
      assert html =~ "value=\"Growth\""
      refute html =~ "Popular Investment Categories" # Should hide suggestions
    end

    test "hide/show suggestions functionality", %{user: user} do
      {view, _html} =
        live_component_isolated(FormComponent, %{
          id: "test-form",
          action: :new,
          category: nil,
          user_id: user.id,
          categories: []
        })

      # Initially shows suggestions
      assert has_element?(view, "h4", "Popular Investment Categories")

      # Hide suggestions
      view
      |> element("button", "Hide suggestions")
      |> render_click()

      refute has_element?(view, "h4", "Popular Investment Categories")
    end

    test "creates new category successfully", %{user: user} do
      {view, _html} =
        live_component_isolated(FormComponent, %{
          id: "test-form",
          action: :new,
          category: nil,
          user_id: user.id,
          categories: []
        })

      # Hide suggestions to show the form
      view |> element("button", "Create custom category instead") |> render_click()

      # Submit valid form
      view
      |> element("#category-form")
      |> render_submit(%{
        "name" => "New Growth Category",
        "color" => "#22C55E",
        "parent_category_id" => ""
      })

      # Should receive success message
      assert_receive {AshfolioWeb.CategoryLive.FormComponent, {:saved, category}}
      assert category.name == "New Growth Category"
      assert category.color == "#22C55E"
      assert category.user_id == user.id
      assert category.is_system == false
    end

    test "updates existing category successfully", %{user: user, existing_category: existing_category} do
      {view, _html} =
        live_component_isolated(FormComponent, %{
          id: "test-form",
          action: :edit,
          category: existing_category,
          user_id: user.id,
          categories: [existing_category]
        })

      # Submit updated form
      view
      |> element("#category-form")
      |> render_submit(%{
        "name" => "Updated Category Name",
        "color" => "#EF4444",
        "parent_category_id" => ""
      })

      # Should receive success message
      assert_receive {AshfolioWeb.CategoryLive.FormComponent, {:saved, category}}
      assert category.name == "Updated Category Name"
      assert category.color == "#EF4444"
      assert category.id == existing_category.id
    end

    test "handles validation errors on save", %{user: user, existing_category: existing_category} do
      {view, _html} =
        live_component_isolated(FormComponent, %{
          id: "test-form",
          action: :new,
          category: nil,
          user_id: user.id,
          categories: [existing_category]
        })

      # Hide suggestions to show the form
      view |> element("button", "Create custom category instead") |> render_click()

      # Submit form with duplicate name
      view
      |> element("#category-form")
      |> render_submit(%{
        "name" => existing_category.name,
        "color" => "#3B82F6",
        "parent_category_id" => ""
      })

      # Should show validation error
      assert has_element?(view, "li", "Category name must be unique")
    end

    test "cancels form", %{user: user} do
      {view, _html} =
        live_component_isolated(FormComponent, %{
          id: "test-form",
          action: :new,
          category: nil,
          user_id: user.id,
          categories: []
        })

      # Click cancel using the phx-click attribute instead of text
      view
      |> element("button[phx-click=\"cancel\"]")
      |> render_click()

      # Should receive cancel message
      assert_receive {AshfolioWeb.CategoryLive.FormComponent, :cancelled}
    end

    test "validates custom color input", %{user: user} do
      {view, _html} =
        live_component_isolated(FormComponent, %{
          id: "test-form",
          action: :new,
          category: nil,
          user_id: user.id,
          categories: []
        })

      # Hide suggestions to show the form
      view |> element("button", "Create custom category instead") |> render_click()

      # Enter custom color
      view
      |> element("#category-form")
      |> render_change(%{"name" => "Test", "color" => "#FF5733"})

      # Click preview button
      view
      |> element("button", "Preview")
      |> render_click()

      # Should update selected color
      html = render(view)
      assert html =~ "background-color: #FF5733"
    end

    test "shows loading state during save", %{user: user} do
      {view, _html} =
        live_component_isolated(FormComponent, %{
          id: "test-form",
          action: :new,
          category: nil,
          user_id: user.id,
          categories: []
        })

      # Hide suggestions to show the form
      view |> element("button", "Create custom category instead") |> render_click()

      # The loading state would be visible briefly during form submission
      # This test verifies the UI elements are present
      assert has_element?(view, "button[type='submit']", "Create Category")

      # In a real scenario with network delays, we'd see:
      # - Disabled submit button
      # - Loading spinner
      # - "Creating..." text
    end

    test "parent category selection", %{user: user} do
      # Create a parent category with retry logic
      parent_category = with_retry(fn ->
        case TransactionCategory.create(%{
          name: "Parent Category",
          color: "#6366F1",
          user_id: user.id,
          is_system: false
        }, actor: user) do
          {:ok, category} -> category
          {:error, error} -> raise "Failed to create parent category: #{inspect(error)}"
        end
      end)

      {view, _html} =
        live_component_isolated(FormComponent, %{
          id: "test-form",
          action: :new,
          category: nil,
          user_id: user.id,
          categories: [parent_category]
        })

      # Hide suggestions to show the form
      view |> element("button", "Create custom category instead") |> render_click()

      # Should show parent category in dropdown
      html = render(view)
      assert html =~ "Parent Category (Optional)"
      assert html =~ parent_category.name

      # Select parent category
      view
      |> element("#category-form")
      |> render_change(%{
        "name" => "Child Category",
        "color" => "#3B82F6",
        "parent_category_id" => parent_category.id
      })

      # Submit form
      view
      |> element("#category-form")
      |> render_submit(%{
        "name" => "Child Category",
        "color" => "#3B82F6",
        "parent_category_id" => parent_category.id
      })

      # Should create category with parent
      assert_receive {AshfolioWeb.CategoryLive.FormComponent, {:saved, category}}
      assert category.parent_category_id == parent_category.id
    end

    test "excludes system categories from parent options", %{user: user} do
      # Create a system category with retry logic
      system_category = with_retry(fn ->
        case TransactionCategory.create(%{
          name: "System Category",
          color: "#6366F1",
          user_id: user.id,
          is_system: true
        }, actor: user) do
          {:ok, category} -> category
          {:error, error} -> raise "Failed to create system category: #{inspect(error)}"
        end
      end)

      {_view, html} =
        live_component_isolated(FormComponent, %{
          id: "test-form",
          action: :new,
          category: nil,
          user_id: user.id,
          categories: [system_category]
        })

      # System category should not appear in parent options
      refute html =~ "System Category"
    end
  end

  # Helper function for isolated component testing
  defp live_component_isolated(component_module, assigns) do
    # Create a minimal LiveView that hosts the component
    defmodule TestHostLiveView do
      use Phoenix.LiveView

      def render(assigns) do
        ~H"""
        <.live_component module={@component_module} {@component_assigns} />
        """
      end

      def mount(_params, session, socket) do
        component_module = session["component_module"]
        component_assigns = session["component_assigns"]
        test_pid = session["test_pid"]

        {:ok, assign(socket, component_module: component_module, component_assigns: component_assigns, test_pid: test_pid)}
      end

      # Forward component messages to the test process
      def handle_info({_component_module, _message} = msg, socket) do
        send(socket.assigns.test_pid, msg)
        {:noreply, socket}
      end
    end

    session = %{
      "component_module" => component_module,
      "component_assigns" => assigns,
      "test_pid" => self()
    }

    {:ok, view, html} = live_isolated(build_conn(), TestHostLiveView, session: session)
    {view, html}
  end
end
