#!/bin/bash
# Test Slurm mode for sandbox rm subcommand

set -e

echo "=== Testing sandbox run.py slurm rm command ==="

# Source the test helpers
source "$(dirname "$0")/../common.sh"

# Test 1: Verify cmd_rm references cancel_slurm_job for Slurm mode
echo "Verifying cmd_rm uses cancel_slurm_job for Slurm mode..."
python3 << 'PYEOF'
import sys
sys.path.insert(0, './sandbox')
from run import cmd_rm
import inspect

source = inspect.getsource(cmd_rm)
# Check for Slurm mode indicators
checks = [
    ("cancel_slurm_job" in source, "cancel_slurm_job function not called in cmd_rm"),
    ("slurm_job_id" in source, "slurm_job_id check not found in cmd_rm"),
]

for check, error_msg in checks:
    if not check:
        print(f"FAIL: {error_msg}")
        sys.exit(1)

print("cmd_rm contains Slurm/cancel_slurm_job handling")
PYEOF

# Test 2: Verify cancel_slurm_job function
echo "Verifying cancel_slurm_job function..."
python3 << 'PYEOF'
import sys
sys.path.insert(0, './sandbox')
from run import cancel_slurm_job
import inspect

source = inspect.getsource(cancel_slurm_job)
if "scancel" not in source:
    print("FAIL: cancel_slurm_job does not call scancel")
    sys.exit(1)
print("cancel_slurm_job function verified")
PYEOF

# Test 3: Verify mode branching logic (skip container operations for Slurm)
echo "Verifying mode branching logic..."
python3 << 'PYEOF'
import sys
sys.path.insert(0, './sandbox')
from run import cmd_rm
import inspect

source = inspect.getsource(cmd_rm)
# Should have conditional logic for slurm_job_id
# When slurm_job_id exists, should skip container operations
if "if slurm_job_id:" not in source:
    print("FAIL: Missing slurm_job_id conditional in cmd_rm")
    sys.exit(1)
print("Mode branching logic verified")
PYEOF

# Test 4: Verify work directory is still removed for Slurm
echo "Verifying work directory removal for Slurm mode..."
python3 << 'PYEOF'
import sys
sys.path.insert(0, './sandbox')
from run import cmd_rm
import inspect

source = inspect.getsource(cmd_rm)
# work_dir removal should happen regardless of mode
if "remove_work_dir" not in source:
    print("FAIL: remove_work_dir not found in cmd_rm")
    sys.exit(1)
print("Work directory removal verified")
PYEOF

echo "=== All Slurm rm tests passed ==="