#!/bin/bash

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Create .tmp folder
TMP_DIR="$PROJECT_ROOT/.tmp/c-sdk-test"
echo "Creating temporary directory: $TMP_DIR"
rm -rf "$TMP_DIR"

# Use make agentize to create C SDK in .tmp
echo "Creating C SDK using make agentize..."
make -C "$PROJECT_ROOT" agentize \
    AGENTIZE_PROJECT_NAME="test-c-sdk" \
    AGENTIZE_PROJECT_PATH="$TMP_DIR" \
    AGENTIZE_PROJECT_LANG="c" \
    AGENTIZE_MODE="init"

echo "Building C SDK..."
make -C "$TMP_DIR" build

echo "Running C SDK tests..."
make -C "$TMP_DIR" test

echo "C SDK tests completed successfully!"

# Clean up
echo "Cleaning up..."
rm -rf "$TMP_DIR"

echo "Test script completed successfully!"
