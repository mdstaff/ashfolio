defmodule Ashfolio.FinancialManagement.TransactionCategoryTest do
  use Ashfolio.DataCase, async: false

  alias Ashfolio.FinancialManagement.TransactionCategory
  alias Ashfolio.Portfolio.Transaction
  alias Ashfolio.SQLiteHelpers

  @moduletag :ash_resources
  @moduletag :unit
  @moduletag :fast

  setup do
    # Database-as-user architecture: No user needed
    %{}
  end

  describe "TransactionCategory resource" do
    test "can create category with required attributes" do
      {:ok, category} =
        TransactionCategory.create(%{
          name: "Growth"
        })

      assert category.name == "Growth"
      assert category.is_system == false
      assert category.color == nil
      assert category.parent_category_id == nil
      assert category.id
    end

    test "can create category with all attributes" do
      {:ok, parent_category} =
        TransactionCategory.create(%{
          name: "Parent Category",
          color: "#0000FF"
        })

      {:ok, category} =
        TransactionCategory.create(%{
          name: "Growth",
          color: "#10B981",
          is_system: true,
          parent_category_id: parent_category.id
        })

      assert category.name == "Growth"
      assert category.color == "#10B981"
      assert category.is_system == true
      assert category.parent_category_id == parent_category.id
    end

    test "can update category attributes" do
      {:ok, category} =
        TransactionCategory.create(%{
          name: "Test Category",
          color: "#FF0000"
        })

      {:ok, updated_category} =
        Ash.update(category, %{
          name: "Updated Category",
          color: "#00FF00"
        })

      assert updated_category.name == "Updated Category"
      assert updated_category.color == "#00FF00"
    end

    test "can delete non-system category" do
      {:ok, category} =
        TransactionCategory.create(%{
          name: "Test Category",
          is_system: false
        })

      :ok = Ash.destroy(category)

      # Verify the specific category is deleted
      {:ok, categories} = Ash.read(TransactionCategory)
      category_ids = Enum.map(categories, & &1.id)
      refute category.id in category_ids
    end

    test "validates required name field" do
      {:error, changeset} =
        TransactionCategory.create(%{})

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :name end)
    end

    test "prevents deletion of system categories" do
      {:ok, system_category} =
        TransactionCategory.create(%{
          name: "System Category",
          is_system: true
        })

      {:error, error} = Ash.destroy(system_category)
      assert error
    end

    test "can create hierarchical categories" do
      {:ok, parent} =
        TransactionCategory.create(%{
          name: "Investment",
          color: "#3B82F6"
        })

      {:ok, child} =
        TransactionCategory.create(%{
          name: "Growth Stocks",
          parent_category_id: parent.id,
          color: "#10B981"
        })

      assert child.parent_category_id == parent.id

      # Load with parent relationship
      loaded_child = Ash.load!(child, [:parent_category])
      assert loaded_child.parent_category.name == "Investment"
    end
  end

  describe "TransactionCategory queries" do
    test "can list all categories" do
      {:ok, _category1} =
        TransactionCategory.create(%{
          name: "Category 1",
          color: "#FF0000"
        })

      {:ok, _category2} =
        TransactionCategory.create(%{
          name: "Category 2",
          color: "#00FF00"
        })

      {:ok, categories} = TransactionCategory.list()

      # Should include at least our 2 categories (may include others from other tests)
      category_names = Enum.map(categories, & &1.name)
      assert "Category 1" in category_names
      assert "Category 2" in category_names
    end

    test "can filter categories by system flag" do
      {:ok, _user_category} =
        TransactionCategory.create(%{
          name: "User Category",
          is_system: false
        })

      {:ok, _system_category} =
        TransactionCategory.create(%{
          name: "System Category",
          is_system: true
        })

      {:ok, all_categories} = TransactionCategory.list()
      user_categories = Enum.filter(all_categories, &(&1.is_system == false))
      system_categories = Enum.filter(all_categories, &(&1.is_system == true))

      assert length(user_categories) >= 1
      assert length(system_categories) >= 1
      assert Enum.all?(user_categories, fn cat -> cat.is_system == false end)
      assert Enum.all?(system_categories, fn cat -> cat.is_system == true end)
    end

    test "can get category by name" do
      {:ok, _category} =
        TransactionCategory.create(%{
          name: "Unique Category",
          color: "#123456"
        })

      {:ok, found_category} = TransactionCategory.get_by_name("Unique Category")

      assert found_category.name == "Unique Category"
    end

    test "get_categories_with_children function works" do
      {:ok, parent_category} =
        TransactionCategory.create(%{
          name: "Parent Category"
        })

      {:ok, child_category} =
        TransactionCategory.create(%{
          name: "Child Category",
          parent_category_id: parent_category.id
        })

      {:ok, categories_with_children} =
        TransactionCategory.get_categories_with_children()

      # Find our parent category in the results
      parent_in_results =
        Enum.find(categories_with_children, fn cat -> cat.id == parent_category.id end)

      child_in_results =
        Enum.find(categories_with_children, fn cat -> cat.id == child_category.id end)

      assert parent_in_results
      assert child_in_results
      assert child_in_results.parent_category
      assert child_in_results.parent_category.id == parent_category.id
    end
  end

  describe "TransactionCategory relationships" do
    test "loads parent category relationship" do
      {:ok, parent} =
        TransactionCategory.create(%{
          name: "Parent Category",
          color: "#FF0000"
        })

      {:ok, child} =
        TransactionCategory.create(%{
          name: "Child Category",
          parent_category_id: parent.id,
          color: "#00FF00"
        })

      # Load child with parent relationship
      category_with_parent = Ash.load!(child, [:parent_category])

      assert category_with_parent.parent_category.id == parent.id
      assert category_with_parent.parent_category.name == "Parent Category"
    end

    test "loads child categories relationship" do
      {:ok, parent} =
        TransactionCategory.create(%{
          name: "Parent Category"
        })

      {:ok, child1} =
        TransactionCategory.create(%{
          name: "Child 1",
          parent_category_id: parent.id
        })

      {:ok, child2} =
        TransactionCategory.create(%{
          name: "Child 2",
          parent_category_id: parent.id
        })

      # Load parent with children relationships
      category_with_children = Ash.load!(parent, [:child_categories])

      child_ids = Enum.map(category_with_children.child_categories, & &1.id)
      assert child1.id in child_ids
      assert child2.id in child_ids
      assert length(category_with_children.child_categories) == 2
    end

    test "can create and load transaction relationships" do
      account = SQLiteHelpers.get_default_account()

      symbol =
        SQLiteHelpers.get_or_create_symbol("CATREL", %{
          name: "Category Relationship Test",
          current_price: Decimal.new("100")
        })

      {:ok, category} =
        TransactionCategory.create(%{
          name: "Investment Category"
        })

      # Create transaction with category
      {:ok, transaction} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("10"),
          price: Decimal.new("100"),
          total_amount: Decimal.new("1000"),
          date: Date.utc_today(),
          account_id: account.id,
          symbol_id: symbol.id,
          category_id: category.id
        })

      # Load category with transactions
      category_with_transactions = Ash.load!(category, [:transactions])

      transaction_ids = Enum.map(category_with_transactions.transactions, & &1.id)
      assert transaction.id in transaction_ids
    end
  end

  describe "TransactionCategory validations" do
    test "validates color format when provided" do
      # Valid hex color should work
      {:ok, _category} =
        TransactionCategory.create(%{
          name: "Valid Color Category",
          color: "#FF0000"
        })

      # Invalid color format should fail
      {:error, changeset} =
        TransactionCategory.create(%{
          name: "Invalid Color Category",
          color: "not-a-hex-color"
        })

      assert changeset.errors != []
    end

    test "validates name uniqueness" do
      {:ok, _first_category} =
        TransactionCategory.create(%{
          name: "Duplicate Name Test"
        })

      {:error, changeset} =
        TransactionCategory.create(%{
          name: "Duplicate Name Test"
        })

      assert changeset.errors != []
    end

    test "validates parent category exists" do
      non_existent_id = Ash.UUID.generate()

      {:error, changeset} =
        TransactionCategory.create(%{
          name: "Invalid Parent Test",
          parent_category_id: non_existent_id
        })

      assert changeset.errors != []
    end
  end

  describe "TransactionCategory system operations" do
    test "system categories cannot be deleted" do
      {:ok, system_category} =
        TransactionCategory.create(%{
          name: "System Category",
          is_system: true
        })

      {:error, _error} = Ash.destroy(system_category)

      # Verify it still exists
      {:ok, found} = TransactionCategory.get_by_id(system_category.id)
      assert found.id == system_category.id
    end

    test "non-system categories can be deleted" do
      {:ok, user_category} =
        TransactionCategory.create(%{
          name: "User Category",
          is_system: false
        })

      :ok = Ash.destroy(user_category)

      # Verify it's gone
      assert {:error, %Ash.Error.Invalid{}} = TransactionCategory.get_by_id(user_category.id)
    end

    test "can update non-system categories" do
      {:ok, category} =
        TransactionCategory.create(%{
          name: "Updateable Category",
          is_system: false,
          color: "#000000"
        })

      {:ok, updated} =
        Ash.update(category, %{
          name: "Updated Name",
          color: "#FFFFFF"
        })

      assert updated.name == "Updated Name"
      assert updated.color == "#FFFFFF"
    end
  end
end
