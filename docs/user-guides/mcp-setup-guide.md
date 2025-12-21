# MCP Setup Guide

User Guide
10-15 minutes to setup
Ashfolio v0.9.0+ with MCP integration
AI consent required (see AI Settings Guide)

## Overview

The Model Context Protocol (MCP) enables AI assistants like Claude Desktop to directly access your Ashfolio portfolio data through standardized tools. This guide walks you through setup, configuration, and usage of MCP with Ashfolio.

Key Benefits:

- Natural conversation about your portfolio with AI assistants
- Privacy-controlled data access with four security modes
- Real-time portfolio insights without manual data copying
- Local-first architecture keeps your data secure

## What is Model Context Protocol?

Model Context Protocol (MCP) is an open standard that allows AI assistants to interact with external applications through well-defined tools. Think of it as a secure bridge between your AI assistant and Ashfolio.

How It Works:

1. Your AI assistant (like Claude Desktop) connects to Ashfolio's MCP server
2. The assistant can request data using specific tools (list_accounts, get_portfolio_summary, etc.)
3. Ashfolio filters the data based on your privacy settings
4. The assistant receives the filtered data and can answer your questions

All communication happens locally on your machine - no cloud services involved unless you explicitly enable cloud AI providers.

## What AI Assistants Can Do

With MCP integration, AI assistants can:

Portfolio Analysis:
- "Show me my account balances and allocation"
- "Which accounts have the best performance this year?"
- "What's my overall portfolio diversification score?"

Transaction Tracking:
- "List my recent stock purchases"
- "How much have I invested in AAPL?"
- "Show dividend transactions from last quarter"

Financial Insights:
- "What's my net worth trend over time?"
- "Which sectors am I most exposed to?"
- "Compare my actual vs target asset allocation"

Data Entry:
- "Add an expense: Groceries $87.43 today"
- "Record transaction: Bought 5 MSFT at $380"

All capabilities respect your privacy mode settings - you control exactly what data is shared.

## Prerequisites

Before setting up MCP, ensure you have:

### 1. AI Consent Granted

MCP tools only work after you've granted AI consent in Ashfolio:

1. Navigate to Settings &gt; AI Settings
2. Click "Enable AI Features"
3. Choose your privacy mode (recommended: Anonymized)
4. Review and accept the AI usage terms
5. Confirm consent

See the [AI Settings Guide](ai-settings-guide.md) for detailed instructions.

### 2. Supported AI Client

Currently supported MCP clients:

- **Claude Desktop** (recommended) - Official Anthropic desktop app
- **VS Code with MCP extensions** - For developer workflows
- **Other MCP-compatible tools** - Any client supporting MCP 2024-11-05 spec

This guide focuses on Claude Desktop setup, as it's the most common use case.

### 3. Technical Requirements

- Ashfolio v0.9.0 or later running on your machine
- macOS, Linux, or Windows with Node.js 16+ (for Claude Desktop)
- Basic familiarity with JSON configuration files

## Setup Instructions

### Step 1: Install Claude Desktop

If you haven't already:

1. Download Claude Desktop from [claude.ai/download](https://claude.ai/download)
2. Install the application for your operating system
3. Sign in with your Anthropic account

### Step 2: Configure MCP in Claude Desktop

Claude Desktop uses a configuration file to connect to MCP servers.

#### Locate Configuration File

The configuration file location varies by operating system:

**macOS:**
```
~/Library/Application Support/Claude/claude_desktop_config.json
```

**Windows:**
```
%APPDATA%\Claude\claude_desktop_config.json
```

**Linux:**
```
~/.config/Claude/claude_desktop_config.json
```

If the file doesn't exist, create it with an empty JSON object: `{}`

#### Add Ashfolio MCP Server

Edit the configuration file and add the Ashfolio MCP server configuration:

```json
{
  "mcpServers": {
    "ashfolio": {
      "command": "mix",
      "args": ["ash_ai.mcp"],
      "cwd": "/absolute/path/to/ashfolio",
      "env": {
        "MIX_ENV": "dev"
      }
    }
  }
}
```

**Important:** Replace `/absolute/path/to/ashfolio` with the actual path to your Ashfolio installation.

Example for macOS:
```json
{
  "mcpServers": {
    "ashfolio": {
      "command": "mix",
      "args": ["ash_ai.mcp"],
      "cwd": "/Users/yourname/Projects/ashfolio",
      "env": {
        "MIX_ENV": "dev"
      }
    }
  }
}
```

#### Configuration Options Explained

- `command`: The executable to run (Mix for Elixir projects)
- `args`: Arguments passed to the command (ash_ai.mcp task)
- `cwd`: Working directory where Ashfolio is installed
- `env`: Environment variables (use "dev" for development, "prod" for production builds)

### Step 3: Start Ashfolio

Before using MCP, ensure Ashfolio is running:

```bash
cd /path/to/ashfolio
just dev
```

Wait for the server to start completely (you should see "Access AshfolioWeb.Endpoint at http://localhost:4000").

### Step 4: Restart Claude Desktop

After saving the configuration:

1. Quit Claude Desktop completely
2. Restart Claude Desktop
3. Wait for the application to fully load

### Step 5: Verify Connection

To verify MCP is working:

1. Open a new conversation in Claude Desktop
2. Look for the MCP tools indicator (usually shows connected servers)
3. Ask Claude: "Can you see my Ashfolio portfolio?"
4. If connected, Claude will respond with portfolio information filtered by your privacy mode

If Claude says it doesn't have access, proceed to the Troubleshooting section below.

## Available Tools

Ashfolio provides seven MCP tools organized by function:

### Portfolio Query Tools

#### list_accounts_filtered

List all investment and cash accounts with privacy filtering.

Example questions:
- "Show me all my accounts"
- "What accounts do I have?"
- "List my investment accounts"

Returns (based on privacy mode):
- Account names (or anonymized IDs)
- Account types
- Balance information (exact or tier-based)
- Holdings overview

#### get_portfolio_summary

Get aggregate portfolio metrics and allocation.

Example questions:
- "What's my portfolio summary?"
- "Show my asset allocation"
- "What's my total portfolio value?"

Returns:
- Total value (exact or tier-based)
- Account count
- Asset allocation percentages
- Diversification score
- Risk level assessment

#### list_transactions_filtered

Query transaction history with filtering and limits.

Parameters:
- `limit`: Maximum transactions to return (default: 100)

Example questions:
- "Show my recent transactions"
- "List stock purchases from last month"
- "What dividends did I receive?"

Returns:
- Transaction type (buy/sell/dividend/etc.)
- Symbol and quantity
- Price and total amount (based on privacy mode)
- Transaction date
- Account name (or anonymized)

#### list_symbols_filtered

List all available securities and symbols.

Example questions:
- "What stocks can I track?"
- "Show available symbols"
- "List all securities"

Returns:
- Symbol ticker
- Security name
- Asset class

### Data Entry Tools (Two-Phase)

These tools support natural language input with structured validation.

#### add_expense

Add an expense record with natural language support.

Phase 1 (Guidance):
```
You: "Add expense: groceries $87.43 today"
Claude: "I'll help you add that expense. Here's the structured format needed..."
```

Phase 2 (Execution):
Claude converts your input to structured data:
```json
{
  "expense": {
    "amount": "87.43",
    "category": "groceries",
    "date": "2025-11-30",
    "description": "Groceries"
  }
}
```

Supported amount formats:
- `$100`, `100.50`, `1.5k`, `EUR 500`

Supported date formats:
- ISO format: `2025-11-30`
- Relative: `today`, `yesterday`

#### add_transaction

Add a portfolio transaction with natural language support.

Phase 1 (Guidance):
```
You: "Bought 10 shares of AAPL at $150 yesterday"
Claude: "I'll parse that transaction. Here's what I understood..."
```

Phase 2 (Execution):
```json
{
  "transaction": {
    "type": "buy",
    "symbol": "AAPL",
    "quantity": "10",
    "price": "150",
    "date": "2025-11-29"
  }
}
```

Supported transaction types:
- buy, sell, dividend, fee, interest
- liability, deposit, withdrawal

### Tool Discovery

#### search_tools

Search for available tools by keyword or description.

This tool helps reduce token usage by ~85% by letting Claude find the right tool before loading all tool definitions.

Example:
```
You: "How do I see my transactions?"
Claude: *uses search_tools with query "transactions"*
Claude: "I found the list_transactions_filtered tool..."
```

## Privacy Controls

Your privacy mode (set in AI Settings) determines what data MCP tools return.

### Privacy Mode Impact

**Strict Mode:**
- Tools return: Account count, value tiers, allocation percentages
- Tools hide: Account names, exact amounts, transaction details
- Example: "You have 5 accounts with total value in $100K-$500K range"

**Anonymized Mode (Default):**
- Tools return: Letter IDs (A, B, C), relative weights, asset classes
- Tools hide: Account names, exact dollar amounts
- Example: "Account A (45% of portfolio) holds US Large Cap stocks"

**Standard Mode:**
- Tools return: Account names, types, relative sizes
- Tools hide: Exact dollar amounts, specific values
- Example: "Your Fidelity 401k has a large allocation to VTSAX"

**Full Access Mode:**
- Tools return: Everything - names, exact amounts, all details
- Tools hide: Nothing
- Example: "Your Fidelity 401k ($125,432.18) holds 500 shares of VTSAX"

### Changing Privacy Mode

To change your privacy mode:

1. Navigate to Settings &gt; AI Settings
2. Click on a different privacy mode card
3. Confirm the change in the modal dialog
4. The new mode takes effect immediately for all future MCP requests

See [AI Settings Guide](ai-settings-guide.md) for detailed privacy mode explanations.

## Example Use Cases

### Portfolio Performance Analysis

**You:** "What's my portfolio performance this year?"

**Claude:** *Uses get_portfolio_summary and list_accounts_filtered*

**Response (Anonymized mode):**
"Based on your portfolio data, you have 5 accounts with a total value in the six-figure range. Your asset allocation is 65% equities, 25% bonds, 10% cash. Your diversification score is 0.73, indicating moderate diversification. Risk level is assessed as Moderate."

### Account Comparison

**You:** "Which accounts have the highest returns?"

**Claude:** *Uses list_accounts_filtered*

**Response (Standard mode):**
"Looking at your accounts:
- Fidelity 401k has the largest allocation
- Schwab IRA shows strong recent activity
- Chase Savings maintains stable value

For specific return calculations, I'd need access to historical performance data. Would you like me to explain how to calculate returns yourself?"

### Recent Transaction Review

**You:** "Show my recent stock purchases"

**Claude:** *Uses list_transactions_filtered with type filter*

**Response (Anonymized mode):**
"Your recent buy transactions:
1. Buy - 2 days ago
2. Buy - 1 week ago
3. Buy - 2 weeks ago

I can see transaction patterns but specific symbols and amounts are anonymized based on your privacy settings. To see full details, you could switch to Standard or Full privacy mode in Settings."

### Expense Tracking

**You:** "Add expense: dinner at restaurant $67.50 yesterday"

**Claude:** *Uses add_expense tool (two-phase)*

**Response:**
"I'll add that expense for you:
- Amount: $67.50
- Category: dining
- Date: 2025-11-29
- Description: Dinner at restaurant

Does this look correct? (In a real implementation, you'd confirm and Ashfolio would save it)"

## Troubleshooting

### Connection Issues

**Problem:** Claude says it can't access Ashfolio

Check:
1. Is Ashfolio running? (`just dev` should show the server running)
2. Is the config file path correct? Use absolute paths, not `~/` shortcuts
3. Did you restart Claude Desktop after saving the config?
4. Check Claude Desktop logs for errors:
   - macOS: `~/Library/Logs/Claude/`
   - Windows: `%APPDATA%\Claude\logs\`

**Solution:**
```bash
# Verify Ashfolio is running
cd /path/to/ashfolio
just dev

# Test MCP server directly
mix ash_ai.mcp

# If that works, check your Claude Desktop config file syntax
```

### Permission Errors

**Problem:** "AI consent required" or "Privacy mode does not allow this operation"

Check:
1. Have you granted AI consent in Settings &gt; AI Settings?
2. Is MCP Tools enabled in your feature toggles?
3. Does your privacy mode allow the tool you're using?
   - Strict mode only allows aggregate tools
   - Other modes allow all tools

**Solution:**
1. Navigate to http://localhost:4000/settings/ai
2. Enable AI Features if not already enabled
3. Ensure "MCP Tools" feature is enabled
4. Consider switching to a less restrictive privacy mode if needed

### Data Not Appearing

**Problem:** Claude returns empty results or says "no data found"

Check:
1. Do you have accounts/transactions in Ashfolio?
   - Visit http://localhost:4000 to verify
2. Are database migrations current?
   ```bash
   mix ash.setup
   ```
3. Is the database file accessible?
   ```bash
   ls -la data/ashfolio.db
   ```

**Solution:**
1. Add sample data if database is empty
2. Run migrations: `mix ash.setup`
3. Check Ashfolio logs for database errors

### MCP Server Not Starting

**Problem:** Claude Desktop shows "Server not responding" or similar error

Check:
1. Is Mix installed and in PATH? `mix --version`
2. Are dependencies installed? `mix deps.get`
3. Does the Elixir app compile? `mix compile`
4. Check for port conflicts (Ashfolio uses 4000 by default)

**Solution:**
```bash
cd /path/to/ashfolio
mix deps.get
mix compile
mix ash_ai.mcp  # Test MCP server directly
```

If you see errors, fix them before connecting Claude Desktop.

### Verifying MCP Server

To verify the MCP server works independently of Claude Desktop:

```bash
cd /path/to/ashfolio
mix ash_ai.mcp
```

The server should start and wait for JSON-RPC messages. If it crashes or shows errors, fix those issues before attempting Claude Desktop integration.

Press Ctrl+C twice to stop the server.

## Security Considerations

### Who Has Access to Your Data

With MCP integration:

**Local-Only Setup (Default):**
- Data stays on your computer
- Only Claude Desktop (running locally) can access it
- No cloud services involved unless you enable cloud AI providers
- MCP communication happens over stdio (standard input/output)

**With Cloud AI Enabled:**
- Claude Desktop may send filtered data to Anthropic servers
- Data is encrypted in transit
- Subject to Anthropic's privacy policy
- Your privacy mode still applies - exact amounts may be hidden

### How MCP Differs from Cloud Services

Traditional cloud services:
- Upload your entire database to the cloud
- You lose control over data copies
- Provider can access data anytime
- Subject to provider's terms and potential breaches

MCP with Ashfolio:
- Data stays in your SQLite database on your machine
- AI assistant requests specific data points in real-time
- You control privacy filtering for every request
- Can revoke access instantly by disabling consent
- No persistent data storage on remote servers

### Best Practices

**Privacy Mode Selection:**
- Start with Strict or Anonymized mode
- Only use Full mode if you completely trust your AI provider
- Re-evaluate privacy mode when portfolio size increases

**API Key Security (if using cloud AI):**
- Store API keys in environment variables
- Never commit API keys to git repositories
- Rotate keys every 90 days
- Revoke keys immediately if compromised

**Consent Management:**
- Review consent settings monthly
- Check audit trail for unexpected MCP usage
- Revoke consent if you stop using AI features
- Re-grant consent with updated settings when needed

**Network Security:**
- Keep Ashfolio updated for security patches
- Use firewall to restrict Phoenix server to localhost
- Don't expose Ashfolio port 4000 to the internet
- Consider VPN if accessing remotely

**Data Backup:**
- Regular backups of `data/ashfolio.db`
- Store backups encrypted
- Test backup restoration periodically
- Keep backups offline for maximum security

## Advanced Configuration

### Multiple Privacy Modes for Different Tools

Currently, Ashfolio uses a single privacy mode for all tools. To use different privacy levels:

1. Create separate consent records for different scenarios
2. Switch privacy mode in Settings before sensitive queries
3. Use Strict mode by default, switch to Full only when needed

Future enhancement: Tool-specific privacy overrides.

### Custom Tool Permissions

To disable specific tools while keeping MCP enabled:

1. Edit `config/config.exs`:
```elixir
config :ashfolio, :mcp,
  privacy_mode: :anonymized,
  enabled: true,
  disabled_tools: [:add_expense, :add_transaction]
```

2. Restart Ashfolio
3. Disabled tools won't appear in Claude's tool list

### Performance Tuning

For large portfolios (1000+ transactions):

1. Increase MCP timeout in config:
```elixir
config :ashfolio, :mcp,
  timeout_ms: 30_000  # 30 seconds instead of default 10
```

2. Use transaction limits in queries:
   - "Show my last 50 transactions" instead of "all transactions"

3. Monitor performance with Ashfolio's built-in logging

## Next Steps

After successful MCP setup:

1. **Explore AI Capabilities:**
   - Ask Claude to analyze your portfolio
   - Try natural language transaction entry
   - Get investment recommendations

2. **Fine-Tune Privacy:**
   - Review what data Claude sees
   - Adjust privacy mode based on comfort level
   - Check audit trail for actual usage patterns

3. **Learn Advanced Features:**
   - Portfolio optimization with AI guidance
   - Tax planning scenarios
   - Retirement projection analysis

4. **Stay Informed:**
   - Check CHANGELOG.md for MCP updates
   - Review new tools as they're added
   - Participate in GitHub Discussions for best practices

## Related Documentation

- [AI Settings Guide](ai-settings-guide.md) - Detailed privacy and consent management
- [MCP Architecture](../features/implemented/mcp-integration/ARCHITECTURE.md) - Technical implementation details
- [Privacy Filtering](../features/implemented/mcp-integration/decisions/ADR-MCP-001-privacy-modes.md) - Privacy mode design decisions

## Frequently Asked Questions

**Q: Can I use MCP with ChatGPT or other AI assistants?**

A: Currently, MCP is best supported by Claude Desktop. Other AI assistants may add MCP support in the future. Check their documentation for MCP compatibility.

**Q: Does MCP work offline?**

A: Yes, if you're using local AI (Ollama) and Ashfolio is running locally. Claude Desktop can access Ashfolio data without internet connectivity. Only price updates require internet.

**Q: How much does MCP integration cost?**

A: MCP itself is free. If you use cloud AI providers (OpenAI, Anthropic API), you'll pay their standard API rates. Local AI with Ollama is completely free.

**Q: Can I revoke MCP access without disabling all AI features?**

A: Yes. In Settings &gt; AI Settings, disable the "MCP Tools" feature toggle. This keeps AI Analysis and other features enabled while blocking MCP data access.

**Q: What happens to my data if I revoke consent?**

A: MCP tools immediately stop returning data. Your Ashfolio database remains unchanged. No data is deleted, but AI assistants can no longer access it via MCP.

**Q: Can multiple AI assistants access Ashfolio simultaneously?**

A: Yes, as long as each is configured with the MCP connection. Each request respects your current privacy mode and consent settings.

**Q: Does MCP track what questions I ask my AI assistant?**

A: No. Ashfolio logs MCP tool invocations (which tool was called, when, and privacy mode used) but not the questions you ask Claude or the full conversation context.

---

This guide covers Ashfolio v0.9.0+ MCP capabilities. As MCP integration evolves, this guide will be updated with new features, tools, and best practices.

For technical support or questions, visit [GitHub Discussions](https://github.com/mdstaff/ashfolio/discussions) or open an issue at [GitHub Issues](https://github.com/mdstaff/ashfolio/issues).
