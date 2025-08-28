defmodule Ashfolio.FinancialManagement.TransactionCategory do
  @moduledoc """
  TransactionCategory resource for organizing investment transactions.

  Provides hierarchical categorization of investment transactions with color coding
  and system-defined categories. Supports both user-defined and system categories
  for flexible investment organization.
  """

  use Ash.Resource,
    domain: Ashfolio.FinancialManagement,
    data_layer: AshSqlite.DataLayer

  sqlite do
    table("transaction_categories")
    repo(Ashfolio.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :name, :string do
      allow_nil?(false)
      description("Category name (e.g., 'Growth', 'Income', 'Speculative')")
    end

    attribute :color, :string do
      description("Hex color code for category display (e.g., '#3B82F6')")
    end

    attribute :is_system, :boolean do
      default(false)
      allow_nil?(false)
      description("Whether this is a system-defined category (cannot be deleted)")
    end

    timestamps()
  end

  relationships do
    belongs_to :parent_category, __MODULE__ do
      description("Parent category for hierarchical organization")
    end

    has_many :child_categories, __MODULE__ do
      destination_attribute(:parent_category_id)
      description("Child categories under this category")
    end

    has_many :transactions, Ashfolio.Portfolio.Transaction do
      destination_attribute(:category_id)
      description("Transactions assigned to this category")
    end
  end

  validations do
    validate(present(:name), message: "Category name is required")

    # Validate name length
    validate(string_length(:name, min: 2, max: 50))

    # Validate name format
    validate(match(:name, ~r/^[a-zA-Z0-9\s\-_&]+$/),
      message: "Category name can only contain letters, numbers, spaces, hyphens, underscores, and ampersands"
    )

    # Validate color format (hex color)
    validate(match(:color, ~r/^#[0-9A-Fa-f]{6}$/),
      where: present(:color),
      message: "Color must be a valid hex color code (e.g., #3B82F6)"
    )

    # Validate name uniqueness per user
    validate(fn changeset, _context ->
      name = Ash.Changeset.get_attribute(changeset, :name)
      id = Ash.Changeset.get_attribute(changeset, :id)

      if name do
        require Ash.Query

        # Database-as-user architecture: Check for unique names within the database instance
        existing_query = Ash.Query.filter(__MODULE__, name: name)

        # Exclude current record if updating
        existing_query =
          if id do
            Ash.Query.filter(existing_query, id != ^id)
          else
            existing_query
          end

        case Ash.read_first(existing_query) do
          {:ok, nil} ->
            :ok

          {:ok, _existing} ->
            {:error, field: :name, message: "Category name must be unique per user"}

          {:error, _} ->
            :ok
        end
      else
        :ok
      end
    end)

    # Prevent circular parent relationships
    validate(fn changeset, _context ->
      parent_category_id = Ash.Changeset.get_attribute(changeset, :parent_category_id)
      id = Ash.Changeset.get_attribute(changeset, :id)

      if parent_category_id && id && parent_category_id == id do
        {:error, field: :parent_category_id, message: "Category cannot be its own parent"}
      else
        :ok
      end
    end)
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      description("Create a new transaction category")
      accept([:name, :color, :is_system, :parent_category_id])
      primary?(true)
    end

    update :update do
      description("Update category attributes")
      accept([:name, :color, :parent_category_id])
      primary?(true)
      require_atomic?(false)

      # Prevent updating system categories
      change(fn changeset, _context ->
        case changeset.data do
          %{is_system: true} ->
            Ash.Changeset.add_error(changeset,
              field: :is_system,
              message: "System categories cannot be modified"
            )

          _ ->
            changeset
        end
      end)
    end

    read :system_categories do
      description("Returns only system-defined categories")
      filter(expr(is_system == true))
    end

    read :user_categories do
      description("Returns only user-defined categories")
      filter(expr(is_system == false))
    end

    read :root_categories do
      description("Returns categories without parent categories")
      filter(expr(is_nil(parent_category_id)))
    end

    read :by_parent do
      description("Returns categories with a specific parent")
      argument(:parent_category_id, :uuid, allow_nil?: false)
      filter(expr(parent_category_id == ^arg(:parent_category_id)))
    end

    destroy :destroy_if_not_system do
      description("Delete category only if it's not a system category")
      primary?(true)
      require_atomic?(false)

      # Prevent deleting system categories
      change(fn changeset, _context ->
        case changeset.data do
          %{is_system: true} ->
            Ash.Changeset.add_error(changeset,
              field: :is_system,
              message: "System categories cannot be deleted"
            )

          _ ->
            changeset
        end
      end)
    end
  end

  code_interface do
    domain(Ashfolio.FinancialManagement)

    define(:create, action: :create)
    define(:list, action: :read)
    define(:get_by_id, action: :read, get_by: [:id])
    define(:system_categories, action: :system_categories)
    define(:user_categories, action: :user_categories)
    define(:root_categories, action: :root_categories)
    define(:categories_by_parent, action: :by_parent, args: [:parent_category_id])
    define(:update, action: :update)
    define(:destroy, action: :destroy_if_not_system)

    def get_by_name(name) do
      require Ash.Query

      # Database-as-user architecture: No user_id needed
      __MODULE__
      |> Ash.Query.filter(name: name)
      |> Ash.read_first()
    end

    def get_categories_with_children do
      require Ash.Query

      # Database-as-user architecture: Return all categories for this database instance
      __MODULE__
      |> Ash.Query.load([:child_categories, :parent_category])
      |> Ash.read()
    end
  end
end
