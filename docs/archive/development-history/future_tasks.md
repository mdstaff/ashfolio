# Ashfolio Future Development Tasks

This document breaks down the high-level features from `future_features.md` into a more granular list of development tasks. This can serve as a roadmap for future work on the project.

---

## Feature: CSV Import/Export for Transactions

**Goal**: Allow users to easily bulk-import and export their transaction history.

- [ ] **Phase 1: Backend & Export**
    - [ ] Create a new Ash action on the `Transaction` resource for bulk creation from a list of maps.
    - [ ] Implement a simple CSV export function that queries all transactions and generates a CSV file.
    - [ ] Create a new route (e.g., `/transactions/export`) that triggers the CSV export.
    - [ ] Write tests for the bulk creation action and the export function.

- [ ] **Phase 2: Import UI**
    - [ ] Create a new `TransactionImportLive` LiveView component.
    - [ ] Design and build the UI for uploading a CSV file.
    - [ ] Implement the backend logic in the LiveView to parse the uploaded CSV.
    - [ ] Add a column mapping interface to allow users to match CSV columns to transaction fields.
    - [ ] Implement validation and error handling for the import process, showing a preview and highlighting any issues.
    - [ ] Write LiveView tests for the import UI.

---

## Feature: Basic Portfolio Charting

**Goal**: Provide users with visual representations of their portfolio's performance and allocation.

- [ ] **Phase 1: Historical Performance Chart**
    - [ ] Research and select a JavaScript charting library (e.g., Chart.js, ApexCharts.js) and integrate it into the project.
    - [ ] Create a new `PortfolioSnapshot` Ash resource to store daily portfolio value, cost basis, and P&L.
    - [ ] Create a recurring task (e.g., a daily GenServer call or a future Oban job) to create a new `PortfolioSnapshot`.
    - [ ] Create a new function or API endpoint to provide data for the historical performance chart.
    - [ ] Implement the line chart on the dashboard, showing portfolio value over time.
    - [ ] Write tests for the snapshot creation logic and the chart data endpoint.

- [ ] **Phase 2: Asset Allocation Chart**
    - [ ] Create a new function to calculate asset allocation percentages based on the `Symbol`'s `asset_class`.
    - [ ] Implement a pie or donut chart on the dashboard to visualize the asset allocation.
    - [ ] Add the ability to view allocation by other criteria, such as sector or country.
    - [ ] Write tests for the allocation calculation.

---

## Feature: Liability and Cash Tracking

**Goal**: Allow users to track more than just investments to get a true picture of their net worth.

- [ ] **Phase 1: Data Model & Backend**
    - [ ] Create a new `Liability` Ash resource with attributes like `name`, `type` (e.g., loan, mortgage), `initial_amount`, `current_balance`, and `interest_rate`.
    - [ ] Create the corresponding database migration for the `liabilities` table.
    - [ ] Add a `type` attribute to the `Account` resource to distinguish between `:investment` and `:cash` accounts.
    - [ ] Update the portfolio calculation engine to include liabilities and cash in a new "Net Worth" calculation.
    - [ ] Write tests for the `Liability` resource and the updated net worth calculations.

- [ ] **Phase 2: UI Implementation**
    - [ ] Create a new LiveView for managing liabilities (CRUD operations).
    - [ ] Add a "Net Worth" display to the main dashboard.
    - [ ] Update the account management UI to handle the new account types.

---

## Feature: Dark Mode

**Goal**: Provide a dark theme for the application to improve user experience.

- [ ] **Phase 1: Implementation**
    - [ ] Configure `tailwind.config.js` to enable dark mode support.
    - [ ] Add a UI toggle (e.g., in the header) to switch between light, dark, and system themes.
    - [ ] Use JavaScript to manage the theme state in the browser's `localStorage`.
    - [ ] Update all core CSS and components to use Tailwind's `dark:` variants for styling.
    - [ ] Ensure all UI elements, including charts, are styled correctly in both modes.

---

## Feature: Advanced Performance Analytics

**Goal**: Provide users with more sophisticated tools to analyze their investment performance.

- [ ] **Phase 1: Time-Weighted Return (TWR)**
    - [ ] Research and document the formula and data requirements for TWR.
    - [ ] Implement the TWR calculation logic, which will likely require iterating through transactions and portfolio snapshots to account for cash flows.
    - [ ] Add a new "Analytics" page or enhance the dashboard to display TWR for various periods (YTD, 1Y, All-time).
    - [ ] Write extensive tests to ensure the accuracy of the TWR calculation.

- [ ] **Phase 2: Money-Weighted Return (MWR) / IRR**
    - [ ] Research and document the formula for MWR/IRR.
    - [ ] Implement the MWR calculation logic. This is an iterative calculation and may require a numerical methods library or a custom implementation.
    - [ ] Add the MWR metric to the "Analytics" page.
    - [ ] Write tests to validate the MWR calculation.

---

## Feature: Multi-Currency Support

**Goal**: Allow users to track investments in different currencies.

- [ ] **Phase 1: Backend Foundation**
    - [ ] Add a `currency` attribute to the `Transaction` resource.
    - [ ] Add a `base_currency` setting to the `User` resource.
    - [ ] Integrate a reliable foreign exchange rate API.
    - [ ] Create a new `ExchangeRate` resource and a caching mechanism for historical exchange rates.

- [ ] **Phase 2: Calculation Engine Update**
    - [ ] Update the entire calculation engine (`Calculator` and `HoldingsCalculator`) to handle currency conversions. All calculations will need to be converted to the user's base currency before being displayed.

- [ ] **Phase 3: UI Update**
    - [ ] Update the UI to allow specifying the currency for each transaction and account.
    - [ ] Update all UI displays to show the correct currency symbols and converted values.

---

## Feature: Progressive Web App (PWA) Features

**Goal**: Improve the mobile and offline experience.

- [ ] **Phase 1: PWA Foundation**
    - [ ] Create a `manifest.json` file to define the app's name, icons, and other PWA properties.
    - [ ] Create a basic service worker (`sw.js`) to handle asset caching.
    - [ ] Modify the root layout to register the service worker.
    - [ ] Ensure the application is served over HTTPS (a PWA requirement for many features).

- [ ] **Phase 2: Offline Functionality**
    - [ ] Implement caching strategies in the service worker for API data (e.g., portfolio data).
    - [ ] Allow read-only access to the last-synced data when the user is offline.
