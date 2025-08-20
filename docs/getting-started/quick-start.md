# Quick Start Guide

Get Ashfolio running and explore its features in 10 minutes!

## Prerequisites Check

Before starting, ensure you have:

- **Elixir 1.14+** and **Erlang/OTP 25+**
- **macOS** (currently optimized for Apple Silicon)
- `brew install just`

_Need to install these? See the [Installation Guide](installation.md)_

## 5-Minute Setup

1.  ```bash
    git clone https://github.com/mdstaff/ashfolio.git
    cd ashfolio
    ```

2.  ```bash
    just dev
    ```

    _This installs dependencies, sets up the database, and starts the Phoenix server_

3.  - Open [http://localhost:4000](http://localhost:4000)
    - You'll see a pre-populated portfolio with sample data!

## Explore the Features

### 📊 Dashboard

- Total worth of all holdings
- Gains/losses with color coding (green = gains, red = losses)
- Complete view of all positions with current prices

### 💰 Account Management

- Navigate to "Accounts" to see investment accounts (Schwab, Fidelity, etc.)
- Click "New Account" to add your own
- Include/exclude accounts from portfolio calculations

### 📈 Transaction Management

- Navigate to "Transactions" to see all investment activity
- Click "New Transaction" to record buys, sells, dividends
- BUY, SELL, DIVIDEND, FEE, INTEREST, LIABILITY

### 💱 Price Updates

- Use the refresh button on the dashboard
- Prices are fetched from Yahoo Finance API
- Prices are cached for performance

## Development Commands

```bash
# Essential development commands
just dev                    # Start everything (most common)
just server                # Start server only (if already set up)
just test                  # Run test suite
just test-fast             # Quick tests for development
just format                # Format code
just check                 # Format + compile + test
```

## Sample Data Overview

The pre-seeded database includes:

- Default local user
- Schwab Brokerage, Fidelity 401k, Crypto Wallet
- AAPL, MSFT, GOOGL, SPY, VTI, BTC-USD, TSLA, NVDA
- Mix of buys, sells, and dividends for realistic portfolio

## Next Steps

Now that Ashfolio is running:

1.  Click through all the pages and features
2.  Read the [Architecture Overview](../development/architecture.md)
3.  Follow the [First Contribution Guide](first-contribution.md)
4.  Try `just test-fast` to see the testing framework

## Common Issues

### Port Already in Use

```bash
# Kill existing Phoenix server
pkill -f "phx.server"
# Or use a different port
PORT=4001 just server
```

### Database Issues

```bash
# Reset database
just reset
# Or backup and restore
just backup
just restore
```

### Test Failures

```bash
# Run database health check
just test-health-check
# Reset test database if needed
just test-db-emergency-reset
```

---

**Having issues?** Check the [Troubleshooting Guide](troubleshooting.md)  
**Ready to contribute?** See [First Contribution Guide](first-contribution.md)
