# AI Natural Language Entry

> **Feature Status**: Experimental (v0.7.1+)
> **Privacy Approach**: Local-First AI (Ollama recommended)
> **Philosophy**: Keeping AI processing on your computer, just like your financial data

## Overview

Ashfolio includes an AI-powered natural language transaction entry system that allows you to describe financial transactions in plain English instead of filling out forms manually.

**Example:**
```
"Bought 10 shares of AAPL at 150 yesterday on my Fidelity account"
```

This will automatically parse into:
- **Type**: Buy
- **Symbol**: AAPL
- **Quantity**: 10
- **Price**: 150.00
- **Date**: (Yesterday's date)
- **Account**: Fidelity (if it exists)

## Why Local AI?

Ashfolio was built on the principle that **your financial data belongs on your computer, not in the cloud**. Our AI features follow the same philosophy:

- ✅ No data sent to third-party servers
- ✅ Works offline (once model is downloaded)
- ✅ No API costs or usage limits
- ✅ Complete privacy and control
- ✅ Aligns with Ashfolio's local-first architecture

**You've already chosen privacy by using Ashfolio** - our AI features respect that choice.

---

## Setup Options

### Option 1: Ollama (Local AI) - **Recommended** ✅

**Perfect for**: Privacy-conscious users who value control over their data (that's why you chose Ashfolio!)

**Your financial data never leaves your computer**.

**Setup:**

1. **Install Ollama** (one-time setup):
   ```bash
   # macOS
   brew install ollama

   # Or download from https://ollama.ai
   ```

2. **Start Ollama**:
   ```bash
   ollama serve
   ```

3. **Pull a model** (one-time, ~4GB download):
   ```bash
   ollama pull llama3
   ```

4. **Configure Ashfolio** (config/config.exs):
   ```elixir
   config :ashfolio,
     ai_provider: :ollama,
     ai_model: "llama3"
   ```

5. **Restart Ashfolio**:
   ```bash
   just dev
   ```

### Option 2: OpenAI API (Cloud) - **Opt-In Alternative**

**Perfect for**: Users who prioritize ease of setup and are comfortable with the privacy trade-off.

⚠️ **Privacy Trade-off**: Your transaction descriptions (e.g., "Bought 10 AAPL at $150") are sent to OpenAI's servers for processing. Your portfolio data, account balances, and net worth are **NOT** sent.

**When to choose this**:
- Quick testing/evaluation of AI features
- Hardware limitations (< 8GB RAM)
- Traveling with limited resources
- You understand and accept the privacy implications

**Important**: This is still **far more private** than cloud-based financial apps (Mint, Personal Capital) which send your entire linked account data to the cloud. OpenAI only sees the specific text you type for parsing.

**Setup:**

1. **Get an API key** from [OpenAI](https://platform.openai.com/api-keys)

2. **Set environment variable**:
   ```bash
   export OPENAI_API_KEY="sk-..."
   ```

3. **Configure Ashfolio** (config/config.exs):
   ```elixir
   config :ashfolio,
     ai_provider: :openai,
     ai_model: "gpt-4o-mini"  # Recommended: faster and cheaper than gpt-4o
   ```

4. **Restart Ashfolio**

**Cost**: ~$0.003-0.006/month for typical usage (essentially free)

## How to Use

1. Navigate to **Transactions** page
2. Find the **"Natural Language Entry"** card (blue gradient)
3. Type your transaction description in plain English
4. Click **Parse**
5. Review the pre-filled form
6. Adjust any fields if needed
7. Click **Save**

### Examples of Supported Descriptions

| Your Input | What Gets Parsed |
|------------|------------------|
| `Bought 100 MSFT at 350` | Type: Buy, Symbol: MSFT, Qty: 100, Price: 350 |
| `Sold 50 shares of TSLA yesterday` | Type: Sell, Symbol: TSLA, Qty: 50, Date: (yesterday) |
| `Received $25 dividend from VTI on 2024-06-15` | Type: Dividend, Symbol: VTI, Amount: 25, Date: 2024-06-15 |
| `Deposited 5000 into savings account` | Type: Deposit, Amount: 5000, Account: (savings if exists) |
| `Withdraw 1000 from checking` | Type: Withdrawal, Amount: 1000 |

### Supported Transaction Types

- `buy` / `bought` / `purchase` → Buy transaction
- `sell` / `sold` → Sell transaction
- `dividend` / `received dividend` → Dividend
- `deposit` / `deposited` → Deposit
- `withdraw` / `withdrawal` → Withdrawal
- `fee` / `paid fee` → Fee
- `interest` / `received interest` → Interest

---

## Choosing Your AI Provider

### Quick Comparison

| Feature | Ollama (Recommended) | OpenAI (Alternative) |
|---------|---------------------|----------------------|
| **Privacy** | ✅ **100% local** (nothing leaves your computer) | ⚠️ Transaction text sent to OpenAI |
| **Setup Time** | 15-20 minutes (one-time) | 2 minutes |
| **Setup Complexity** | Moderate (similar to Ashfolio install) | Easy (paste API key) |
| **Internet Required** | ❌ No (after initial download) | ✅ Yes (for each request) |
| **Cost** | 💰 Free (electricity only) | 💰 ~$0.004/month |
| **Speed** | 2-10s (hardware dependent) | 1-3s |
| **Hardware Needs** | 8GB+ RAM recommended | None |
| **Aligns with Ashfolio Philosophy** | ✅ **Yes** (local-first) | ⚠️ Partial |

### Our Recommendation

**If you chose Ashfolio for privacy** → Choose **Ollama**

You've already invested time in setting up Ashfolio (Elixir, Phoenix, SQLite) to keep your financial data local. Ollama follows the same philosophy - if you can install Ashfolio, you can install Ollama!

**If you're evaluating AI features quickly** → Choose **OpenAI temporarily**

Test the AI parsing with OpenAI, then switch to Ollama for production use. The configuration change takes 2 minutes.

### Technical Note

Ashfolio users are self-selected technical individuals who value privacy and control. The Ollama setup process is **simpler than the initial Ashfolio installation** - if you made it here, you've got this!

---

## Troubleshooting

### "AI features are not available"

**Cause**: AI provider is not configured or unavailable.

**Solutions:**

1. **If using Ollama**:
   ```bash
   # Check if Ollama is running
   curl http://localhost:11434/api/tags

   # If not, start it
   ollama serve

   # Verify model is installed
   ollama list
   ```

2. **If using OpenAI**:
   ```bash
   # Check environment variable
   echo $OPENAI_API_KEY

   # Set if missing
   export OPENAI_API_KEY="sk-..."
   ```

3. **Check configuration**:
   ```elixir
   # config/config.exs
   config :ashfolio,
     ai_provider: :ollama,  # or :openai
     ai_model: "llama3"     # or "gpt-4o"
   ```

### "I didn't understand that command"

**Cause**: Your text didn't match transaction patterns.

**Solution**: Use transaction keywords like "bought", "sold", "dividend", etc.

**Good**: `Bought 10 AAPL at 150`
**Bad**: `I acquired some Apple stock`

### Wrong values parsed

**Cause**: AI misinterpreted your description.

**Solution**:
1. Review the pre-filled form carefully
2. Correct any errors manually
3. Click Save
4. The form validates before saving (AI can't bypass validation)

### Performance is slow

**Cause**: LLM inference takes time, especially on local models.

**Expected Performance**:
- Ollama (local): 2-10 seconds depending on your hardware
- OpenAI: 1-3 seconds (network dependent)

**Optimization**: Use a smaller local model:
```bash
ollama pull llama3.2:1b  # Smaller, faster model
```

## Accuracy & Validation

### What the AI Does Well ✅
- Extracting ticker symbols (AAPL, MSFT, etc.)
- Identifying transaction types (buy/sell/dividend)
- Parsing quantities and prices
- Understanding relative dates ("yesterday", "last week")

### What Requires Review ⚠️
- Account name matching (may not find exact match)
- Ambiguous dates ("last month" without specific day)
- Total amount vs. per-share price calculation
- Currency conversions (not supported)

### Safety Features 🛡️
- **Form Review**: AI only pre-fills the form, never saves automatically
- **Validation**: All normal transaction validation rules apply
- **Audit Trail**: "Parsed from: [your text]" added to notes
- **Reversible**: Can always edit or delete parsed transactions

## Technical Architecture

```
User Input (Text)
    ↓
Ashfolio.AI.Dispatcher (finds handler)
    ↓
TransactionParser (keyword matching)
    ↓
Transaction.parse_from_text (Ash AI action)
    ↓
LLM (Ollama or OpenAI)
    ↓
Structured Transaction Data
    ↓
Pre-filled Form (User Review)
    ↓
Manual Save
```

## Privacy Comparison

| Feature | Ollama (Local) | OpenAI (Cloud) |
|---------|----------------|----------------|
| Data leaves computer | ❌ Never | ✅ Yes (sent to OpenAI) |
| Internet required | ❌ No | ✅ Yes |
| API costs | 💰 Free | 💰 Pay per use |
| Setup complexity | ⚙️ Higher | ⚙️ Lower |
| Accuracy | 📊 Good | 📊 Excellent |
| Speed | 🐢 2-10s | 🚀 1-3s |

**Recommendation**: Use Ollama for maximum privacy. Your financial data is sensitive and should stay local.

## Limitations

- **Not a substitute for manual entry**: Always review AI-parsed data
- **English only**: Currently supports English descriptions
- **Simple transactions**: Complex multi-leg transactions require manual entry
- **No file uploads**: Can't parse from bank statements or PDFs
- **Experimental**: This feature is new and may have bugs

## Future Enhancements

Planned improvements (v0.8.0+):
- [ ] Multi-language support
- [ ] Batch parsing (multiple transactions at once)
- [ ] CSV/QFX import with AI enhancement
- [ ] Learning from corrections (user feedback loop)
- [ ] Voice input support
- [ ] Confidence scores for parsed values

## Disabling AI Features

If you don't want to use AI features:

1. **Option 1**: Simply don't use the Natural Language Entry card (it's optional)

2. **Option 2**: Remove AI dependencies (config/config.exs):
   ```elixir
   config :ashfolio,
     ai_provider: nil,
     ai_handlers: []
   ```

The rest of Ashfolio works perfectly without AI.

## Getting Help

- **Issues**: Report bugs at [GitHub Issues](https://github.com/mdstaff/ashfolio/issues)
- **Discussions**: Ask questions in [GitHub Discussions](https://github.com/mdstaff/ashfolio/discussions)
- **Tag**: Use `[ai-integration]` tag for AI-specific issues

---

*Last Updated: November 2025 | Version: v0.7.1*
