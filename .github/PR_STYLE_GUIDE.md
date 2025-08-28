# Pull Request Description Style Guide

## Formatting Principles

### Professional & Concise

- Scannable structure with clear section headers
- Bullet points for easy reading
- Focused sections - 4-6 maximum
- Professional tone without excessive detail

### Value-Focused Content

- Emphasize user benefits over implementation details
- Highlight architectural alignment with local-first design
- Focus on what changed and why it matters
- Include testing/quality considerations

### ❌ What to Avoid

- Verbose explanations or technical deep-dives
- More than 5-7 bullet points per section
- Repetitive information across sections
- Implementation details better suited for code comments

## Template Structure

### Standard Flow

1.  Clear, descriptive feature/version name
2.  Changes to docs, guides, specs
3.  Alignment with ADR-001, design decisions
4.  User-facing functionality changes
5.  Tooling, setup, development changes
6.  Test coverage, performance, stability

### Section Guidelines

- Focus on documentation improvements and consistency
- Mention version reference updates
- Note removal of outdated content

- Reference ADR-001 compliance
- Document trade-offs or design decisions
- Mention local-first alignment

- Brief, user-focused descriptions
- Group related functionality
- Avoid technical implementation details

- Justfile/tooling changes
- New documentation or guides
- Setup or workflow improvements

- Test coverage improvements
- Performance considerations
- Quality assurance measures

### Specific Templates Available

- `.github/pull_request_template.md` (default)
- `.github/PULL_REQUEST_TEMPLATE/release.md`
- `.github/PULL_REQUEST_TEMPLATE/feature.md`
- `.github/PULL_REQUEST_TEMPLATE/bugfix.md`
- `.github/PULL_REQUEST_TEMPLATE/docs.md`

## Example: Good vs. Poor Formatting

### Good Example

```markdown
# Symbol Autocomplete Feature

## Features

- Autocomplete: Intelligent symbol search in transaction forms
- Performance: Sub-second search with ETS caching
- UX: Dropdown interface with keyboard navigation

## Developer Experience

- Tests: Added unit and integration tests for search functionality
- Documentation: Updated user guide with autocomplete usage
```

### ❌ Poor Example

```markdown
# This PR implements the symbol autocomplete feature that we discussed

## Changes

- I added a new GenServer called SymbolSearchServer that handles the autocomplete functionality by querying the symbols table and caching results in ETS for performance
- The frontend now has a dropdown component that shows search results
- There's a new endpoint for the search API that returns JSON
- I refactored some of the existing code to support this
- Added tests for the new functionality including edge cases
- Updated documentation to explain how it works
- Fixed a small bug I found while working on this
```

## Review Checklist

Before submitting a PR, verify:

- [ ] Title is clear and descriptive
- [ ] Sections are focused and scannable
- [ ] Bullet points are concise (1-2 lines max)
- [ ] Architecture alignment mentioned
- [ ] User benefits highlighted
- [ ] Testing considerations included
- [ ] Professional tone maintained
- [ ] No redundant information

## Future Evolution

This style guide will evolve based on:

- Team feedback on template usage
- PR review efficiency improvements
- Community contribution patterns
- Project scaling needs

Templates can be simplified or expanded based on what works best in practice.
