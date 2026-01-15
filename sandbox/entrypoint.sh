#!/bin/bash
# Entrypoint script for agentize container
#
# Supports two modes:
# - Default: Runs 'claude' with plugin support
# - With --ccr flag: Runs 'ccr code' with plugin support

# Parse arguments to check for --ccr flag
HAS_CCR=0
ARGS=()

for arg in "$@"; do
    if [ "$arg" = "--ccr" ]; then
        HAS_CCR=1
    else
        ARGS+=("$arg")
    fi
done

if [ $HAS_CCR -eq 1 ]; then
    # Remove --ccr from args and run ccr
    exec ccr code --dangerously-skip-permissions --plugin-dir .claude-plugin "${ARGS[@]}"
else
    exec claude --dangerously-skip-permissions --plugin-dir .claude-plugin "$@"
fi