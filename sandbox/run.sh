#!/bin/bash
# Run agentize container with volume passthrough
#
# This script mounts external resources into the container:
# - ~/.claude-code-router/config.json -> /home/agentizer/.claude-code-router/config.json
# - ~/.config/gh -> /home/agentizer/.config/gh (GitHub CLI credentials)
# - ~/.git-credentials -> /home/agentizer/.git-credentials
# - ~/.gitconfig -> /home/agentizer/.gitconfig
# - Current agentize project directory -> /workspace/agentize

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="agentize-sandbox"

# Determine container name (first positional argument, if not starting with -)
CONTAINER_NAME="${1:-agentize-runner}"
if [[ "$CONTAINER_NAME" != -* ]]; then
    shift
else
    CONTAINER_NAME="agentize-runner"
fi

# Build volume mounts
VOLUMES=()

# 1. Passthrough claude-code-router config if exists
CCR_CONFIG="$HOME/.claude-code-router/config.json"
if [ -f "$CCR_CONFIG" ]; then
    VOLUMES+=("-v $CCR_CONFIG:/home/agentizer/.claude-code-router/config.json:ro")
fi

# 2. Passthrough GitHub CLI credentials
GH_CONFIG="$HOME/.config/gh"
if [ -d "$GH_CONFIG" ]; then
    VOLUMES+=("-v $GH_CONFIG:/home/agentizer/.config/gh:ro")
fi

# 3. Passthrough git credentials (if exists)
GIT_CREDS="$HOME/.git-credentials"
if [ -f "$GIT_CREDS" ]; then
    VOLUMES+=("-v $GIT_CREDS:/home/agentizer/.git-credentials:ro")
fi
GIT_CONFIG="$HOME/.gitconfig"
if [ -f "$GIT_CONFIG" ]; then
    VOLUMES+=("-v $GIT_CONFIG:/home/agentizer/.gitconfig:ro")
fi

# 4. Passthrough agentize project directory
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VOLUMES+=("-v $PROJECT_DIR:/workspace/agentize")

# Run docker with all configurations
docker run \
    --name "$CONTAINER_NAME" \
    --rm \
    -it \
    "${VOLUMES[@]}" \
    -w /workspace/agentize \
    "$IMAGE_NAME" \
    "$@"