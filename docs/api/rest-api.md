# Ashfolio Local REST API Documentation

## Overview

The Ashfolio application provides a local REST API for accessing portfolio data. The API is available only on localhost and requires no authentication, making it suitable for local development, testing, and personal automation scripts.

**Base URL:** `http://localhost:4000/api/v1`

**Authentication:** None required (localhost-only access)

**Content-Type:** `application/json`

## API Endpoints

### Portfolio Summary

Get a comprehensive summary of the portfolio including total value, returns, and key metrics.

```http
GET /api/v1/portfolio/summary
```

**Response:**

```json
{
  "total_value": "25000.00",
  "cost_basis": "22500.00",
  "total_return": "2500.00",
  "total_return_percent": "11.11",
  "holdings_count": 5,
  "last_updated": "2025-08-06T10:30:00Z"
}
```

**Response Fields:**

- `total_value`: Current total portfolio value in USD
- `cost_basis`: Total amount invested (cost basis) in USD
- `total_return`: Dollar amount of gains/losses in USD
- `total_return_percent`: Percentage return on investment
- `holdings_count`: Number of unique holdings in portfolio
- `last_updated`: Timestamp of last price update (ISO 8601 format)

### Holdings List

Get detailed information about all current holdings in the portfolio.

```http
GET /api/v1/holdings
```

**Response:**

```json
{
  "holdings": [
    {
      "symbol": "AAPL",
      "name": "Apple Inc.",
      "quantity": "100.00",
      "current_price": "150.00",
      "current_value": "15000.00",
      "cost_basis": "13500.00",
      "average_cost": "135.00",
      "unrealized_pnl": "1500.00",
      "unrealized_pnl_pct": "11.11"
    },
    {
      "symbol": "MSFT",
      "name": "Microsoft Corporation",
      "quantity": "50.00",
      "current_price": "200.00",
      "current_value": "10000.00",
      "cost_basis": "9000.00",
      "average_cost": "180.00",
      "unrealized_pnl": "1000.00",
      "unrealized_pnl_pct": "11.11"
    }
  ]
}
```

**Holdings Object Fields:**

- `symbol`: Stock ticker symbol
- `name`: Company or security name
- `quantity`: Number of shares held
- `current_price`: Current market price per share
- `current_value`: Total current value (quantity × current_price)
- `cost_basis`: Total amount paid for this holding
- `average_cost`: Average cost per share (cost_basis ÷ quantity)
- `unrealized_pnl`: Unrealized profit/loss in dollars
- `unrealized_pnl_pct`: Unrealized profit/loss as percentage

### Accounts List

Get information about all investment accounts.

```http
GET /api/v1/accounts
```

**Response:**

```json
{
  "accounts": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Schwab Brokerage",
      "platform": "Schwab",
      "balance": "25000.00",
      "is_excluded": false,
      "transaction_count": 15,
      "created_at": "2025-01-01T00:00:00Z",
      "updated_at": "2025-08-06T10:30:00Z"
    }
  ]
}
```

**Account Object Fields:**

- `id`: Unique account identifier (UUID)
- `name`: User-defined account name
- `platform`: Brokerage platform (e.g., "Schwab", "Fidelity")
- `balance`: Current account balance in USD
- `is_excluded`: Whether account is excluded from portfolio calculations
- `transaction_count`: Number of transactions in this account
- `created_at`: Account creation timestamp (ISO 8601)
- `updated_at`: Last modification timestamp (ISO 8601)

### Transactions List

Get all transactions with optional filtering by account or date range.

```http
GET /api/v1/transactions
GET /api/v1/transactions?account_id={account_id}
GET /api/v1/transactions?start_date={YYYY-MM-DD}&end_date={YYYY-MM-DD}
```

**Query Parameters:**

- `account_id` (optional): Filter transactions by account UUID
- `start_date` (optional): Filter transactions from this date (YYYY-MM-DD format)
- `end_date` (optional): Filter transactions to this date (YYYY-MM-DD format)
- `limit` (optional): Maximum number of transactions to return (default: 100)
- `offset` (optional): Number of transactions to skip for pagination (default: 0)

**Response:**

```json
{
  "transactions": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "type": "BUY",
      "symbol": "AAPL",
      "symbol_name": "Apple Inc.",
      "account_name": "Schwab Brokerage",
      "quantity": "100.00",
      "price": "135.00",
      "fee": "9.95",
      "total_amount": "13509.95",
      "date": "2025-01-15",
      "comment": "Initial AAPL position",
      "created_at": "2025-01-15T14:30:00Z"
    }
  ],
  "pagination": {
    "total": 150,
    "limit": 100,
    "offset": 0,
    "has_more": true
  }
}
```

**Transaction Object Fields:**

- `id`: Unique transaction identifier (UUID)
- `type`: Transaction type (BUY, SELL, DIVIDEND, FEE, INTEREST)
- `symbol`: Stock ticker symbol
- `symbol_name`: Company or security name
- `account_name`: Name of the account this transaction belongs to
- `quantity`: Number of shares (positive for BUY, negative for SELL)
- `price`: Price per share at time of transaction
- `fee`: Transaction fee charged by broker
- `total_amount`: Total transaction amount including fees
- `date`: Transaction date (YYYY-MM-DD format)
- `comment`: Optional user comment
- `created_at`: Transaction creation timestamp (ISO 8601)

### Price Refresh

Trigger a manual refresh of current market prices for all holdings.

```http
POST /api/v1/prices/refresh
```

**Response:**

```json
{
  "status": "success",
  "message": "Prices refreshed successfully",
  "updated_symbols": ["AAPL", "MSFT", "GOOGL"],
  "failed_symbols": [],
  "refresh_timestamp": "2025-08-06T10:35:00Z"
}
```

**Response Fields:**

- `status`: "success" or "error"
- `message`: Human-readable status message
- `updated_symbols`: Array of symbols that were successfully updated
- `failed_symbols`: Array of symbols that failed to update
- `refresh_timestamp`: Timestamp when refresh was completed

## Error Responses

All endpoints may return error responses in the following format:

```json
{
  "error": {
    "code": "INVALID_REQUEST",
    "message": "The requested resource was not found",
    "details": "Account with ID 550e8400-e29b-41d4-a716-446655440000 does not exist"
  }
}
```

**Common Error Codes:**

- `INVALID_REQUEST`: Malformed request or invalid parameters
- `NOT_FOUND`: Requested resource does not exist
- `SERVER_ERROR`: Internal server error
- `SERVICE_UNAVAILABLE`: External service (e.g., Yahoo Finance) unavailable

**HTTP Status Codes:**

- `200 OK`: Request successful
- `400 Bad Request`: Invalid request parameters
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error
- `503 Service Unavailable`: External service unavailable

## Usage Examples

### Get Portfolio Summary with curl

```bash
curl http://localhost:4000/api/v1/portfolio/summary
```

### Get Holdings for Analysis

```bash
curl http://localhost:4000/api/v1/holdings | jq '.holdings[] | select(.unrealized_pnl_pct > 10)'
```

### Refresh Prices Before Market Close

```bash
curl -X POST http://localhost:4000/api/v1/prices/refresh
```

### Export Transactions to CSV

```bash
curl http://localhost:4000/api/v1/transactions | jq -r '.transactions[] | [.date, .type, .symbol, .quantity, .price, .total_amount] | @csv'
```

## Rate Limiting

The API has no rate limiting since it's designed for localhost-only access. However, the price refresh endpoint is limited to one request per minute to avoid overwhelming external market data providers.

## Data Formats

- **Dates**: ISO 8601 format (YYYY-MM-DDTHH:MM:SSZ) for timestamps, YYYY-MM-DD for date-only fields
- **Currency**: USD amounts as decimal strings with 2 decimal places (e.g., "1234.56")
- **Quantities**: Share quantities as decimal strings with up to 6 decimal places (e.g., "100.000000")
- **Percentages**: Percentage values as decimal strings (e.g., "11.11" for 11.11%)

## Security Considerations

- **Localhost Only**: The API is only accessible from localhost (127.0.0.1)
- **No Authentication**: No API keys or authentication required
- **No HTTPS**: Uses HTTP since it's localhost-only
- **No CORS**: Cross-origin requests are not supported

This API is designed for local development, testing, and personal automation. It should not be exposed to external networks or used in production environments without proper security measures.
