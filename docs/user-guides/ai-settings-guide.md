# AI Settings & Privacy Controls Guide

User Guide
5-10 minutes to configure
Ashfolio v0.10.0+ with AI features available

## Overview

The AI Settings page provides comprehensive control over how AI assistants can access and analyze your portfolio data. This guide explains each privacy mode, feature toggle, and consent management option to help you make informed decisions about AI integration while maintaining your preferred level of privacy.

Key Capabilities:

- Granular privacy control with four distinct modes
- Feature-level toggles for MCP tools, AI analysis, and cloud AI
- GDPR-compliant consent management and data export
- Real-time consent withdrawal with immediate effect
- Audit trail for all consent-related actions

## Accessing AI Settings

### Navigation Path

From anywhere in Ashfolio:

1. Click Settings in the main navigation
2. Select "AI Settings" from the settings menu

Or navigate directly to: `/settings/ai`

### First-Time Setup

When accessing AI Settings for the first time:

1. You'll see an "AI Features Not Enabled" state
2. Click "Enable AI Features" or "Get Started"
3. The consent modal will appear with options to configure:
   - Privacy Mode (default: Anonymized)
   - Feature Selection (MCP Tools pre-selected)
   - Terms acceptance checkbox
4. Review and accept terms to enable AI features

## Privacy Modes Explained

Choose the level of data sharing that matches your privacy preferences and use case.

### Strict Privacy

Maximum privacy protection with minimal data exposure.

What's Shared:
- Total portfolio value tier (e.g., "$100K-$500K" instead of exact amount)
- Number of accounts (count only)
- Asset class percentages (e.g., "60% stocks, 40% bonds")
- General portfolio characteristics

What's Hidden:
- Individual account names and balances
- Specific transaction details
- Exact dollar amounts
- Account types and institutions

Best For:
- Users who want AI insights without sharing personal financial details
- Exploratory AI feature testing
- Scenarios where privacy is the top priority

Example AI Response:
"Your portfolio is in the $100K-$500K range with 5 accounts. Asset allocation is 60% equities, 30% bonds, 10% cash."

### Anonymized

Balanced privacy with functional AI assistance.

What's Shared:
- Accounts shown as letters (Account A, Account B, Account C)
- Amounts shown as relative weights ("Account A is 45% of portfolio")
- Recent activity patterns
- Diversification metrics

What's Hidden:
- Actual account names (Fidelity, Schwab, etc.)
- Exact dollar amounts
- Account owner information

Best For:
- Most users seeking a balance of privacy and functionality
- Portfolio analysis and optimization recommendations
- Diversification and allocation advice

Example AI Response:
"Account A (45% of portfolio) has strong tech exposure. Consider rebalancing with Account B (30%) which holds more bonds."

### Standard

Account visibility with amount privacy.

What's Shared:
- Actual account names (e.g., "Fidelity 401k", "Chase Checking")
- Account types and institutions
- Relative size indicators ("Large allocation", "Small position")
- Monthly expense trends without exact amounts

What's Hidden:
- Exact dollar amounts
- Specific transaction values

Best For:
- Users comfortable sharing account structure but not exact balances
- Getting account-specific recommendations
- Expense categorization and trend analysis

Example AI Response:
"Your Fidelity 401k has a large allocation to VTSAX. Recent activity in Chase Checking shows increased monthly expenses."

### Full Access

Complete data access for detailed AI analysis.

What's Shared:
- All account names and exact balances
- Specific transaction details with amounts
- Exact prices and quantities
- Complete historical data

What's Hidden:
- Nothing (full transparency for maximum AI capability)

Best For:
- Users who trust their AI provider completely
- Detailed portfolio optimization and tax planning
- Precise financial analysis and projections
- Advanced features requiring exact calculations

Example AI Response:
"Your Fidelity 401k ($125,432) could benefit from tax-loss harvesting. The AAPL position (10 shares @ $150 cost basis) is down 15%, creating a $225 tax-loss opportunity."

Security Note:
Only use Full Access with AI providers you completely trust, ideally with local-only AI (Ollama) to keep data on your machine.

## Feature Toggles

### MCP Tools

Model Context Protocol (MCP) tools allow AI assistants to query your portfolio data.

When Enabled:
- AI assistants can request account lists, portfolio summaries, transaction history
- Data is filtered according to your privacy mode
- Each request logs to audit trail
- Tools available: `list_accounts`, `get_portfolio_summary`, `list_transactions`, `list_symbols`

When Disabled:
- AI assistants cannot access any portfolio data via MCP
- You can still use AI features manually by copying/pasting data
- Privacy mode settings are preserved but not applied

Use Case:
Enable if you use Claude Desktop, VS Code with AI extensions, or other MCP-compatible tools that would benefit from portfolio context.

### AI Analysis

AI-powered insights, recommendations, and portfolio analysis.

When Enabled:
- Portfolio health assessments
- Investment recommendations
- Expense pattern analysis
- Retirement planning insights
- Tax optimization suggestions

When Disabled:
- No automated AI analysis
- Manual data entry still works
- Natural language transaction parsing may be limited

Use Case:
Enable if you want proactive AI suggestions and automated analysis. Disable if you prefer manual control over all analysis.

### Cloud AI

Controls whether cloud-based AI models can be used versus local-only.

When Enabled:
- Can use OpenAI GPT-4, Claude API, or other cloud LLMs
- Data is sent to third-party AI providers (encrypted in transit)
- Generally faster and more capable models
- Requires API keys and may incur costs

When Disabled:
- Only local AI models are used (Ollama)
- All processing happens on your machine
- Complete data privacy (nothing leaves your computer)
- Requires local GPU/CPU resources

Use Case:
Enable Cloud AI for best performance and latest models. Disable for maximum privacy and data sovereignty (recommended default).

## Consent Management

### Granting Consent

To enable AI features:

1. Click "Enable AI Features" on the AI Settings page
2. Select your preferred privacy mode
3. Choose which features to enable (at least one required)
4. Click "View terms" to review AI usage terms
5. Check "I accept the AI usage terms"
6. Click "Enable AI Features"

The system records:
- Timestamp of consent
- Selected privacy mode and features
- Terms version and hash (for detecting changes)
- IP address and user agent (for audit)

### Changing Privacy Mode

To update your privacy mode after initial consent:

1. Navigate to AI Settings
2. Click on a different privacy mode card
3. Review the confirmation dialog showing the change
4. Click "Confirm Change"

The change:
- Takes effect immediately
- Is recorded in the audit trail
- Applies to all future AI requests
- Does not affect historical data already shared

### Withdrawing Consent

To revoke all AI access:

1. Navigate to AI Settings
2. Click "Revoke Consent" in the Data & Privacy section
3. Review the confirmation dialog explaining the impact
4. Click "Revoke Consent" to confirm

What Happens:
- All AI features are immediately disabled
- All feature toggles are turned off
- MCP tools stop returning data
- Privacy settings are cleared
- Audit record is created

You Can Still:
- View your consent history
- Export your data
- Re-enable AI features at any time

### Consent Versioning

Ashfolio tracks terms changes through version hashing:

- Each consent stores a hash of the accepted terms
- If terms change, the hash changes
- You may be prompted to re-consent for major changes
- Your previous consent preferences are preserved

## GDPR Rights & Data Export

### Exporting Your Data

To export all AI-related data:

1. Navigate to AI Settings
2. Click "Export My Data" in the Data & Privacy section
3. Wait for export generation (usually instant)
4. Review the summary showing record count
5. Download the JSON file (future: automatic download)

Export Includes:
- Current consent record with all settings
- Complete audit trail of all consent actions
- Privacy mode changes over time
- Feature toggle history

Export Format:
- JSON file with structured data
- Human-readable timestamps
- Complete field descriptions
- Suitable for GDPR data portability requirements

### Your Data Rights

Under GDPR, you have the right to:

1. Access: View all data related to your AI consent
2. Portability: Export your data in machine-readable format
3. Rectification: Update your privacy mode and feature selections
4. Erasure: Withdraw consent and stop all AI data processing
5. Object: Opt-out of specific AI features while keeping others

All rights are exercisable through the AI Settings interface.

### Audit Trail

Every consent action is logged:

- Initial consent grant with timestamp
- Privacy mode changes (old → new)
- Feature toggle updates
- Consent withdrawals
- Data export requests

Audit records are:
- Append-only (never modified or deleted)
- Timestamped to microsecond precision
- Linked to specific consent record
- Exportable via GDPR data export

## Best Practices

### Recommended Privacy Modes by Use Case

Local AI Only (Ollama):
- Recommended: Standard or Full
- Reasoning: Data never leaves your machine, so privacy risk is minimal
- Benefit: Get full AI capability without cloud exposure

Cloud AI (OpenAI, Claude API):
- Recommended: Anonymized
- Reasoning: Balance between functionality and third-party data sharing
- Benefit: Useful analysis without exposing exact amounts

Testing AI Features:
- Recommended: Strict
- Reasoning: Minimal data exposure while learning capabilities
- Benefit: Explore safely before committing to more open modes

Advanced Financial Planning:
- Recommended: Full (with local AI) or Standard (with cloud)
- Reasoning: Detailed analysis requires precise data
- Benefit: Tax optimization, retirement projections need exact figures

### When to Use Local AI vs Cloud AI

Choose Local AI (Ollama) When:
- Privacy is your top priority
- You have adequate GPU/CPU resources (Mac M1+, modern PC)
- You're comfortable with slightly longer response times
- Your data is highly sensitive (large portfolios, complex tax situations)
- You want zero third-party data exposure

Choose Cloud AI (OpenAI, Claude) When:
- You need the fastest, most capable models
- Local hardware is insufficient
- You're already comfortable with encrypted cloud data
- You want latest model updates automatically
- Cost of API usage is acceptable

Hybrid Approach:
- Use local AI for regular queries and analysis
- Enable cloud AI temporarily for complex questions
- Disable cloud AI when not actively needed
- This gives best of both worlds

### Security Considerations

API Key Management:
- Store API keys in environment variables, never in code
- Rotate keys periodically (every 90 days recommended)
- Use keys with minimum necessary permissions
- Revoke unused or compromised keys immediately

Privacy Mode Selection:
- Start with stricter modes and relax only as needed
- Re-evaluate privacy mode quarterly
- Use stricter modes when portfolio value increases
- Consider regulatory requirements for your jurisdiction

Audit Your AI Usage:
- Review audit trail monthly
- Check for unexpected privacy mode changes
- Verify feature toggles match your intentions
- Export data periodically for offline backup

## Troubleshooting

### AI Features Not Working After Consent

Check:
1. At least one feature is enabled (MCP Tools, AI Analysis, or Cloud AI)
2. If using cloud AI, verify API keys are configured correctly
3. If using local AI, ensure Ollama is running (`ollama list`)
4. Check browser console for any error messages
5. Try refreshing the page after consent grant

### Privacy Mode Not Applying

Verify:
1. Privacy mode change was confirmed (check for success message)
2. Audit trail shows the mode change
3. Try withdrawing and re-granting consent if persists
4. Check that MCP server has restarted to pick up changes

### Data Export Not Generating

Possible causes:
1. No consent record exists yet (grant consent first)
2. Browser blocking download (check permissions)
3. Database connectivity issue (check logs)

Solution:
- Refresh page and try again
- Check browser console for errors
- Contact support if issue persists

## Next Steps

After configuring AI Settings:

1. Test AI Features: Try asking your AI assistant about your portfolio
2. Review Responses: Verify data matches your expected privacy mode
3. Adjust Settings: Fine-tune privacy mode based on actual usage
4. Explore MCP Tools: Connect Claude Desktop or other MCP clients
5. Monitor Audit Trail: Check periodically to ensure expected usage

For more information:
- MCP Integration: See `docs/mcp/OVERVIEW.md`
- Natural Language Entry: See `docs/user-guides/natural-language-entry.md`
- Privacy Architecture: See `docs/architecture/privacy-filtering.md`

---

This guide covers Ashfolio v0.10.0 AI Settings capabilities. As AI features evolve, this guide will be updated to reflect new privacy controls and consent options.

_For questions about AI Settings or privacy concerns, please visit our [GitHub Discussions](https://github.com/mdstaff/ashfolio/discussions)._
