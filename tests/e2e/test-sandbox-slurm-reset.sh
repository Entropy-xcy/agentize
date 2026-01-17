#!/bin/bash
# Test Slurm mode for sandbox reset subcommand

set -e

echo "=== Testing sandbox run.py slurm reset command ==="

# Source the test helpers
source "$(dirname "$0")/../common.sh"

# Test 1: Verify cmd_reset skips Slurm jobs
echo "Verifying cmd_reset skips Slurm jobs..."
python3 << 'PYEOF'
import sys
sys.path.insert(0, './sandbox')
from run import cmd_reset
import inspect

source = inspect.getsource(cmd_reset)
# Check for Slurm mode indicators
checks = [
    ("slurm_job_id" in source, "slurm_job_id check not found in cmd_reset"),
    ("continue" in source or "skip" in source.lower(), "Skip mechanism not found in cmd_reset"),
    ("Warning" in source or "warning" in source, "Warning message not found in cmd_reset"),
]

for check, error_msg in checks:
    if not check:
        print(f"FAIL: {error_msg}")
        sys.exit(1)

print("cmd_reset contains Slurm job skipping logic")
PYEOF

# Test 2: Verify local containers are still removed
echo "Verifying local container removal is preserved..."
python3 << 'PYEOF'
import sys
sys.path.insert(0, './sandbox')
from run import cmd_reset
import inspect

source = inspect.getsource(cmd_reset)
# Local containers should still be stopped and removed
checks = [
    ("stop_container" in source, "stop_container not found in cmd_reset"),
    ("remove_container" in source, "remove_container not found in cmd_reset"),
]

for check, error_msg in checks:
    if not check:
        print(f"FAIL: {error_msg}")
        sys.exit(1)

print("Local container removal preserved")
PYEOF

# Test 3: Verify work directory and other resources are still cleaned
echo "Verifying resource cleanup is preserved..."
python3 << 'PYEOF'
import sys
sys.path.insert(0, './sandbox')
from run import cmd_reset
import inspect

source = inspect.getsource(cmd_reset)
# Other resources should still be cleaned up
checks = [
    ("shutil.rmtree" in source, "shutil.rmtree not found in cmd_reset"),
    ("db_path.unlink()" in source or "unlink" in source, "database unlink not found in cmd_reset"),
    ("CACHE_FILE" in source, "CACHE_FILE cleanup not found in cmd_reset"),
]

for check, error_msg in checks:
    if not check:
        print(f"FAIL: {error_msg}")
        sys.exit(1)

print("Resource cleanup preserved")
PYEOF

# Test 4: Verify warning message about Slurm jobs
echo "Verifying warning message content..."
python3 << 'PYEOF'
import sys
sys.path.insert(0, './sandbox')
from run import cmd_reset
import inspect

source = inspect.getsource(cmd_reset)
# Warning should mention Slurm and rm command
if "Slurm" not in source or "rm" not in source:
    print("FAIL: Warning message should mention Slurm and rm command")
    sys.exit(1)
print("Warning message verified")
PYEOF

echo "=== All Slurm reset tests passed ==="