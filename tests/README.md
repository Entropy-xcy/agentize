# Agentize Test Suite

This directory contains integration tests for the Agentize SDK installation and configuration system.

## Directory Structure

```
tests/
├── README.md              # This file
├── test.inc              # Common Makefile variables for tests
├── lib/                  # Test utilities and assertion library
│   ├── test-utils.sh     # Setup/teardown helpers
│   └── assertions.sh     # Assertion functions
├── test-init-mode.sh     # Init mode tests
└── test-port-mode.sh     # Port mode tests
```

## Quick Start

### Run All Tests

```bash
make test
```

### Run Individual Test

```bash
./tests/test-init-mode.sh
./tests/test-port-mode.sh
```

### Clean Test Artifacts

```bash
make clean
```

## Test Utilities Library

### tests/lib/test-utils.sh

Provides setup/teardown utilities and helper functions.

#### create_test_dir(name_suffix)

Creates unique temporary directory for test isolation.

```bash
source "$(dirname "$0")/lib/test-utils.sh"
test_dir=$(create_test_dir "example")
# Returns: .tmp/agentize-test-example-a1b2c3
```

**Returns:** Absolute path to created temporary directory

**Note:** Caller is responsible for cleanup via `cleanup_test_dir()` or use `make clean`

#### cleanup_test_dir(path)

Removes temporary directory. Safe to call multiple times (idempotent).

```bash
cleanup_test_dir "$test_dir"
```

#### run_agentize(target_dir, project_name, mode, [lang], [impl_dir])

Executes `make agentize` with given parameters.

```bash
run_agentize "$test_dir" "TestProject" "init"
run_agentize "$test_dir" "MyPyLib" "init" "python" "lib"
```

**Parameters:**
- `target_dir` - Target directory (AGENTIZE_MASTER_PROJ)
- `project_name` - Project name (AGENTIZE_PROJ_NAME)
- `mode` - Installation mode: 'init', 'port', or 'update'
- `lang` - (optional) Comma-separated language list
- `impl_dir` - (optional) Implementation directory name

**Returns:** Exit code from make command (0 = success)

#### Logging Functions

```bash
log_pass "Test passed"      # Green [PASS] message
log_fail "Test failed"      # Red [FAIL] message
log_info "Information"      # Blue [INFO] message
log_warning "Warning"       # Yellow [WARN] message
```

### tests/lib/assertions.sh

Provides assertion functions for test validation. All assertions exit with code 1 on failure.

#### assert_file_exists(path)

Verifies file exists at path.

```bash
source "$(dirname "$0")/lib/assertions.sh"
assert_file_exists "$test_dir/.claude/CLAUDE.md"
```

#### assert_dir_exists(path)

Verifies directory exists at path.

```bash
assert_dir_exists "$test_dir/.claude/agents"
```

#### assert_file_contains(path, pattern)

Verifies file contains pattern (grep regex).

```bash
assert_file_contains "$test_dir/Makefile" "build-python"
```

#### assert_command_succeeds(command)

Runs command and verifies exit code 0.

```bash
assert_command_succeeds "make -C $test_dir build"
```

#### fail(message)

Explicitly fails test with custom message.

```bash
if [[ $count -ne 13 ]]; then
    fail "Expected 13 files but found $count"
fi
```

## Writing New Tests

### Basic Test Template

```bash
#!/bin/bash
set -euo pipefail

# Source test utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/test-utils.sh"
source "$SCRIPT_DIR/lib/assertions.sh"

# Test setup
log_info "Starting test: My Feature"
test_dir=$(create_test_dir "my-feature")

# Test execution
run_agentize "$test_dir" "TestProject" "init"
assert_dir_exists "$test_dir/.claude"
assert_file_contains "$test_dir/Makefile" "build:"

# Test cleanup
cleanup_test_dir "$test_dir"
log_pass "Test completed successfully"
```

### Test Isolation Pattern

Use trap for automatic cleanup:

```bash
test_dir=$(create_test_dir "feature")
trap 'cleanup_test_dir "$test_dir"' EXIT ERR

# Test operations...
# Cleanup happens automatically on exit or error
```

## Common Test Patterns

### Test Installation Mode

```bash
test_dir=$(create_test_dir "init")
run_agentize "$test_dir" "TestProject" "init"
assert_dir_exists "$test_dir/.claude"
assert_file_exists "$test_dir/Makefile"
cleanup_test_dir "$test_dir"
```

### Test Generated Files

```bash
assert_file_exists "$test_dir/.claude/CLAUDE.md"
assert_file_contains "$test_dir/.claude/CLAUDE.md" "TestProject"
```

### Test Language-Specific Generation

```bash
run_agentize "$test_dir" "PyLib" "init" "python" "lib"
assert_file_exists "$test_dir/pyproject.toml"
assert_file_contains "$test_dir/Makefile" "test-python"
```

## Integration with CI/CD

Tests are designed to run in CI environments:

```yaml
# Example GitHub Actions workflow
- name: Run Agentize tests
  run: make test
```

All tests use project-local `.tmp/` directory (not `/tmp/`) to avoid permission issues in restricted environments.

## Troubleshooting

### Tests fail with permission errors

Ensure `.tmp/` directory is writable:
```bash
rm -rf .tmp/
mkdir .tmp/
```

### Stale test directories

Clean up manually:
```bash
make clean
```

Or remove specific directories:
```bash
rm -rf .tmp/agentize-test-*
```

### Test hangs or doesn't clean up

Check for background processes:
```bash
ps aux | grep agentize
```

Manually cleanup:
```bash
killall make  # If needed
rm -rf .tmp/
```

## Contributing

When adding new tests:

1. Follow the basic test template structure
2. Use test utilities for consistency
3. Ensure proper cleanup (use trap if needed)
4. Add meaningful assertions
5. Test in isolation (unique test_dir per test)

## See Also

- [Test Infrastructure Design](../docs/architecture/test-infrastructure.md) - Comprehensive design documentation
- [SDK Installation](../README.md#installation-modes) - Installation mode documentation
