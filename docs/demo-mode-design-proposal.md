# Demo Mode & Interactive Tutorial - Design Proposal

## Executive Summary

A comprehensive demo mode and tutorial system for Ashfolio that combines synthetic data generation with interactive onboarding to reduce time-to-value for new users and showcase v0.2.0's wealth management capabilities.

## Problem Statement

New users face several challenges:

- Empty state provides no immediate value demonstration
- Feature discovery happens slowly through trial and error
- Investment tracking concepts may be unfamiliar
- v0.2.0's new features (categories, cash accounts, net worth) need introduction

## Goals & Objectives

### Primary Goals

1.  Users see value within 30 seconds
2.  Highlight v0.2.0 capabilities naturally
3.  Learn without fear of mistakes
4.  Generate compelling demo content

### Success Metrics

- Time to first meaningful interaction < 1 minute
- Feature discovery rate > 80% within first session
- Tutorial completion rate > 60%
- User conversion from demo to real data > 40%

## Core Design Principles

### 1. Progressive Disclosure

Start simple, reveal complexity gradually:

- Level 1: Basic navigation and dashboard understanding
- Level 2: Transaction entry and account management
- Level 3: Categories and filtering
- Level 4: Advanced features (bulk operations, analysis)

### 2. Learning by Doing

Interactive rather than passive:

- Users interact with real (demo) data
- Actions have visible consequences
- Immediate feedback on interactions

### 3. Respect User Intelligence

- Skip options always available
- No forced tutorials
- Smart detection of experienced users
- Contextual help rather than interruption

## User Experience Architecture

### Entry Points

```
New User Flow:
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Landing   │────▶│ Choose Path  │────▶│ Demo Mode   │
│    Page     │     │ • Explore    │     │  Selected   │
└─────────────┘     │ • Start Real │     └─────────────┘
                    └──────────────┘

Existing User Flow:
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  Empty      │────▶│ Prompt for   │────▶│ Load Demo   │
│  Dashboard  │     │ Demo Mode    │     │   Persona   │
└─────────────┘     └──────────────┘     └─────────────┘
```

### Demo Personas

Three carefully crafted personas representing different life stages:

#### 1. Sarah Starter (Age 25)

- Recent graduate, first job, learning to invest
- $15,000
- Robinhood ($5K), Chase Checking ($3K), Ally Savings ($7K)
- Build emergency fund, start retirement savings
- Simple ETF purchases, monthly contributions

#### 2. Mike & Jennifer Family (Age 35)

- Growing family, balancing multiple goals
- $285,000
- 401k ($180K), IRA ($45K), 529 ($15K), Checking ($20K), Emergency ($25K)
- Retirement, college savings, house down payment
- Diverse portfolio, regular rebalancing

#### 3. Patricia Planner (Age 58)

- Approaching retirement, focus on preservation
- $1,250,000
- Multiple IRAs, Taxable accounts, Cash reserves
- Income generation, tax efficiency, estate planning
- Dividend stocks, bonds, cash management

### Tutorial Flow Architecture

```
┌───────────────────────────────────────────────────────┐
│                   Tutorial Controller                  │
├───────────────────────────────────────────────────────┤
│  • Progress Tracking                                  │
│  • Step Sequencing                                    │
│  • Completion Detection                               │
│  • Analytics Events                                   │
└─────────────┬─────────────────────────────────────────┘
              │
    ┌─────────▼──────────┬──────────────┬──────────────┐
    │   Overlay System   │ State Manager │   Content    │
    ├───────────────────┼──────────────┼──────────────┤
    │ • Tooltips        │ • Progress   │ • Scripts    │
    │ • Spotlights      │ • Features   │ • Videos     │
    │ • Highlights      │ • Settings   │ • Tips       │
    │ • Animations      │ • Completion │ • Examples   │
    └───────────────────┴──────────────┴──────────────┘
```

## Feature Discovery System

### Progressive Feature Unlocking

Features are introduced based on user readiness:

1. **Dashboard Basics** (Immediate)

   - Net worth display
   - Account overview
   - Recent transactions

2. **Data Entry** (After exploration)

   - Add account
   - Enter transaction
   - Symbol search

3. **Organization** (After 5+ transactions)

   - Categories
   - Filtering
   - Account grouping

4. **Advanced** (Power user)
   - Bulk operations
   - Export/Import
   - Custom reports

### Contextual Hints System

```
Trigger Types:
- First Visit: Element has never been interacted with
- Idle Detection: User inactive on complex screen
- Error Recovery: After user encounters error
- Feature Update: New features since last visit
- Success Moment: Celebrate completed actions
```

### Achievement & Gamification (Optional)

Light gamification without being patronizing:

- Visited all major sections
- Used categories effectively
- Generated first report
- Used advanced features

## Technical Architecture

### Data Management Strategy

#### Option A: Isolated Demo Environment (Recommended)

```
Pros:
- Complete separation from real data
- Can reset/refresh anytime
- No risk of data mixing
- Easy to identify demo sessions

Cons:
- Requires switching logic
- Duplicate data structures
- Session management complexity
```

#### Option B: Flagged Demo User

```
Pros:
- Uses existing infrastructure
- Simple implementation
- Easy state transition

Cons:
- Risk of data mixing
- Filtering required everywhere
- Cleanup complexity
```

### State Management

```elixir
Demo Session State:
%{
  mode: :demo | :real,
  persona: :sarah | :mike | :patricia,
  tutorial_progress: %{
    current_step: 1..n,
    completed_steps: MapSet,
    skipped: boolean,
    features_discovered: MapSet
  },
  session_analytics: %{
    started_at: DateTime,
    interactions: [...],
    conversion_points: [...]
  }
}
```

### Persistence Strategy

- Tutorial progress: LocalStorage
- Demo data: Server-side with TTL
- User preferences: Account settings
- Analytics: Server-side event stream

## Implementation Phases

### Phase 1: Foundation (Week 1-2)

- [ ] Demo data generator
- [ ] Persona definitions
- [ ] Basic mode switching
- [ ] Session management

### Phase 2: Tutorial System (Week 3-4)

- [ ] Overlay components
- [ ] Step sequencing
- [ ] Progress tracking
- [ ] Skip/replay functionality

### Phase 3: Intelligence (Week 5-6)

- [ ] Contextual hints
- [ ] Feature discovery tracking
- [ ] Adaptive tutorials
- [ ] Analytics integration

### Phase 4: Polish (Week 7-8)

- [ ] Animations and transitions
- [ ] Mobile optimization
- [ ] Accessibility
- [ ] Performance optimization

## Success Metrics & Analytics

### Key Performance Indicators

1. **Engagement Metrics**

   - Tutorial start rate
   - Completion rate
   - Skip rate by step
   - Time to completion

2. **Discovery Metrics**

   - Features discovered
   - Time to discovery
   - Usage after discovery

3. **Conversion Metrics**
   - Demo to real account
   - Feature adoption rate
   - Return visitor rate

### Analytics Events

```javascript
events: [
  "demo_mode_started",
  "tutorial_step_completed",
  "tutorial_skipped",
  "feature_discovered",
  "persona_selected",
  "demo_mode_exited",
  "conversion_to_real",
];
```

## Risk Mitigation

### Potential Risks & Solutions

1. **Over-tutorialization**

   - Solution: Always skippable, smart detection

2. **Demo/Real Data Confusion**

   - Solution: Clear visual indicators, separate database

3. **Performance Impact**

   - Solution: Lazy loading, efficient animations

4. **Mobile Experience**

   - Solution: Responsive design, touch-optimized

5. **Accessibility**
   - Solution: Screen reader support, keyboard navigation

## Alternative Approaches

### Minimal Viable Tutorial

Just contextual tooltips on hover, no formal tutorial flow

### Video Onboarding

Pre-recorded walkthrough videos instead of interactive

### Template System

Pre-built portfolio templates users can start from

### Guided Sandbox

Time-limited sandbox that converts to real account

## Open Questions

1. Should demo data be obviously fake or surprisingly realistic?
2. How much personality should the tutorial have?
3. Should we track detailed analytics or respect privacy?
4. Mobile-first or desktop-first tutorial design?
5. Should demos be shareable for education/marketing?

## Next Steps

1.  Gather feedback on this proposal
2.  Survey target users about onboarding preferences
3.  Prototype overlay system
4.  Write tutorial scripts
5.  Create visual designs for tutorial elements

## Appendix

### Inspiration & References

- Stripe: Test mode implementation
- Linear: Progressive disclosure
- Notion: Template system
- GitHub: First-time user experience
- Robinhood: Investment education

### Technical Considerations

- Phoenix LiveView for real-time updates
- PostgreSQL/SQLite for demo data
- JavaScript hooks for animations
- Playwright for testing/recording

### Accessibility Requirements

- WCAG 2.1 AA compliance
- Keyboard navigation
- Screen reader support
- High contrast mode
- Reduced motion support
