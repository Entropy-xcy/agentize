# Test Infrastructure Design

## Overview

The Agentize test infrastructure provides a unified, isolated testing environment with project-local temporary directories and common test utilities.

### Motivation

Previously, tests used system `/tmp` directory which caused issues:
- Limited `/tmp` access in restricted environments
- Security concerns with world-writable shared namespace
- Cleanup complexity across different system configurations

The new design uses project-local `.tmp/` directory for:
- Full access control within project boundaries
- Better isolation between test runs
- Simplified cleanup (just `rm -rf .tmp/`)

### Key Components

1. **tests/test.inc** - Makefile include with common test variables
2. **tests/lib/test-utils.sh** - Test setup/teardown utilities
3. **tests/lib/assertions.sh** - Test assertion library
4. **Unified test targets** - Language-specific test-* targets

## Architecture

### Directory Structure

```
project-root/
├── .tmp/                          # Project-local temp directory (git-ignored)
│   └── agentize-test-*-XXXXXX/    # Isolated test directories
├── tests/
│   ├── test.inc                   # Common Makefile variables
│   ├── lib/
│   │   ├── test-utils.sh         # Test utilities
│   │   └── assertions.sh         # Assertion library
│   ├── test-init-mode.sh         # Integration tests
│   └── test-port-mode.sh
└── Makefile                       # Includes test infrastructure
```

### Temporary Directory Management

Tests create isolated temporary directories under `.tmp/`:
- Each test gets unique directory: `.tmp/agentize-test-<name>-<random>/`
- Automatic cleanup via `cleanup_test_dir()` or `make clean`
- No system `/tmp` access required

### Unified Test Targets

Language-specific test targets are coordinated by unified `make test`:

```makefile
test: test-python test-cxx test-c
```

Each language template defines its own `test-<lang>` target.

## Test Utilities Reference

### tests/lib/test-utils.sh

**create_test_dir(name_suffix)**
- Creates unique temporary directory under `.tmp/`
- Returns absolute path
- Example: `test_dir=$(create_test_dir "init")`

**cleanup_test_dir(path)**
- Removes temporary directory
- Idempotent (safe to call multiple times)
- Example: `cleanup_test_dir "$test_dir"`

**run_agentize(target_dir, project_name, mode, [lang], [impl_dir])**
- Executes `make agentize` with parameters
- Returns make exit code
- Example: `run_agentize "$test_dir" "TestProject" "init"`

**Logging functions:**
- `log_pass(message)` - Green [PASS] output
- `log_fail(message)` - Red [FAIL] output
- `log_info(message)` - Blue [INFO] output
- `log_warning(message)` - Yellow [WARN] output

### tests/lib/assertions.sh

**assert_file_exists(path)**
- Verifies file exists
- Exits with code 1 on failure

**assert_dir_exists(path)**
- Verifies directory exists
- Exits with code 1 on failure

**assert_file_contains(path, pattern)**
- Verifies file contains grep pattern
- Exits with code 1 on failure

**assert_command_succeeds(command)**
- Runs command, verifies exit code 0
- Exits with code 1 on failure

**fail(message)**
- Explicitly fails test with custom message
- Always exits with code 1

## Common Variables (tests/test.inc)

The `tests/test.inc` Makefile include defines common test variables:

```makefile
# Test temporary directory (project-local)
TEST_TMP_DIR := .tmp

# Build directory (for consistency across language templates)
BUILD_DIR := build

# Common test cleanup
.PHONY: clean-test
clean-test:
	@rm -rf $(TEST_TMP_DIR)
```

### When to Include test.inc

- **SDK development**: Include in Agentize SDK Makefile for testing the SDK itself
- **Generated projects**: Optionally include via `-include` for SDK-style testing
- **Custom projects**: Include if you want common test variables

Usage:
```makefile
-include tests/test.inc  # Optional, won't error if missing
```

## Usage Guide

### Writing New Tests

1. **Source test utilities:**
   ```bash
   #!/bin/bash
   source "$(dirname "$0")/lib/test-utils.sh"
   source "$(dirname "$0")/lib/assertions.sh"
   ```

2. **Create isolated test directory:**
   ```bash
   test_dir=$(create_test_dir "my-test")
   ```

3. **Run test operations:**
   ```bash
   run_agentize "$test_dir" "TestProject" "init"
   assert_dir_exists "$test_dir/.claude"
   assert_file_contains "$test_dir/Makefile" "build:"
   ```

4. **Cleanup:**
   ```bash
   cleanup_test_dir "$test_dir"
   ```

### Test Isolation Patterns

**Pattern 1: Full cleanup after each test**
```bash
test_feature() {
    local test_dir=$(create_test_dir "feature")
    # ... test operations ...
    cleanup_test_dir "$test_dir"
}
```

**Pattern 2: Cleanup on error**
```bash
trap 'cleanup_test_dir "$test_dir"' ERR EXIT
test_dir=$(create_test_dir "feature")
# ... test operations ...
```

### Running Tests

```bash
# Run all tests
make test

# Run language-specific tests
make test-python
make test-cxx
make test-c

# Run specific test script
./tests/test-init-mode.sh

# Clean test artifacts
make clean
```

## Integration with Generated Projects

### Template Integration

Language templates include test targets that use test infrastructure:

**Python (templates/python/Makefile.template):**
```makefile
.PHONY: test-python
test-python:
	@pytest tests/ -v
```

**C++ (templates/cxx/Makefile.template):**
```makefile
BUILD_DIR := build

.PHONY: test-cxx
test-cxx:
	@cd $(BUILD_DIR) && ctest --output-on-failure
```

### Generated Project Usage

Projects generated by Agentize can optionally include test.inc:

```makefile
-include tests/test.inc

.PHONY: test
test: test-python test-cxx
```

## Migration from /tmp to .tmp/

### Rationale

**Security:** System `/tmp` is world-writable shared namespace ([systemd.io guide](https://systemd.io/TEMPORARY_DIRECTORIES/))

**Isolation:** Project-local `.tmp/` prevents cross-project contamination

**Access Control:** No special permissions needed for project directories

**Cleanup:** Simple `rm -rf .tmp/` vs. hunting for `/tmp/agentize-test-*` files

### Updating Existing Tests

Change mktemp path from `/tmp` to `.tmp/`:

**Before:**
```bash
temp_dir=$(mktemp -d "/tmp/agentize-test-${name}-XXXXXX")
```

**After:**
```bash
mkdir -p .tmp
temp_dir=$(mktemp -d ".tmp/agentize-test-${name}-XXXXXX")
```

Or use the utility:
```bash
source tests/lib/test-utils.sh
temp_dir=$(create_test_dir "test-name")
```

## Troubleshooting

### Issue: .tmp/ not being cleaned up

**Cause:** Test script exited before cleanup_test_dir() called

**Solution:**
1. Use `make clean` to manually remove `.tmp/`
2. Add trap for automatic cleanup:
   ```bash
   trap 'cleanup_test_dir "$test_dir"' EXIT
   ```

### Issue: Permission denied in .tmp/

**Cause:** Stale directories from previous runs

**Solution:**
```bash
rm -rf .tmp/
mkdir .tmp/
```

### Issue: Tests fail with "No such file or directory: .tmp/"

**Cause:** .tmp/ directory not created

**Solution:** Tests should create .tmp/ if it doesn't exist:
```bash
mkdir -p .tmp
```

Or use `create_test_dir()` which handles this automatically.

## References

### External Best Practices

- [Using /tmp/ and /var/tmp/ Safely](https://systemd.io/TEMPORARY_DIRECTORIES/) - systemd temp directory security guide
- [Pytest tmp_path Best Practices](https://pytest-with-eric.com/pytest-best-practices/pytest-tmp-path/) - Python test isolation patterns
- [Advanced Makefiles for Infrastructure Projects](https://medium.com/@eren.c.uysal/advanced-makefiles-for-infrastructure-projects-499311ee3b26) - Makefile variable and include patterns
- [Makefiles Best Practices](https://danyspin97.org/blog/makefiles-best-practices/) - .PHONY targets, modular design
- [Isolating Tests with Temporary Directories](https://symflower.com/en/company/blog/2023/intellij-temporary-project-directories/) - Copy-based testing with temp directories

### Internal References

- Draft design: `docs/draft/test-infra-tmp-migration-20251221-162147.md`
- Test utilities: `tests/lib/test-utils.sh`
- Test assertions: `tests/lib/assertions.sh`
- Makefile variables: `tests/test.inc`
