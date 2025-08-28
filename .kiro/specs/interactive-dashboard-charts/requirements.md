# Interactive Dashboard Charts Requirements

## Introduction

This feature adds interactive charts to the dashboard for portfolio performance visualization and asset allocation analysis, enhancing the existing dashboard with professional data visualization.

Built on v0.1.0's dashboard with existing portfolio calculations and Phoenix LiveView architecture.

## Requirements

### Requirement 1: Portfolio Performance Chart

User Story: As a portfolio manager, I want to see my portfolio performance over time so that I can track my investment progress visually.

#### Acceptance Criteria

1. WHEN viewing the dashboard THEN the system SHALL display a line chart showing portfolio value over the last 30 days
2. WHEN hovering over chart points THEN tooltips SHALL show exact date, portfolio value, and daily change
3. WHEN insufficient historical data exists THEN the system SHALL show a helpful message explaining data requirements
4. WHEN the chart loads THEN it SHALL use skeleton loading states during data fetching
5. WHEN portfolio data updates THEN the chart SHALL refresh automatically via LiveView

### Requirement 2: Asset Allocation Pie Chart

User Story: As an investor, I want to see how my portfolio is allocated across different assets so that I can understand my diversification.

#### Acceptance Criteria

1. WHEN viewing the dashboard THEN the system SHALL display a pie chart showing allocation by asset class
2. WHEN clicking on pie segments THEN they SHALL highlight and show detailed allocation information
3. WHEN hovering over segments THEN tooltips SHALL show asset class, value, and percentage
4. WHEN portfolio has no holdings THEN the system SHALL show an empty state with guidance
5. WHEN allocation changes THEN the chart SHALL update in real-time

### Requirement 3: Responsive Chart Design

User Story: As a mobile user, I want charts to work well on my device so that I can view my portfolio data anywhere.

#### Acceptance Criteria

1. WHEN viewing charts on mobile THEN they SHALL be touch-interactive with appropriate sizing
2. WHEN screen size changes THEN charts SHALL resize responsively without losing functionality
3. WHEN on small screens THEN chart legends SHALL adapt to available space
4. WHEN charts are displayed THEN they SHALL maintain readability across all device sizes
5. WHEN touch interactions occur THEN they SHALL provide appropriate feedback

## Technical Requirements

### New Dependencies

- Lightweight charting library compatible with Phoenix LiveView
- New PortfolioSnapshot resource for time-series data

### Integration Points

- Enhance current DashboardLive module
- Use existing calculation engines
- Leverage existing real-time capabilities

### Performance Targets

- Chart rendering: < 1s for 30 days of data
- Interactive response: < 100ms for hover/click events
- Data loading: Progressive loading with skeleton states
- Memory usage: < 10MB for chart data and rendering
