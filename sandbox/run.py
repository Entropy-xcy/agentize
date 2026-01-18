#!/usr/bin/env python3
"""
Sandbox session manager with tmux-based worktree + container management.

This script manages sandboxes that combine:
- Git worktrees for isolated code branches
- Persistent containers with tmux sessions
- SQLite database for state tracking

Subcommands:
- new: Create new worktree + container
- ls: List all sandboxes
- rm: Delete worktree + container
- attach: Attach to tmux session

Container runtime is detected in priority order:
1. Local config file (sandbox/agentize.toml or ./agentize.toml)
2. ~/.config/agentize/agentize.toml config file
3. CONTAINER_RUNTIME environment variable
4. Auto-detection (podman preferred if available)
5. Default to docker
"""

import argparse
import hashlib
import json
import os
import platform
import shlex
import shutil
import sqlite3
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional

# Python 3.11+ has tomllib built-in, older versions need tomli
if sys.version_info >= (3, 11):
    import tomllib
else:
    import tomli as tomllib

# Cache file to store image hash for rebuild detection
CACHE_DIR = Path.home() / ".cache" / "agentize"
CACHE_FILE = CACHE_DIR / "sandbox-image.json"

IMAGE_NAME = "agentize-sandbox"

# Files that trigger rebuild when modified (relative to context/sandbox directory)
BUILD_TRIGGER_FILES = [
    "Dockerfile",
    "install.sh",
    "entrypoint.sh",
]

# Container naming prefix
CONTAINER_PREFIX = "agentize-sb-"

# Work directory name (for shallow clones)
WORK_DIR = ".work"

# Database file name
DB_FILE = ".sandbox_db.sqlite"


# =============================================================================
# SQLite State Management
# =============================================================================


class SandboxDB:
    """SQLite database for sandbox state management."""

    def __init__(self, repo_base: Path):
        self.db_path = repo_base / DB_FILE
        self._init_db()

    def _init_db(self):
        """Initialize database schema."""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS sandboxes (
                    name TEXT PRIMARY KEY,
                    branch TEXT NOT NULL,
                    container_id TEXT,
                    slurm_job_id TEXT,
                    work_dir TEXT NOT NULL,
                    ccr_mode INTEGER DEFAULT 0,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            # Add slurm_job_id column migration for existing databases
            try:
                conn.execute("ALTER TABLE sandboxes ADD COLUMN slurm_job_id TEXT")
            except sqlite3.OperationalError:
                # Column already exists
                pass
            conn.commit()

    def create(
        self,
        name: str,
        branch: str,
        work_dir: str,
        ccr_mode: bool = False,
        slurm_job_id: Optional[str] = None,
    ) -> None:
        """Create a new sandbox record."""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute(
                """INSERT INTO sandboxes (name, branch, container_id, slurm_job_id, work_dir, ccr_mode)
                   VALUES (?, ?, ?, ?, ?, ?)""",
                (name, branch, None, slurm_job_id, work_dir, 1 if ccr_mode else 0),
            )
            conn.commit()

    def update_slurm_job_id(self, name: str, slurm_job_id: str) -> None:
        """Update Slurm job ID for a sandbox."""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute(
                """UPDATE sandboxes SET slurm_job_id = ?, updated_at = ?
                   WHERE name = ?""",
                (slurm_job_id, datetime.now().isoformat(), name),
            )
            conn.commit()

    def update_container_id(self, name: str, container_id: str) -> None:
        """Update container ID for a sandbox."""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute(
                """UPDATE sandboxes SET container_id = ?, updated_at = ?
                   WHERE name = ?""",
                (container_id, datetime.now().isoformat(), name),
            )
            conn.commit()

    def get(self, name: str) -> Optional[dict]:
        """Get sandbox by name."""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute("SELECT * FROM sandboxes WHERE name = ?", (name,))
            row = cursor.fetchone()
            return dict(row) if row else None

    def list_all(self) -> list[dict]:
        """List all sandboxes."""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute("SELECT * FROM sandboxes ORDER BY created_at DESC")
            return [dict(row) for row in cursor.fetchall()]

    def delete(self, name: str) -> None:
        """Delete a sandbox record."""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("DELETE FROM sandboxes WHERE name = ?", (name,))
            conn.commit()

    def get_next_counter(self) -> int:
        """Get the next available counter for auto-naming (cnt_N)."""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.execute("SELECT name FROM sandboxes WHERE name LIKE 'cnt_%'")
            max_counter = 0
            for row in cursor.fetchall():
                name = row[0]
                try:
                    counter = int(name.replace("cnt_", ""))
                    max_counter = max(max_counter, counter)
                except ValueError:
                    pass
            return max_counter + 1


def get_container_runtime() -> str:
    """Determine the container runtime to use.

    Priority:
    1. Local config file (sandbox/agentize.toml or ./agentize.toml)
    2. ~/.config/agentize/agentize.toml config file
    3. CONTAINER_RUNTIME environment variable
    4. Auto-detection (podman preferred if available)
    5. Default to docker
    """
    # Priority 1: Local config file
    script_dir = Path(__file__).parent.resolve()
    local_configs = [
        script_dir / "agentize.toml",
        script_dir.parent / "agentize.toml",
    ]
    for config_path in local_configs:
        if config_path.exists():
            try:
                with open(config_path, "rb") as f:
                    config = tomllib.load(f)
                if "container" in config and "runtime" in config["container"]:
                    return config["container"]["runtime"]
            except Exception:
                pass

    # Priority 2: Global config file
    config_path = Path.home() / ".config" / "agentize" / "agentize.toml"
    if config_path.exists():
        try:
            with open(config_path, "rb") as f:
                config = tomllib.load(f)
            if "container" in config and "runtime" in config["container"]:
                return config["container"]["runtime"]
        except Exception:
            pass

    # Priority 3: Environment variable
    runtime = os.environ.get("CONTAINER_RUNTIME")
    if runtime:
        return runtime

    # Priority 4: Auto-detection
    if shutil.which("podman"):
        return "podman"

    # Default to docker
    return "docker"


def get_host_architecture() -> str:
    """Map platform.machine() to standard architecture names."""
    arch = platform.machine().lower()

    # Normalize architecture names
    arch_map = {
        "x86_64": "amd64",
        "amd64": "amd64",
        "aarch64": "arm64",
        "arm64": "arm64",
        "armv8l": "arm64",
    }
    return arch_map.get(arch, arch)


def is_interactive() -> bool:
    """Check if running interactively (has TTY and not piping)."""
    return sys.stdin.isatty() and sys.stdout.isatty()


def calculate_files_hash(files: list[Path]) -> str:
    """Calculate a hash of the contents of the given files."""
    hasher = hashlib.sha256()
    for file_path in files:
        if file_path.exists():
            with open(file_path, "rb") as f:
                hasher.update(f.read())
    return hasher.hexdigest()


def get_image_hash() -> Optional[str]:
    """Get the cached image hash."""
    if CACHE_FILE.exists():
        try:
            with open(CACHE_FILE) as f:
                data = json.load(f)
            return data.get("hash")
        except Exception:
            pass
    return None


def save_image_hash(image_hash: str) -> None:
    """Save the image hash to cache."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    with open(CACHE_FILE, "w") as f:
        json.dump({"hash": image_hash}, f)


def image_exists(runtime: str, image_name: str) -> bool:
    """Check if the container image exists."""
    try:
        subprocess.run(
            [runtime, "image", "inspect", image_name],
            capture_output=True,
            check=True,
        )
        return True
    except subprocess.CalledProcessError:
        return False


def build_image(runtime: str, image_name: str, context: Path) -> bool:
    """Build the container image."""
    print(f"Building {image_name} with {runtime}...", file=sys.stderr)
    try:
        subprocess.run(
            [runtime, "build", "-t", image_name, str(context)],
            check=True,
        )
        return True
    except subprocess.CalledProcessError as e:
        print(f"Failed to build image: {e}", file=sys.stderr)
        return False


def ensure_image(runtime: str, context: Path) -> bool:
    """Ensure the container image exists and is up-to-date."""
    # Check if image exists
    if not image_exists(runtime, IMAGE_NAME):
        print(f"Image {IMAGE_NAME} not found, building...", file=sys.stderr)
        return build_image(runtime, IMAGE_NAME, context)

    # Calculate current hash of build trigger files
    trigger_paths = [context / f for f in BUILD_TRIGGER_FILES]
    current_hash = calculate_files_hash(trigger_paths)
    cached_hash = get_image_hash()

    if cached_hash != current_hash:
        print(f"Build files changed, rebuilding {IMAGE_NAME}...", file=sys.stderr)
        if build_image(runtime, IMAGE_NAME, context):
            save_image_hash(current_hash)
            return True
        return False

    return True


# =============================================================================
# Git Repository Management
# =============================================================================


def validate_git_repo(repo_base: Path) -> bool:
    """Validate that repo_base is a git repository."""
    git_dir = repo_base / ".git"
    return git_dir.exists()


def get_remote_url(repo_base: Path) -> str:
    """Get the remote URL of the repository."""
    result = subprocess.run(
        ["git", "-C", str(repo_base), "remote", "get-url", "origin"],
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout.strip()


def create_work_dir(repo_base: Path, name: str, branch: str) -> Path:
    """Create a shallow clone of the repository for the sandbox."""
    work_base = repo_base / WORK_DIR
    work_base.mkdir(exist_ok=True)

    work_path = work_base / name

    # Get remote URL
    remote_url = get_remote_url(repo_base)

    # Shallow clone the specific branch
    subprocess.run(
        [
            "git",
            "clone",
            "--depth",
            "1",
            "--branch",
            branch,
            "--single-branch",
            remote_url,
            str(work_path),
        ],
        check=True,
    )

    return work_path


def remove_work_dir(repo_base: Path, name: str) -> None:
    """Remove a work directory."""
    work_path = repo_base / WORK_DIR / name

    if work_path.exists():
        shutil.rmtree(work_path)


# =============================================================================
# Container Management
# =============================================================================


def get_container_name(name: str) -> str:
    """Get container name from sandbox name."""
    return f"{CONTAINER_PREFIX}{name}"


def get_uid_gid_args(runtime: str) -> list[str]:
    """Get UID/GID mapping arguments for the container runtime."""
    # No UID/GID mapping needed - container runs as its own user
    return []


def container_exists(runtime: str, container_name: str) -> bool:
    """Check if a container exists."""
    try:
        result = subprocess.run(
            [runtime, "container", "inspect", container_name],
            capture_output=True,
        )
        return result.returncode == 0
    except Exception:
        return False


def container_running(runtime: str, container_name: str) -> bool:
    """Check if a container is running."""
    try:
        result = subprocess.run(
            [
                runtime,
                "container",
                "inspect",
                "-f",
                "{{.State.Running}}",
                container_name,
            ],
            capture_output=True,
            text=True,
        )
        return result.returncode == 0 and result.stdout.strip() == "true"
    except Exception:
        return False


def start_container(runtime: str, container_name: str) -> bool:
    """Start a stopped container."""
    try:
        subprocess.run([runtime, "start", container_name], check=True)
        return True
    except subprocess.CalledProcessError:
        return False


def stop_container(runtime: str, container_name: str) -> bool:
    """Stop a running container."""
    try:
        subprocess.run(
            [runtime, "stop", container_name], check=True, capture_output=True
        )
        return True
    except subprocess.CalledProcessError:
        return False


def remove_container(runtime: str, container_name: str) -> bool:
    """Remove a container."""
    try:
        subprocess.run(
            [runtime, "rm", "-f", container_name], check=True, capture_output=True
        )
        return True
    except subprocess.CalledProcessError:
        return False


def get_container_volume_args(home: Path, worktree_path: Path) -> list[str]:
    """Get common volume mount arguments for podman container.

    Returns a list of -v arguments for volume mounts.
    """
    cmd = []

    # CCR config
    ccr_config = home / ".claude-code-router" / "config.json"
    if ccr_config.exists():
        cmd.extend(
            ["-v", f"{ccr_config}:/home/agentizer/.claude-code-router/config.json:ro"]
        )
        cmd.extend(
            [
                "-v",
                f"{ccr_config}:/home/agentizer/.claude-code-router/config-router.json:ro",
            ]
        )

    # GitHub CLI credentials
    gh_config_yml = home / ".config" / "gh" / "config.yml"
    if gh_config_yml.exists():
        cmd.extend(["-v", f"{gh_config_yml}:/home/agentizer/.config/gh/config.yml:ro"])

    gh_hosts = home / ".config" / "gh" / "hosts.yml"
    if gh_hosts.exists():
        cmd.extend(["-v", f"{gh_hosts}:/home/agentizer/.config/gh/hosts.yml:ro"])

    # Git credentials
    git_creds = home / ".git-credentials"
    if git_creds.exists():
        cmd.extend(["-v", f"{git_creds}:/home/agentizer/.git-credentials:ro"])

    git_config = home / ".gitconfig"
    if git_config.exists():
        cmd.extend(["-v", f"{git_config}:/home/agentizer/.gitconfig:ro"])

    # Worktree directory
    cmd.extend(["-v", f"{worktree_path}:/workspace"])

    return cmd


def get_container_env_args(ccr_mode: bool) -> list[str]:
    """Get common environment variable arguments for podman container.

    Returns a list of -e arguments for environment variables.
    """
    cmd = []

    if "GITHUB_TOKEN" in os.environ:
        cmd.extend(["-e", f"GITHUB_TOKEN={os.environ['GITHUB_TOKEN']}"])

    if not ccr_mode:
        if "ANTHROPIC_API_KEY" in os.environ:
            cmd.extend(["-e", f"ANTHROPIC_API_KEY={os.environ['ANTHROPIC_API_KEY']}"])
        if "ANTHROPIC_BASE_URL" in os.environ:
            cmd.extend(["-e", f"ANTHROPIC_BASE_URL={os.environ['ANTHROPIC_BASE_URL']}"])

    return cmd


def create_sandbox_container(
    runtime: str,
    container_name: str,
    worktree_path: Path,
    ccr_mode: bool,
) -> str:
    """Create and start a persistent sandbox container with tmux."""
    cmd = [runtime, "run", "-d"]  # Detached mode, no --rm

    # Interactive mode for tmux
    cmd.extend(["-it"])

    # Container name
    cmd.extend(["--name", container_name])

    # Volume mounts
    home = Path.home()
    cmd.extend(get_container_volume_args(home, worktree_path))

    # Environment variables
    cmd.extend(get_container_env_args(ccr_mode))

    # Working directory
    cmd.extend(["-w", "/workspace"])

    # Image and entrypoint with tmux
    cmd.extend(["--entrypoint", "/usr/local/bin/entrypoint"])
    cmd.append(IMAGE_NAME)
    cmd.append("--tmux")
    if ccr_mode:
        cmd.append("--ccr")

    # Run container
    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    return result.stdout.strip()


# =============================================================================
# Slurm Container Management
# =============================================================================


def find_podman_srun() -> Optional[Path]:
    """Find the podman-srun wrapper script.

    Searches in order:
    1. Current directory (./podman-srun)
    2. Sandbox directory (./sandbox/podman-srun)
    3. PATH environment variable
    """
    # Check current directory
    script_dir = Path(__file__).parent.resolve()
    podman_srun_paths = [
        Path.cwd() / "podman-srun",
        script_dir / "podman-srun",
    ]
    for path in podman_srun_paths:
        if path.exists() and path.is_file():
            return path
    # Check PATH
    which_path = shutil.which("podman-srun")
    if which_path:
        return Path(which_path)
    return None


def get_tmux_session_name(name: str) -> str:
    """Get tmux session name for a sandbox."""
    return f"agentize-sb-{name}"


def create_slurm_container(
    worktree_path: Path,
    ccr_mode: bool,
) -> str:
    """Create and start a sandbox container on Slurm via srun + podman-srun.

    Returns the Slurm job ID.
    """
    # Verify required Slurm tools are available
    require_slurm_tools()

    podman_srun_path = find_podman_srun()
    if not podman_srun_path:
        raise RuntimeError(
            "podman-srun wrapper script not found. "
            "Expected at ./podman-srun, ./sandbox/podman-srun, or in PATH."
        )

    # Build the podman run command using shared helpers
    cmd = ["podman", "run", "-it"]

    # Volume mounts using shared helper
    home = Path.home()
    cmd.extend(get_container_volume_args(home, worktree_path))

    # Environment variables using shared helper
    cmd.extend(get_container_env_args(ccr_mode))

    # Working directory
    cmd.extend(["-w", "/workspace"])

    # Image and entrypoint with tmux
    cmd.extend(["--entrypoint", "/usr/local/bin/entrypoint"])
    cmd.append(IMAGE_NAME)
    cmd.append("--tmux")
    if ccr_mode:
        cmd.append("--ccr")

    # Build the command to run via srun
    # The podman-srun wrapper handles node-specific storage
    podman_cmd_str = " ".join(shlex.quote(arg) for arg in cmd)

    # Run via srun with podman-srun wrapper
    # srun will submit the job and capture the job ID
    # Use direct script invocation: srun ./podman-srun run hello-world
    srun_cmd = ["srun", "--job-name=agentize-sandbox", podman_srun_path] + cmd

    result = subprocess.run(srun_cmd, capture_output=True, text=True, check=True)

    # Extract job ID from srun output
    # srun outputs job ID in formats like:
    # - "Submitted batch job 12345"
    # - "12345"
    output = result.stdout.strip()
    job_id = None
    for line in output.split("\n"):
        line = line.strip()
        if "Submitted batch job" in line:
            parts = line.split()
            candidate = parts[-1]
            if candidate.isdigit():
                job_id = candidate
                break
        elif line.isdigit():
            # Fallback: line is just the job ID
            job_id = line
            break

    if not job_id:
        raise RuntimeError(
            f"Could not extract valid job ID from srun output:\n{output}\n"
            "Ensure Slurm is configured to output job ID."
        )

    return job_id


def require_slurm_tools() -> None:
    """Verify that required Slurm tools are available in PATH.

    Raises RuntimeError if any required tool is missing.
    """
    missing = []
    for tool in ["srun", "sattach", "scancel"]:
        if not shutil.which(tool):
            missing.append(tool)
    if missing:
        raise RuntimeError(
            f"Required Slurm tool(s) not found in PATH: {', '.join(missing)}. "
            "Please ensure Slurm is properly installed and configured."
        )


def cancel_slurm_job(job_id: str) -> bool:
    """Cancel a Slurm job using scancel."""
    try:
        result = subprocess.run(
            ["scancel", job_id], check=True, capture_output=True, text=True
        )
        return True
    except subprocess.CalledProcessError as e:
        print(
            f"Warning: Failed to cancel Slurm job {job_id}: {e.stderr}", file=sys.stderr
        )
        return False


# =============================================================================
# Subcommand Handlers
# =============================================================================


def cmd_new(args) -> int:
    """Handle 'new' subcommand: Create new worktree + container."""
    repo_base = Path(args.repo_base).resolve()
    runtime = get_container_runtime()
    slurm_mode = getattr(args, "slurm", False)

    # Validate git repo
    if not validate_git_repo(repo_base):
        print(f"Error: {repo_base} is not a git repository", file=sys.stderr)
        return 1

    db = SandboxDB(repo_base)

    # Auto-generate name if not provided
    name = args.name
    if not name:
        counter = db.get_next_counter()
        name = f"cnt_{counter}"

    # Check for name conflicts
    if db.get(name):
        print(f"Error: Sandbox '{name}' already exists", file=sys.stderr)
        return 1

    # Ensure image exists (required for both local and slurm modes)
    script_dir = Path(__file__).parent.resolve()
    if not ensure_image("podman", script_dir):
        print("Failed to ensure container image", file=sys.stderr)
        return 1

    mode_str = "Slurm" if slurm_mode else "local"
    print(f"Creating sandbox '{name}' on branch '{args.branch}' ({mode_str} mode)...")

    # Create work directory (shallow clone)
    try:
        work_path = create_work_dir(repo_base, name, args.branch)
    except subprocess.CalledProcessError as e:
        print(f"Failed to create work directory: {e}", file=sys.stderr)
        return 1

    # Record in database (will be updated with slurm_job_id or container_id later)
    db.create(name, args.branch, str(work_path), args.ccr, slurm_job_id=None)

    try:
        if slurm_mode:
            # Create container via Slurm srun
            job_id = create_slurm_container(work_path, args.ccr)
            db.update_slurm_job_id(name, job_id)
            print(f"Sandbox '{name}' created successfully")
            print(f"  Work dir: {work_path}")
            print(f"  Slurm job ID: {job_id}")
            print(f"  Attach with: run.py attach -n {name}")
        else:
            # Create local container
            container_name = get_container_name(name)
            container_id = create_sandbox_container(
                runtime, container_name, work_path, args.ccr
            )
            db.update_container_id(name, container_id)
            print(f"Sandbox '{name}' created successfully")
            print(f"  Work dir: {work_path}")
            print(f"  Container: {container_name}")
            print(f"  Attach with: run.py attach -n {name}")
    except subprocess.CalledProcessError as e:
        print(f"Failed to create container: {e}", file=sys.stderr)
        # Cleanup work directory on failure
        remove_work_dir(repo_base, name)
        db.delete(name)
        return 1

    return 0


def cmd_ls(args) -> int:
    """Handle 'ls' subcommand: List all sandboxes."""
    repo_base = Path(args.repo_base).resolve()
    runtime = get_container_runtime()

    if not validate_git_repo(repo_base):
        print(f"Error: {repo_base} is not a git repository", file=sys.stderr)
        return 1

    db = SandboxDB(repo_base)
    sandboxes = db.list_all()

    if not sandboxes:
        print("No sandboxes found")
        return 0

    # Print header
    print(
        f"{'NAME':<15} {'BRANCH':<20} {'CONTAINER/JOB':<15} {'STATUS':<10} {'CREATED'}"
    )
    print("-" * 80)

    for sb in sandboxes:
        slurm_job_id = sb.get("slurm_job_id")
        container_name = get_container_name(sb["name"])

        if slurm_job_id:
            # Slurm mode
            container_or_job = f"slurm:{slurm_job_id}"
            status = "slurm"
        elif container_running(runtime, container_name):
            container_or_job = container_name
            status = "running"
        elif container_exists(runtime, container_name):
            container_or_job = container_name
            status = "stopped"
        else:
            container_or_job = "N/A"
            status = "no container"

        created = sb["created_at"][:16] if sb["created_at"] else "unknown"
        print(
            f"{sb['name']:<15} {sb['branch']:<20} {container_or_job:<15} {status:<10} {created}"
        )

    return 0


def cmd_rm(args) -> int:
    """Handle 'rm' subcommand: Delete worktree + container."""
    repo_base = Path(args.repo_base).resolve()
    runtime = get_container_runtime()

    if not validate_git_repo(repo_base):
        print(f"Error: {repo_base} is not a git repository", file=sys.stderr)
        return 1

    db = SandboxDB(repo_base)
    sandbox = db.get(args.name)

    if not sandbox:
        print(f"Error: Sandbox '{args.name}' not found", file=sys.stderr)
        return 1

    slurm_job_id = sandbox.get("slurm_job_id")
    container_name = get_container_name(args.name)
    print(f"Removing sandbox '{args.name}'...")

    if slurm_job_id:
        # Slurm mode: cancel the job and clean up local worktree
        print(f"  Cancelling Slurm job {slurm_job_id}...")
        if not cancel_slurm_job(slurm_job_id):
            print(f"  Warning: Failed to cancel Slurm job (may already be complete)")
    else:
        # Local mode: stop and remove container
        if container_exists(runtime, container_name):
            print(f"  Stopping and removing container '{container_name}'...")
            stop_container(runtime, container_name)
            remove_container(runtime, container_name)

    # Remove work directory
    try:
        remove_work_dir(repo_base, args.name)
    except Exception as e:
        if not args.force:
            print(f"Failed to remove work directory: {e}", file=sys.stderr)
            return 1

    # Remove from database
    db.delete(args.name)
    print(f"Sandbox '{args.name}' removed")
    return 0


def cmd_attach(args) -> int:
    """Handle 'attach' subcommand: Attach to tmux session."""
    repo_base = Path(args.repo_base).resolve()
    runtime = get_container_runtime()

    if not validate_git_repo(repo_base):
        print(f"Error: {repo_base} is not a git repository", file=sys.stderr)
        return 1

    db = SandboxDB(repo_base)
    sandbox = db.get(args.name)

    if not sandbox:
        print(f"Error: Sandbox '{args.name}' not found", file=sys.stderr)
        return 1

    slurm_job_id = sandbox.get("slurm_job_id")
    container_id = sandbox.get("container_id")

    if slurm_job_id:
        # Slurm mode: use sattach to connect to tmux session
        # Format: sattach -m <job_id>.<step_id>:<session_name>
        # step_id 0 is the main step (the srun job itself)
        session_name = get_tmux_session_name(args.name)
        sattach_cmd = [
            "sattach",
            "-m",
            f"{slurm_job_id}.0:{session_name}",
        ]
        print(f"Attaching to Slurm sandbox '{args.name}' (job {slurm_job_id})...")
        os.execvp(sattach_cmd[0], sattach_cmd)
    else:
        # Local mode: use podman/docker exec
        container_name = get_container_name(args.name)

        # Check container state
        if not container_exists(runtime, container_name):
            print(
                f"Error: Container '{container_name}' does not exist", file=sys.stderr
            )
            return 1

        # Start container if stopped
        if not container_running(runtime, container_name):
            print(f"Starting container '{container_name}'...")
            if not start_container(runtime, container_name):
                print(f"Failed to start container", file=sys.stderr)
                return 1

        # Attach to tmux session using the fixed socket path
        # Use -u 0 (root) because podman rootless maps container UID to different host UID,
        # causing socket permission issues when accessing from exec
        socket_path = "/tmp/tmux-main"
        cmd = [
            runtime,
            "exec",
            "-it",
            "-u",
            "0",
            container_name,
            "tmux",
            "-S",
            socket_path,
            "attach",
            "-t",
            "main",
        ]
        print(f"Attaching to sandbox '{args.name}'...")
        os.execvp(cmd[0], cmd)


def cmd_reset(args) -> int:
    """Handle 'reset' subcommand: Remove all work directories and sandbox images."""
    repo_base = Path(args.repo_base).resolve()
    runtime = get_container_runtime()

    if not validate_git_repo(repo_base):
        print(f"Error: {repo_base} is not a git repository", file=sys.stderr)
        return 1

    print(f"Resetting all sandbox resources for {repo_base}...")

    # Get all sandboxes from database
    db = SandboxDB(repo_base)
    sandboxes = db.list_all()

    # Stop and remove local containers only (skip Slurm sandboxes)
    slurm_job_count = 0
    for sb in sandboxes:
        if sb.get("slurm_job_id"):
            slurm_job_count += 1
            continue
        container_name = get_container_name(sb["name"])
        if container_exists(runtime, container_name):
            print(f"  Stopping and removing container '{container_name}'...")
            stop_container(runtime, container_name)
            remove_container(runtime, container_name)

    # Warn about Slurm jobs if any exist
    if slurm_job_count > 0:
        print(
            f"  Warning: {slurm_job_count} Slurm sandbox(es) not cancelled. "
            "Use 'rm' command to remove Slurm sandboxes.",
            file=sys.stderr,
        )

    # Remove the entire .work directory
    work_base = repo_base / WORK_DIR
    if work_base.exists():
        print(f"  Removing work directory '{work_base}'...")
        shutil.rmtree(work_base)

    # Remove database file
    db_path = repo_base / DB_FILE
    if db_path.exists():
        print(f"  Removing database '{db_path}'...")
        db_path.unlink()

    # Remove sandbox image
    if image_exists(runtime, IMAGE_NAME):
        print(f"  Removing image '{IMAGE_NAME}'...")
        try:
            subprocess.run(
                [runtime, "rmi", "-f", IMAGE_NAME],
                check=True,
                capture_output=True,
            )
        except subprocess.CalledProcessError as e:
            print(f"  Warning: Failed to remove image: {e}", file=sys.stderr)

    # Clear image hash cache
    if CACHE_FILE.exists():
        print(f"  Removing image cache...")
        CACHE_FILE.unlink()

    print("Reset complete.")
    return 0


# =============================================================================
# Argument Parser
# =============================================================================


def main():
    """Main entry point with subcommand routing."""
    parser = argparse.ArgumentParser(
        description="Sandbox session manager with tmux-based worktree + container management.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--repo_base",
        default=".",
        help="Base path of the git repository (default: current directory)",
    )

    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # 'new' subcommand
    new_parser = subparsers.add_parser("new", help="Create new worktree + container")
    new_parser.add_argument(
        "-n", "--name", help="Sandbox name (default: cnt_N where N is auto-incremented)"
    )
    new_parser.add_argument(
        "-b", "--branch", default="main", help="Branch to checkout (default: main)"
    )
    new_parser.add_argument("--ccr", action="store_true", help="Run in CCR mode")
    new_parser.add_argument(
        "-s",
        "--slurm",
        action="store_true",
        help="Run container on Slurm compute nodes via srun",
    )

    # 'ls' subcommand
    subparsers.add_parser("ls", help="List all sandboxes")

    # 'rm' subcommand
    rm_parser = subparsers.add_parser("rm", help="Delete worktree + container")
    rm_parser.add_argument("-n", "--name", required=True, help="Sandbox name")
    rm_parser.add_argument("--force", action="store_true", help="Force removal")

    # 'attach' subcommand
    attach_parser = subparsers.add_parser("attach", help="Attach to tmux session")
    attach_parser.add_argument("-n", "--name", required=True, help="Sandbox name")

    # 'reset' subcommand
    subparsers.add_parser(
        "reset", help="Remove all work directories and sandbox images"
    )

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    # Route to subcommand handler
    handlers = {
        "new": cmd_new,
        "ls": cmd_ls,
        "rm": cmd_rm,
        "attach": cmd_attach,
        "reset": cmd_reset,
    }

    handler = handlers.get(args.command)
    if handler:
        sys.exit(handler(args))
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
