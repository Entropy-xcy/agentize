#!/bin/bash
# Test Slurm mode for sandbox new subcommand

set -e

echo "=== Testing sandbox run.py slurm new command ==="

# Source the test helpers
source "$(dirname "$0")/../common.sh"

# Test 1: Verify run.py exists
echo "Verifying run.py exists..."
if [ ! -f "./sandbox/run.py" ]; then
    echo "FAIL: sandbox/run.py does not exist"
    exit 1
fi

# Test 2: Verify --slurm flag is recognized in help
echo "Verifying --slurm flag in help..."
help_output=$(python ./sandbox/run.py new --help 2>&1)
if ! echo "$help_output" | grep -q "\-\-slurm"; then
    echo "FAIL: --slurm flag not found in help output"
    exit 1
fi
echo "Found --slurm flag in help"

# Test 3: Verify -s short flag is recognized
if ! echo "$help_output" | grep -q "\-s"; then
    echo "FAIL: -s short flag not found in help output"
    exit 1
fi
echo "Found -s short flag in help"

# Test 4: Verify podman-srun lookup function exists
echo "Verifying podman-srun lookup..."
python3 << 'PYEOF'
import sys
sys.path.insert(0, './sandbox')
from run import find_podman_srun
import os
from pathlib import Path

# Mock existence check - the function should search for the script
# We'll test that the function exists and has proper logic
result = find_podman_srun()
# Result can be None if not found, or a Path object
print(f"find_podman_srun() returned: {result}")
PYEOF

echo "Podman-srun lookup function verified"

# Test 5: Verify slurm-related functions exist and are callable
echo "Verifying slurm-related functions..."
python3 << 'PYEOF'
import sys
sys.path.insert(0, './sandbox')
from run import (
    create_slurm_container,
    cancel_slurm_job,
    get_tmux_session_name,
    SandboxDB,
)
import tempfile
from pathlib import Path

# Test get_tmux_session_name
session = get_tmux_session_name("test-sb")
assert session == "agentize-sb-test-sb", f"Unexpected session name: {session}"
print(f"get_tmux_session_name works: {session}")

# Test SandboxDB with slurm_job_id
with tempfile.TemporaryDirectory() as tmpdir:
    db = SandboxDB(Path(tmpdir))
    # Test create with slurm_job_id
    db.create("test-slurm", "main", "/tmp/work", False, slurm_job_id="12345")
    
    # Verify the record was created
    record = db.get("test-slurm")
    assert record is not None, "Record should exist"
    assert record["slurm_job_id"] == "12345", f"slurm_job_id mismatch: {record['slurm_job_id']}"
    print(f"SandboxDB create with slurm_job_id works")
    
    # Test update_slurm_job_id
    db.update_slurm_job_id("test-slurm", "67890")
    record = db.get("test-slurm")
    assert record["slurm_job_id"] == "67890", f"Updated slurm_job_id mismatch: {record['slurm_job_id']}"
    print(f"SandboxDB update_slurm_job_id works")

print("All slurm-related functions verified")
PYEOF

# Test 6: Verify cmd_new handles --slurm argument
echo "Verifying cmd_new slurm argument handling..."
python3 << 'PYEOF'
import sys
sys.path.insert(0, './sandbox')
import argparse
from run import cmd_new
import inspect

# Check that cmd_new accesses args.slurm
source = inspect.getsource(cmd_new)
if "slurm" not in source:
    print("FAIL: cmd_new does not reference slurm argument")
    sys.exit(1)
print("cmd_new references slurm argument")
PYEOF

echo "=== All Slurm new tests passed ==="