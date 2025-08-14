# QA Testing Plan: Task 12 - Investment Category Seeding and System Setup

## Overview

This comprehensive QA testing plan covers Task 12: "Create investment category seeding and system setup" for the Ashfolio project. The plan ensures robust, idempotent category seeding functionality that integrates seamlessly with existing workflows.

## Architectural Context

### Component Overview
- **CategorySeeder Module**: `Ashfolio.FinancialManagement.CategorySeeder`
- **Integration Points**: `priv/repo/seeds.exs`, database migrations, existing user workflows
- **Investment Categories**: Growth (#10B981), Income (#3B82F6), Speculative (#F59E0B), Index (#8B5CF6), Cash (#6B7280), Bonds (#059669)
- **Key Features**: User-scoped system categories, name-based conflict resolution, transaction-based seeding

## 1. Unit Testing Requirements

### 1.1 CategorySeeder Module Tests

**Test File**: `test/ashfolio/financial_management/category_seeder_test.exs`

#### 1.1.1 Core Functionality Tests

```elixir
# Test Case: Basic seeding functionality
test "seeds all investment categories for a user", %{user: user} do
  # Verify all 6 categories are created with correct attributes
  # Check: name, color, is_system flag, user_id
end

# Test Case: Category creation validation
test "creates categories with correct investment attributes" do
  # Verify each category has expected name and color
  # Growth: #10B981, Income: #3B82F6, etc.
end

# Test Case: System flag validation
test "marks seeded categories as system categories" do
  # Verify is_system = true for all seeded categories
end

# Test Case: User association
test "associates categories with correct user" do
  # Verify user_id is correctly set for all categories
end
```

#### 1.1.2 Idempotent Behavior Tests

```elixir
# Test Case: Duplicate seeding prevention
test "does not create duplicate categories on repeated seeding", %{user: user} do
  # Run seeder twice, verify only 6 categories exist
  # Check category counts before and after
end

# Test Case: Name-based conflict resolution
test "handles existing categories with same names gracefully", %{user: user} do
  # Pre-create a category with same name
  # Run seeder, verify no duplicates or errors
end

# Test Case: Partial seeding scenarios
test "handles partial category sets correctly", %{user: user} do
  # Pre-create some categories, run seeder
  # Verify missing categories are created, existing ones untouched
end

# Test Case: Cross-user isolation
test "seeding for one user does not affect other users" do
  # Create multiple users, seed for each
  # Verify each user has their own category set
end
```

#### 1.1.3 Error Handling Tests

```elixir
# Test Case: Database constraint violations
test "handles database errors gracefully" do
  # Test various constraint violations
  # Verify proper error handling and rollback
end

# Test Case: Invalid user scenarios
test "handles invalid user_id appropriately" do
  # Test with nil, non-existent user_id
  # Verify appropriate error responses
end

# Test Case: Transaction rollback
test "rolls back on partial failures" do
  # Force failure after some categories created
  # Verify no partial state persists
end
```

#### 1.1.4 Performance Tests

```elixir
# Test Case: Seeding performance
test "completes seeding within acceptable time limits" do
  # Benchmark seeding operation
  # Verify < 100ms for single user seeding
end

# Test Case: Bulk seeding performance
test "handles multiple users efficiently" do
  # Test seeding for 100+ users
  # Verify reasonable performance scaling
end
```

### 1.2 Integration with TransactionCategory Resource Tests

```elixir
# Test Case: Category resource compatibility
test "seeded categories work with existing TransactionCategory functions" do
  # Verify categories_for_user includes seeded categories
  # Test system_categories action returns seeded categories
end

# Test Case: Category hierarchy support
test "seeded categories support parent-child relationships" do
  # Test adding child categories to seeded parents
  # Verify relationship functionality works
end

# Test Case: Update protection
test "prevents modification of seeded system categories" do
  # Attempt to update seeded categories
  # Verify protection mechanisms work
end

# Test Case: Deletion protection
test "prevents deletion of seeded system categories" do
  # Attempt to delete seeded categories
  # Verify protection mechanisms work
end
```

## 2. Integration Testing Requirements

### 2.1 Database Seeds Integration Tests

**Test File**: `test/integration/category_seeding_integration_test.exs`

#### 2.1.1 Seeds.exs Integration

```elixir
# Test Case: Seeds script integration
test "category seeding integrates with existing seeds.exs workflow" do
  # Run full seeds.exs script
  # Verify users, accounts, symbols, transactions, and categories created
  # Check proper execution order and dependencies
end

# Test Case: Idempotent seeds execution
test "running seeds multiple times produces consistent results" do
  # Run seeds.exs multiple times
  # Verify stable state achieved
  # Check no duplicate data created
end

# Test Case: Seeds output validation
test "seeds script provides appropriate user feedback" do
  # Capture output from seeds script
  # Verify informative messages about category creation
  # Check success/skip indicators match actual state
end
```

#### 2.1.2 Migration Integration

```elixir
# Test Case: Data migration for existing users
test "migration seeds categories for existing users" do
  # Create users before running category migration
  # Run migration, verify all users get categories
  # Check migration idempotency
end

# Test Case: Migration rollback behavior
test "migration handles rollback scenarios properly" do
  # Test migration down functionality
  # Verify clean removal of seeded categories
  # Check constraint handling
end

# Test Case: Fresh database setup
test "fresh database gets complete category setup" do
  # Start with empty database
  # Run all migrations and seeds
  # Verify complete, consistent state
end
```

### 2.2 Multi-User Seeding Tests

```elixir
# Test Case: Concurrent user category seeding
test "handles concurrent seeding for multiple users" do
  # Create multiple users simultaneously
  # Run seeding operations concurrently
  # Verify all users get complete category sets
  # Check for race conditions or conflicts
end

# Test Case: Large-scale user seeding
test "efficiently seeds categories for many users" do
  # Create 1000+ users
  # Run bulk seeding operation
  # Verify performance and correctness at scale
end
```

### 2.3 Database Transaction Tests

```elixir
# Test Case: Transaction isolation
test "seeding operations maintain transaction isolation" do
  # Test seeding within database transactions
  # Verify ACID properties maintained
  # Check rollback behavior on failures
end

# Test Case: Deadlock prevention
test "prevents deadlocks during concurrent seeding" do
  # Run multiple seeding operations simultaneously
  # Verify no deadlock conditions occur
  # Check proper lock ordering
end
```

## 3. Performance Testing Requirements

### 3.1 Benchmarking Criteria

#### 3.1.1 Single User Seeding Performance

```elixir
# Performance Benchmark: Individual user seeding
# Target: < 50ms for 6 categories
# Measurement: Average over 100 iterations
# Variance: < 10ms standard deviation

test "single user category seeding performance" do
  user = create_test_user()
  
  {time_microseconds, _result} = :timer.tc(fn ->
    CategorySeeder.seed_categories_for_user(user.id)
  end)
  
  assert time_microseconds < 50_000 # 50ms
end
```

#### 3.1.2 Bulk Seeding Performance

```elixir
# Performance Benchmark: Bulk user seeding
# Target: < 5ms per user for 100+ users
# Target: Linear scaling characteristics
# Memory: Constant memory usage regardless of user count

test "bulk user category seeding performance" do
  users = create_test_users(100)
  
  {time_microseconds, _result} = :timer.tc(fn ->
    CategorySeeder.seed_categories_for_all_users()
  end)
  
  avg_time_per_user = time_microseconds / 100
  assert avg_time_per_user < 5_000 # 5ms per user
end
```

#### 3.1.3 Memory Usage Tests

```elixir
# Performance Test: Memory efficiency
test "category seeding maintains reasonable memory usage" do
  initial_memory = get_memory_usage()
  
  # Seed categories for 1000 users
  seed_categories_for_users(1000)
  
  final_memory = get_memory_usage()
  memory_increase = final_memory - initial_memory
  
  # Should not increase significantly with user count
  assert memory_increase < 10_000_000 # 10MB limit
end
```

### 3.2 Load Testing Scenarios

#### 3.2.1 Concurrent Access Testing

```elixir
# Load Test: Concurrent seeding operations
test "handles concurrent seeding requests efficiently" do
  # Spawn 50 concurrent seeding processes
  # Measure completion time and success rate
  # Verify database consistency after completion
end
```

#### 3.2.2 Database Connection Pool Testing

```elixir
# Load Test: Connection pool efficiency
test "efficiently uses database connection pool during seeding" do
  # Monitor connection pool usage during seeding
  # Verify no connection pool exhaustion
  # Check proper connection cleanup
end
```

## 4. User Acceptance Testing Requirements

### 4.1 End-User Scenarios

#### 4.1.1 New User Onboarding

**Scenario**: Fresh user account setup
```
Given: A new user has been created
When: The system runs initial setup (seeds or migration)
Then: The user should have all 6 investment categories available
And: Categories should be properly labeled and colored
And: Categories should be marked as system categories
And: User should be able to assign transactions to categories
```

#### 4.1.2 Existing User Category Enhancement

**Scenario**: Existing user receives new categories
```
Given: An existing user with some manual categories
When: Category seeding migration runs
Then: User should receive all missing system categories
And: Existing user categories should remain unchanged
And: No duplicate categories should be created
And: User can distinguish between system and user categories
```

#### 4.1.3 Category Usage Workflows

**Scenario**: Transaction categorization
```
Given: A user with seeded investment categories
When: User creates a new transaction
Then: System categories should be available for selection
And: Categories should display with correct colors
And: Category assignment should persist correctly
And: System categories should not be editable by user
```

### 4.2 Developer Experience Testing

#### 4.2.1 Development Environment Setup

**Scenario**: Developer database setup
```
Given: A developer setting up local environment
When: Running `mix run priv/repo/seeds.exs`
Then: Complete sample data should be created including categories
And: Categories should be properly associated with sample transactions
And: Setup should complete without errors
And: Multiple runs should not create duplicates
```

#### 4.2.2 Testing Environment Consistency

**Scenario**: Test suite reliability
```
Given: Automated test suite execution
When: Tests run with category seeding
Then: Tests should be deterministic and reproducible
And: Category setup should not affect test isolation
And: Performance should remain consistent across test runs
```

### 4.3 Production Deployment Testing

#### 4.3.1 Migration Safety

**Scenario**: Production database migration
```
Given: Production database with existing users
When: Category seeding migration is applied
Then: All existing users should receive categories
And: No data loss or corruption should occur
And: Migration should complete within reasonable time
And: Application should remain available during migration
```

#### 4.3.2 Rollback Safety

**Scenario**: Migration rollback
```
Given: Category seeding migration has been applied
When: Migration needs to be rolled back
Then: Seeded categories should be cleanly removed
And: User-created categories should remain intact
And: No orphaned data should remain
And: Application should function normally post-rollback
```

## 5. Manual Validation Scenarios

### 5.1 Database State Validation

#### 5.1.1 Post-Seeding Database Inspection

**Manual Steps**:
1. Connect to database after seeding
2. Query transaction_categories table
3. Verify category counts per user
4. Check color values match specification
5. Confirm is_system flags are set correctly
6. Validate user_id associations

**Expected Results**:
- Exactly 6 categories per user
- Colors: Growth (#10B981), Income (#3B82F6), Speculative (#F59E0B), Index (#8B5CF6), Cash (#6B7280), Bonds (#059669)
- All seeded categories have is_system = true
- All categories properly associated with correct users

#### 5.1.2 Idempotency Validation

**Manual Steps**:
1. Run seeding operation
2. Record category IDs and timestamps
3. Run seeding operation again
4. Compare category IDs and timestamps
5. Verify no new categories created

**Expected Results**:
- Identical category IDs after multiple runs
- No change in inserted_at timestamps
- Consistent database state

### 5.2 Integration Validation

#### 5.2.1 Seeds Script Validation

**Manual Steps**:
1. Reset database to clean state
2. Run `mix run priv/repo/seeds.exs`
3. Observe console output
4. Verify complete sample data creation
5. Test sample transactions have category associations

**Expected Results**:
- Clear console messages about category creation
- Sample transactions properly categorized
- No error messages or warnings
- Complete, usable sample dataset

#### 5.2.2 Migration Validation

**Manual Steps**:
1. Create database with users but no categories
2. Run category seeding migration
3. Verify all users receive categories
4. Test migration rollback
5. Confirm clean rollback state

**Expected Results**:
- All existing users get categories
- Migration completes successfully
- Rollback removes only seeded categories
- User data remains intact

### 5.3 UI Integration Validation

#### 5.3.1 Category Selection Interface

**Manual Steps**:
1. Navigate to transaction creation form
2. Check category dropdown/selection
3. Verify system categories are present
4. Confirm color coding is applied
5. Test category filtering by type

**Expected Results**:
- All seeded categories appear in selection
- Categories display with correct colors
- System vs user categories clearly distinguished
- Smooth user interaction experience

## 6. Automated Test Implementation Structure

### 6.1 Test File Organization

```
test/
├── ashfolio/
│   └── financial_management/
│       ├── category_seeder_test.exs                 # Unit tests
│       └── category_seeder_performance_test.exs     # Performance tests
├── integration/
│   ├── category_seeding_integration_test.exs        # Integration tests
│   ├── category_migration_test.exs                  # Migration tests
│   └── category_seeds_integration_test.exs          # Seeds integration
└── acceptance/
    └── category_seeding_acceptance_test.exs         # UAT scenarios
```

### 6.2 Test Data Management

#### 6.2.1 Test Fixtures

```elixir
# Standard test user fixture
def create_test_user(attrs \\ %{}) do
  default_attrs = %{
    name: "Test User",
    currency: "USD", 
    locale: "en-US"
  }
  
  attrs = Map.merge(default_attrs, attrs)
  {:ok, user} = Ash.create(User, attrs)
  user
end

# Multiple users fixture for bulk testing
def create_test_users(count) do
  1..count
  |> Enum.map(fn i ->
    create_test_user(%{name: "Test User #{i}"})
  end)
end
```

#### 6.2.2 Database Cleanup

```elixir
# Ensure clean state between tests
setup do
  # Clean category data
  Ash.read!(TransactionCategory) |> Enum.each(&Ash.destroy!/1)
  
  on_exit(fn ->
    # Additional cleanup if needed
    cleanup_test_data()
  end)
  
  :ok
end
```

### 6.3 Test Assertions and Helpers

#### 6.3.1 Category Validation Helpers

```elixir
def assert_complete_category_set(user_id) do
  {:ok, categories} = TransactionCategory.categories_for_user(user_id)
  
  expected_categories = [
    %{name: "Growth", color: "#10B981"},
    %{name: "Income", color: "#3B82F6"},
    %{name: "Speculative", color: "#F59E0B"},
    %{name: "Index", color: "#8B5CF6"},
    %{name: "Cash", color: "#6B7280"},
    %{name: "Bonds", color: "#059669"}
  ]
  
  assert length(categories) == 6
  
  Enum.each(expected_categories, fn expected ->
    assert Enum.any?(categories, fn cat ->
      cat.name == expected.name && 
      cat.color == expected.color &&
      cat.is_system == true &&
      cat.user_id == user_id
    end)
  end)
end

def assert_idempotent_seeding(user_id) do
  # Run seeding twice
  CategorySeeder.seed_categories_for_user(user_id)
  {:ok, first_run} = TransactionCategory.categories_for_user(user_id)
  
  CategorySeeder.seed_categories_for_user(user_id)  
  {:ok, second_run} = TransactionCategory.categories_for_user(user_id)
  
  # Should have identical results
  assert length(first_run) == length(second_run)
  assert Enum.sort_by(first_run, & &1.id) == Enum.sort_by(second_run, & &1.id)
end
```

## 7. Success Criteria and Acceptance Standards

### 7.1 Functional Requirements

- ✅ All investment categories seeded correctly for each user
- ✅ Idempotent seeding behavior (no duplicates on repeated runs)
- ✅ Integration with existing seeds.exs workflow
- ✅ Migration support for existing users
- ✅ Name-based conflict resolution
- ✅ Transaction-based seeding with rollback capability
- ✅ User-scoped category isolation

### 7.2 Performance Requirements

- ✅ Single user seeding: < 50ms
- ✅ Bulk seeding: < 5ms per user average
- ✅ Memory usage: Constant regardless of user count
- ✅ Database connection efficiency
- ✅ Concurrent access support

### 7.3 Quality Requirements

- ✅ 100% test coverage for CategorySeeder module
- ✅ All integration points tested
- ✅ Error handling scenarios covered
- ✅ Performance benchmarks established
- ✅ Manual validation procedures documented
- ✅ Production deployment safety verified

### 7.4 Documentation Requirements

- ✅ Code documentation with examples
- ✅ API documentation for public functions
- ✅ Migration documentation
- ✅ Troubleshooting guide
- ✅ Performance characteristics documented

## 8. Test Execution Timeline

### 8.1 Phase 1: Unit Testing (Days 1-2)
- CategorySeeder module unit tests
- Core functionality validation
- Error handling tests
- Performance baseline establishment

### 8.2 Phase 2: Integration Testing (Days 3-4)
- Seeds.exs integration
- Migration testing
- Database transaction testing
- Multi-user scenarios

### 8.3 Phase 3: Performance & Load Testing (Day 5)
- Performance benchmarking
- Load testing scenarios
- Memory usage validation
- Concurrent access testing

### 8.4 Phase 4: Manual Validation (Day 6)
- Database state validation
- UI integration testing
- End-to-end scenario validation
- Production deployment simulation

### 8.5 Phase 5: Final Acceptance (Day 7)
- Complete test suite execution
- Performance criteria validation
- Documentation review
- Deployment readiness assessment

## Conclusion

This comprehensive QA testing plan ensures that the Category Seeding functionality (Task 12) meets all requirements for robustness, performance, and integration with the existing Ashfolio system. The multi-layered testing approach covers unit, integration, performance, and acceptance testing scenarios while maintaining the high quality standards established in the existing codebase.

The plan emphasizes idempotent behavior, transaction safety, and seamless integration with existing workflows - critical requirements for a production-ready investment portfolio management application.