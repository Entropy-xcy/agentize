#!/usr/bin/env bash
# Test for agentize-init.sh zsh execution compatibility
# Verifies the script works when executed directly via zsh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
AGENTIZE_INIT="$PROJECT_ROOT/scripts/agentize-init.sh"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "=== agentize-init.sh ZSH Compatibility Test ==="

TEST_PROJECT=$(mktemp -d)
trap "rm -rf '$TEST_PROJECT'" EXIT

echo ""
echo "Test 1: Script executes correctly with zsh"
(
  cd "$TEST_PROJECT"
  AGENTIZE_PROJECT_PATH="$TEST_PROJECT/sdk" \
    AGENTIZE_PROJECT_NAME="zsh_test" \
    AGENTIZE_PROJECT_LANG="python" \
    /bin/zsh "$AGENTIZE_INIT" >/dev/null 2>&1

  if [ ! -d "$TEST_PROJECT/sdk" ]; then
    echo -e "${RED}FAIL: SDK directory was not created${NC}"
    exit 1
  fi

  if [ ! -f "$TEST_PROJECT/sdk/CLAUDE.md" ]; then
    echo -e "${RED}FAIL: CLAUDE.md was not created${NC}"
    exit 1
  fi

  echo -e "${GREEN}PASS: Script works with zsh${NC}"
)

echo ""
echo "Test 2: Script works with bash (regression test)"
(
  cd "$TEST_PROJECT"
  AGENTIZE_PROJECT_PATH="$TEST_PROJECT/sdk2" \
    AGENTIZE_PROJECT_NAME="bash_test" \
    AGENTIZE_PROJECT_LANG="python" \
    /bin/bash "$AGENTIZE_INIT" >/dev/null 2>&1

  if [ ! -d "$TEST_PROJECT/sdk2" ]; then
    echo -e "${RED}FAIL: SDK directory was not created${NC}"
    exit 1
  fi

  echo -e "${GREEN}PASS: Script works with bash${NC}"
)

echo ""
echo "Test 3: Script executes correctly with zsh and restricted PATH"
(
  cd "$TEST_PROJECT"
  env -i PATH=/bin:/usr/bin AGENTIZE_PROJECT_PATH="$TEST_PROJECT/sdk3" \
    AGENTIZE_PROJECT_NAME="zsh_restricted" \
    AGENTIZE_PROJECT_LANG="python" \
    /bin/zsh "$AGENTIZE_INIT" >/dev/null 2>&1

  if [ ! -d "$TEST_PROJECT/sdk3" ]; then
    echo -e "${RED}FAIL: SDK directory was not created${NC}"
    exit 1
  fi

  echo -e "${GREEN}PASS: Script works with zsh and restricted PATH${NC}"
)

echo ""
echo -e "${GREEN}=== All agentize-init.sh zsh tests passed ===${NC}"