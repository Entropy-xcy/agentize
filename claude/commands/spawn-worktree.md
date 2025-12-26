---
name: spawn-worktree
description: Create or reuse worktree for an issue and print next-step instructions
argument-hint: <issue-number>
---

# Spawn Worktree Command

Create or reuse a worktree for a GitHub issue and print explicit next-step instructions for continuing work in the worktree.

## Invocation

```
/spawn-worktree <issue-number>
```

**Arguments:**
- `issue-number` (required): GitHub issue number to create/reuse worktree for

## Inputs

**From arguments:**
- Issue number (required via `$ARGUMENTS`)

**From git:**
- Existing worktrees (via `git worktree list --porcelain`)
- Current repository root path

**From GitHub (via `scripts/worktree.sh`):**
- Issue title (for branch naming when creating new worktree)

## Outputs

**Terminal output:**
- Worktree path (absolute or relative)
- Next-step instructions:
  1. Open a new terminal at the worktree path
  2. Start Claude Code: `claude`
  3. Run: `/issue-to-impl <N>`

**Side effects:**
- Creates new worktree at `trees/issue-<N>-<title>/` if none exists
- Creates branch `issue-<N>-<title>` if none exists

## Workflow

### Step 1: Parse Issue Number

Extract issue number from `$ARGUMENTS`:

```bash
issue_number="$ARGUMENTS"
```

If `$ARGUMENTS` is empty or invalid:
```
Error: Issue number required

Usage: /spawn-worktree <issue-number>
Example: /spawn-worktree 42
```
Stop execution.

### Step 2: Check for Existing Worktree

Query existing worktrees for this issue:

```bash
git worktree list --porcelain | grep "^worktree " | cut -d' ' -f2 | grep "trees/issue-${issue_number}-"
```

**Porcelain format example:**
```
worktree /path/to/repo
HEAD abc123def456
branch refs/heads/main

worktree /path/to/repo/trees/issue-42-add-feature
HEAD def456abc123
branch refs/heads/issue-42-add-feature
```

Extract the worktree path from lines matching `trees/issue-{N}-*`.

**If worktree exists:**
- Store the path
- Skip to Step 4 (Print Instructions)

**If no worktree exists:**
- Continue to Step 3

### Step 3: Create Worktree

Use the existing `scripts/worktree.sh` helper to create the worktree:

```bash
./scripts/worktree.sh create ${issue_number}
```

**The script will:**
- Fetch issue title from GitHub via `gh issue view`
- Create branch `issue-{N}-{slugified-title}`
- Create worktree at `trees/issue-{N}-{slugified-title}/`
- Bootstrap `CLAUDE.md` into the worktree

**Error handling:**

If `scripts/worktree.sh` fails:
```
Error: Failed to create worktree for issue #${issue_number}

Possible causes:
- GitHub CLI (gh) not authenticated
- Issue #${issue_number} does not exist
- Worktree already exists

Try running manually:
  ./scripts/worktree.sh create ${issue_number}
```
Stop execution.

**After successful creation:**
- Re-query worktrees to get the exact path:
  ```bash
  git worktree list --porcelain | grep "^worktree " | cut -d' ' -f2 | grep "trees/issue-${issue_number}-"
  ```

### Step 4: Print Next-Step Instructions

Display clear, actionable next steps to the user:

```
Worktree ready for issue #${issue_number}

Path: ${worktree_path}

Next steps:
1. Open a new terminal at the worktree path:
   cd ${worktree_path}

2. Start Claude Code:
   claude

3. Run the implementation command:
   /issue-to-impl ${issue_number}

Note: Each worktree is its own project root. Do not use 'cd' once in Claude Code.
```

**Important:** The instructions are explicit and manual - no terminal automation, no hooks, no automatic spawning. The user must perform these steps in a new terminal session.

## Error Handling

### Missing Issue Number

If `$ARGUMENTS` is empty:
```
Error: Issue number required

Usage: /spawn-worktree <issue-number>
Example: /spawn-worktree 42
```

### Invalid Issue Number Format

If `$ARGUMENTS` is not a number:
```
Error: Invalid issue number "${ARGUMENTS}"

Issue number must be a positive integer.
Example: /spawn-worktree 42
```

### Git Not a Repository

If `git worktree list` fails:
```
Error: Not in a git repository

The /spawn-worktree command must be run from a git repository root.
```

### Worktree Creation Failure

If `scripts/worktree.sh create` fails:
```
Error: Failed to create worktree for issue #${issue_number}

Common causes:
- Issue does not exist on GitHub
- GitHub CLI (gh) not authenticated (run: gh auth login)
- Worktree path already exists
- Network connection issue

Try creating manually:
  ./scripts/worktree.sh create ${issue_number}

Or provide a custom description:
  ./scripts/worktree.sh create ${issue_number} my-feature
```

## Design Rationale

### Why Not Automate Terminal Spawning?

**Rejected approaches:**
- **tmux automation**: Environment-specific, requires tmux to be running
- **osascript (macOS)**: Platform-specific, unreliable across terminal emulators
- **wezterm/kitty APIs**: Requires specific terminal emulator
- **Hooks and handoff files**: Adds complexity without native support

**Chosen approach:**
- Print explicit, copy-ready instructions
- Let user open terminal manually at worktree path
- Clear, recoverable, works in all environments

### Why Reuse Existing Worktrees?

Prevents errors from attempting to create duplicate worktrees and provides a consistent workflow whether the worktree exists or not.

### Why Separate from /issue-to-impl?

`/spawn-worktree` handles the worktree creation step only, keeping responsibilities clear:
- `/spawn-worktree`: Create/reuse worktree, print instructions
- `/issue-to-impl`: Implement the issue (docs, tests, code, milestones)

Users can run them separately for flexibility or together as documented workflow.

## Examples

### Example 1: Creating New Worktree

```
User: /spawn-worktree 84

Agent: Creating worktree for issue #84...
Agent: [Runs: ./scripts/worktree.sh create 84]
Agent: Worktree created successfully

Worktree ready for issue #84

Path: trees/issue-84-add-feature

Next steps:
1. Open a new terminal at the worktree path:
   cd trees/issue-84-add-feature

2. Start Claude Code:
   claude

3. Run the implementation command:
   /issue-to-impl 84

Note: Each worktree is its own project root. Do not use 'cd' once in Claude Code.
```

### Example 2: Reusing Existing Worktree

```
User: /spawn-worktree 42

Agent: Checking for existing worktree for issue #42...
Agent: Found existing worktree at trees/issue-42-bugfix

Worktree ready for issue #42

Path: trees/issue-42-bugfix

Next steps:
1. Open a new terminal at the worktree path:
   cd trees/issue-42-bugfix

2. Start Claude Code:
   claude

3. Run the implementation command:
   /issue-to-impl 42

Note: Each worktree is its own project root. Do not use 'cd' once in Claude Code.
```

### Example 3: Error - GitHub Not Authenticated

```
User: /spawn-worktree 99

Agent: Creating worktree for issue #99...
Agent: [Runs: ./scripts/worktree.sh create 99]

Error: Failed to create worktree for issue #99

Common causes:
- Issue does not exist on GitHub
- GitHub CLI (gh) not authenticated (run: gh auth login)
- Worktree path already exists
- Network connection issue

Try creating manually:
  ./scripts/worktree.sh create 99

Or provide a custom description:
  ./scripts/worktree.sh create 99 my-feature
```
