.PHONY: test test-verbose format clean install-hooks

# Run comprehensive test suite (default)
test:
	@nvim -l test/smoke_test.lua && \
	nvim -l test/text_object_operations.lua && \
	nvim -l test/comprehensive_operations.lua

# Run verbose test suite with detailed output
test-verbose:
	@./scripts/test-verbose

# Format Lua code with stylua
format:
	@stylua .

# Install git hooks
install-hooks:
	@git config core.hooksPath .githooks
	@echo "Git hooks installed. Pre-commit hook will format code with stylua."

# Clean test artifacts
clean:
	@rm -rf /tmp/lazy-test /tmp/lazy.nvim /tmp/lazy-lock.json

# Help
help:
	@echo "Available targets:"
	@echo "  make test          - Run comprehensive test suite"
	@echo "  make test-verbose  - Run tests with detailed output"
	@echo "  make format        - Format code with stylua"
	@echo "  make install-hooks - Install git pre-commit hooks"
	@echo "  make clean         - Clean test artifacts"
