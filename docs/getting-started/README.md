# Getting Started with Ashfolio Development

Welcome to Ashfolio! This guide will get you from zero to your first contribution in under an hour.

## Your Journey

1. **Setup** → [Installation Guide](installation.md) (5 minutes)
2. **Explore** → [Quick Start](quick-start.md) (10 minutes)
3. **Understand** → [Architecture Overview](../development/architecture.md) (20 minutes)
4. **Contribute** → [First Contribution](first-contribution.md) (30 minutes)

## Role-Specific Paths

Choose the path that matches your interest:

### 🎨 Frontend Developer

- Phoenix LiveView components and user interfaces
- `lib/ashfolio_web/live/`, `lib/ashfolio_web/components/`
- UI improvements, responsive design, accessibility
- `just test-liveview` and `just test-ui`

### ⚙️ Backend Developer

- Ash resources, business logic, and data models
- `lib/ashfolio/portfolio/`, `lib/ashfolio/market_data/`
- New Ash resources, portfolio calculations, API integrations
- `just test-ash` and `just test-calculations`

### 🤖 AI Agent Developer

- AI-assisted development and tooling
- `.kiro/`, `docs/development/ai-agent-guide.md`
- Improve AI context, testing patterns, documentation
- `just test-ai` and AI testing patterns

### 🧪 Quality Assurance

- Testing, reliability, and performance
- `test/`, `docs/testing/`
- Test coverage, performance testing, edge cases
- All test categories, focus on `just test-integration`

## Prerequisites

- Currently optimized for macOS (Monterey 12.0+)
- Elixir 1.14+, Phoenix 1.7+, Just task runner
- Basic Git workflow (branch, commit, push, PR)
- 30-60 minutes for first contribution

## Quick Commands Reference

```bash
# Essential commands you'll use daily
just dev                    # Start development (deps + migrate + server)
just test                   # Run test suite
just test-file path.exs     # Run specific test
just format                 # Format code
just check                  # Format + compile + test
```

## Need Help?

- See [Troubleshooting](troubleshooting.md)
- Review [Architecture Guide](../development/architecture.md)
- Check [Testing Overview](../testing/README.md)
- Open a GitHub issue or discussion

## Success Indicators

By the end of your onboarding, you should be able to:

- [ ] Start the development server with `just dev`
- [ ] Run tests successfully with `just test`
- [ ] Understand the basic architecture (Ash + Phoenix + LiveView)
- [ ] Create a branch and make a small contribution
- [ ] Run the specific tests relevant to your changes

---

**Ready to begin?** Start with the [Installation Guide](installation.md) →
