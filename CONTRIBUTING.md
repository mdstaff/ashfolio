# Contributing to Ashfolio

We welcome contributions to Ashfolio! Whether you're fixing a bug, adding a new feature, or improving documentation, your help is greatly appreciated. This guide will help you get started and ensure your contributions align with the project's standards.

## Code of Conduct

By participating in this project, you are expected to uphold our [Code of Conduct](CODE_OF_CONDUCT.md). (Note: This file is a placeholder and should be created with actual content).

## Getting Started

Before you start contributing, please ensure your development environment is set up correctly. Follow the instructions in [DEVELOPMENT_SETUP.md](docs/DEVELOPMENT_SETUP.md).

Once set up, you can get the application running with:

```bash
just dev
```

## How to Contribute

### 1. Find a Task

Check the [tasks.md](.kiro/specs/tasks.md) file for a list of planned features and bug fixes. If you have an idea for a new feature not listed, please open an issue first to discuss it.

### 2. Branching Strategy

We use a simple feature branching strategy:

*   Create a new branch from `main` for each feature or bug fix:
    ```bash
    git checkout main
    git pull origin main
    git checkout -b feature/your-feature-name
    # or
    git checkout -b bugfix/issue-description
    ```

### 3. Implement Your Changes

*   Write clean, maintainable code that adheres to the [Ashfolio Coding Standards](#coding-standards).
*   Write tests for all new functionality and ensure existing tests pass.
*   Make incremental commits with clear messages.

### 4. Commit Messages

Write clear, concise, and descriptive commit messages. A good commit message explains *what* was changed and *why*.

Example:

```
feat: Implement transaction CRUD operations

Adds full create, read, update, and delete functionality for transactions.
This completes Phase 9 and allows users to manage their investment records.
```

### 5. Pull Request Process

1.  **Push your branch** to your fork:
    ```bash
    git push origin feature/your-feature-name
    ```
2.  **Open a Pull Request** on the main Ashfolio repository.
3.  **Provide a clear description** of your changes, linking to any relevant issues or tasks.
4.  **Ensure all checks pass** (tests, linting, formatting).
5.  **Address any feedback** from reviewers.

## Coding Standards

Ashfolio adheres to specific coding standards to maintain consistency and quality. Please review the detailed guidelines in [.kiro/steering/ashfolio-coding-standards.md](.kiro/steering/ashfolio-coding-standards.md). Key highlights include:

*   **Ash Framework Usage**: All business logic must be implemented as Ash resources. No direct Ecto usage.
*   **Financial Data Handling**: Always use `Decimal` types for monetary values and keep everything in USD.
*   **Error Handling**: Use `Ashfolio.ErrorHandler` and `ErrorHelpers` for consistent, user-friendly error messages.
*   **Simplicity First**: Prefer explicit over clever code. Avoid premature optimizations.

## Testing

Maintaining a robust test suite is crucial for Ashfolio's stability. We expect all contributions to include appropriate tests and ensure the entire test suite passes.

*   **Run Tests**: Always run the full test suite before submitting a pull request:
    ```bash
    just test
    ```
*   **Specific Tests**: During development, use targeted commands:
    ```bash
    just test-file <path/to/your_test_file.exs>
    just test-watch
    ```
*   **Test Coverage**: Aim for high test coverage for new features. You can check coverage with:
    ```bash
    just test-coverage
    ```
*   **Mocking External APIs**: Never make real API calls in tests. Use Mox for mocking external services like Yahoo Finance.
*   **GenServer Testing**: Be aware of the specific patterns for testing singleton GenServers and shared state, as detailed in [.kiro/steering/phase9-testing-strategy.md](.kiro/steering/phase9-testing-strategy.md) and [.kiro/steering/project-context.md](.kiro/steering/project-context.md).

## Documentation

Keep documentation up-to-date. If your changes affect any of the following, please update them:

*   `CHANGELOG.md`: Summarize your changes for the next release.
*   `tasks.md`: Update the status of the task you're working on.
*   `.kiro/steering/project-context.md`: Add key learnings or significant technical decisions.
*   `docs/ARCHITECTURE.md`: If your changes impact the overall system design.

## Before Submitting a Pull Request - Checklist

*   [ ] Your code adheres to the [Ashfolio Coding Standards](#coding-standards).
*   [ ] All new features have corresponding tests.
*   [ ] All tests pass (`just test`).
*   [ ] Your code is formatted (`just format`).
*   [ ] Your commit messages are clear and descriptive.
*   [ ] You have updated relevant documentation (CHANGELOG, tasks, project context, architecture).
*   [ ] You have pulled the latest changes from `main` and resolved any conflicts.

Thank you for contributing to Ashfolio!
