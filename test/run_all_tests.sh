#!/bin/bash

# Clean test runner for beam.nvim

echo "============================================================="
echo "BEAM.NVIM TEST SUITE"
echo "============================================================="
echo ""

PASSED=0
FAILED=0
FAILED_TESTS=""

# List of test files to run (excluding debug and temporary files)
TEST_FILES=(
  "smoke_test.lua"
  "comprehensive_operations.lua"
  "text_object_operations.lua"
  "cross_buffer_test.lua"
  "custom_text_objects.lua"
  "motion_operations_test.lua"
  "text_object_discovery_test.lua"
  "search_transform_test.lua"
)

for test_file in "${TEST_FILES[@]}"; do
  if [ -f "test/$test_file" ]; then
    test_name="${test_file%.lua}"
    test_name="${test_name//_/ }"
    
    # Run test and capture output
    output=$(nvim -l "test/$test_file" 2>&1)
    exit_code=$?
    
    # Check if test passed
    if [ $exit_code -eq 0 ] && echo "$output" | grep -q "✓ All.*passed\|All.*tests passed\|✓ All.*work correctly"; then
      # Extract test count if available
      test_count=$(echo "$output" | grep -oE "[0-9]+/[0-9]+ tests passed" | head -1)
      if [ -z "$test_count" ]; then
        test_count="PASSED"
      fi
      printf "  ✓ %-40s %s\n" "$test_name" "$test_count"
      ((PASSED++))
    else
      printf "  ✗ %-40s FAILED\n" "$test_name"
      ((FAILED++))
      FAILED_TESTS="$FAILED_TESTS\n  - $test_name"
    fi
  fi
done

echo ""
echo "============================================================="
echo "RESULTS: $PASSED passed, $FAILED failed"
echo "============================================================="

if [ $FAILED -gt 0 ]; then
  echo -e "\nFAILED TESTS:$FAILED_TESTS"
  exit 1
else
  echo -e "\n✓ All tests passed!"
  exit 0
fi