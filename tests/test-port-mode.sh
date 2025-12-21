#!/bin/bash
# test-port-mode.sh - Test suite for port mode installation
#
# Tests that 'make agentize AGENTIZE_MODE=port' correctly:
# - Creates .claude/ directory structure only
# - Copies all components (agents, commands, rules, skills, hooks)
# - Processes templates with project-specific values
# - Does NOT create project files (README.md, Makefile, etc.)
# - No references to agentize source directory remain in files

set -euo pipefail

# Get script directory and source test library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/test-utils.sh"
source "$SCRIPT_DIR/lib/assertions.sh"

# ============================================================================
# Test Configuration
# ============================================================================

TEST_NAME="port-mode"
TEST_PROJECT_NAME="TestPortProject"

# ============================================================================
# Test Setup
# ============================================================================

setup_test() {
    log_info "Setting up test environment for port mode..."
    TEST_DIR=$(create_test_dir "$TEST_NAME")
    log_info "Test directory: $TEST_DIR"
}

# ============================================================================
# Test Teardown
# ============================================================================

teardown_test() {
    log_info "Cleaning up test environment..."
    cleanup_test_dir "$TEST_DIR"
}

# Ensure cleanup runs even on failure
trap teardown_test EXIT

# ============================================================================
# Test Cases
# ============================================================================

test_installation_succeeds() {
    log_info "Test: Installation succeeds"

    if run_agentize "$TEST_DIR" "$TEST_PROJECT_NAME" "port"; then
        log_pass "Installation completed successfully"
        increment_pass
    else
        log_fail "Installation failed with exit code $?"
        increment_fail
        fail "Installation command failed"
    fi
}

test_claude_directory_structure() {
    log_info "Test: .claude/ directory structure created"

    assert_dir_exists "$TEST_DIR/.claude"
    assert_dir_exists "$TEST_DIR/.claude/agents"
    assert_dir_exists "$TEST_DIR/.claude/commands"
    assert_dir_exists "$TEST_DIR/.claude/rules"
    assert_dir_exists "$TEST_DIR/.claude/skills"
    assert_dir_exists "$TEST_DIR/.claude/hooks"

    log_pass "All .claude/ subdirectories exist"
    increment_pass
}

test_agents_copied() {
    log_info "Test: Agent files copied"

    # Count actual source agents to avoid hardcoded expectations
    local agentize_root="$(cd "$SCRIPT_DIR/.." && pwd)"
    local expected_count=$(find "$agentize_root/claude/agents" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    local agent_count=$(find "$TEST_DIR/.claude/agents" -type f -name "*.md" | wc -l | tr -d ' ')

    if [[ $agent_count -eq $expected_count ]] && [[ $agent_count -gt 0 ]]; then
        log_pass "Found $agent_count agent files (matches source)"
        increment_pass
    else
        log_fail "Expected $expected_count agents, found $agent_count"
        increment_fail
        fail "Incorrect number of agent files copied"
    fi
}

test_commands_copied() {
    log_info "Test: Command files copied"

    # Count actual source commands to avoid hardcoded expectations
    local agentize_root="$(cd "$SCRIPT_DIR/.." && pwd)"
    local expected_count=$(find "$agentize_root/claude/commands" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    local cmd_count=$(find "$TEST_DIR/.claude/commands" -type f -name "*.md" | wc -l | tr -d ' ')

    if [[ $cmd_count -eq $expected_count ]] && [[ $cmd_count -gt 0 ]]; then
        log_pass "Found $cmd_count command files (matches source)"
        increment_pass
    else
        log_fail "Expected $expected_count commands, found $cmd_count"
        increment_fail
        fail "Incorrect number of command files copied"
    fi
}

test_rules_copied() {
    log_info "Test: Rule files copied"

    # Count actual source rules to avoid hardcoded expectations
    local agentize_root="$(cd "$SCRIPT_DIR/.." && pwd)"
    local expected_count=$(find "$agentize_root/claude/rules" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    local rule_count=$(find "$TEST_DIR/.claude/rules" -type f -name "*.md" | wc -l | tr -d ' ')

    if [[ $rule_count -eq $expected_count ]] && [[ $rule_count -gt 0 ]]; then
        log_pass "Found $rule_count rule files (matches source)"
        increment_pass
    else
        log_fail "Expected $expected_count rules, found $rule_count"
        increment_fail
        fail "Incorrect number of rule files copied"
    fi
}

test_hooks_copied() {
    log_info "Test: Hook files copied"

    assert_dir_exists "$TEST_DIR/.claude/hooks"

    # Check for hook files
    local hook_count=$(find "$TEST_DIR/.claude/hooks" -type f | wc -l | tr -d ' ')

    if [[ $hook_count -ge 1 ]]; then
        log_pass "Found $hook_count hook files"
        increment_pass
    else
        log_fail "Expected at least 1 hook file, found $hook_count"
        increment_fail
        fail "No hook files found"
    fi
}

test_template_files_created() {
    log_info "Test: Template files created"

    assert_file_exists "$TEST_DIR/.claude/CLAUDE.md"
    assert_file_exists "$TEST_DIR/.claude/git-tags.md"
    assert_file_exists "$TEST_DIR/.claude/settings.json"
    assert_file_exists "$TEST_DIR/.claude/PROJECT_CONFIG.md"

    log_pass "All template files exist"
    increment_pass
}

test_template_variable_substitution() {
    log_info "Test: Template variable substitution"

    # Check that CLAUDE.md contains project name, not template variable
    assert_file_contains "$TEST_DIR/.claude/CLAUDE.md" "$TEST_PROJECT_NAME"

    # Check that settings.json is valid JSON and contains project name
    if python3 -m json.tool < "$TEST_DIR/.claude/settings.json" > /dev/null 2>&1; then
        log_pass "settings.json is valid JSON"
    else
        log_fail "settings.json is not valid JSON"
        increment_fail
        fail "Invalid JSON in settings.json"
    fi

    assert_file_contains "$TEST_DIR/.claude/settings.json" "$TEST_PROJECT_NAME"

    log_pass "Template variables substituted correctly"
    increment_pass
}

test_project_files_not_created() {
    log_info "Test: Project files NOT created (port mode)"

    # Port mode only installs .claude/ structure, not full project scaffolding
    # This is by design - port mode is for existing projects that already have
    # their own Makefile, README.md, etc.
    if [[ -f "$TEST_DIR/README.md" ]]; then
        log_fail "README.md should not exist in port mode"
        increment_fail
        fail "README.md created in port mode (should only be .claude/)"
    fi

    if [[ -f "$TEST_DIR/Makefile" ]]; then
        log_fail "Makefile should not exist in port mode"
        increment_fail
        fail "Makefile created in port mode (should only be .claude/)"
    fi

    if [[ -f "$TEST_DIR/setup.sh" ]]; then
        log_fail "setup.sh should not exist in port mode"
        increment_fail
        fail "setup.sh created in port mode (should only be .claude/)"
    fi

    if [[ -d "$TEST_DIR/docs" ]]; then
        log_fail "docs/ directory should not exist in port mode"
        increment_fail
        fail "docs/ created in port mode (should only be .claude/)"
    fi

    log_pass "Project files correctly NOT created (port mode only creates .claude/)"
    increment_pass
}

test_no_source_paths_in_files() {
    log_info "Test: No references to agentize source directory"

    # Get the actual agentize repo path
    local agentize_root="$(cd "$SCRIPT_DIR/.." && pwd)"

    # Search for references to agentize source path in installed files
    if grep -r "$agentize_root" "$TEST_DIR/.claude/" 2>/dev/null | grep -v "Binary file"; then
        log_fail "Found references to agentize source directory in installed files"
        increment_fail
        fail "Installed files contain hardcoded paths to agentize source"
    fi

    log_pass "No source directory paths found in installed files"
    increment_pass
}

test_no_template_variables_remain() {
    log_info "Test: No unsubstituted template variables"

    # Check for all template variable patterns used in install.sh
    # Patterns: ${PROJECT_NAME}, __PROJECT_NAME__, __NAME__, __NAME_UPPER__
    if grep -r '\${PROJECT_NAME}\|__PROJECT_NAME__\|__NAME_UPPER__\|__NAME__' "$TEST_DIR/.claude/" 2>/dev/null | grep -v "Binary file"; then
        log_fail "Found unsubstituted template variables"
        increment_fail
        fail "Template variables not fully substituted"
    fi

    log_pass "No unsubstituted template variables found"
    increment_pass
}

test_settings_json_valid() {
    log_info "Test: settings.json is valid JSON"

    if python3 -m json.tool < "$TEST_DIR/.claude/settings.json" > /dev/null 2>&1; then
        log_pass "settings.json is valid JSON"
        increment_pass
    else
        log_fail "settings.json is not valid JSON"
        increment_fail
        fail "Invalid JSON in settings.json"
    fi
}

# ============================================================================
# Main Test Execution
# ============================================================================

main() {
    echo ""
    echo "========================================"
    echo "Port Mode Installation Test Suite"
    echo "========================================"
    echo ""

    setup_test

    # Run tests in order
    test_installation_succeeds
    test_claude_directory_structure
    test_agents_copied
    test_commands_copied
    test_rules_copied
    test_hooks_copied
    test_template_files_created
    test_template_variable_substitution
    test_project_files_not_created
    test_no_source_paths_in_files
    test_no_template_variables_remain
    test_settings_json_valid

    # Print summary
    print_test_summary
}

main
