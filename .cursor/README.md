# Cursor Configuration

This directory contains configuration files for Cursor IDE integration.

## Hooks Support

**Important**: Cursor hooks are only supported in the **UI (IDE) version**, not in the CLI version.

### UI Support

The Cursor IDE supports hooks through `.cursor/hooks.json`. These hooks execute at specific lifecycle events in the Cursor IDE workflow:

- **Event**: `beforeSubmitPrompt` - Executes before a prompt is submitted to Cursor
- **Configuration**: Defined in `.cursor/hooks.json`
- **Implementation**: See [hooks/README.md](hooks/README.md) for details

### CLI Limitation

The Cursor CLI does **not** support hooks. If you need hook functionality in a CLI environment, use Claude Code CLI instead, which supports hooks through `.claude-plugin/hooks/hooks.json`.

## Directory Structure

- `hooks.json` - Hook configuration for Cursor IDE
- `hooks/` - Hook implementation scripts
  - `before-prompt-submit.py` - Handles workflow initialization
  - `logger.py` - Shared logging utility

## Relationship to Claude Code

This directory provides Cursor IDE-specific hooks that replicate functionality available in Claude Code CLI hooks (located at `.claude-plugin/hooks/`). Both implementations:

- Use the same session state file format
- Support the same workflow commands (`/ultra-planner`, `/issue-to-impl`)
- Create session state files in the same location (`${AGENTIZE_HOME:-.}/.tmp/hooked-sessions/`)

The main difference is that Cursor hooks only work in the IDE, while Claude Code hooks work in the CLI.
