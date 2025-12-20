---
name: ci-checks
description: Run local CI validation checks before pushing. Use when reviewing code, checking before commit/push, validating changes match CI requirements, or debugging CI failures. Runs formatting, special character, dialect definition, and markdown link checks.
allowed-tools: Read, Grep, Glob, Bash
---

# CI Validation Checks Skill

This skill runs the same checks that CI performs, allowing you to catch issues before pushing. Use this to validate your changes will pass CI.

## When to Use

- Before committing or pushing changes
- When you want to validate code matches CI requirements
- When reviewing your own or others' code locally
- When CI fails and you want to debug locally
- As part of code review process

## Available Checks

The DSA Stack CI runs these checks (in order of importance):

### 1. C++ Code Formatting Check

**Script**: `utils/checks/check-format.py`
**Purpose**: Ensures all C++ code follows LLVM style formatting
**Fix**: Run `make lint` to auto-format

```bash
python3 utils/checks/check-format.py --exclude tests/cicd
```

### 2. Special Character Check

**Script**: `utils/checks/check-special-chars.py`
**Purpose**: Detects CJK characters, emojis, or special symbols
**Allowed**: U+2699 (gear), U+26A0 (warning), U+2713 (check), U+2717 (x mark)

```bash
python3 utils/checks/check-special-chars.py --exclude tests/cicd
```

### 3. DSA Dialect Definition Check

**Script**: `utils/checks/check-dialect-def.py`
**Purpose**: Verifies all `dsa.{compute,memory,generate}_*` references are defined in dialect files
**Fix**: Add missing definitions to appropriate dialect files

```bash
python3 utils/checks/check-dialect-def.py --exclude tests/cicd,docs/draft
```

### 4. Markdown Link Reference Check

**Script**: `utils/checks/check-md-ref.py`
**Purpose**: Validates all markdown-style links point to existing files and sections
**Fix**: Update broken links or create missing sections

```bash
python3 utils/checks/check-md-ref.py --exclude tests/cicd
```

## Review Process

When performing CI validation:

1. **Run all checks** in sequence
2. **Report findings** with file paths and line numbers
3. **Provide fix suggestions** for each issue
4. **Summarize results** in a structured format

## Output Format

After running checks, provide a structured report:

```
## CI Validation Results

### Check Summary

| Check | Status | Issues |
|-------|--------|--------|
| Formatting | PASS/FAIL | N issues |
| Special Chars | PASS/FAIL | N issues |
| Dialect Defs | PASS/FAIL | N issues |
| Markdown Links | PASS/FAIL | N issues |

### Issues Found

[List each issue with file:line and description]

### Fix Commands

[Provide commands to fix issues]

### Result

[PASS/FAIL] - [Summary]
```

## Scoring Integration

### Separation of Concerns

**Code review** and **CI checks** are handled separately:

1. **Code review** (claude-automation.yml): Scores code quality using additive scoring
   - Focuses on code correctness, security, style, and documentation
   - Cannot check CI status (chicken-egg: review runs AS part of CI)

2. **CI checks** (this skill): Run independently via GitHub Actions
   - Formatting, special characters, dialect definitions, markdown links
   - Results enforced by GitHub's branch protection, not by code reviewer

### Code Review Scoring Model

Code review uses additive scoring (start at 0, earn points by verifying quality):

**Score-to-Assessment Mapping**:
- **90-100**: Approve - Excellent, ready to merge
- **81-89**: Approve with Minor Suggestion - Good with optional improvements
- **70-80**: Major changes needed - Code issues must be addressed
- **Below 70**: Reject - Fundamental problems requiring rework

**Blocking caps** (for code-related security issues only):
- Security vulnerabilities: cap at "Reject"
- Exposed secrets: cap at "Reject"

CI check failures are NOT caps for code review. They are enforced separately by GitHub's branch protection rules.

## Quick Commands

Run all checks at once:

```bash
python3 utils/checks/check-format.py --exclude tests/cicd && \
python3 utils/checks/check-special-chars.py --exclude tests/cicd && \
python3 utils/checks/check-dialect-def.py --exclude tests/cicd,docs/draft && \
python3 utils/checks/check-md-ref.py --exclude tests/cicd
```

Check only staged files (for pre-commit):

```bash
git diff --cached --name-only --diff-filter=ACM | grep -E '\.(cpp|h|hpp)$' | head -5
# Then run format check on those files
```

## Integration with CI

This skill mirrors the following CI workflows:
- `check-format.yml` - C++ formatting
- `check-special-chars.yml` - Special characters
- `check-docs.yml` - Dialect definitions and markdown links

If all local checks pass, CI should also pass (assuming no build/test failures).

## Related Components

- **code-reviewer agent**: For comprehensive skeptical code review with scoring

See [CI-REFERENCE.md](CI-REFERENCE.md) for detailed information about the CI system.
