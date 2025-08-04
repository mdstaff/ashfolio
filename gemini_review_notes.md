# Gemini Review Notes

## Project Understanding

After a thorough review of the Ashfolio project, including the `.kiro` specifications, the codebase, and the `README.md`, I have a comprehensive understanding of the system.

### High-Level Summary
Ashfolio is a **single-user, local portfolio management application** built with a modern Elixir stack. It is designed to be simple, robust, and run on a local machine without any complex setup or authentication. The development process is highly structured, following a phased, spec-driven approach managed within the `.kiro` directory, with a strong emphasis on testing.

### Core Architecture
- **Tech Stack**: The project is built on **Elixir**, **Phoenix 1.7+**, and the **Ash Framework 3.0+**. The frontend is powered by **Phoenix LiveView**, creating a real-time, single-page application experience.
- **Data Layer**: Data is stored in a local **SQLite** database, managed through the `AshSqlite` data layer. All business logic and data modeling are handled by **Ash resources**.
- **Business Logic**: The core logic is well-organized in the `lib/ashfolio` directory.
    - **Ash Resources**: `User`, `Account`, `Symbol`, and `Transaction` resources define the data model and business rules.
    - **Calculation Engine**: A powerful dual-calculator architecture (`Portfolio.Calculator` and `Portfolio.HoldingsCalculator`) provides a rich set of analytics, including total portfolio value, P&L, and FIFO cost basis.
- **Market Data**:
    - Market prices are fetched from the **Yahoo Finance API** using the `HTTPoison` library.
    - A `PriceManager` GenServer coordinates price updates, providing a single point of control for manual refreshes.
    - **ETS** is used for in-memory caching of prices to improve performance and reduce API calls.
- **Web Layer**: The user interface is built with **Phoenix LiveView**, located in `lib/ashfolio_web`. It features a responsive dashboard that displays key portfolio metrics and a detailed, sortable holdings table.
- **Development & Tooling**:
    - The project uses `just` as a command runner to simplify and standardize development tasks like testing, running the server, and managing the database.
    - There is a heavy emphasis on testing, with a comprehensive suite of **192 passing tests** covering Ash resources, calculators, and LiveView components.

### Current Status & Next Steps
- The project is currently in **Phase 7** of its development plan.
- The foundational layers are complete and robust: data models, database, calculation engine, and the main dashboard UI are all functional.
- The immediate next steps are to build out the user interfaces for:
    1.  Triggering the manual price refresh.
    2.  CRUD (Create, Read, Update, Delete) operations for Accounts.
    3.  CRUD operations for Transactions.

## Initial Questions (Answered)

- **What is the current status of the project?**
  - The project is in active development, approximately 69% complete according to the `tasks.md` file. The core backend functionality and the main dashboard are complete.
- **Are there any specific areas of the project that the user wants me to focus on?**
  - The initial request was a general review and README update, which I have completed.
- **What are the testing and deployment strategies for this project?**
  - **Testing**: The project has a very strong testing culture. It uses ExUnit with Mox for mocking external services. The `just test` command runs a comprehensive suite of 192 tests.
  - **Deployment**: The application is designed for local deployment only. The `just dev` command is sufficient to set up and run the application on a local machine. There are no complex deployment configurations.

## Completed TODOs

- [x] Read the contents of the `.kiro` directory to understand the project's specifications and steering instructions.
- [x] Review the `mix.exs` file to understand the project's dependencies.
- [x] Review the `lib` directory to understand the core application logic.
- [x] Review the existing `README.md` file.
- [x] Update the `README.md` with my findings.
- [x] Update this notes file with my current understanding.
