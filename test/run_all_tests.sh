#!/bin/bash

# Clean test runner for beam.nvim

echo "============================================================="
echo "BEAM.NVIM TEST SUITE"
echo "============================================================="
echo ""

PASSED=0
FAILED=0
FAILED_TESTS=""

# Auto-discover all test files (excluding debug and temporary files)
TEST_FILES=()
while IFS= read -r -d '' file; do
  basename_file=$(basename "$file")
  # Skip debug files, temporary files, and non-test files
  if [[ ! "$basename_file" =~ ^debug_ ]] && \
     [[ ! "$basename_file" =~ _debug\.lua$ ]] && \
     [[ ! "$basename_file" =~ ^temp_ ]] && \
     [[ ! "$basename_file" =~ \.tmp$ ]] && \
     [[ ! "$basename_file" == "minimal_init.lua" ]] && \
     [[ "$basename_file" =~ \.lua$ ]]; then
    TEST_FILES+=("$basename_file")
  fi
done < <(find test/ -name "*.lua" -type f -print0 | sort -z)

echo "Discovered ${#TEST_FILES[@]} test files:"
printf "  - %s\n" "${TEST_FILES[@]}"
echo ""

for test_file in "${TEST_FILES[@]}"; do
  if [ -f "test/$test_file" ]; then
    test_name="${test_file%.lua}"
    test_name="${test_name//_/ }"
    
    # Run test and capture output
    # Use minimal_init for spec files
    if [[ "$test_file" == *_spec.lua ]]; then
      output=$(nvim --headless -u test/minimal_init.lua -c "luafile test/$test_file" -c "qa!" 2>&1)
    else
      output=$(nvim -l "test/$test_file" 2>&1)
    fi
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