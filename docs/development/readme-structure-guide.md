# README Structure Guide

This guide establishes standards for maintaining the project README.md, with focus on version updates, information architecture, and avoiding duplication.

## Overview

The README is the project's front door - the first document developers, users, and contributors encounter. It must be:

- **Current**: Reflect the actual state of the project
- **Concise**: Provide essential information without overwhelming
- **Consistent**: Maintain structure across versions
- **Accurate**: Match the codebase reality
- **Maintainable**: Easy to update without introducing duplication

## Information Architecture

### Core Principle: Single Source of Truth

Each piece of information should appear in exactly ONE authoritative location. Other documents reference or link to it, rather than duplicating it.

### Section Hierarchy

```markdown
1. Project Overview (What & Why)
   ├── Title & Tagline
   ├── Brief Description
   └── Why Ashfolio? (Value Proposition)

2. Getting Started (How to Run)
   ├── Prerequisites
   ├── Installation
   └── Quick Start

3. Features (What It Does)
   ├── High-level Feature List
   ├── Privacy/Security Features
   └── Setup Features

4. Project Status (Where We Are)
   ├── Current Version
   ├── Latest Features (last 2-3 versions)
   ├── Currently Available (stable features)
   └── Development Roadmap (future)

5. Architecture & Development (How It Works)
   ├── Tech Stack
   ├── Development Workflow
   └── Contributing

6. Documentation (Where to Learn More)
   ├── Getting Started Guides
   ├── Development Guides
   ├── Feature Documentation
   └── API Reference

7. Support & License
   ├── Troubleshooting
   ├── Community
   └── License
```

## Version Update Workflow

### When to Update README

Update the README when:

- New version is released
- Major features are added
- Project status changes
- Core architecture changes
- Getting started process changes

### Version Update Checklist

#### 1. Pre-Update Assessment

**Identify Content to Change:**
```bash
# Find all version references
grep -n "v0\.[0-9]*\.[0-9]*" README.md

# Find version-specific sections
grep -n "Completed in v" README.md
grep -n "### v0\." README.md
```

**Determine Content Fate:**
- **Remove**: Outdated version callouts ("Completed in v0.7.0")
- **Consolidate**: Duplicate feature lists
- **Archive**: Detailed version history → CHANGELOG.md
- **Update**: Version numbers, status markers

#### 2. Update Execution

**A. Update Version Numbers**
- [ ] "Current Version" line
- [ ] Latest feature headers
- [ ] Any other version references

**B. Update "Latest Features" Section**

Rules for "Latest Features":
- Show only last 2-3 versions
- Use version headers (#### v0.X.0 - Name)
- Include 3-5 key features per version
- Keep descriptions brief (one line each)
- Remove older versions as new ones are added

Example:
```markdown
### Latest Features

#### v0.10.0 - MCP Phase 2 (November 2025)
- AI Settings page with privacy controls and consent management
- GDPR-compliant consent infrastructure with audit trails
- Natural language parsing for amounts and dates
- Tool discovery optimization (~85% token reduction)

#### v0.9.0 - MCP Integration (November 2025)
- Model Context Protocol server for AI assistants
- Privacy filtering system with four modes
- Secure portfolio data access for AI tools

#### v0.8.0 - AI Natural Language Entry (November 2025)
- Parse conversational transactions with natural language
- Local AI with Ollama or cloud with OpenAI
- Human-in-the-loop validation before saving
```

**C. Remove Version-Specific Callouts**

❌ **Remove sections like:**
```markdown
### Completed in v0.7.0 ✅
- Feature A
- Feature B
```

These create several problems:
1. Become outdated as project progresses
2. Confuse users about what's "current"
3. Create maintenance burden
4. Violate single source of truth

✅ **Instead:**
- Add to CHANGELOG.md for historical record
- Move stable features to "Currently Available"
- Reference in "Latest Features" if recent

**D. Consolidate Duplicate Sections**

Common duplication patterns:
- Feature lists appearing in multiple sections
- Same information with different formatting
- Redundant explanations of capabilities

**Detection Method:**
```bash
# Find duplicate feature descriptions
grep -A 5 "Natural Language" README.md
grep -A 5 "MCP Integration" README.md
```

**Resolution:**
1. Identify the "primary" location for information
2. Remove duplicate sections
3. Add cross-reference if needed

Example:
```markdown
<!-- Primary location: Latest Features section -->
#### v0.10.0 - MCP Phase 2
- AI Settings page with privacy controls
- Natural language parsing for amounts

<!-- Remove duplicate section later in doc -->
<!-- ❌ This should be removed:
#### AI-Enhanced Features
- AI Settings page with privacy controls
- Natural language parsing for amounts
-->
```

**E. Update "Currently Available" Section**

Purpose: Document stable, production-ready features.

Rules:
- No version numbers here
- Present tense ("provides", "includes", "supports")
- Organized by category
- Features that have been stable for 1+ version

When to add features:
- Feature is stable and tested
- Feature is documented
- Feature is recommended for production use

Example:
```markdown
### Currently Available

#### Core Financial Management
- Investment Portfolio Tracking with FIFO cost basis
- Net Worth Calculation across accounts
- Cash Account Management for checking, savings, etc.
```

**F. Update Development Roadmap**

Use consistent status markers:
- ✅ Complete (versions up to current)
- 🚧 In Progress (current development)
- 📋 Planned (future versions)

Format:
```markdown
### Development Roadmap

- ✅ v0.1.0 - v0.10.0: Complete (AI integration, MCP, consent)
- 🚧 v0.11.0: Additional AI enhancements and analytics
- 📋 v1.0.0: Production hardening and performance optimization
```

#### 3. Post-Update Verification

**Check for Duplication:**
```bash
# Manual review
grep -n "^###.*Features" README.md

# Look for similar content
diff <(grep -A 3 "Natural Language" README.md | head -5) \
     <(grep -A 3 "Natural Language" README.md | tail -5)
```

**Verify Consistency:**
- [ ] Version in README matches mix.exs
- [ ] Version in README matches ROADMAP.md
- [ ] Version in README matches CHANGELOG.md
- [ ] All version references updated
- [ ] No "Completed in vX.Y.Z" sections remain

**Test Links:**
```bash
# Extract and test internal links
grep -o '\[.*\](docs/.*\.md)' README.md | \
  sed 's/.*(\(.*\))/\1/' | \
  while read link; do
    [ -f "$link" ] || echo "Broken: $link"
  done
```

## Feature Documentation Lifecycle

### Lifecycle Stages

1. **New Feature** (v0.X.0 release)
   - Appears in "Latest Features" with version header
   - May have "🆕" or similar indicator
   - Detailed documentation in `docs/features/implemented/`

2. **Stable Feature** (1-2 versions after release)
   - Moves to "Currently Available"
   - Remains in "Latest Features" for 2-3 versions
   - Loses version-specific callouts

3. **Established Feature** (3+ versions old)
   - Only in "Currently Available"
   - Removed from "Latest Features"
   - Historical details only in CHANGELOG.md

4. **Deprecated Feature**
   - Marked clearly in documentation
   - Moved to deprecation notice
   - Eventually removed from README

### Example Lifecycle

**Version 0.8.0 Release:**
```markdown
### Latest Features
#### v0.8.0 - AI Natural Language Entry
- Parse conversational transactions
```

**Version 0.9.0 Release:**
```markdown
### Latest Features
#### v0.9.0 - MCP Integration
- Model Context Protocol server

#### v0.8.0 - AI Natural Language Entry
- Parse conversational transactions
```

**Version 0.10.0 Release:**
```markdown
### Latest Features
#### v0.10.0 - MCP Phase 2
- AI Settings page

#### v0.9.0 - MCP Integration
- Model Context Protocol server

#### v0.8.0 - AI Natural Language Entry
- Parse conversational transactions
```

**Version 0.11.0 Release:**
```markdown
### Latest Features
#### v0.11.0 - Enhanced Analytics
- Advanced reporting features

#### v0.10.0 - MCP Phase 2
- AI Settings page

#### v0.9.0 - MCP Integration
- Model Context Protocol server

<!-- v0.8.0 removed - now only in "Currently Available" -->
```

## Common Anti-Patterns

### ❌ Anti-Pattern 1: Version-Specific Callouts

**Problem:**
```markdown
### Completed in v0.7.0 ✅
- Advanced Portfolio Analytics
- Corporate Actions Engine
```

**Why It's Bad:**
- Becomes outdated immediately
- Creates confusion about current state
- Duplicates information
- Requires removal in next update

**Solution:**
```markdown
### Currently Available

#### Advanced Analytics
- Markowitz portfolio optimization
- Risk metrics (Sharpe, Sortino, VaR)
- Correlation analysis

<!-- Version history in CHANGELOG.md -->
```

### ❌ Anti-Pattern 2: Duplicate Feature Lists

**Problem:**
```markdown
### Latest Features
- Natural Language Transaction Entry
- MCP Integration
- Privacy Controls

<!-- Later in document -->
#### AI-Enhanced Features
- Natural Language Transaction Entry
- MCP Integration
- Privacy Controls
```

**Why It's Bad:**
- Maintenance burden (update in multiple places)
- Risk of inconsistency
- Violates DRY principle
- Confuses readers

**Solution:**
```markdown
### Latest Features
- Natural Language Transaction Entry
- MCP Integration
- Privacy Controls

<!-- Later in document -->
For complete AI feature documentation, see:
- [AI Natural Language Entry](docs/features/implemented/ai-natural-language-entry.md)
- [MCP Integration](docs/features/implemented/mcp-integration.md)
```

### ❌ Anti-Pattern 3: Missing Version Migration

**Problem:**
Updating version numbers but not removing old content.

**Solution:**
Use checklist approach:
- [ ] Update version numbers
- [ ] Add new features
- [ ] Remove outdated callouts
- [ ] Consolidate duplicates
- [ ] Archive historical details

## README Maintenance

### Regular Maintenance Tasks

**After Each Release:**
- Update version numbers
- Add latest features
- Remove version-specific sections from 3+ versions ago
- Consolidate any duplicates
- Update roadmap status

**Quarterly Review:**
- Review entire README structure
- Check for outdated information
- Verify all links
- Update screenshots (if any)
- Validate code examples

**Annual Review:**
- Assess if README structure still serves users
- Consider reorganization if needed
- Update architectural descriptions
- Refresh "Why Ashfolio?" based on evolved value prop

### Quality Metrics

Track these metrics over time:

- **Duplication Score**: Instances of duplicate information
- **Staleness Score**: Outdated version references
- **Link Integrity**: Percentage of working links
- **Update Lag**: Days between version release and README update
- **Structure Stability**: Major restructures per year

**Target Values:**
- Duplication Score: 0
- Staleness Score: 0
- Link Integrity: 100%
- Update Lag: <1 day
- Structure Stability: <2 major changes/year

## Tools and Automation

### Helpful Commands

**Find Version References:**
```bash
# Find all version numbers
grep -n "v[0-9]\+\.[0-9]\+\.[0-9]\+" README.md

# Find version-specific sections
grep -n "### .*v[0-9]" README.md
```

**Detect Duplication:**
```bash
# Find duplicate section headers
grep "^###" README.md | sort | uniq -d

# Find similar content
grep -A 5 "Features" README.md | sort | uniq -d
```

**Verify Links:**
```bash
# Check internal documentation links
grep -o '\[.*\](docs/.*\.md)' README.md | \
  sed 's/.*(\(.*\))/\1/' | \
  while read link; do
    if [ ! -f "$link" ]; then
      echo "❌ Broken link: $link"
    else
      echo "✅ Valid: $link"
    fi
  done
```

**Version Consistency Check:**
```bash
# Compare versions across files
echo "mix.exs: $(grep 'version:' mix.exs)"
echo "README: $(grep 'Current Version:' README.md)"
echo "ROADMAP: $(grep 'Current Version:' ROADMAP.md)"
```

### Automation Opportunities

**Pre-commit Hook:**
```bash
#!/bin/sh
# .git/hooks/pre-commit

# Check for duplicate sections in README
if git diff --cached README.md | grep -q "^+### "; then
  echo "Checking README for duplicates..."
  grep "^###" README.md | sort | uniq -d
fi
```

**CI/CD Check:**
```yaml
# .github/workflows/docs-quality.yml
- name: Check README Quality
  run: |
    # No duplicate headers
    duplicates=$(grep "^###" README.md | sort | uniq -d | wc -l)
    if [ "$duplicates" -gt 0 ]; then
      echo "❌ Found duplicate headers in README"
      exit 1
    fi

    # Version consistency
    readme_version=$(grep 'Current Version:' README.md | sed 's/.*v//')
    mix_version=$(grep 'version:' mix.exs | sed 's/.*"\(.*\)".*/\1/')
    if [ "$readme_version" != "$mix_version" ]; then
      echo "❌ Version mismatch: README $readme_version vs mix.exs $mix_version"
      exit 1
    fi
```

## Integration with Agent Workflow

### For Technical Writing Agent

When updating README as part of version release:

1. **Load this guide** before starting
2. **Follow version update checklist** step-by-step
3. **Use detection commands** to find duplication
4. **Verify against checklist** before completing
5. **Document any deviations** and reasoning

### Success Criteria

README update is successful when:

- ✅ No duplicate information exists
- ✅ No version-specific callouts older than 3 versions
- ✅ All links resolve correctly
- ✅ Version numbers consistent across files
- ✅ Feature lifecycle followed correctly
- ✅ Single source of truth maintained
- ✅ Information architecture preserved

## References

- [Documentation Review Checklist](/.claude/templates/documentation-review-checklist.md)
- [Documentation Style Guide](/docs/development/documentation-style-guide.md)
- [Technical Writing Agent Config](/.claude/agents/technical-writing-agent.md)
- [CLAUDE.md Development Guidelines](/CLAUDE.md)

---

**Guide Version**: 1.0
**Created**: December 21, 2025
**Last Updated**: December 21, 2025
**Maintained By**: Technical Writing Team
