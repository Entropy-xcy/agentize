# Design Draft: Unified Test Infrastructure with Project-Local Temp Directory

**Created**: 20251221-162147
**Status**: Draft - Brainstorming Complete

## Executive Summary

Migrate test infrastructure from system /tmp to project-local .tmp/ directory to resolve limited /tmp access issues. Add unified test targets and common Makefile variables while maintaining existing naming conventions.

## Problem Statement

The current test infrastructure uses system /tmp directory (`/tmp/agentize-test-*`) which causes issues in environments with limited /tmp access. The user has full access to project-local directories but restricted access to /tmp, preventing tests from running properly.

Additionally, the test infrastructure lacks:
- Common Makefile variables shared across language-specific tests
- Unified test target that runs all SDK tests
- Consistent cleanup mechanism for project-local temp directories

## Design Decision Record

### Key Decisions Made

| Decision | Choice | Rationale | Alternatives Considered |
|----------|--------|-----------|------------------------|
| Temp directory location | `.tmp/` in project root | User has full access to project directories, limited /tmp access | `/tmp` (rejected: access issues), `build/.tmp` (rejected: coupling with build dir) |
| Test target naming | Keep existing `test-python`, `test-cxx`, `test-c` | Consistency with existing template Makefiles | `test-py-sdk`, `test-cxx-sdk` (rejected: inconsistent with templates) |
| Common variables location | `tests/test.inc` Makefile include | Centralize common Make variables, follow Make conventions | Shell script in tests/lib/ (rejected: wrong purpose), inline in each template (rejected: duplication) |
| Unified test target name | `test` | Standard Make convention, already expected interface | `test-all`, `test-sdk` (rejected: verbose) |

### Critical Issues Resolved

1. **Limited /tmp access**: Using project-local .tmp/ eliminates permission issues
2. **Naming convention conflict**: Resolved by maintaining existing test-python, test-cxx, test-c pattern
3. **test.inc purpose confusion**: Clarified as Makefile include (not shell script duplicate)

### Acknowledged Tradeoffs

1. **Project-local temp cleanup**: Tests must clean up .tmp/ on failure (acceptable: better isolation)
2. **Git ignore pattern**: Must ensure .tmp/ is ignored (acceptable: one-line .gitignore addition)

## Design Specification

### Overview

Migrate test infrastructure to use project-local `.tmp/` directory instead of system `/tmp/`. Add Makefile infrastructure for unified test execution while maintaining existing language-specific test target naming.

### Key Components

1. **tests/test.inc** - Makefile include with common variables:
   - `TEST_TMP_DIR` - Base temp directory path (.tmp/)
   - `BUILD_DIR` - Common build directory variable (for consistency)
   - Common cleanup patterns

2. **Modified tests/lib/test-utils.sh** - Update temp directory creation:
   - Change `mktemp -d "/tmp/agentize-test-${name}-XXXXXX"` to `.tmp/` based pattern
   - Update documentation/comments

3. **Modified Makefile** - Add unified test infrastructure:
   - Add `test` target that calls `test-python test-cxx test-c`
   - Update `clean` target to remove `.tmp/` instead of `/tmp/agentize-test-*`
   - Optionally include `tests/test.inc` for SDK development testing

4. **.gitignore update** - Ignore project-local temp:
   - Add `.tmp/` pattern

### Interfaces

#### tests/test.inc (New File)

```makefile
# Common test infrastructure variables
# Include this in Makefiles that need test configuration

# Test temporary directory (project-local)
TEST_TMP_DIR := .tmp

# Build directory (for consistency across language templates)
BUILD_DIR := build

# Ensure test temp directory exists
$(TEST_TMP_DIR):
	@mkdir -p $(TEST_TMP_DIR)

# Common test cleanup patterns
.PHONY: clean-test
clean-test:
	@echo "Cleaning test artifacts..."
	@rm -rf $(TEST_TMP_DIR)
```

#### tests/lib/test-utils.sh Modifications

```bash
# BEFORE:
create_test_dir() {
    local name_suffix="$1"
    local temp_dir
    temp_dir=$(mktemp -d "/tmp/agentize-test-${name_suffix}-XXXXXX")
    echo "$temp_dir"
}

# AFTER:
create_test_dir() {
    local name_suffix="$1"
    local temp_dir

    # Create .tmp/ if it doesn't exist
    mkdir -p .tmp

    # Create unique temporary directory in project-local .tmp/
    temp_dir=$(mktemp -d ".tmp/agentize-test-${name_suffix}-XXXXXX")

    echo "$temp_dir"
}
```

#### Makefile Additions

```makefile
# Add after existing targets:

# Include test infrastructure (optional, for SDK development)
-include tests/test.inc

# Unified test target
.PHONY: test
test: test-python test-cxx test-c
	@echo "All SDK tests complete"

# Individual test targets (call language-specific test scripts)
.PHONY: test-python test-cxx test-c
test-python:
	@echo "Running Python SDK tests..."
	@# TODO: Add test script invocation

test-cxx:
	@echo "Running C++ SDK tests..."
	@# TODO: Add test script invocation

test-c:
	@echo "Running C SDK tests..."
	@# TODO: Add test script invocation

# Update clean target
.PHONY: clean
clean:
	@echo "Cleaning temporary artifacts..."
	@rm -rf .tmp/
	@echo "✓ Clean complete"
```

#### .gitignore Addition

```gitignore
# Test temporary files
.tmp/
```

### Constraints

1. **Backward compatibility**: Existing test scripts must continue to work
2. **Naming consistency**: Must use test-python, test-cxx, test-c (not test-py-sdk, etc.)
3. **Shell script separation**: test.inc is Makefile-only, tests/lib/ remains for shell functions
4. **Relative paths**: .tmp/ must work from project root (tests run from root)

### Implementation Details

#### File Modifications Required

| File | Change Type | Description |
|------|-------------|-------------|
| `tests/test.inc` | CREATE | New Makefile include with common variables |
| `tests/lib/test-utils.sh` | MODIFY | Change mktemp path from /tmp to .tmp/ |
| `Makefile` | MODIFY | Add test target, update clean, include test.inc |
| `.gitignore` | MODIFY | Add .tmp/ pattern |

#### Migration Strategy

1. **Phase 1: Infrastructure** (non-breaking)
   - Create tests/test.inc
   - Add .tmp/ to .gitignore
   - Add test target to Makefile (no-op initially)

2. **Phase 2: Migration** (breaking change)
   - Modify test-utils.sh to use .tmp/
   - Update Makefile clean target
   - Test all existing tests

3. **Phase 3: Populate** (enhancement)
   - Implement test-python, test-cxx, test-c targets
   - Add actual test scripts

#### Rollback Plan

If issues occur, simple rollback:
```bash
git checkout tests/lib/test-utils.sh Makefile .gitignore
rm tests/test.inc
```

## Research References

### Internal References
- `tests/lib/test-utils.sh` - Current temp directory creation logic
- `tests/lib/assertions.sh` - Test assertion library (unchanged)
- `Makefile` - Current clean target using /tmp
- `templates/*/Makefile.template` - Language-specific test target naming

### External References
- Make manual: Include directive for modular Makefiles
- mktemp manual: Creating temp directories with custom paths
- Git ignore patterns: Directory exclusion syntax

## Open Questions

1. **Test script organization**: Where should actual test scripts live?
   - Option A: `tests/test-python.sh`, `tests/test-cxx.sh`, etc.
   - Option B: `tests/sdk/python/test.sh`, etc.
   - **Deferred**: Decide during implementation based on test complexity

2. **test.inc variables scope**: Should BUILD_DIR be in test.inc or remain in templates?
   - Current: Each template defines BUILD_DIR independently
   - Proposed: Centralize in test.inc
   - **Deferred**: Start with TEST_TMP_DIR only, expand as needed

3. **Parallel test execution**: Should unified test target run tests in parallel?
   - Serial: `test: test-python test-cxx test-c`
   - Parallel: Use Make's `-j` flag
   - **Deferred**: Start with serial, optimize later if needed

## Next Steps

This design is ready for:

1. **Implementation issue creation** - Create GitHub issue with this specification
2. **Development via /issue2impl** - Implement the changes
3. **Testing** - Verify tests work with .tmp/ instead of /tmp

### Estimated Effort

- Infrastructure setup (Phase 1): 1 hour
- Migration (Phase 2): 2 hours
- Testing and validation: 1 hour
- **Total**: 4 hours

### Success Criteria

- [ ] `.tmp/` directory is created automatically
- [ ] All existing tests pass using .tmp/ instead of /tmp
- [ ] `make test` runs all SDK tests
- [ ] `make clean` removes .tmp/ directory
- [ ] .tmp/ is git-ignored
- [ ] No /tmp references remain in test infrastructure

### Implementation Priority

**HIGH** - Blocks users in restricted environments from running tests

---

*This draft was created through a three-stage brainstorming process: creative proposal, critical review, and independent synthesis with user feedback.*
