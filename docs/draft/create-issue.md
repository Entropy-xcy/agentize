# Create a skill of creating Github Issue

The issue should have the following structure:

```markdown

# [plan][tag]: A Brief Summary of the Issue

> The tag can be one of the tag from `git-msg-tags.md` file in `docs/` folder.
> or `[bug report]`, `[feature request]`, `[improvement]`.

> A plan prefix is required to indicate this plan is for development planning.

## Description

Provide a detailed description of this issue, including the related modules and the problem statement.

## Steps to Reproduce (optional, only for bug reports)

Provide a minimized step to reproduce the bug.

## Proposed Solution (optional, but mandatory for plan)

Provide a detailed proposed solution or plan to address the issue.

- The plan SHOULD NOT include code audits! Code audits are part of the result of planning.
- The plan SHOULD include the related files to be modified, added, or deleted.

### Anti-example

We would like to implement a skill of creating Github Issues. Implement it.

### Good Example

To implement a skill of creating Github Issues:
1. Create file `claude/skills/open-issue/SKILL.md` to define the skill.
2. Create file `claude/skills/open-issue/README.md` to provide documentation for the skill.
3. Create file `claude/skills/open-issue/scripts/create-issue.sh` to implement the script for creating issues via Github API.

## Related PR (optional, but mandatory when Proposed Solution is provided)

This can be a placeholder upon creating the issue, however, once the PR is created, update the PR# here.

```

# Tags

When creating an issue, the AI agent **MUST** determine which tag to use from the `docs/git-msg-tags.md` file.

# Commands

I am not an expert of `gh` CLI. Please help.