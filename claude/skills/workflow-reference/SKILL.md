---
name: workflow-reference
description: Reference tables and decision guides for /issue2impl workflow. Contains size thresholds, L1/L2 tag inference, and error handling. Use when making workflow decisions about sizing, tagging, or error recovery.
allowed-tools: Read
---

# Workflow Reference Skill

This skill provides decision tables and reference guides for the `/issue2impl` workflow.

## When to Use

- **Phase 4**: Size estimation and planning decisions
- **Phase 5**: Monitoring implementation size
- **Phase 6**: Size re-check after review fixes
- **Phase 7**: L1/L2 tag inference for PR titles
- **Any phase**: Error recovery guidance

---

## Size Management

### Planning Phase Thresholds (Phase 4.2)

Use when estimating scope during planning:

| Estimated Lines | Classification | Action |
|-----------------|----------------|--------|
| < 500 | Small | Proceed normally |
| 500-1000 | Medium | Proceed, monitor size |
| 1000-1500 | Large | Consider splitting into phases |
| > 1500 | Too Large | **Must split** - plan for handoff |

**If estimated > 1000 lines**:
1. Identify logical breakpoints in the work
2. Plan Phase 1 deliverables (subset that can be PR'd)
3. Note remaining work for potential handoff

### Implementation Phase Thresholds (Phase 5.3)

Use when monitoring actual changes during implementation:

| Current Lines | Status | Action |
|---------------|--------|--------|
| < 800 | Green | Continue normally |
| 800-1000 | Yellow | Approach completion or find breakpoint |
| 1000-1200 | Orange | **Consider stopping for handoff** |
| > 1200 | Red | **Stop and create handoff** |

**Size check command**:
```bash
# Committed changes vs main
git diff origin/main...HEAD --stat | tail -1

# Uncommitted changes
git diff --stat | tail -1
```

### Size Management Flow

```
Planning Phase:
  Estimate > 1000 lines? --> Plan for potential split

Implementation Phase:
  Check size periodically:
  - < 800: Continue
  - 800-1000: Wrap up or find breakpoint
  - 1000-1200: Consider stopping
  - > 1200: Must stop, create handoff

After Review Fixes:
  Re-check size (fixes may push over threshold)

Commit Phase:
  If handoff triggered --> Partial PR + handoff issue
```

---

## Component Tag Inference Guide

### From Issue Labels

Labels use `L1:` and `L2:` prefixes for GitHub Project tracking:
```bash
gh issue view $ISSUE_NUMBER --json labels --jq '.labels[].name' | grep -E "^L[12]:"
```

When creating titles, extract the component name (e.g., `L1:CC` → `[CC]`).

### From Modified Files (Phase 7.4)

| Modified Path Pattern | Title Tag | Label |
|----------------------|-----------|-------|
| `lib/dsa/Dialect/` | `[CC]` | `L1:CC` |
| `tools/dsa-cc/` | `[CC]` | `L1:CC` |
| `lib/dsa/Simulation/` | `[SIM]` | `L1:SIM` |
| `tools/dsa-sim/` | `[SIM]` | `L1:SIM` |
| `lib/dsa/Mapper/` | `[MAPPER]` | `L1:MAPPER` |
| `tools/dsa-mapper/` | `[MAPPER]` | `L1:MAPPER` |
| `lib/dsa/HWGen/` | `[HWGEN]` | `L1:HWGEN` |
| `tools/dsa-hwgen/` | `[HWGEN]` | `L1:HWGEN` |
| `tests/` | `[TEST]` | `L1:TEST` |

**Inference command**:
```bash
git diff --stat origin/main...HEAD | head -10
```

### Sub-Area Tag Examples

| Feature Area | Title Tag | Label |
|--------------|-----------|-------|
| Temporal processing | `[Temporal]` | `L2:Temporal` |
| Memory subsystem | `[Memory]` | `L2:Memory` |
| CMSIS-DSP workloads | `[CMSIS]` | `L2:CMSIS` |
| SPEC2017 benchmarks | `[SPEC2017]` | `L2:SPEC2017` |
| Greedy scheduling | `[Greedy]` | `L2:Greedy` |
| Simulated annealing | `[SimAnneal]` | `L2:SimAnneal` |
| LLM-based scheduling | `[LLM]` | `L2:LLM` |
| Reinforcement learning | `[RL]` | `L2:RL` |

---

## Error Handling Reference

### Workflow Error Actions

| Error | Phase | Action |
|-------|-------|--------|
| Build failure | 5, 7 | Stop, report error, do not continue |
| Test failure (pre-commit) | 7.0 | Fix failures, return to Phase 6.1 |
| Review cycle limit (3x) | 6.3 | Summarize issues, ask user |
| GitHub API error | Any | Report error, suggest manual steps |
| Remote review timeout | 8 | Proceed, note review may be pending |
| Size threshold exceeded | 5.3 | Create handoff, complete current phase |

### Pre-Commit Gate Failures

| Gate Status | Recovery Action |
|-------------|----------------|
| FAIL (build errors) | Return to Phase 6.1, fix errors |
| FAIL (DSA-Stack warnings) | Return to Phase 6.1, fix warnings |
| FAIL (test failures) | Return to Phase 6.1, fix tests |

### Code Review Recovery

| Score | Cycle | Action |
|-------|-------|--------|
| >= 81 | Any | Proceed to Phase 7 |
| < 81 | 1-2 | Fix issues, re-review |
| < 81 | 3 | Escalate to user |

---

## Validation Quick Reference

### Input Validation (Phase 1)

| Check | Command | Pass Condition |
|-------|---------|----------------|
| Issue number | `$1` exists | Non-empty, numeric |
| Branch name | `git branch --show-current` | Contains issue number |
| Dependencies | `gh issue view` + parse body | All referenced issues CLOSED |

### Pre-Commit Checks (Phase 7.0)

| Check | Command | Pass Condition |
|-------|---------|----------------|
| Build | `ninja -C build dsa-stack` | No errors, no DSA-Stack warnings |
| Tests | `ninja -C build check-dsa-stack` | All tests pass |

---

## Component Integration Reference

| Component | Type | Purpose | Phase |
|-----------|------|---------|-------|
| `issue-analyzer` | Agent | Issue and codebase analysis | 2 |
| `doc-architect` | Agent | Documentation brainstorming | 3 |
| `code-reviewer` | Agent | Skeptical code review with scoring | 6 |
| `handoff-generator` | Agent | Create continuation issues | 5.4 |
| `project-manager` | Agent | GitHub Project integration (issues only, NOT PRs) | 5.4 |
| `pre-commit-gate` | Agent | Build and test verification | 7.0 |
| `ci-checks` | Skill | CI validation checks | 6 |
| `pr-templates` | Skill | PR body templates | 7.5, 9 |
| `workflow-reference` | Skill | This skill | 4, 5, 7 |
| `/git-commit` | Command | Commit creation | 7.1 |
| `/resolve-pr-comment` | Command | PR feedback resolution | 8.3 |
| `/update-related-issues` | Command | Issue chain updates | 9.1 |
| `/gen-handoff` | Command | Manual handoff | Any |
