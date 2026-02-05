# Documentation Review Checklist

Use this checklist when reviewing or updating project documentation to ensure quality, consistency, and maintainability.

## Version Updates

When updating documentation for a new version release:

- [ ] All version numbers updated consistently across files
- [ ] No outdated "Completed in vX.Y.Z" sections remaining
- [ ] Historical features documented only in appropriate locations:
  - CHANGELOG.md (for version history)
  - "Currently Available" or similar current-state sections
  - NOT in version-specific callout sections
- [ ] Roadmap updated with correct status markers (✅, 🚧, 📋)
- [ ] Version date stamps are accurate

## Content Quality

### Single Source of Truth

- [ ] No duplicate information across sections
- [ ] Each feature documented in exactly one place
- [ ] Cross-references used instead of duplication
- [ ] Related information properly linked (not copied)

### Information Architecture

- [ ] Clear hierarchy (Current → Latest → Roadmap → Historical)
- [ ] Consistent section naming and structure
- [ ] Logical information flow (overview → details)
- [ ] Appropriate use of emphasis (callouts, badges, headers)

### Technical Accuracy

- [ ] Version numbers match mix.exs
- [ ] Test counts verified against actual test suite
- [ ] Feature claims verified against source code
- [ ] API examples tested and working
- [ ] Links resolve correctly

## Duplication Detection

Run these checks before completing documentation updates:

### Manual Checks

- [ ] Search for duplicate section headings
- [ ] Compare feature lists across sections
- [ ] Verify no information appears in multiple locations
- [ ] Check for outdated version references

### Automated Checks (if available)

```bash
# Check for duplicate headings in README
grep '^###.*Features' README.md | sort | uniq -d

# Verify version consistency
grep -r "v0\.[0-9]*\.[0-9]*" README.md ROADMAP.md
```

## Structure Validation

### README.md Specific

- [ ] "Why Ashfolio?" section appears early (establishes value prop)
- [ ] "Quick Start" provides immediate path to running app
- [ ] "Features" section focuses on current capabilities
- [ ] "Latest Features" shows most recent additions (last 2-3 versions)
- [ ] "Currently Available" covers stable, production features
- [ ] "Development Roadmap" shows future direction
- [ ] No version-specific callouts outside "Latest Features"

### Cross-Document Consistency

- [ ] README version matches ROADMAP version
- [ ] README version matches CHANGELOG version
- [ ] README version matches mix.exs version
- [ ] Feature descriptions consistent across docs
- [ ] Terminology used consistently

## Link Integrity

- [ ] All internal links resolve (test with `grep -r "docs/" README.md`)
- [ ] All document references point to existing files
- [ ] No broken relative paths
- [ ] External links are still valid (if applicable)

## Style and Formatting

- [ ] Markdown formatting correct (headers, lists, code blocks)
- [ ] Consistent capitalization in section headers
- [ ] Consistent bullet point style (- vs * vs +)
- [ ] Code blocks have language specifiers
- [ ] Tables formatted correctly (if used)

## Accessibility

- [ ] Section headers follow logical hierarchy (H1 → H2 → H3)
- [ ] Links have descriptive text (not "click here")
- [ ] Images have alt text (if any)
- [ ] Tables have headers
- [ ] Color not used as only indicator (if applicable)

## Special Considerations

### For Version Updates

When moving from version X to version Y:

1. **Archive Previous Version Content**
   - Remove "Completed in vX.Y.Z" sections
   - Move detailed version history to CHANGELOG.md
   - Keep only current state in main sections

2. **Consolidate New Features**
   - Add to "Latest Features" with version header
   - Integrate into "Currently Available" if stable
   - Don't create duplicate sections

3. **Update Navigation**
   - Ensure all links updated to new structure
   - Remove links to deleted sections
   - Add links to new documentation

### For New Feature Documentation

- [ ] Feature appears in exactly one primary location
- [ ] Cross-references point to that location
- [ ] Examples are complete and tested
- [ ] Prerequisites clearly stated
- [ ] Related features linked

## Pre-Commit Verification

Before committing documentation changes:

- [ ] Run `mix format` on any code examples
- [ ] Verify links with automated tool (if available)
- [ ] Review diff for unintended changes
- [ ] Check for trailing whitespace
- [ ] Ensure consistent line endings

## Post-Update Validation

After documentation update is complete:

- [ ] Fresh checkout and verify links work
- [ ] Quick start instructions actually work
- [ ] Examples can be copy-pasted and run
- [ ] No "TODO" markers without issue numbers
- [ ] Documentation renders correctly (if using doc generator)

## Common Pitfalls to Avoid

- ❌ Leaving version-specific sections after major updates
- ❌ Duplicating feature lists in multiple sections
- ❌ Forgetting to update version numbers in all locations
- ❌ Breaking internal links during restructuring
- ❌ Inconsistent feature descriptions across documents
- ❌ Outdated code examples or commands
- ❌ Missing context for new sections

## Success Criteria

Documentation update is complete when:

- ✅ All checklist items above are satisfied
- ✅ No duplicate information exists
- ✅ Version references are current and consistent
- ✅ All links resolve correctly
- ✅ Content follows project style guide
- ✅ Technical accuracy verified against code
- ✅ Review by another person (if available)

---

**Template Version**: 1.0
**Created**: December 21, 2025
**Last Updated**: December 21, 2025
**Owner**: Technical Writing Agent
