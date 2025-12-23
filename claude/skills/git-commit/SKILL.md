---
name: git-commit
description: Commit the staged changes to git with meaningful messages.
---

# Git Commit

This skill instructs AI agent on how to commit staged changes to a git repository with
meaningful commit messages. The commit message should clearly describe the changes made.
If the changes are less than 20 lines, a short commit message is sufficient.
Otherwise, a full commit message is required.

## Full Commit Message

The commit message should follow the structure below:

```plaintext
[tag]: A brief summary of the changes of this commit.

path/to/file/affected1: A brief description of changes made to this file.
path/to/file/affected2: A brief description of changes made to this file.
...

If needed, provide addtional context and explanations about the changes made in this commit.
It is preferred to mention the related Github issue if applicable.
```

## Short Commit Message

The commit message should follow the structure below:

```plaintext
[tag]: A brief summary of the changes of this commit.
```

## Tags

A `git-msg-tags.md` file should appear in `{ROOT_PROJ}/docs/git-msg-tag.md` which
defines the tags related to the corresponding modules or modifications. The AI agent
**MUST** refer to this file to select the appropriate tag for the commit message.
If not, reject the commit, and ask user to provide a list of tags in `docs/git-msg-tag.md`,
by showing the example format below:

Please provide a `docs/git-msg-tags.md`, which can be as simple as the following example: 

```markdown
# Git Commit Message Tags
- `[core]`: Changeing the core functionality of the project.
- `[docs]`: Changing the documentation.
- `[tests]`: Changes test cases.
  - Use it only when solely changing the test cases! Do not mix with other changes with tests!
- `[build]`: Changes related to build scripts or configurations.
```

## Ownership

Any AI agent **SHALL NOT** claim the co-authorship of the commit with the user.
It is the user who is **FULLY** responsible for the commit.

## Pre-commit Check

When **committing** the changes, the AI agent **MUST** ensure that `--no-verify` is
**NOT** used to bypass any pre-commit hooks. This ensures the correctness and quality
of the code being committed.

<---! TODO: Later we should partially allow `--no-verify` bypassing under "milestones" --->
<---! Have milestones implemented later --->
