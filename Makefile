.PHONY: test test-verbose test-old format clean install-hooks

# Run tests with Plenary (default)
test:
	@echo "Running tests with Plenary..."
	@nvim --headless -l test/run_tests.lua

# Run tests with output visible (not headless)
test-verbose:
	@echo "Running tests with Plenary (verbose)..."
	@nvim -l test/run_tests.lua

# Run old test suite (for remaining non-migrated tests)
test-old:
	@./test/run_all_tests.sh

# Format Lua code with stylua
format:
	@stylua .

# Install git hooks
install-hooks:
	@git config core.hooksPath .githooks
	@echo "Git hooks installed. Pre-commit hook will:"
	@echo "  - Format code with stylua"
	@echo "  - Remind to update docs when README changes"
	@echo "  - Run tests"

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
