# Sandbox

Development environment container for agentize SDK.

## Purpose

This directory contains the Docker sandbox environment used for:
- Testing the agentize SDK in a controlled environment
- Development workflows requiring isolated dependencies
- CI/CD pipeline validation

## Contents

- `Dockerfile` - Docker image definition with all required tools
- `install.sh` - Claude Code installation script (copied into container)

## User

The container runs as the `agentizer` user with sudo privileges.

## Installed Tools

- Node.js 20.x LTS
- Python 3.12 with uv package manager
- SDKMAN for Java/SDK management
- Git, curl, wget, and other base utilities
- Playwright with bundled Chromium
- claude-code-router
- Claude Code

## Build

```bash
docker build -t agentize-sandbox ./sandbox
```

## Usage

```bash
docker run -it --rm agentize-sandbox
```

## Testing

```bash
# Run PATH verification tests
./tests/sandbox-path-test.sh

# Run full sandbox build and verification tests
./tests/e2e/test-sandbox-build.sh
```