---
inclusion: manual
---

# Task Execution Guidelines

This steering rule provides specific guidance for executing tasks from the Ashfolio implementation plan.

## Before Starting Any Task

1. **Verify Test Suite Stability**

   - **FIRST:** Run `just test` to ensure all tests pass (currently 201/201 passing)
   - If tests fail, fix test issues before proceeding with new features
   - Use `just test-failed` for debugging failing tests
   - Use `just test-file-verbose <file>` only when debugging specific test failures

2. **Read Context Documents**

   - **SECOND:** Check `CHANGELOG.md` for recent progress and technical decisions
   - Always review `.kiro/specs/requirements.md` for feature requirements
   - Check `.kiro/specs/design.md` for technical architecture
   - Review the specific task details in `.kiro/specs/tasks.md`

3. **Update Steering Documents**

   - Update `.kiro/steering/project-context.md` with current task being started
   - Move the task from "Next Priority Tasks" to "Currently Working On"
   - Update completion percentage if starting a new phase

4. **Update Task Status**

   - Mark task as "in_progress" before starting work
   - Mark as "completed" only when fully finished
   - Handle sub-tasks individually if they exist

5. **Verify Dependencies**
   - Ensure prerequisite tasks are completed
   - Check that required files/modules exist
   - Verify database migrations are up to date

## During Task Execution

### Code Implementation

- Follow the Ashfolio coding standards (always included steering)
- Write tests alongside implementation code
- Use incremental commits for complex tasks
- Test functionality manually before marking complete

### Testing Requirements

- **Maintain 100% test pass rate** - all 201 tests must pass before and after changes
- Unit tests for all new Ash resources and actions
- Integration tests for complex workflows
- Mock external APIs consistently
- Verify error handling scenarios

### Testing Commands (Use Justfile Only)

- Review the justfile #[[file:justfile]]
- **Development testing**: `just test-watch` - Continuous testing during development
- **Focused testing**: `just test-file <path>` - Test specific files (preferred for targeted testing)
- **Main test suite**: `just test` - Run core tests (excludes seeding for speed)
- **Coverage analysis**: `just test-coverage` - Ensure adequate test coverage for new code
- **Seeding tests**: `just test-seeding` - Run seeding tests separately when needed
- **Failed tests**: `just test-failed` - Re-run only previously failed tests
- **Debugging**: `just test-file-verbose <file>` - Use only when debugging specific failures

### Documentation

- Update relevant documentation if architecture changes
- Add code comments for complex business logic
- Update `.kiro/steering/project-context.md` if significant decisions are made
- Keep steering documents current with project progress
- **Capture Key Learnings**: Document technical patterns, gotchas, configuration requirements, testing approaches, and architectural decisions that future tasks should know about

## After Task Completion

1. **Verification Checklist**

   - **All tests pass** (`just test` shows 201/201 passing)
   - **Seeding tests pass** (`just test-seeding` if seeding functionality was modified)
   - Application starts without errors (`mix phx.server`)
   - New functionality works as expected
   - No regressions in existing features
   - Test coverage maintained or improved (`just test-coverage`)

2. **Update Task Status**

   - Mark task as "completed" in tasks.md
   - Update completion percentage in project-context.md
   - Note any deviations from original plan

3. **Update Documentation**

   - **Update `CHANGELOG.md`** with detailed task completion information
   - Move completed task from "Currently Working On" to "Recently Completed" in project-context.md
   - Update "Next Priority Tasks" with upcoming tasks
   - **Add key learnings** to "Key Learnings & Technical Decisions" section in project-context.md
   - Document any important technical decisions, patterns, or gotchas discovered
   - Update the current phase if a milestone is reached

4. **Prepare for Next Task**
   - Review next task requirements
   - Identify any blockers or dependencies
   - Update project status summary

## Task-Specific Guidelines

### Data Model Tasks (5-8)

- Define Ash resources with proper attributes and relationships
- Include comprehensive validations
- Write thorough unit tests
- Verify database schema matches design

### LiveView Tasks (16-26)

- Start with basic functionality, then enhance
- Test user interactions manually
- Ensure real-time updates work correctly
- Follow Phoenix LiveView best practices

### Integration Tasks (27-29)

- Test complete user workflows end-to-end
- Verify error handling across the application
- Ensure performance meets basic requirements
- Document any known limitations

## Common Task Execution Pitfalls

- **Don't skip tests** - Each task should include appropriate testing
- **Don't over-engineer** - Keep solutions simple and focused
- **Don't ignore errors** - Handle edge cases and error scenarios
- **Don't work on multiple tasks** - Complete one task fully before moving to next
- **Don't skip documentation** - Update relevant docs when making changes

## Success Criteria

A task is complete when:

- All code is implemented and tested
- Tests pass consistently
- Functionality works as specified in requirements
- No regressions in existing features
- Task status is updated to "completed"
- Relevant documentation is updated
