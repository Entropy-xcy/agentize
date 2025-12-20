# CI Workflow Reference

This document provides detailed information about the DSA Stack CI system for the CI checks skill.

## CI Architecture Overview

The DSA Stack CI uses a smart decision engine to optimize build times:

```
ci-triggers.yml (decision logic)
├── rhel9-build-and-test.yml (native RHEL9)
├── ubuntu24-build-and-test.yml (native Ubuntu)
├── podman-ubuntu24.yml (containerized)
├── podman-almalinux9.yml (containerized)
└── check-docs.yml (documentation validation)

Pre-merge checks (always run):
├── check-format.yml (C++ formatting)
├── check-special-chars.yml (special characters)
└── claude-automation.yml (AI code review)
```

## Check Script Details

### check-format.py

**Location**: `utils/checks/check-format.py`
**Dependencies**: `clang-format-20`
**File Types**: `.cpp`, `.h`, `.hpp`

The script:
1. Finds all C++ files (excluding specified directories)
2. Runs `clang-format --dry-run` on each file
3. Reports files that would be modified

**Common Issues**:
- Indentation inconsistencies
- Line length violations
- Brace placement
- Whitespace issues

**Fix**: `make lint` runs clang-format on all source files

### check-special-chars.py

**Location**: `utils/checks/check-special-chars.py`
**Dependencies**: `ripgrep` (rg)
**File Types**: All text files

The script detects:
- CJK characters (Chinese, Japanese, Korean)
- Emojis and pictographs
- Special Unicode symbols

**Allowed Characters** (not flagged):
- U+2699 (gear symbol)
- U+26A0 (warning symbol)
- U+2713 (check mark)
- U+2717 (x mark)

**Common Sources**:
- Copy-pasted code from documentation
- Comments with non-ASCII characters
- String literals with special characters

### check-dialect-def.py

**Location**: `utils/checks/check-dialect-def.py`
**Dependencies**: Python 3.11+
**File Types**: `.md` (markdown documentation)

The script validates:
- `dsa.compute_*` operations are defined in compute dialect
- `dsa.memory_*` operations are defined in memory dialect
- `dsa.generate_*` operations are defined in generate dialect

**Pattern Matching**:
```
dsa\.compute_\w+
dsa\.memory_\w+
dsa\.generate_\w+
```

**Common Issues**:
- New operations referenced before dialect definition
- Typos in operation names
- Outdated documentation referencing removed operations

### check-md-ref.py

**Location**: `utils/checks/check-md-ref.py`
**Dependencies**: Python 3.11+
**File Types**: `.md` (markdown files)

The script validates:
- File references: markdown links point to existing files
- Section references: links with anchors point to existing sections
- Relative paths are resolved correctly

**Pattern Matching**:
```
\[([^\]]+)\]\(([^)]+\.md)(#[^)]+)?\)
```

**Common Issues**:
- Broken links after file moves/renames
- References to deleted sections
- Case sensitivity mismatches

## CI Triggers Logic

The CI uses smart skip logic:

**Skip E2E builds when**:
1. Only documentation files changed AND
2. Previous commit's CI was successful

**Documentation file extensions** (from `ci-triggers.yml`):
- `.md`, `.txt`, `.rst`, `.adoc`
- `.pdf`, `.doc`, `.docx`
- `.png`, `.jpg`, `.jpeg`, `.gif`, `.svg`

**Never skip**:
- Format check
- Special character check
- Claude code review (for PRs)

## Test Detection Framework

CI includes a test detection mechanism to ensure checks work:

**Test Directories**:
- `tests/cicd/test-dialect-def/` - Intentionally broken dialect references
- `tests/cicd/test-md-ref/` - Intentionally broken markdown links

**Validation Process**:
1. Run check WITHOUT `--exclude` - must detect test errors
2. Run check WITH `--exclude tests/cicd` - must pass for production

This ensures the check scripts remain effective and don't have false negatives.

## Claude AI Review Integration

The CI includes automated AI code review:

**Workflow**: `claude-automation.yml`
**Modes**:
- `claude-question`: Q&A for issues and PR comments with "question"
- `claude-review`: Full code review with scoring

### Scoring Philosophy

**Score Computation** uses additive scoring starting from zero:
- Reviewer starts at 0 and earns points by verifying quality
- Each category has a maximum (e.g., Code Quality: 25 points)
- Points are awarded based on evidence of quality, not deducted from a perfect score

**Threshold Gating** is a separate pass/fail decision:
- After the score is calculated, a threshold determines if the PR can merge
- This is independent of how the score was computed

**Separation of Concerns**:
- Code review scores code quality only (cannot check CI status - chicken-egg problem)
- CI checks (build, tests, linting) are enforced by GitHub's branch protection, not code review

**Blocking Issue Caps** (for code-related security issues only):
- Security vulnerabilities: cap assessment at "Reject"
- Exposed secrets: cap assessment at "Reject"
- Example: Score of 92 with exposed secrets results in "[92/100] Reject"
- Caps do NOT modify the score, only the assessment label

**Review Output Format**:
```
[XX/100] Assessment
```

Where Assessment is one of:
- `Approve` (90-100)
- `Approve with Minor Suggestion` (81-89)
- `Major changes needed` (70-80)
- `Reject` (below 70)

**Pass Criteria** (for PR merge, separate from scoring):
- Score >= 81
- Assessment is `Approve` or `Approve with Minor Suggestion`

## Local vs CI Environment Differences

| Aspect | Local | CI |
|--------|-------|-----|
| clang-format | System version | clang-format-20 |
| Python | System version | 3.11 |
| DEV_DSA_STACK | May be set | Always unset |
| Submodules | May be initialized | Not initialized for checks |

**Important**: Unset `DEV_DSA_STACK` before running checks locally to match CI behavior:
```bash
unset DEV_DSA_STACK
```
