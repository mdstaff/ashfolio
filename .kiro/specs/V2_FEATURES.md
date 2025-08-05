# Ashfolio V2: Future Enhancements

This document outlines features that are planned for a future V2 release of Ashfolio. These items are intentionally deferred from the initial Proof of Concept (PoC) to keep the initial scope focused and manageable.

## V2 Feature Roadmap

### 1. Advanced Data Management

*   **CSV Import/Export:**
    *   Implement a robust CSV import wizard to allow users to bulk-import transactions from various brokerage formats.
    *   Provide flexible column mapping to handle different CSV layouts.
    *   Add functionality to export the entire transaction history or filtered views to CSV.

*   **Draft Transactions:**
    *   Allow users to save transactions as drafts.
    *   Drafts will not be included in portfolio calculations until they are explicitly confirmed.
    *   Provide a dedicated view to manage and finalize draft transactions.

### 2. Enhanced User Interface & Experience

*   **Symbol Autocomplete:**
    *   In the transaction form, implement a symbol input field with real-time autocomplete suggestions.
    *   The autocomplete will search the existing `Symbol` database and potentially query external APIs for new symbols.

*   **Real-time Price Lookup:**
    *   When a symbol is selected in the transaction form, automatically fetch and display its current market price to assist with data entry.

*   **Inline Table Editing:**
    *   Allow users to edit transactions directly within the transaction list table for a faster, more spreadsheet-like editing experience.

### 3. Advanced Analytics & Reporting

*   **Time-Weighted Return (TWR) & Money-Weighted Return (MWR/IRR):**
    *   Implement more advanced performance calculation methodologies.

*   **Tax Lot Management:**
    *   Support for different cost basis accounting methods (FIFO, LIFO, Specific Lot).
    *   Provide tools for tax-loss harvesting.

### 4. Multi-Currency Support

*   Expand the application to support holding accounts and transactions in multiple currencies.
*   Implement automatic currency conversion for portfolio summary views.
