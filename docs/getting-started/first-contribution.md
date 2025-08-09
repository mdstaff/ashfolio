# Your First Contribution

Welcome! This guide will help you make your first contribution to Ashfolio in 30 minutes.

## 15-Minute Quick Win

Perfect for getting familiar with the codebase:

### 1. Find a Good First Issue
- Check [GitHub Issues](https://github.com/mdstaff/ashfolio/issues) labeled "good first issue"
- Look for documentation improvements, typo fixes, or small UI enhancements
- Or fix a typo you notice while exploring the code!

### 2. Set Up Your Development Environment
```bash
# Fork the repository on GitHub, then:
git clone https://github.com/YOUR_USERNAME/ashfolio.git
cd ashfolio
just dev  # This sets everything up
```

### 3. Create a Branch
```bash
git checkout -b fix/your-improvement-description
```

### 4. Make Your Change
Examples of great first contributions:
- Fix a typo in documentation
- Improve a comment or error message
- Add a helpful code comment
- Update outdated documentation links
- Improve formatting or styling

### 5. Test Your Change
```bash
just test              # Run all tests
just format            # Format your code
just check             # Run format + compile + test
```

### 6. Submit Your PR
```bash
git add .
git commit -m "fix: improve error message clarity in Account validation"
git push origin fix/your-improvement-description
```

Then open a Pull Request on GitHub with a clear description!

## 30-Minute Feature Addition

Ready for something more substantial:

### 1. Choose a Small Feature
Look for features in the project tasks:
- Small UI improvements
- Additional validation
- New helper functions
- Test improvements

### 2. Follow the TDD Pattern
```bash
# 1. Write a failing test first
just test-file test/path/to/your_test.exs

# 2. Implement the feature
# Edit the relevant files

# 3. Make the test pass
just test-file test/path/to/your_test.exs

# 4. Run all tests to ensure no regressions
just test
```

### 3. Example Feature: Add Quantity Validation

Let's walk through adding a small feature:

**Step 1: Write a failing test** (`test/ashfolio/portfolio/transaction_test.exs`):
```elixir
test "validates quantity is not zero for BUY transactions" do
  attrs = @valid_attrs |> Map.put(:quantity, Decimal.new("0"))
  assert {:error, %Ash.Error.Invalid{}} = Transaction.create(attrs)
end
```

**Step 2: Run the test (it should fail)**:
```bash
just test-file test/ashfolio/portfolio/transaction_test.exs
```

**Step 3: Implement the feature** (`lib/ashfolio/portfolio/transaction.ex`):
```elixir
validations do
  validate validate_quantity_not_zero(:quantity)
end

defp validate_quantity_not_zero(quantity) do
  if Decimal.eq?(quantity, 0) do
    {:error, "Quantity cannot be zero"}
  else
    :ok
  end
end
```

**Step 4: Make the test pass**:
```bash
just test-file test/ashfolio/portfolio/transaction_test.exs
just test  # Ensure no regressions
```

### 4. Follow Code Standards

Ashfolio follows specific patterns:

- **Ash Framework**: All business logic in Ash resources
- **Decimal Types**: Always use `Decimal` for monetary values
- **Error Handling**: Use `ErrorHandler` for consistent messages
- **Testing**: Write tests for all new functionality

### 5. Update Documentation

If your feature changes behavior:
- Update relevant `.md` files
- Add comments to complex code
- Update the CHANGELOG.md

## Quality Checklist

Before submitting your PR:

- [ ] **Tests Pass**: `just test` shows all green
- [ ] **Code Formatted**: `just format` applied
- [ ] **No Warnings**: `just check` succeeds
- [ ] **Clear Commit Message**: Explains what and why
- [ ] **Documentation Updated**: If behavior changed
- [ ] **Self-Review**: You've reviewed your own changes

## Common Patterns in Ashfolio

### Ash Resource Pattern
```elixir
# Always use Ash resources for business logic
{:ok, user} = User.create(%{name: "New User"})
{:ok, users} = User.list()
```

### Error Handling Pattern
```elixir
case Account.create(attrs) do
  {:ok, account} -> 
    # Success path
  {:error, error} -> 
    ErrorHandler.handle_error(error, "Failed to create account")
end
```

### Testing Pattern
```elixir
describe "create/1" do
  test "creates account with valid attributes" do
    attrs = %{name: "Test Account", platform: "Schwab"}
    assert {:ok, %Account{} = account} = Account.create(attrs)
    assert account.name == "Test Account"
  end
end
```

## Getting Help

- **Stuck on Ash Framework?** Check [Ash Documentation](https://ash-hq.org/)
- **Phoenix/LiveView Questions?** See [Phoenix Guides](https://hexdocs.pm/phoenix/overview.html)
- **Testing Issues?** Review [Testing Guide](../testing/README.md)
- **Architecture Questions?** Read [Architecture Overview](../development/architecture.md)
- **General Help?** Ask on GitHub Discussions or open an issue

## What Makes a Great First Contribution?

1. **Solves a Real Problem**: Even small improvements help
2. **Includes Tests**: Shows you understand the codebase
3. **Follows Patterns**: Consistent with existing code
4. **Clear Description**: Explains the what and why
5. **Respects Standards**: Formatted, tested, documented

## Next Steps After Your First PR

1. **Review Feedback**: Learn from code review comments
2. **Tackle Bigger Features**: Look for more complex issues
3. **Help Others**: Review other contributors' PRs
4. **Improve Documentation**: Share what you learned
5. **Suggest Features**: Propose new functionality

---

**Ready to start?** Pick an issue and follow the 15-minute quick win process!  
**Need more context?** Review the [Architecture Overview](../development/architecture.md) first.