# Ashfolio API Endpoints Reference

This document provides detailed technical specifications for all Ashfolio REST API endpoints.

## Base Configuration

- **Base URL**: `http://localhost:4000/api/v1`
- **Content-Type**: `application/json`
- **Authentication**: None (localhost-only)
- **Rate Limiting**: None (except price refresh: 1 request/minute)

## Endpoint Specifications

### 1. Portfolio Summary

**Endpoint**: `GET /api/v1/portfolio/summary`

**Description**: Returns comprehensive portfolio performance metrics and summary data.

**Parameters**: None

**Response Schema**:

```json
{
  "type": "object",
  "properties": {
    "total_value": {
      "type": "string",
      "format": "decimal",
      "description": "Current portfolio value in USD"
    },
    "cost_basis": {
      "type": "string",
      "format": "decimal",
      "description": "Total invested amount in USD"
    },
    "total_return": {
      "type": "string",
      "format": "decimal",
      "description": "Total profit/loss in USD"
    },
    "total_return_percent": {
      "type": "string",
      "format": "decimal",
      "description": "Return percentage"
    },
    "holdings_count": {
      "type": "integer",
      "description": "Number of unique holdings"
    },
    "last_updated": {
      "type": "string",
      "format": "date-time",
      "description": "Last price update timestamp"
    }
  },
  "required": [
    "total_value",
    "cost_basis",
    "total_return",
    "total_return_percent",
    "holdings_count"
  ]
}
```

**Example Response**:

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

**Error Responses**:

- `500 Internal Server Error`: Portfolio calculation failed

---

### 2. Holdings List

**Endpoint**: `GET /api/v1/holdings`

**Description**: Returns detailed information about all current portfolio holdings.

**Parameters**: None

**Response Schema**:

```json
{
  "type": "object",
  "properties": {
    "holdings": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "symbol": { "type": "string", "description": "Stock ticker symbol" },
          "name": {
            "type": "string",
            "description": "Company or security name"
          },
          "quantity": {
            "type": "string",
            "format": "decimal",
            "description": "Number of shares held"
          },
          "current_price": {
            "type": "string",
            "format": "decimal",
            "description": "Current market price per share"
          },
          "current_value": {
            "type": "string",
            "format": "decimal",
            "description": "Total current value"
          },
          "cost_basis": {
            "type": "string",
            "format": "decimal",
            "description": "Total amount paid"
          },
          "average_cost": {
            "type": "string",
            "format": "decimal",
            "description": "Average cost per share"
          },
          "unrealized_pnl": {
            "type": "string",
            "format": "decimal",
            "description": "Unrealized profit/loss"
          },
          "unrealized_pnl_pct": {
            "type": "string",
            "format": "decimal",
            "description": "Unrealized P&L percentage"
          }
        },
        "required": [
          "symbol",
          "name",
          "quantity",
          "current_price",
          "current_value",
          "cost_basis",
          "average_cost",
          "unrealized_pnl",
          "unrealized_pnl_pct"
        ]
      }
    }
  },
  "required": ["holdings"]
}
```

**Example Response**:

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
    }
  ]
}
```

**Error Responses**:

- `500 Internal Server Error`: Holdings calculation failed

---

### 3. Accounts List

**Endpoint**: `GET /api/v1/accounts`

**Description**: Returns information about all investment accounts.

**Parameters**: None

**Response Schema**:

```json
{
  "type": "object",
  "properties": {
    "accounts": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "id": {
            "type": "string",
            "format": "uuid",
            "description": "Unique account identifier"
          },
          "name": {
            "type": "string",
            "description": "User-defined account name"
          },
          "platform": {
            "type": "string",
            "description": "Brokerage platform name"
          },
          "balance": {
            "type": "string",
            "format": "decimal",
            "description": "Current account balance"
          },
          "is_excluded": {
            "type": "boolean",
            "description": "Whether excluded from calculations"
          },
          "transaction_count": {
            "type": "integer",
            "description": "Number of transactions"
          },
          "created_at": {
            "type": "string",
            "format": "date-time",
            "description": "Creation timestamp"
          },
          "updated_at": {
            "type": "string",
            "format": "date-time",
            "description": "Last update timestamp"
          }
        },
        "required": [
          "id",
          "name",
          "balance",
          "is_excluded",
          "transaction_count",
          "created_at",
          "updated_at"
        ]
      }
    }
  },
  "required": ["accounts"]
}
```

**Example Response**:

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

**Error Responses**:

- `500 Internal Server Error`: Account retrieval failed

---

### 4. Transactions List

**Endpoint**: `GET /api/v1/transactions`

**Description**: Returns transaction history with optional filtering and pagination.

**Query Parameters**:

- `account_id` (optional): UUID of account to filter by
- `start_date` (optional): Start date filter (YYYY-MM-DD format)
- `end_date` (optional): End date filter (YYYY-MM-DD format)
- `type` (optional): Transaction type filter (BUY, SELL, DIVIDEND, FEE, INTEREST)
- `symbol` (optional): Symbol filter (e.g., "AAPL")
- `limit` (optional): Maximum results to return (default: 100, max: 1000)
- `offset` (optional): Number of results to skip (default: 0)

**Response Schema**:

```json
{
  "type": "object",
  "properties": {
    "transactions": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "id": {
            "type": "string",
            "format": "uuid",
            "description": "Unique transaction identifier"
          },
          "type": {
            "type": "string",
            "enum": ["BUY", "SELL", "DIVIDEND", "FEE", "INTEREST"],
            "description": "Transaction type"
          },
          "symbol": { "type": "string", "description": "Stock ticker symbol" },
          "symbol_name": {
            "type": "string",
            "description": "Company or security name"
          },
          "account_name": { "type": "string", "description": "Account name" },
          "quantity": {
            "type": "string",
            "format": "decimal",
            "description": "Number of shares"
          },
          "price": {
            "type": "string",
            "format": "decimal",
            "description": "Price per share"
          },
          "fee": {
            "type": "string",
            "format": "decimal",
            "description": "Transaction fee"
          },
          "total_amount": {
            "type": "string",
            "format": "decimal",
            "description": "Total transaction amount"
          },
          "date": {
            "type": "string",
            "format": "date",
            "description": "Transaction date"
          },
          "comment": {
            "type": "string",
            "description": "Optional user comment"
          },
          "created_at": {
            "type": "string",
            "format": "date-time",
            "description": "Creation timestamp"
          }
        },
        "required": [
          "id",
          "type",
          "symbol",
          "symbol_name",
          "account_name",
          "quantity",
          "price",
          "fee",
          "total_amount",
          "date",
          "created_at"
        ]
      }
    },
    "pagination": {
      "type": "object",
      "properties": {
        "total": {
          "type": "integer",
          "description": "Total number of transactions"
        },
        "limit": { "type": "integer", "description": "Results limit applied" },
        "offset": {
          "type": "integer",
          "description": "Results offset applied"
        },
        "has_more": {
          "type": "boolean",
          "description": "Whether more results available"
        }
      },
      "required": ["total", "limit", "offset", "has_more"]
    }
  },
  "required": ["transactions", "pagination"]
}
```

**Example Request**:

```
GET /api/v1/transactions?account_id=550e8400-e29b-41d4-a716-446655440000&limit=50
```

**Example Response**:

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
    "limit": 50,
    "offset": 0,
    "has_more": true
  }
}
```

**Error Responses**:

- `400 Bad Request`: Invalid query parameters
- `404 Not Found`: Account not found (when account_id specified)
- `500 Internal Server Error`: Transaction retrieval failed

---

### 5. Price Refresh

**Endpoint**: `POST /api/v1/prices/refresh`

**Description**: Triggers manual refresh of current market prices for all holdings.

**Parameters**: None

**Rate Limiting**: 1 request per minute

**Response Schema**:

```json
{
  "type": "object",
  "properties": {
    "status": {
      "type": "string",
      "enum": ["success", "partial", "error"],
      "description": "Refresh status"
    },
    "message": {
      "type": "string",
      "description": "Human-readable status message"
    },
    "updated_symbols": {
      "type": "array",
      "items": { "type": "string" },
      "description": "Successfully updated symbols"
    },
    "failed_symbols": {
      "type": "array",
      "items": { "type": "string" },
      "description": "Failed to update symbols"
    },
    "refresh_timestamp": {
      "type": "string",
      "format": "date-time",
      "description": "Refresh completion timestamp"
    }
  },
  "required": [
    "status",
    "message",
    "updated_symbols",
    "failed_symbols",
    "refresh_timestamp"
  ]
}
```

**Example Response (Success)**:

```json
{
  "status": "success",
  "message": "All prices refreshed successfully",
  "updated_symbols": ["AAPL", "MSFT", "GOOGL"],
  "failed_symbols": [],
  "refresh_timestamp": "2025-08-06T10:35:00Z"
}
```

**Example Response (Partial Success)**:

```json
{
  "status": "partial",
  "message": "Some prices failed to refresh",
  "updated_symbols": ["AAPL", "MSFT"],
  "failed_symbols": ["GOOGL"],
  "refresh_timestamp": "2025-08-06T10:35:00Z"
}
```

**Error Responses**:

- `429 Too Many Requests`: Rate limit exceeded (1 request/minute)
- `503 Service Unavailable`: External market data service unavailable
- `500 Internal Server Error`: Price refresh system error

---

## Common Response Patterns

### Success Response

All successful responses return HTTP 200 OK with JSON data as specified above.

### Error Response Format

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": "Additional error details (optional)"
  }
}
```

### Error Codes

- `INVALID_REQUEST`: Malformed request or invalid parameters
- `NOT_FOUND`: Requested resource does not exist
- `RATE_LIMITED`: Request rate limit exceeded
- `SERVER_ERROR`: Internal server error
- `SERVICE_UNAVAILABLE`: External service unavailable
- `CALCULATION_ERROR`: Portfolio calculation failed

## Data Type Specifications

### Decimal Format

All monetary amounts and quantities are returned as decimal strings to preserve precision:

- Currency: "1234.56" (2 decimal places)
- Quantities: "100.000000" (up to 6 decimal places)
- Percentages: "11.11" (2 decimal places)

### Date/Time Format

- Timestamps: ISO 8601 format with UTC timezone (e.g., "2025-08-06T10:30:00Z")
- Dates: YYYY-MM-DD format (e.g., "2025-08-06")

### UUID Format

All IDs are UUID v4 format: "550e8400-e29b-41d4-a716-446655440000"

## Implementation Notes

### Caching

- Portfolio and holdings data is calculated in real-time
- Price data is cached in ETS with timestamps
- Account and transaction data is retrieved from SQLite database

### Performance

- All endpoints are optimized for local access
- Large transaction lists use pagination to maintain performance
- Holdings calculations use efficient FIFO cost basis algorithms

### Reliability

- All endpoints include comprehensive error handling
- External API failures gracefully degrade to cached data
- Database errors return appropriate HTTP status codes
