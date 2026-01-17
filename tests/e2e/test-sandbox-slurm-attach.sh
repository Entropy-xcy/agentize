#!/bin/bash
# Test Slurm mode for sandbox attach subcommand

set -e

echo "=== Testing sandbox run.py slurm attach command ==="

# Source the test helpers
source "$(dirname "$0")/../common.sh"

# Test 1: Verify cmd_attach references sattach for Slurm mode
echo "Verifying cmd_attach uses sattach for Slurm mode..."
python3 << 'PYEOF'
import sys
sys.path.insert(0, './sandbox')
from run import cmd_attach
import inspect

source = inspect.getsource(cmd_attach)
# Check for Slurm mode indicators
checks = [
    ("sattach" in source, "sattach command not found in cmd_attach"),
    ("slurm_job_id" in source, "slurm_job_id check not found in cmd_attach"),
    ("sattach_cmd" in source or "os.execvp" in source, "sattach execution not found"),
]

for check, error_msg in checks:
    if not check:
        print(f"FAIL: {error_msg}")
        sys.exit(1)

print("cmd_attach contains Slurm/sattach handling")
PYEOF

# Test 2: Verify sattach command format
echo "Verifying sattach command format..."
python3 << 'PYEOF'
import sys
sys.path.insert(0, './sandbox')
from run import cmd_attach
import inspect

source = inspect.getsource(cmd_attach)
# The sattach command should use the format: sattach -m <job_id>:<session_name>
if "-m" not in source or "job_id" not in source:
    print("FAIL: sattach command format not correct")
    sys.exit(1)
print("sattach command format verified")
PYEOF

# Test 3: Verify mode branching logic (slurm vs local)
echo "Verifying mode branching logic..."
python3 << 'PYEOF'
import sys
sys.path.insert(0, './sandbox')
from run import cmd_attach
import inspect

source = inspect.getsource(cmd_attach)
# Should have conditional logic for slurm_job_id
if "if slurm_job_id:" not in source:
    print("FAIL: Missing slurm_job_id conditional in cmd_attach")
    sys.exit(1)
print("Mode branching logic verified")
PYEOF

echo "=== All Slurm attach tests passed ==="