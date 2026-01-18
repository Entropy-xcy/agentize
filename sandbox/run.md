# Sandbox Manager (run.py)

Sandbox session manager with tmux-based worktree + container management, supporting both local containers and Slurm compute nodes.

## Features

- **Local Mode**: Run containers locally with Podman or Docker
- **Slurm Mode**: Run containers on HPC Slurm compute nodes via `srun` + `podman-srun`

## Quick Start

### Local Mode (Default)

```bash
# Create a new sandbox
python sandbox/run.py new -n my-sandbox

# Create sandbox in CCR mode
python sandbox/run.py new -n my-sandbox --ccr

# Attach to the sandbox
python sandbox/run.py attach -n my-sandbox

# List all sandboxes
python sandbox/run.py ls

# Remove a sandbox
python sandbox/run.py rm -n my-sandbox

# Reset all local sandboxes (keeps Slurm jobs)
python sandbox/run.py reset
```

### Slurm Mode

```bash
# Create a sandbox on Slurm compute nodes
python sandbox/run.py new -n my-sandbox -s

# Attach to Slurm sandbox
python sandbox/run.py attach -n my-sandbox

# Remove and cancel Slurm job
python sandbox/run.py rm -n my-sandbox
```

## Usage

```
run.py [--repo_base <path>] <command> [options]

Options:
  --repo_base    Base path of the git repository (default: current directory)

Commands:
  new            Create new worktree + container
  ls             List all sandboxes
  rm             Delete worktree + container
  attach         Attach to tmux session
  reset          Remove all work directories and sandbox images

new options:
  -n, --name NAME      Sandbox name (default: cnt_N)
  -b, --branch BRANCH  Branch to checkout (default: main)
  --ccr                Run in CCR mode
  -s, --slurm          Run on Slurm compute nodes via srun
```

## Database Schema

The sandbox database (`.sandbox_db.sqlite`) stores:

| Column | Type | Description |
|--------|------|-------------|
| name | TEXT | Sandbox name (primary key) |
| branch | TEXT | Git branch |
| container_id | TEXT | Local container ID |
| slurm_job_id | TEXT | Slurm job ID (if running on Slurm) |
| work_dir | TEXT | Worktree path |
| ccr_mode | INTEGER | CCR mode flag |
| created_at | TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | Last update time |

## Architecture

### Local Container Mode

```
run.py → podman/docker run → Container with tmux → podman exec → tmux attach
```

### Slurm Mode

```
run.py → srun --wrap="podman-srun podman run ..." → Compute Node
                                                      ↓
                                              podman with tmux
                                                      ↓
                                          sattach → tmux session
```

## Slurm Mode Requirements

1. **Slurm tools** in PATH:
   - `srun` - Submit jobs to Slurm
   - `sattach` - Attach to Slurm job sessions
   - `scancel` - Cancel Slurm jobs

2. **podman-srun wrapper script**:
   - Searches: `./podman-srun`, `./sandbox/podman-srun`, or PATH
   - Handles node-specific storage for shared filesystems
   - Configures Podman for non-root containers on compute nodes

3. **Shared filesystem access**:
   - Home directory must be accessible from compute nodes
   - Git repository accessible from compute nodes

## Environment Variables

When running on Slurm, the following environment variables are passed to the container:
- `GITHUB_TOKEN` - If set in the environment

API keys (`ANTHROPIC_API_KEY`, `ANTHROPIC_BASE_URL`) are NOT passed in Slurm mode for security.

## Volume Mounts

The following are mounted into both local and Slurm containers:

| Source | Target | Description |
|--------|--------|-------------|
| ~/.claude-code-router/config.json | /home/agentizer/.claude-code-router/config.json | CCR config |
| ~/.config/gh/* | /home/agentizer/.config/gh/* | GitHub CLI config |
| ~/.git-credentials | /home/agentizer/.git-credentials | Git credentials |
| ~/.gitconfig | /home/agentizer/.gitconfig | Git config |
| worktree | /workspace | Project code |

## Troubleshooting

### Slurm Tools Not Found

```
Error: Required Slurm tool(s) not found in PATH: srun, sattach, scancel
```

Ensure Slurm is installed and the `sbatch` command is available.

### podman-srun Not Found

```
Error: podman-srun wrapper script not found
```

Place `podman-srun` in one of:
- Current directory: `./podman-srun`
- Sandbox directory: `./sandbox/podman-srun`
- PATH: `which podman-srun`

### Reset Skips Slurm Jobs

The `reset` command only cleans local resources. Slurm jobs are NOT cancelled. Use `rm` to remove Slurm sandboxes.

### sattach Fails

Ensure the Slurm job is still running. sattach requires an active job session:
```
sattach -m <job_id>.<step_id>:<session_name>
```