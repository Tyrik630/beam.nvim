.PHONY: test test-verbose clean

# Run comprehensive test suite (default)
test:
	@nvim -l test/smoke_test.lua && \
	nvim -l test/text_object_operations.lua && \
	nvim -l test/comprehensive_operations.lua

# Run verbose test suite with detailed output
test-verbose:
	@./scripts/test-verbose

# Clean test artifacts
clean:
	@rm -rf /tmp/lazy-test /tmp/lazy.nvim /tmp/lazy-lock.json

# Help
help:
	@echo "Available targets:"
	@echo "  make test           - Run Plenary test suite"
	@echo "  make test-integration - Run integration tests"
	@echo "  make test-verbose   - Run existing test suite"
	@echo "  make clean         - Clean test artifacts"
