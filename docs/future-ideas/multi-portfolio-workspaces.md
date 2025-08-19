# Multi-Portfolio Workspace System
## Database-as-User + Workspace Selection

## Overview
Transform Ashfolio into a workspace-based system where users can create, manage, and switch between multiple portfolios (databases), similar to how code editors handle workspaces/projects.

## Architecture Concept

```
Ashfolio Application
├── Global Config DB (portfolio_registry.db)
│   └── Stores: portfolio list, last active, app preferences
│
├── Portfolio 1 (personal_portfolio.db)
│   ├── UserSettings (name: "Personal Portfolio")
│   ├── Accounts, Transactions, etc.
│   └── Complete isolated portfolio data
│
├── Portfolio 2 (retirement_401k.db)
│   ├── UserSettings (name: "401k Retirement")
│   ├── Accounts, Transactions, etc.
│   └── Complete isolated portfolio data
│
└── Portfolio 3 (family_investments.db)
    ├── UserSettings (name: "Family Investments")
    ├── Accounts, Transactions, etc.
    └── Complete isolated portfolio data
```

## User Experience

### 1. **Startup Flow**
```
User opens Ashfolio
    ↓
Check for existing portfolio registry
    ↓
If none exist → Show "Welcome/Create First Portfolio" page
If registry exists → Show "Portfolio Selection" page
    ↓
User selects portfolio → Connect to that database → Dashboard
```

### 2. **Portfolio Selection Page** (like VS Code workspace picker)
```
┌─────────────────────────────────────────────────┐
│ 🏦 Ashfolio - Select Portfolio                  │
├─────────────────────────────────────────────────┤
│                                                 │
│ Recent Portfolios:                              │
│                                                 │
│ 📊 Personal Portfolio              [Open]       │
│    Last opened: 2 hours ago                     │
│    ~/Documents/Ashfolio/personal_portfolio.db   │
│                                                 │
│ 🏢 401k Retirement                 [Open]       │
│    Last opened: 3 days ago                      │
│    ~/Documents/Ashfolio/retirement_401k.db      │
│                                                 │
│ 👨‍👩‍👧‍👦 Family Investments            [Open]       │
│    Last opened: 1 week ago                      │
│    ~/Documents/Ashfolio/family_investments.db   │
│                                                 │
├─────────────────────────────────────────────────┤
│ [+ Create New Portfolio]  [📁 Open Existing]    │
│                          [⚙️ Settings]         │
└─────────────────────────────────────────────────┘
```

### 3. **In-App Portfolio Switching**
- Top bar shows current portfolio name
- Quick switcher (Cmd+P style) to switch portfolios
- "Switch Portfolio" option in settings menu

## Technical Implementation

### **Global Portfolio Registry**

```elixir
defmodule Ashfolio.PortfolioRegistry do
  @moduledoc """
  Global registry for managing multiple portfolios.
  Stored in a separate SQLite database (portfolio_registry.db)
  """
  
  use Ash.Resource,
    domain: Ashfolio.Registry,
    data_layer: AshSqlite.DataLayer

  sqlite do
    table("portfolios")
    repo(Ashfolio.RegistryRepo)  # Separate repo for registry
  end

  attributes do
    uuid_primary_key(:id)
    
    attribute :name, :string do
      allow_nil?(false)
      description("User-friendly portfolio name")
    end
    
    attribute :database_path, :string do
      allow_nil?(false)
      description("Absolute path to the portfolio database file")
    end
    
    attribute :last_opened_at, :utc_datetime do
      description("When this portfolio was last opened")
    end
    
    attribute :created_at, :utc_datetime do
      allow_nil?(false)
      description("When this portfolio was created")
    end
    
    attribute :description, :string do
      description("Optional description of the portfolio")
    end
    
    attribute :color, :string do
      description("UI color theme for this portfolio")
      default("#3B82F6")
    end
    
    timestamps()
  end

  actions do
    defaults([:read, :destroy])
    
    create :create do
      accept([:name, :database_path, :description, :color])
      
      change(fn changeset, _context ->
        changeset
        |> Ash.Changeset.change_attribute(:created_at, DateTime.utc_now())
        |> Ash.Changeset.change_attribute(:last_opened_at, DateTime.utc_now())
      end)
    end
    
    update :mark_opened do
      accept([])
      
      change(fn changeset, _context ->
        Ash.Changeset.change_attribute(changeset, :last_opened_at, DateTime.utc_now())
      end)
    end
    
    read :recent do
      description("Get portfolios ordered by last opened")
      
      prepare(fn query, _context ->
        query
        |> Ash.Query.sort(last_opened_at: :desc)
      end)
    end
  end
end
```

### **Portfolio Manager Service**

```elixir
defmodule Ashfolio.PortfolioManager do
  @moduledoc """
  Service for managing portfolio creation, switching, and lifecycle.
  """
  
  alias Ashfolio.{PortfolioRegistry, Repo}
  
  @default_portfolio_dir Path.join([System.user_home(), "Documents", "Ashfolio"])
  
  def list_portfolios do
    PortfolioRegistry.recent()
  end
  
  def create_portfolio(attrs) do
    with {:ok, name} <- validate_name(attrs[:name]),
         {:ok, db_path} <- generate_database_path(name),
         :ok <- create_portfolio_database(db_path),
         :ok <- initialize_portfolio_schema(db_path),
         {:ok, user_settings} <- create_initial_user_settings(db_path, attrs),
         {:ok, portfolio} <- register_portfolio(name, db_path, attrs) do
      {:ok, portfolio}
    else
      {:error, reason} -> {:error, reason}
    end
  end
  
  def open_portfolio(portfolio_id) do
    with {:ok, portfolio} <- PortfolioRegistry.by_id(portfolio_id),
         :ok <- validate_database_exists(portfolio.database_path),
         :ok <- switch_active_database(portfolio.database_path),
         {:ok, _} <- PortfolioRegistry.mark_opened(portfolio) do
      {:ok, portfolio}
    else
      {:error, reason} -> {:error, reason}
    end
  end
  
  def open_existing_portfolio(file_path) do
    with :ok <- validate_portfolio_database(file_path),
         {:ok, user_settings} <- extract_portfolio_info(file_path),
         {:ok, portfolio} <- register_portfolio(user_settings.name, file_path, %{}) do
      open_portfolio(portfolio.id)
    else
      {:error, reason} -> {:error, reason}
    end
  end
  
  def export_portfolio(portfolio_id, export_path) do
    with {:ok, portfolio} <- PortfolioRegistry.by_id(portfolio_id) do
      File.cp(portfolio.database_path, export_path)
    end
  end
  
  def get_current_portfolio do
    # Get from application state or session
    case get_active_database_path() do
      nil -> {:error, :no_active_portfolio}
      path -> 
        case PortfolioRegistry.by_database_path(path) do
          {:ok, portfolio} -> {:ok, portfolio}
          {:error, _} -> {:error, :portfolio_not_registered}
        end
    end
  end
  
  # Private functions
  
  defp generate_database_path(name) do
    safe_name = String.replace(name, ~r/[^a-zA-Z0-9_-]/, "_")
    filename = "#{safe_name}.db"
    path = Path.join(@default_portfolio_dir, filename)
    
    # Ensure directory exists
    File.mkdir_p!(@default_portfolio_dir)
    
    # Ensure unique filename
    unique_path = ensure_unique_filename(path)
    {:ok, unique_path}
  end
  
  defp create_portfolio_database(db_path) do
    # Create new SQLite database file
    case Sqlite.Ecto3.storage_up([database: db_path]) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
  
  defp initialize_portfolio_schema(db_path) do
    # Run all migrations on the new database
    temp_repo_config = [
      database: db_path,
      pool_size: 1
    ]
    
    # This would require dynamic repo configuration
    # Implementation depends on how we handle multiple databases
    # Could use Ecto.Migrator.run with dynamic config
    :ok
  end
  
  defp create_initial_user_settings(db_path, attrs) do
    # Connect to the new database and create UserSettings
    # This requires switching database context temporarily
    settings_attrs = %{
      name: attrs[:portfolio_name] || attrs[:name],
      currency: attrs[:currency] || "USD",
      locale: attrs[:locale] || "en-US"
    }
    
    # Would need to implement database switching logic
    {:ok, settings_attrs}
  end
  
  defp register_portfolio(name, db_path, attrs) do
    PortfolioRegistry.create(%{
      name: name,
      database_path: db_path,
      description: attrs[:description],
      color: attrs[:color]
    })
  end
  
  defp switch_active_database(db_path) do
    # Update application configuration to point to this database
    # This is the core challenge - dynamic database switching
    # Could use process dictionary, GenServer state, or Phoenix session
    
    # Store in application environment
    Application.put_env(:ashfolio, :active_database_path, db_path)
    
    # Update Repo configuration dynamically
    # This might require restarting the Repo process
    :ok
  end
  
  defp get_active_database_path do
    Application.get_env(:ashfolio, :active_database_path)
  end
end
```

### **Dynamic Database Connection**

```elixir
defmodule Ashfolio.DynamicRepo do
  @moduledoc """
  Dynamic repository that can switch between portfolio databases.
  """
  
  use Ecto.Repo,
    otp_app: :ashfolio,
    adapter: Ecto.Adapters.SQLite3
    
  def init(_type, config) do
    # Get active database path from application config
    case Application.get_env(:ashfolio, :active_database_path) do
      nil -> 
        # Default to registry database or show portfolio selection
        default_config = Keyword.put(config, :database, registry_database_path())
        {:ok, default_config}
        
      active_path ->
        dynamic_config = Keyword.put(config, :database, active_path)
        {:ok, dynamic_config}
    end
  end
  
  defp registry_database_path do
    Path.join([System.user_home(), "Documents", "Ashfolio", "portfolio_registry.db"])
  end
end
```

### **Portfolio Selection LiveView**

```elixir
defmodule AshfolioWeb.PortfolioSelectionLive do
  use AshfolioWeb, :live_view
  
  alias Ashfolio.PortfolioManager
  
  def mount(_params, _session, socket) do
    portfolios = PortfolioManager.list_portfolios()
    
    socket = 
      socket
      |> assign(:portfolios, portfolios)
      |> assign(:show_create_form, false)
      |> assign(:page_title, "Select Portfolio")
    
    {:ok, socket}
  end
  
  def handle_event("open_portfolio", %{"id" => portfolio_id}, socket) do
    case PortfolioManager.open_portfolio(portfolio_id) do
      {:ok, _portfolio} ->
        {:noreply, redirect(socket, to: ~p"/")}
        
      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to open portfolio: #{reason}")}
    end
  end
  
  def handle_event("create_new", _params, socket) do
    {:noreply, assign(socket, :show_create_form, true)}
  end
  
  def handle_event("create_portfolio", %{"portfolio" => attrs}, socket) do
    case PortfolioManager.create_portfolio(attrs) do
      {:ok, portfolio} ->
        case PortfolioManager.open_portfolio(portfolio.id) do
          {:ok, _} ->
            {:noreply, redirect(socket, to: ~p"/")}
            
          {:error, reason} ->
            {:noreply, put_flash(socket, :error, "Created but failed to open: #{reason}")}
        end
        
      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to create portfolio: #{reason}")}
    end
  end
  
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 flex items-center justify-center">
      <div class="max-w-2xl w-full mx-4">
        <div class="text-center mb-8">
          <h1 class="text-4xl font-bold text-gray-900 mb-2">🏦 Ashfolio</h1>
          <p class="text-gray-600">Select a portfolio to get started</p>
        </div>
        
        <%= if @show_create_form do %>
          <.portfolio_create_form />
        <% else %>
          <div class="bg-white rounded-lg shadow-lg p-6">
            <h2 class="text-xl font-semibold mb-4">Recent Portfolios</h2>
            
            <%= if Enum.empty?(@portfolios) do %>
              <div class="text-center py-8">
                <p class="text-gray-500 mb-4">No portfolios found</p>
                <.button phx-click="create_new" class="btn-primary">
                  Create Your First Portfolio
                </.button>
              </div>
            <% else %>
              <div class="space-y-3 mb-6">
                <div :for={portfolio <- @portfolios} class="portfolio-item">
                  <.portfolio_card portfolio={portfolio} />
                </div>
              </div>
              
              <div class="flex gap-3">
                <.button phx-click="create_new" class="btn-secondary">
                  + Create New Portfolio
                </.button>
                <.button class="btn-secondary">
                  📁 Open Existing
                </.button>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
```

## Key Benefits

### **1. True Multi-Portfolio Support**
- **Personal + Business**: Separate investment tracking
- **Family Members**: Each family member's portfolio
- **Different Strategies**: Growth vs Income vs Retirement
- **Experimentation**: Test portfolios without affecting main data

### **2. Perfect Data Isolation**
- **Complete Privacy**: No data mixing between portfolios
- **Easy Backup**: Copy specific .db files
- **Sharing**: Send portfolio file to advisor/accountant
- **Migration**: Move portfolios between devices easily

### **3. Enhanced UX**
- **Visual Organization**: Color coding, descriptions
- **Quick Switching**: Like IDE workspace switching
- **Recent Portfolios**: Fast access to frequently used ones
- **Import/Export**: Easy portfolio management

## Implementation Challenges

### **1. Dynamic Database Connections**
- Need to switch Ecto repos at runtime
- Manage multiple database connections
- Handle connection pooling for multiple databases

### **2. Migration Management**
- Each portfolio database needs schema migrations
- Version compatibility between portfolios
- Backup/restore during schema updates

### **3. State Management**
- Track current active portfolio in LiveView
- Handle database switching in sessions
- Manage database connections across processes

## File Structure After Implementation

```
~/Documents/Ashfolio/
├── portfolio_registry.db          # Global portfolio list
├── personal_portfolio.db           # User's personal investments
├── retirement_401k.db              # 401k tracking
├── family_investments.db           # Family portfolio
└── business_portfolio.db           # Business investments
```

This creates a truly powerful workspace system where each SQLite database is a complete, portable portfolio that users can organize however makes sense for their financial life!

Would you like me to start implementing any specific part of this system?