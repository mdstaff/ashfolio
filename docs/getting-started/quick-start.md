# Quick Start Guide

Get Ashfolio running and explore its features in 10 minutes!

## Prerequisites Check

Before starting, ensure you have:

- ✅ **Elixir 1.14+** and **Erlang/OTP 25+**
- ✅ **macOS** (currently optimized for Apple Silicon)
- ✅ **Just task runner**: `brew install just`

*Need to install these? See the [Installation Guide](installation.md)*

## 5-Minute Setup

1. **Clone and enter the project**:
   ```bash
   git clone https://github.com/mdstaff/ashfolio.git
   cd ashfolio
   ```

2. **One-command setup**:
   ```bash
   just dev
   ```
   *This installs dependencies, sets up the database, and starts the Phoenix server*

3. **Access the application**:
   - Open [http://localhost:4000](http://localhost:4000)
   - You'll see a pre-populated portfolio with sample data!

## Explore the Features

### 📊 Dashboard
- **Portfolio Value**: Total worth of all holdings
- **Returns**: Gains/losses with color coding (green = gains, red = losses)
- **Holdings Table**: Complete view of all positions with current prices

### 💰 Account Management
- **View Accounts**: Navigate to "Accounts" to see investment accounts (Schwab, Fidelity, etc.)
- **Create Account**: Click "New Account" to add your own
- **Toggle Exclusion**: Include/exclude accounts from portfolio calculations

### 📈 Transaction Management
- **View Transactions**: Navigate to "Transactions" to see all investment activity
- **Add Transaction**: Click "New Transaction" to record buys, sells, dividends
- **Transaction Types**: BUY, SELL, DIVIDEND, FEE, INTEREST, LIABILITY

### 💱 Price Updates
- **Manual Refresh**: Use the refresh button on the dashboard
- **Yahoo Finance**: Prices are fetched from Yahoo Finance API
- **Cache System**: Prices are cached for performance

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

- **User**: Default local user
- **Accounts**: Schwab Brokerage, Fidelity 401k, Crypto Wallet
- **Symbols**: AAPL, MSFT, GOOGL, SPY, VTI, BTC-USD, TSLA, NVDA
- **Transactions**: Mix of buys, sells, and dividends for realistic portfolio

## Next Steps

Now that Ashfolio is running:

1. **Explore the Interface**: Click through all the pages and features
2. **Understand the Architecture**: Read the [Architecture Overview](../development/architecture.md)
3. **Make Your First Change**: Follow the [First Contribution Guide](first-contribution.md)
4. **Run Some Tests**: Try `just test-fast` to see the testing framework

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