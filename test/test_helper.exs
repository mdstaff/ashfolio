ExUnit.configure(
  trace: System.get_env("CI") == "true",
  capture_log: true,
  colors: [enabled: true],
  timeout: 120_000,
  # Default exclusions - can be overridden with --include
  exclude_tags: [:seeding, :slow, :external_deps],
  formatters: [ExUnit.CLIFormatter]
)

ExUnit.start()

# Set up Mox for mocking
Mox.defmock(YahooFinanceMock, for: Ashfolio.MarketData.YahooFinanceBehaviour)
Mox.defmock(HttpClientMock, for: Ashfolio.MarketData.HttpClientBehaviour)
Mox.defmock(Ashfolio.ContextMock, for: Ashfolio.ContextBehaviour)

# Ensure application is started for test infrastructure
{:ok, _} = Application.ensure_all_started(:ashfolio)

# Set up sandbox mode for test isolation
Ecto.Adapters.SQL.Sandbox.mode(Ashfolio.Repo, :manual)

# Establish database ownership BEFORE creating any data
:ok = Ecto.Adapters.SQL.Sandbox.checkout(Ashfolio.Repo)

# Create all global test data with proper database ownership
# This ensures baseline data is committed to the database permanently
Ashfolio.SQLiteHelpers.setup_global_test_data!()

# ============================================================================
# MODULAR TESTING FILTER CONFIGURATION
# ============================================================================
#
# This configuration enables targeted test execution using ExUnit tags that
# align with Ashfolio's architectural layers and performance characteristics.
#
# Usage Examples:
#   mix test --only unit                 # Fast unit tests only
#   mix test --only ash_resources        # Business logic layer only
#   mix test --only liveview             # UI layer only
#   mix test --only integration          # End-to-end workflows only
#   mix test --only calculations         # Portfolio calculation tests only
#   mix test --only market_data          # Market data system tests only
#   mix test --only fast                 # Quick development feedback
#   mix test --include slow              # Include slower tests
#   mix test --include external_deps     # Include tests requiring external APIs
#   mix test --include seeding           # Include database seeding tests
#
# Combined filters:
#   mix test --only unit --only fast     # Fast unit tests only
#   mix test --include integration --include slow  # All integration + slow tests
#
# Architectural Layer Filters:
# - :ash_resources    - Business logic, validations, relationships
# - :liveview        - Phoenix LiveView UI components and interactions
# - :market_data     - Price fetching, caching, external API integration
# - :calculations    - Portfolio mathematics and FIFO cost basis logic
# - :database        - Database operations, migrations, schema tests
# - :ui             - User interface, accessibility, responsive design
# - :pubsub         - Real-time communication and event handling
#
# Performance-based Filters:
# - :fast           - Quick tests for development feedback (< 100ms typically)
# - :slow           - Slower tests requiring more setup or processing
# - :unit           - Isolated unit tests with minimal dependencies
# - :integration    - End-to-end workflow and system integration tests
#
# Dependency-based Filters:
# - :external_deps  - Tests requiring external APIs (Yahoo Finance, etc.)
# - :genserver      - Tests involving GenServer state and async operations
# - :ets_cache      - Tests involving ETS cache operations
# - :mocked         - Tests using Mox for external service mocking
#
# SQLite-specific Filters:
# - :async_false    - Tests that require async: false due to SQLite constraints
# - :sandbox        - Tests requiring special database sandbox handling
# - :seeding        - Database seeding and sample data generation tests
#
# Development Workflow Filters:
# - :smoke          - Essential tests that must always pass
# - :regression     - Tests covering previously fixed bugs
# - :edge_cases     - Tests for boundary conditions and unusual scenarios
# - :error_handling - Tests specifically for error conditions and recovery
#
# ============================================================================
