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
- **Focus**: Phoenix LiveView components and user interfaces
- **Key Files**: `lib/ashfolio_web/live/`, `lib/ashfolio_web/components/`
- **First Tasks**: UI improvements, responsive design, accessibility
- **Testing**: `just test-liveview` and `just test-ui`

### ⚙️ Backend Developer  
- **Focus**: Ash resources, business logic, and data models
- **Key Files**: `lib/ashfolio/portfolio/`, `lib/ashfolio/market_data/`
- **First Tasks**: New Ash resources, portfolio calculations, API integrations
- **Testing**: `just test-ash` and `just test-calculations`

### 🤖 AI Agent Developer
- **Focus**: AI-assisted development and tooling
- **Key Files**: `.kiro/`, `docs/development/ai-agent-guide.md`
- **First Tasks**: Improve AI context, testing patterns, documentation
- **Testing**: `just test-ai` and AI testing patterns

### 🧪 Quality Assurance
- **Focus**: Testing, reliability, and performance
- **Key Files**: `test/`, `docs/testing/`
- **First Tasks**: Test coverage, performance testing, edge cases
- **Testing**: All test categories, focus on `just test-integration`

## Prerequisites

- **macOS**: Currently optimized for macOS (Monterey 12.0+)
- **Development Tools**: Elixir 1.14+, Phoenix 1.7+, Just task runner
- **Git Knowledge**: Basic Git workflow (branch, commit, push, PR)
- **Time Commitment**: 30-60 minutes for first contribution

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

- **Installation Issues**: See [Troubleshooting](troubleshooting.md)
- **Architecture Questions**: Review [Architecture Guide](../development/architecture.md)
- **Testing Problems**: Check [Testing Overview](../testing/README.md)
- **General Questions**: Open a GitHub issue or discussion

## Success Indicators

By the end of your onboarding, you should be able to:

- [ ] Start the development server with `just dev`
- [ ] Run tests successfully with `just test`
- [ ] Understand the basic architecture (Ash + Phoenix + LiveView)
- [ ] Create a branch and make a small contribution
- [ ] Run the specific tests relevant to your changes

---

**Ready to begin?** Start with the [Installation Guide](installation.md) →