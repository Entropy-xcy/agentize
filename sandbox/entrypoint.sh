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
    # Create logs directory for CCR (running as non-root user with sudo)
    /usr/bin/sudo mkdir -p /home/agentizer/.claude-code-router/logs
    /usr/bin/sudo chown -R agentizer:agentizer /home/agentizer/.claude-code-router/logs

    # Set environment variables for Claude (passed through by CCR)
    # These are read by Claude when running inside CCR
    export ANTHROPIC_DANGEROUSLY_SKIP_PERMISSIONS=1
    export ANTHROPIC_PLUGIN_DIR=.claude-plugin

    # Run CCR code mode - args after --ccr are treated as prompt to Claude
    exec ccr code "${ARGS[@]}"
else
    exec claude --dangerously-skip-permissions --plugin-dir .claude-plugin "$@"
fi