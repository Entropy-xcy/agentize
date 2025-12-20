---
name: issue-templates
description: Templates for GitHub implementation issues created by /feat2issue workflow. Contains feature, sub-issue, documentation, and refactoring templates. Use when creating issues that describe requirements and design.
allowed-tools: Read
---

# Issue Templates Skill

This skill provides standardized templates for creating GitHub implementation issues in the `/feat2issue` workflow.

## When to Use

- **Phase 5.2**: Creating implementation issues from approved plan
- Any time implementation issues need to be created following project standards

## Core Principle

**Implementation issues describe REQUIREMENTS and DESIGN, not implementation code.**

| Include | Exclude |
|---------|---------|
| Clear acceptance criteria | Large code blocks |
| API signatures / interfaces | Step-by-step implementation |
| Design constraints | Boilerplate code |
| Test expectations | Anything that belongs in source |
| References to documentation | Detailed algorithms |

---

## Template Variables

All templates use `$VARIABLE` placeholders. Replace when applying:

| Variable | Description | Example |
|----------|-------------|---------|
| `$COMPONENT` | Primary component | `CC`, `SIM`, `MAPPER` |
| `$SUBAREA` | Feature sub-area | `Temporal`, `Memory` |
| `$TITLE` | Brief description | `Add temporal PE scheduling` |
| `$BACKGROUND` | Why this is needed | Context paragraph |
| `$GOALS` | List of objectives | Bullet points |
| `$EXPECTED_BEHAVIOUR` | Post-implementation state | What should work |
| `$ACCEPTANCE_CRITERIA` | Verification checkboxes | Specific criteria |
| `$INTERFACE_SPEC` | API signatures | Code signatures |
| `$TEST_EXPECTATIONS` | Test requirements | Test file paths |
| `$DOC_REFERENCE` | Design doc path | `docs/architecture/file.md` |
| `$DEPENDENCIES` | Prerequisite issues | `#123, #456` |
| `$PARENT_ISSUE` | Parent issue number | `#100` |

---

## Feature Implementation Template

Use for new features that add functionality.

### Title Format

```
[$COMPONENT][$SUBAREA] $TITLE
```

Or with single component:
```
[$COMPONENT] $TITLE
```

### Body Template

````markdown
## Problem Statement

$BACKGROUND

### Goals
$GOALS

---

## Expected Behaviour

After implementation:
$EXPECTED_BEHAVIOUR

### Example

```mlir
// Minimal example showing expected functionality
$EXAMPLE_CODE
```

---

## Acceptance Criteria

- [ ] $ACCEPTANCE_CRITERIA_1
- [ ] $ACCEPTANCE_CRITERIA_2
- [ ] $ACCEPTANCE_CRITERIA_3
- [ ] Tests pass: `llvm-lit -v build/tests/$TEST_PATH`
- [ ] Build succeeds: `ninja -C build dsa-stack`

---

## Interface Specification

### New Operations/Functions

```cpp
$INTERFACE_SPEC
```

### Key Data Structures

```cpp
$DATA_STRUCTURES
```

---

## Test Expectations

$TEST_EXPECTATIONS

### Test Files
- `tests/$TEST_FILE_1`: [What it tests]
- `tests/$TEST_FILE_2`: [What it tests]

---

## Design Reference

- **Design Document**: `$DOC_REFERENCE`
- **Draft Document**: `$DRAFT_REFERENCE`

**Important**: Review the design documentation before starting implementation.

---

## Dependencies & Relationships

- **Depends on**: $DEPENDENCIES
- **Design reference**: `$DOC_REFERENCE`
- **Related to**: $RELATED_ISSUES
````

---

## Sub-Issue Template

Use for subtasks of larger features. Must reference parent issue.

### Title Format

```
[$COMPONENT][$SUBAREA] $TITLE
```

Or with single component:
```
[$COMPONENT] $TITLE
```

### Body Template

````markdown
## Parent Issue

This is a sub-task of #$PARENT_ISSUE.

---

## Problem Statement

$BACKGROUND

This sub-issue focuses specifically on: $SPECIFIC_SCOPE

---

## Expected Behaviour

After this sub-issue is complete:
$EXPECTED_BEHAVIOUR

---

## Acceptance Criteria

- [ ] $ACCEPTANCE_CRITERIA_1
- [ ] $ACCEPTANCE_CRITERIA_2
- [ ] Tests pass: `llvm-lit -v build/tests/$TEST_PATH`
- [ ] Parent issue checklist item completed

---

## Files to Modify

| File | Change |
|------|--------|
| `$FILE_1` | $CHANGE_DESCRIPTION_1 |
| `$FILE_2` | $CHANGE_DESCRIPTION_2 |

---

## Interface (if applicable)

```cpp
$INTERFACE_SPEC
```

---

## Dependencies & Relationships

- **Parent**: #$PARENT_ISSUE
- **Depends on**: $DEPENDENCIES
- **Blocks**: $BLOCKS
- **Design reference**: `$DOC_REFERENCE`
````

---

## Documentation Issue Template

Use for documentation-focused work (not implementation).

### Title Format

```
[DOCS] $TITLE
```

### Body Template

````markdown
## Problem Statement

$BACKGROUND

### Documentation Goals
$GOALS

---

## Documentation Scope

### Files to Create
- `$NEW_FILE_1`: $DESCRIPTION
- `$NEW_FILE_2`: $DESCRIPTION

### Files to Update
- `$UPDATE_FILE_1`: $CHANGES
- `$UPDATE_FILE_2`: $CHANGES

---

## Content Outline

### $NEW_FILE_1

```markdown
# [Title]

## Overview
[Content overview]

## Key Concepts
[Concepts to cover]

## Design
[Design content]

## Examples
[Example content]
```

---

## Acceptance Criteria

- [ ] All specified files created/updated
- [ ] Documentation follows project guidelines
- [ ] All internal links working
- [ ] No placeholder content remaining
- [ ] Reviewed for accuracy

---

## Design Reference

- **Draft Document**: `$DRAFT_REFERENCE`
- **Related Issues**: $RELATED_ISSUES

---

## Dependencies

- **Depends on**: None (documentation first)
- **Blocks**: $BLOCKS (implementation issues)
````

---

## Refactoring Issue Template

Use for code restructuring without functional changes.

### Title Format

```
[$COMPONENT] Refactor: $TITLE
```

### Body Template

```markdown
## Problem Statement

$BACKGROUND

### Current State
$CURRENT_STATE

### Desired State
$DESIRED_STATE

---

## Scope

### Files to Modify
| File | Change Type |
|------|-------------|
| `$FILE_1` | $CHANGE_TYPE |
| `$FILE_2` | $CHANGE_TYPE |

### Out of Scope
- $OUT_OF_SCOPE_1
- $OUT_OF_SCOPE_2

---

## Acceptance Criteria

- [ ] Refactoring complete per design
- [ ] All existing tests still pass
- [ ] No functional changes introduced
- [ ] Build succeeds: `ninja -C build dsa-stack`
- [ ] Code follows project conventions

---

## Risk Mitigation

- **Breaking changes**: $BREAKING_CHANGE_RISK
- **Verification**: $VERIFICATION_APPROACH

---

## Design Reference

- **Design Document**: `$DOC_REFERENCE`
- **Motivation**: $MOTIVATION

---

## Dependencies

- **Depends on**: $DEPENDENCIES
- **Blocks**: $BLOCKS
```

---

## Test Issue Template

Use for adding test coverage.

### Title Format

```
[TEST][$SUBAREA] $TITLE
```

Or without sub-area:
```
[TEST] $TITLE
```

### Body Template

```markdown
## Problem Statement

$BACKGROUND

### Test Coverage Goals
$GOALS

---

## Test Plan

### Unit Tests

| Test File | Tests |
|-----------|-------|
| `$TEST_FILE_1` | $TEST_CASES_1 |
| `$TEST_FILE_2` | $TEST_CASES_2 |

### Integration Tests

| Test File | Scenario |
|-----------|----------|
| `$INTEGRATION_TEST_1` | $SCENARIO_1 |

### Edge Cases to Cover

- [ ] $EDGE_CASE_1
- [ ] $EDGE_CASE_2
- [ ] $EDGE_CASE_3

---

## Acceptance Criteria

- [ ] All specified tests implemented
- [ ] Tests pass: `llvm-lit -v build/tests/$TEST_PATH`
- [ ] Coverage meets expectations
- [ ] No flaky tests introduced

---

## Dependencies

- **Depends on**: $FEATURE_ISSUE (feature must be implemented first)
- **Design reference**: `$DOC_REFERENCE`
```

---

## Label Reference

**Note**: Titles use clean tags like `[CC]`, `[Temporal]`, but labels use `L1:` and `L2:` prefixes for GitHub Project tracking.

### Component Labels (L1)

| Title Tag | Label | Description |
|-----------|-------|-------------|
| `[CC]` | `L1:CC` | Compiler |
| `[SIM]` | `L1:SIM` | Simulator |
| `[MAPPER]` | `L1:MAPPER` | Mapper |
| `[HWGEN]` | `L1:HWGEN` | Hardware Generator |
| `[TEST]` | `L1:TEST` | Testing |
| `[DOCS]` | `L1:DOCS` | Documentation |
| `[PERF]` | `L1:PERF` | Performance |

### Sub-Area Labels (L2)

| Title Tag | Label | Description |
|-----------|-------|-------------|
| `[Temporal]` | `L2:Temporal` | Temporal PE features |
| `[Memory]` | `L2:Memory` | Memory subsystem |
| `[CMSIS]` | `L2:CMSIS` | CMSIS-DSP workloads |
| `[Greedy]` | `L2:Greedy` | Greedy scheduling |

### Priority Labels

| Label | Description | Color |
|-------|-------------|-------|
| `priority:high` | High priority | Red |
| `priority:medium` | Medium priority | Yellow |
| `priority:low` | Low priority | Green |

### Type Labels

| Label | Description |
|-------|-------------|
| `enhancement` | New feature |
| `implementation` | Implementation work |
| `documentation` | Documentation |
| `refactor` | Code restructuring |
| `test` | Test coverage |

---

## Quality Checklist

Before creating an issue, verify:

- [ ] Title follows `[Component][SubArea] Description` format (no L1:/L2: prefixes)
- [ ] Problem statement is clear and concise
- [ ] Acceptance criteria are specific and verifiable
- [ ] Interface spec uses signatures only, not implementation
- [ ] Test expectations are included
- [ ] Design documentation is referenced
- [ ] Dependencies are listed
- [ ] Issue is appropriately sized (< 1000 lines expected)
- [ ] No large code blocks (only signatures/interfaces)

---

## Anti-Patterns to Avoid

### Too Much Code

**Bad:**
````markdown
## Implementation

```cpp
void processData(Buffer& buf) {
    for (int i = 0; i < buf.size(); i++) {
        // 50 lines of implementation...
    }
}
```
````

**Good:**
````markdown
## Interface

```cpp
// Process buffer data according to design spec
void processData(Buffer& buf);
```
````

### Vague Acceptance Criteria

**Bad:**
- [ ] Code works correctly
- [ ] Tests pass

**Good:**
- [ ] `processData()` handles empty buffer without crash
- [ ] Tests pass: `llvm-lit -v build/tests/Data/process_test.mlir`

### Missing Dependencies

**Bad:**
```markdown
## Dependencies
None
```

**Good:**
```markdown
## Dependencies
- **Depends on**: #123 (Buffer interface must be defined first)
- **Design reference**: `docs/architecture/data-processing.md`
```

---

## Usage Notes

1. **Choose the right template** based on issue type
2. **Replace all $VARIABLES** with actual values
3. **Remove sections** that don't apply (but keep core sections)
4. **Add sections** if needed for clarity
5. **Verify against checklist** before creating
