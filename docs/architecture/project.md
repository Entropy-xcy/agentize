# Project Management

In `./metadata.md`, we discussed the metadata file `.agentize.yaml` that stores
the Github Project associated information:

```yaml
project:
   org: Synthesys-Lab
   id: 3
```

This section discusses how to manage a Github Project with an `agentize`d project.

## Create a Project

Create a new project and associate it with the current repo:
```bash
lol project --create
```

This will associate an existing project of a specific organization with the current repo:
```bash
lol project --associate Synthesys-Lab/3
```

## Kanban Design [^1]

We have two Kanban for plans (i.e. Github Issues) and implementations (i.e. Pull Requests):

For issues, we additionally have one more column `Status` as a `Single Selection` field:
- `Proposed`: The issue is proposed but not yet approved.
  - All the issues created by AI agents shall start with this status.
- `Approved`: The issue is approved and ready for implementation.
  - `\issue-to-impl` command will reject issues that are not `Approved`.
- `WIP`: The issue is being worked on.
  - This is an overengineering for further tracking. We can avoid multiple workers working on the same issue.
- `PR Created`: A pull request has been created for the issue.
- `Abandoned`: The issue has been abandoned, which can happen for two senarios:
  - After careful consideration, this addition does not make sense at issue phase.
  - After implementation, we find it is not a good idea.
- `Dependency`: The issue is blocked by other issues.
- `Done`: The issue has been completed and merged.

We use `Single Selection` field instead of labels because labels cannot be enforced strictly for mutual exclusivity.
For example, all 6 labels can be added to one issue at the same time, which makes no sense.

For pull requests, we use the default columns:
- `Initial Review`: The PR is created and waiting for review.
- `Changes Requested`: Changes are requested on the PR.
- `Dependency`: This PR is blocked for merging because of dependencies on other PRs.
- `Approved`: The PR is approved and ready to be merged.
- `Merged`: The PR has been merged.

[^1]: Kanban is **NOT** a Japanese word! 看 (kan4) means view, and 板 (ban3) means board. So Kanban literally means a "view board".