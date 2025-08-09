# Real-Time Price Lookup Requirements

## Introduction

This feature adds automatic price lookup when users select symbols in transaction forms, providing current market data to assist with accurate transaction entry.

**Foundation**: Built on v1.0's existing PriceManager GenServer and Yahoo Finance integration.

## Requirements

### Requirement 1: Automatic Price Fetching

**User Story:** As an investor entering transactions, I want to see current market prices when I select a symbol so that I can enter accurate transaction data.

#### Acceptance Criteria

1. WHEN a user selects a symbol in the transaction form THEN the system SHALL automatically fetch the current market price
2. WHEN price lookup is in progress THEN the system SHALL show a loading indicator next to the price field
3. WHEN current price is retrieved THEN it SHALL display prominently with timestamp
4. WHEN a price is auto-populated THEN the user SHALL be able to override it with manual entry
5. WHEN the form is submitted THEN it SHALL use the user-entered price, not the auto-fetched price

### Requirement 2: Fallback and Error Handling

**User Story:** As a user, I want the form to work even when price lookup fails so that I can still enter transactions manually.

#### Acceptance Criteria

1. WHEN price lookup fails THEN the system SHALL show the last known cached price with staleness indicator
2. WHEN no price data is available THEN the system SHALL allow manual price entry with appropriate validation
3. WHEN API rate limits are hit THEN the system SHALL show cached price and explain the limitation
4. WHEN network is unavailable THEN the system SHALL gracefully degrade to manual entry mode
5. WHEN errors occur THEN they SHALL not prevent form submission with manual prices

### Requirement 3: Market Context Information

**User Story:** As an investor, I want to understand the context of price data so that I can make informed decisions about my transaction entries.

#### Acceptance Criteria

1. WHEN price data is displayed THEN it SHALL include market status (open/closed/pre-market/after-hours)
2. WHEN showing cached prices THEN the system SHALL display last update timestamp
3. WHEN markets are closed THEN the system SHALL show the last closing price with appropriate label
4. WHEN price data is stale (>1 hour) THEN it SHALL be clearly marked as outdated
5. WHEN displaying prices THEN they SHALL use consistent currency formatting ($X,XXX.XX)

## Technical Requirements

### Integration Points

- **Existing PriceManager**: Extend for individual symbol lookup
- **Yahoo Finance API**: Reuse existing integration
- **Transaction Forms**: Integrate with FormComponent
- **ETS Cache**: Utilize existing price caching

### Performance Targets

- Price lookup: < 2s response time
- Cache utilization: > 90% for recently viewed symbols
- Form responsiveness: No blocking of user input during lookup
- Error recovery: < 1s fallback to cached/manual entry
