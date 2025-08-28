defmodule AshfolioWeb.Router do
  use AshfolioWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AshfolioWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AshfolioWeb do
    pipe_through :browser

    live "/", DashboardLive, :index
    live "/accounts", AccountLive.Index, :index
    live "/accounts/new", AccountLive.Index, :new
    live "/accounts/:id", AccountLive.Show, :show
    live "/accounts/:id/edit", AccountLive.Index, :edit
    live "/transactions", TransactionLive.Index, :index
    live "/categories", CategoryLive.Index, :index
    live "/categories/new", CategoryLive.Index, :new
    live "/categories/:id/edit", CategoryLive.Index, :edit
    live "/expenses", ExpenseLive.Index, :index
    live "/expenses/new", ExpenseLive.Index, :new
    live "/expenses/:id/edit", ExpenseLive.Index, :edit
    live "/expenses/import", ExpenseLive.Import, :index
    live "/expenses/analytics", ExpenseLive.Analytics, :index
    live "/net_worth", NetWorthLive.Index, :index
    live "/goals", FinancialGoalLive.Index, :index
    live "/goals/new", FinancialGoalLive.Index, :new
    live "/goals/:id/edit", FinancialGoalLive.Index, :edit
    live "/forecast", ForecastLive.Index, :index
  end

  # Health check endpoints - accessible without authentication
  scope "/", AshfolioWeb do
    pipe_through :api

    get "/health", HealthController, :check
    get "/ping", HealthController, :ping
  end

  # API routes for future expansion
  scope "/api", AshfolioWeb do
    pipe_through :api

    get "/health", HealthController, :check
    get "/ping", HealthController, :ping
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:ashfolio, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AshfolioWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
