.PHONY: test test-verbose format clean install-hooks

# Run comprehensive test suite (default)
test:
	@./test/run_all_tests.sh

# Run verbose test suite with detailed output  
test-verbose:
	@for test in test/*.lua; do \
		case "$$test" in \
			*_spec.lua|*run_tests.lua) continue ;; \
			*) echo "Running $$test..."; \
			   nvim -l "$$test" || exit 1; \
			   echo "" ;; \
		esac \
	done

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
