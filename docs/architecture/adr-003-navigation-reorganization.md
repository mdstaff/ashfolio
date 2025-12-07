# ADR 003: Navigation Reorganization

## Status
Accepted

## Context
The Ashfolio application's navigation bar has grown to include many items (Dashboard, Accounts, Transactions, Corporate Actions, Expenses, Analytics, Net Worth, Goals, Money Ratios, Forecast, Retirement, Advanced Analytics).

The current horizontal scrolling list (`overflow-x-auto`) was an interim fix but is becoming unwieldy as features grow. Users struggle to find related items (e.g., "Expenses" and "Analytics" are separate top-level items), and the sheer number of links increases cognitive load.

## Decision
We will transition from a flat list to a **Grouped Navigation Structure**. This will organize features into logical categories, reducing top-level clutter and improving findability.

### Proposed Grouping Structure

We propose the following top-level categories and sub-items:

1.  **Dashboard**
    *   Overview (`/`)

2.  **Portfolio**
    *   Accounts (`/accounts`)
    *   Transactions (`/transactions`)
    *   Corporate Actions (`/corporate-actions`)
    *   Net Worth (`/net_worth`)

3.  **Planning**
    *   Forecast (`/forecast`)
    *   Retirement (`/retirement`)
    *   Goals (`/goals`)
    *   Tax Planning (`/tax-planning`)

4.  **Analysis**
    *   Advanced Analytics (`/advanced_analytics`)
    *   Money Ratios (`/money-ratios`)

5.  **Expenses**
    *   Expense List (`/expenses`)
    *   Expense Analytics (`/expenses/analytics`)

6.  **Settings**
    *   General / AI (`/settings/ai`)
    *   Categories (`/categories`) *(To be exposed)*

### Implementation Strategy
*   **Desktop**: Use dropdown menus (e.g., using `details`/`summary` or a Popover component) for top-level groups.
*   **Mobile**: Use an accordion-style expansion in the mobile drawer.
*   **Tech Stack**: We will leverage Phoenix LiveView components (possibly `CoreComponents` dropdowns if available, or a custom `TopBar.dropdown` component).

## Consequences

### Positive
*   **Scalability**: New features can be added to existing groups without breaking the layout.
*   **Clarity**: Related features (like Expenses and Expense Analytics) are grouped together.
*   **Cleanliness**: Reduces visual noise on the primary interface.

### Negative
*   **Click Depth**: One extra click (or hover) is required to access specific tools.
*   **Complexity**: Requires building robust accessible dropdown components.
