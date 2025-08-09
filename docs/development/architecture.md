# Ashfolio Architecture Documentation

This document provides a detailed overview of Ashfolio's technical architecture, illustrating the relationships between its core components, modules, and data flows. Understanding this architecture is crucial for new developers to effectively contribute to the project.

## 1. Overall System Architecture

Ashfolio is built on the Phoenix LiveView framework, leveraging Elixir's OTP capabilities and the Ash Framework for robust data modeling and business logic. It follows a clear separation of concerns to ensure maintainability and extensibility.

```mermaid
graph TD
    subgraph "Ashfolio Application (Elixir/Phoenix)"
        A[User Interface (Phoenix LiveView)] --> B{Business Logic Layer}
        B --> C[Data Layer]
        B --> D[Market Data Services]
        D --> E[ETS Cache]
        D --> F[External APIs (Yahoo Finance)]
        C --> G[(SQLite Database)]
    end

    subgraph "Business Logic Layer"
        B1[Ash Resources] --> B2[Portfolio Calculators]
        B1 --> B3[Validations & Actions]
    end

    subgraph "Data Layer"
        C1[AshSqlite Data Layer] --> G
        C2[Ecto Adapters] --> G
    end

    subgraph "Market Data Services"
        D1[PriceManager GenServer] --> D2[YahooFinance Module]
        D1 --> E
        D2 --> F
    end

    A -- "User Interactions (LiveView Events)" --> B
    B -- "Data Operations (Ash Actions)" --> C
    B -- "Price Requests" --> D
    D -- "Cached Prices" --> E
    D -- "API Calls" --> F
    C -- "Data Storage" --> G
    E -- "Price Data" --> B
```

## 2. Ash Resources and Relationships

The Ash Framework forms the backbone of Ashfolio's data model and business logic. Each resource encapsulates a core domain concept and defines its attributes, relationships, and available actions.

```mermaid
erDiagram
    User ||--o{ Account : has
    User ||--o{ Transaction : has
    Account ||--o{ Transaction : has
    Symbol ||--o{ Transaction : has

    User { 
        uuid id PK
        string name
        string currency
        string locale
    }
    Account {
        uuid id PK
        uuid user_id FK
        string name
        string platform
        decimal balance
        boolean is_excluded
    }
    Symbol {
        uuid id PK
        string symbol
        string name
        decimal current_price
        datetime price_updated_at
    }
    Transaction {
        uuid id PK
        uuid user_id FK
        uuid account_id FK
        uuid symbol_id FK
        atom type
        decimal quantity
        decimal unit_price
        decimal fee
        date date
        decimal total_amount
    }
```

## 3. LiveView Component Flow

Phoenix LiveView handles the dynamic user interface, providing real-time updates and interactive components. The application uses a component-based approach for UI modularity.

```mermaid
graph TD
    LV[LiveView Page (e.g., DashboardLive, AccountLive.Index)] --> LC[LiveComponent (e.g., FormComponent)]
    LV -- "mount/3 (initial state)" --> LV
    LV -- "handle_event/3 (user interaction)" --> LV
    LV -- "handle_info/3 (async updates)" --> LV
    LC -- "update/2 (component lifecycle)" --> LC
    LC -- "handle_event/3 (component interaction)" --> LC
    LC -- "send/2 (parent communication)" --> LV

    subgraph "Example: Account Management"
        ALI[AccountLive.Index] --> ALFC[AccountLive.FormComponent]
        ALI -- "new_account / edit_account events" --> ALFC
        ALFC -- "{:saved, account} / :cancel messages" --> ALI
        ALI -- "list_accounts()" --> AR[Account Ash Resource]
        ALFC -- "Account.create() / Account.update()" --> AR
    end
```

## 4. Market Data Flow

The market data system is responsible for fetching, caching, and providing current prices for symbols. It's designed for resilience and efficiency.

```mermaid
graph TD
    UI[User Interface (e.g., DashboardLive)] --> PM[PriceManager GenServer]
    PM -- "fetch_prices()" --> YF[YahooFinance Module]
    YF -- "HTTP Request" --> EXT[External Yahoo Finance API]
    EXT -- "Price Data (JSON)" --> YF
    YF -- "Parsed Price" --> PM
    PM -- "Cache Price" --> ETS[ETS Cache]
    ETS -- "Retrieve Price" --> PM
    PM -- "Update UI" --> UI

    subgraph "PriceManager Internal Flow"
        PMI[PriceManager] -- "Periodically / On Request" --> PMF[Fetch & Cache Logic]
        PMF -- "Update Symbol Resource" --> SR[Symbol Ash Resource]
    end
```

## 5. Ecto Schema (Underlying Ash Resources)

While Ash Resources provide the primary interface for data modeling, it's helpful to understand the underlying Ecto schemas that AshSqlite generates and manages. These represent the actual database table structures.

```mermaid
erDiagram
    users { 
        text id PK
        text name
        text currency
        text locale
        datetime inserted_at
        datetime updated_at
    }
    accounts {
        text id PK
        text user_id FK
        text name
        text platform
        text currency
        boolean is_excluded
        decimal balance
        datetime inserted_at
        datetime updated_at
    }
    symbols {
        text id PK
        text symbol UNIQUE
        text name
        text asset_class
        text currency
        text isin
        text sectors
        text countries
        text data_source
        decimal current_price
        datetime price_updated_at
        datetime inserted_at
        datetime updated_at
    }
    transactions {
        text id PK
        text user_id FK
        text account_id FK
        text symbol_id FK
        text type
        decimal quantity
        decimal unit_price
        decimal fee
        date date
        text currency
        text comment
        boolean is_draft
        datetime inserted_at
        datetime updated_at
    }
```
