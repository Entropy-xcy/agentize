---
name: pr-templates
description: Templates for PR bodies and final summaries used by /issue2impl workflow. Contains standard and handoff PR templates, completion summaries. Use when creating PRs or reporting workflow completion.
allowed-tools: Read
---

# PR Templates Skill

This skill provides standardized templates for Pull Requests and workflow summaries in the `/issue2impl` workflow.

## When to Use

- **Phase 7.4**: Creating or updating PRs
- **Phase 9.2**: Generating final workflow summaries
- Any time a standardized PR body or summary is needed

## Template Variables

All templates use `$VARIABLE` placeholders. Replace these when applying templates:

| Variable | Description | Example |
|----------|-------------|---------|
| `$ISSUE_NUMBER` | GitHub issue number | `123` |
| `$DESCRIPTION` | Brief description of changes | `Add temporal PE scheduling` |
| `$HUMAN_COMMENTS_SECTION` | Addressed human comments | See format below |
| `$CHANGES_LIST` | File changes with descriptions | See format below |
| `$COMPONENT` | Component tag | `CC` |
| `$SUBAREA` | Feature sub-area tag | `Temporal` |
| `$PR_NUMBER` | PR number after creation | `456` |
| `$PR_URL` | Full PR URL | `https://github.com/...` |
| `$SCORE` | Code review score | `92` |
| `$ASSESSMENT` | Review assessment | `Approve` |
| `$HANDOFF_NUMBER` | Handoff issue number | `789` |
| `$HANDOFF_TITLE` | Handoff issue title | `[CC][Issue #123] Continue...` |
| `$ADDITIONAL_VERIFICATION` | Extra test plan steps | `Manual testing of edge cases` |
| `$PHASE_DESCRIPTION` | Description of partial work | `Implements core scheduling logic` |
| `$PR_STATUS` | Current PR status | `ready for merge` |
| `$REMOTE_STATUS` | Remote review status | `approved` |
| `$CHANGES_SUMMARY` | Brief summary of changes | `Modified 5 files...` |
| `$RELATED_ISSUES_UPDATES` | Issues updated by workflow | `#124: Added comment` |
| `$USER_ACTIONS` | Remaining actions for user | `Merge when CI passes` |
| `$PHASE` | Current phase number | `1` |
| `$TASK_COUNT` | Remaining task count | `3` |
| `$NEXT_TASK` | Next priority task | `Implement error handling` |
| `$HANDOFF_COMMAND` | Direct handoff instruction | `Continue implementation...` |
| `$PHASE_CHANGES` | Changes in current phase | `Added scheduling module` |

---

## PR Body Templates

### Standard PR (No Handoff)

Use when work fully resolves the issue:

```markdown
## Summary

Resolves #$ISSUE_NUMBER

$DESCRIPTION

## Human Comments Addressed

$HUMAN_COMMENTS_SECTION

## Changes Made

$CHANGES_LIST

## Test Plan

- [ ] `ninja -C build dsa-stack` builds without errors or warnings
- [ ] `ninja -C build check-dsa-stack` tests pass
- [ ] $ADDITIONAL_VERIFICATION

## Related Issues & PRs

| Relationship | Issue/PR | Description |
|--------------|----------|-------------|
| **Resolves** | #$ISSUE_NUMBER | Primary issue |

## Checklist

- [ ] Code follows project conventions
- [ ] Documentation updated if needed
- [ ] Commit messages follow git-commit-format.md
- [ ] All human comments on issue addressed
```

### Partial PR (With Handoff)

Use when work is split due to size threshold:

```markdown
## Summary

Partial implementation for #$ISSUE_NUMBER

$PHASE_DESCRIPTION

## Human Comments Addressed

$HUMAN_COMMENTS_SECTION

## Changes Made

$CHANGES_LIST

## Test Plan

- [ ] `ninja -C build dsa-stack` builds without errors or warnings
- [ ] `ninja -C build check-dsa-stack` tests pass

## Related Issues & PRs

| Relationship | Issue/PR | Description |
|--------------|----------|-------------|
| **Partial for** | #$ISSUE_NUMBER | Does not fully close |
| **Handoff** | #$HANDOFF_NUMBER | Continuation work |

## Checklist

- [ ] Code follows project conventions
- [ ] Documentation updated if needed
- [ ] Commit messages follow git-commit-format.md
- [ ] Human comments addressed or noted in handoff
```

---

## Human Comments Section Format

### If Human Comments Exist

```markdown
- **@username question**: How it was resolved
- **@username concern**: How it was addressed
- **@username suggestion**: Accepted/Declined with rationale
```

### If No Human Comments

```markdown
No human comments on the original issue.
```

---

## Changes List Format

```markdown
- **path/to/file.cpp**: What changed and why
- **path/to/file.h**: Interface updates for new feature
- **tests/test_file.cpp**: Added tests for new functionality
```

---

## Final Summary Templates

### Work Complete Summary

Use when work fully resolves the issue (Phase 9.2):

```markdown
## Work Complete for Issue #$ISSUE_NUMBER

### PR Status
- PR #$PR_NUMBER: $PR_URL
- Status: $PR_STATUS

### Code Review Results
- Local review: [$SCORE/100] $ASSESSMENT
- Remote review: $REMOTE_STATUS

### Changes Made
$CHANGES_SUMMARY

### Related Issues Updated
$RELATED_ISSUES_UPDATES

### Next Steps
$USER_ACTIONS
```

### Handoff Work Summary

Use when work is partial with handoff created (Phase 9.2):

```markdown
## Partial Work Complete for Issue #$ISSUE_NUMBER

### PR Status
- PR #$PR_NUMBER: $PR_URL (Phase $PHASE)
- Status: $PR_STATUS

### Code Review Results
- Local review: [$SCORE/100] $ASSESSMENT

### Handoff Created
- Handoff Issue: #$HANDOFF_NUMBER - $HANDOFF_TITLE
- Remaining tasks: $TASK_COUNT items
- Priority 1: $NEXT_TASK

### To Continue
Copy this to start the next session:
> $HANDOFF_COMMAND

### Changes in This Phase
$PHASE_CHANGES
```

---

## PR Title Format

PR titles must follow this format:

```
[$COMPONENT][$SUBAREA][Issue #$ISSUE_NUMBER] $DESCRIPTION
```

Or with single component:
```
[$COMPONENT][Issue #$ISSUE_NUMBER] $DESCRIPTION
```

**Examples**:
- `[CC][Temporal][Issue #123] Add temporal PE scheduling`
- `[SIM][CMSIS][Issue #45] Fix buffer overflow in allocator`
- `[TEST][Issue #85] Add unit tests for temporal PE`

**With Handoff**:
- `[CC][Temporal][Issue #123] Phase 1: Add scheduling infrastructure`

---

## Usage Notes

1. **Never include local code review scores in PR body** - These are internal metrics
2. **Always address human comments** - Even if just noting them in handoff
3. **Use relationship table** for clear issue/PR connections
4. **Test plan should be actionable** - Specific commands to run

---

## GitHub Auto-Linking Requirements

**CRITICAL**: For GitHub to automatically link PRs to issues (showing "linked pull requests" on the issue page), you MUST include a linking keyword line in the Summary section.

### Required Format

Per [GitHub documentation](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/linking-a-pull-request-to-an-issue), supported keywords are:
- `close`, `closes`, `closed`
- `fix`, `fixes`, `fixed`
- `resolve`, `resolves`, `resolved`

**Single issue syntax**: `KEYWORD #ISSUE-NUMBER` (case-insensitive)

**Multiple issues syntax**: Each issue requires its own keyword:
```markdown
Resolves #10, resolves #123, resolves #145
```

[WRONG] Single keyword for multiple issues:
```markdown
Resolves #10, #123, #145
```

[CORRECT] Keyword for each issue:
```markdown
Resolves #10, resolves #123, resolves #145
```

**Cross-repository syntax:**
```markdown
Resolves #10, resolves octo-org/octo-repo#100
```

### Template Compliance

The Standard PR template includes this line:
```markdown
## Summary

Resolves #$ISSUE_NUMBER    <- REQUIRED for auto-linking
```

For PRs resolving multiple issues, use:
```markdown
## Summary

Resolves #$ISSUE_NUMBER1, resolves #$ISSUE_NUMBER2, resolves #$ISSUE_NUMBER3

Brief description...
```

**This line MUST be present** - do not omit it when creating PRs.

### Why Both Keyword Line AND Table?

The PR templates include BOTH:
1. **`Resolves #XXX` line in Summary** - Enables GitHub auto-linking feature
2. **Related Issues & PRs table** - Provides human-readable documentation of relationships

The table alone does NOT trigger GitHub's auto-linking. All official GitHub examples use plain text format in the description.

### Common Mistake

[WRONG] Only using the table:
```markdown
## Summary

Brief description of changes.

## Related Issues & PRs

| Relationship | Issue/PR | Description |
|--------------|----------|-------------|
| **Resolves** | #123 | Primary issue |
```

[CORRECT] Including keyword line in Summary:
```markdown
## Summary

Resolves #123

Brief description of changes.

## Related Issues & PRs

| Relationship | Issue/PR | Description |
|--------------|----------|-------------|
| **Resolves** | #123 | Primary issue |
```

### Verification

After creating a PR, check the linked issue page - it should show the PR under "Linked pull requests". If not, ensure the `Resolves #XXX` line is present in the Summary section.
