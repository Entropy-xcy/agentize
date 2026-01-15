#!/bin/bash

set -e

echo "=== Testing sandbox PATH configuration ==="

# Verify uv is in PATH
echo "Verifying uv..."
if ! command -v uv &>/dev/null; then
    echo "FAIL: uv not found in PATH"
    exit 1
fi
echo "PASS: uv found in PATH ($(uv --version))"

# Verify claude is in PATH
echo "Verifying claude..."
if ! command -v claude &>/dev/null; then
    echo "FAIL: claude not found in PATH"
    exit 1
fi
# Note: claude --version may require authentication, so we just check it exists
echo "PASS: claude found in PATH"

# Verify git is in PATH
echo "Verifying git..."
if ! command -v git &>/dev/null; then
    echo "FAIL: git not found in PATH"
    exit 1
fi
echo "PASS: git found in PATH ($(git --version))"

# Verify node is in PATH
echo "Verifying node..."
if ! command -v node &>/dev/null; then
    echo "FAIL: node not found in PATH"
    exit 1
fi
echo "PASS: node found in PATH ($(node --version))"

# Verify npm is in PATH
echo "Verifying npm..."
if ! command -v npm &>/dev/null; then
    echo "FAIL: npm not found in PATH"
    exit 1
fi
echo "PASS: npm found in PATH ($(npm --version))"

# Verify claude-code-router is in PATH
echo "Verifying claude-code-router..."
if ! command -v claude-code-router &>/dev/null; then
    echo "FAIL: claude-code-router not found in PATH"
    exit 1
fi
echo "PASS: claude-code-router found in PATH ($(claude-code-router --version))"

echo ""
echo "=== All PATH tests passed ==="