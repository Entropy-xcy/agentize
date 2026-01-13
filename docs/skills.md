# Skills

This document describes the skill definitions for Claude Code. Skills are reusable AI behaviors that can be invoked by commands or directly.

## Purpose

Skills provide modular, reusable AI capabilities that can be composed into larger workflows. Each skill is defined in a subdirectory under `skills/` with a `SKILL.md` file containing frontmatter and instructions.

## Configuration

Each skill subdirectory contains:
- `SKILL.md`: Skill definition with frontmatter (name, description) and instructions
- Optional supporting files (scripts, templates)

## Available Skills

### Git Operations

- `commit-msg`: Commit staged changes to git with meaningful messages
- `fork-dev-branch`: Create a development branch for a GitHub issue with standardized naming

### GitHub Integration

- `open-issue`: Create GitHub issues from conversation context with proper formatting and tag selection
- `open-pr`: Create GitHub pull requests from conversation context with proper formatting and tag selection

### Planning & Documentation

- `plan-guideline`: Create comprehensive implementation plans with detailed file-level changes and test strategies
- `doc-architect`: Generate comprehensive documentation checklist for feature implementation
- `document-guideline`: Documentation standards for design docs, folder READMEs, source code interfaces, and test cases

### Implementation

- `milestone`: Drive implementation forward incrementally with automatic progress tracking, LOC monitoring, and milestone checkpoint creation
- `move-a-file`: Move or rename a file while automatically updating all references in source code and documentation

### Review & Quality

- `review-standard`: Systematic code review checking documentation quality and promoting code reuse
- `shell-script-review`: Review shell scripts for shell-neutral behavior (bash/zsh compatibility)
- `external-consensus`: Synthesize consensus implementation plan from multi-agent debate reports using external AI review

### Debugging

- `debug-report`: Debug a codebase when a test case fails, and report bugs through GitHub Issues if unresolved
