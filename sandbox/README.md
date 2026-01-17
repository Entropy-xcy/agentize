# Sandbox

Development environment container for agentize SDK with tmux-based session management.

## Purpose

This directory contains the Docker/Podman sandbox environment used for:
- Running Claude/CCR in isolated containers with persistent tmux sessions
- Development workflows requiring isolated dependencies
- CI/CD pipeline validation

## Contents

- `Dockerfile` - Container image definition with all required tools
- `install.sh` - Claude Code installation script
- `entrypoint.sh` - Container entrypoint with tmux session support
- `run.py` - Python-based sandbox manager

## Quick Start

```bash
# Create a new sandbox (image builds automatically on first run)
uv run sandbox/run.py --repo_base /path/to/repo new -n my-sandbox

# Create sandbox in CCR (claude code router) mode
uv run sandbox/run.py --repo_base /path/to/repo new -n my-sandbox --ccr

# Attach to the sandbox
uv run sandbox/run.py --repo_base /path/to/repo attach -n my-sandbox

# List all sandboxes
uv run sandbox/run.py --repo_base /path/to/repo ls

# Remove a sandbox
uv run sandbox/run.py --repo_base /path/to/repo rm -n my-sandbox
```

## CLI Interface

```
run.py --repo_base <base_path> <subcommand> [options]
```

### Subcommands

| Command | Description |
|---------|-------------|
| `new -n <name> [--ccr] [-b <branch>]` | Create new worktree + container |
| `ls` | List all sandboxes |
| `rm -n <name>` | Delete sandbox |
| `attach -n <name>` | Attach to tmux session |
| `reset` | Remove all sandboxes and reset state |

## Container Runtime

Supports both Docker and Podman. Detection order:

1. Local config: `sandbox/agentize.toml` or `./agentize.toml`
2. Global config: `~/.config/agentize/agentize.toml`
3. `CONTAINER_RUNTIME` environment variable
4. Auto-detection: Podman preferred, falls back to Docker

### Config File Format

```toml
[container]
runtime = "podman"  # or "docker"
```

## Automatic Build

The image builds automatically when needed:
- First run if image doesn't exist
- When `Dockerfile`, `install.sh`, or `entrypoint.sh` change
- Use `--build` flag to force rebuild

## Volume Mounts

Automatically mounted:
- `~/.claude-code-router/config.json` → CCR config (read-only)
- `~/.config/gh/` → GitHub CLI config (read-only)
- `~/.git-credentials` → Git credentials (read-only)
- `~/.gitconfig` → Git config (read-only)
- Worktree directory → `/workspace` (read-write)
- `GITHUB_TOKEN` environment variable (if set)

## Installed Tools

- Node.js 20.x LTS
- Python 3.12 with uv
- Claude Code & claude-code-router
- Playwright with Chromium
- GitHub CLI
- tmux
- Git, curl, wget, vim, jq

## FACT Lab Setup

For users on FACT Lab machines (e.g., mantis), you need to configure Podman for network filesystem compatibility.

Create `~/.config/containers/storage.conf`:

```toml
[storage]
driver = "overlay"

[storage.options.overlay]
force_mask = "700"
# Use fuse-overlayfs for better stability on network filesystems
mount_program = "/usr/bin/fuse-overlayfs"
```

Create `~/.config/containers/containers.conf`:

```toml
[engine]
# Disable healthcheck timer - main cause of lock contention
healthcheck_events = false

# Reduce concurrent operations
parallel_pull = 1

# Increase lock wait timeout
image_copy_tmp_dir = "/tmp"

[containers]
# Disable container healthcheck by default
init = true
```

If that still does not work, your username maybe not been included in the fakeroot list. Ask the admin for adding to fakeroot list. 
