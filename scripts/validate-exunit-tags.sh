#!/bin/bash

# Validation script for ExUnit tagging strategy
# This script tests if the modular testing commands work correctly

echo "🧪 Validating ExUnit Tagging Strategy..."
echo

cd /Users/matthewstaff/Projects/github.com/mdstaff/ashfolio

# Test 1: Check Ash Resource tests
echo "1. Testing Ash Resource tests..."
result=$(mix test --only ash_resources 2>&1)
if echo "$result" | grep -q "tests,"; then
    count=$(echo "$result" | grep -oE "[0-9]+ tests," | head -1 | cut -d' ' -f1)
    echo "✅ Found $count Ash Resource tests"
else
    echo "❌ No Ash Resource tests found"
fi
echo

# Test 2: Check LiveView tests 
echo "2. Testing LiveView tests..."
result=$(mix test --only liveview 2>&1)
if echo "$result" | grep -q "tests,"; then
    count=$(echo "$result" | grep -oE "[0-9]+ tests," | head -1 | cut -d' ' -f1)
    echo "✅ Found $count LiveView tests"
else
    echo "❌ No LiveView tests found"
fi
echo

# Test 3: Check Calculation tests
echo "3. Testing Calculation tests..."
result=$(mix test --only calculations 2>&1)
if echo "$result" | grep -q "tests,"; then
    count=$(echo "$result" | grep -oE "[0-9]+ tests," | head -1 | cut -d' ' -f1)
    echo "✅ Found $count Calculation tests"
else
    echo "❌ No Calculation tests found"
fi
echo

# Test 4: Check Market Data tests
echo "4. Testing Market Data tests..."
result=$(mix test --only market_data 2>&1)
if echo "$result" | grep -q "tests,"; then
    count=$(echo "$result" | grep -oE "[0-9]+ tests," | head -1 | cut -d' ' -f1)
    echo "✅ Found $count Market Data tests"
else
    echo "❌ No Market Data tests found"
fi
echo

# Test 5: Check Integration tests
echo "5. Testing Integration tests..."
result=$(mix test --only integration 2>&1)
if echo "$result" | grep -q "tests,"; then
    count=$(echo "$result" | grep -oE "[0-9]+ tests," | head -1 | cut -d' ' -f1)
    echo "✅ Found $count Integration tests"
else
    echo "❌ No Integration tests found"
fi
echo

# Test 6: Check Fast tests
echo "6. Testing Fast tests..."
result=$(mix test --only fast 2>&1)
if echo "$result" | grep -q "tests,"; then
    count=$(echo "$result" | grep -oE "[0-9]+ tests," | head -1 | cut -d' ' -f1)
    echo "✅ Found $count Fast tests"
else
    echo "❌ No Fast tests found"
fi
echo

echo "🏁 Validation complete!"