#!/usr/bin/env python3
"""PreToolUse hook - thin wrapper delegating to agentize.permission module.

This hook imports and invokes agentize.permission.determine() for all permission
decisions. Rules are defined in python/agentize/permission/rules.py.

Falls back to 'ask' on any import/execution errors.
"""

import json
import os
import sys
from pathlib import Path


def main():
    try:
        # Dual-mode: plugin mode uses CLAUDE_PLUGIN_ROOT, project-local uses relative path
        plugin_dir = os.environ.get("CLAUDE_PLUGIN_ROOT")
        if plugin_dir:
            sys.path.insert(0, os.path.join(plugin_dir, "python"))
        else:
            # Project-local mode: hooks/ is at .claude-plugin/hooks/, 2 levels below repo root
            repo_root = Path(__file__).resolve().parents[2]
            sys.path.insert(0, str(repo_root / "python"))
        from agentize.permission import determine
        result = determine(sys.stdin.read())
    except Exception as e:
        os.mkdir('.tmp', exist_ok=True)
        with open('.tmp/pre_tool_use_hook_error.log', 'w') as f:
            f.write("Error in PreToolUse hook:\n")
            import traceback
            traceback.print_exc(file=f)
            f.write(str(e))
        result = {"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "ask"}}
    print(json.dumps(result))


if __name__ == "__main__":o
    main()
