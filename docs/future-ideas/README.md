# Future Ideas & Enhancements

This directory contains specifications and designs for features that are compelling but not currently prioritized for development. These serve as a reference for future roadmap planning and architectural decisions.

## Organization

Each major feature idea gets its own markdown file with:

- What user need this addresses
- High-level approach
- Implementation details
- Why this would be valuable
- Effort estimation

## Current Future Ideas

### 🏦 [Multi-Portfolio Workspace System](./multi-portfolio-workspaces.md)

Designed but not prioritized  
 High  
 High for power users

Transform Ashfolio into a workspace-based system where users can create, manage, and switch between multiple portfolios (databases), similar to how code editors handle workspaces/projects.

Key Benefits:

- Multiple isolated portfolios (Personal, Business, Family, etc.)
- True data portability (copy .db file = complete portfolio)
- Enhanced privacy and organization
- Perfect for financial advisors managing multiple clients

Implementation Challenge:

- Dynamic database connection switching
- Portfolio registry management
- Migration coordination across databases

---

## Contributing Ideas

When adding new future ideas:

1. Create a detailed spec following the template
2. Include mockups/wireframes if applicable
3. Consider integration with existing architecture
4. Estimate complexity and list dependencies
5. Add to this README with brief summary

## Review Process

Future ideas should be reviewed periodically to:

- Reassess priority based on user feedback
- Update complexity as technology/architecture evolves
- Archive ideas that are no longer relevant
- Graduate ideas to active development when prioritized
