# Agentize your development workflow

This work aims at creating a framework to easily deploy AI agents to automate your development.

## Common Interface

By complying your build and development tools in a common interface, this framework can be
easilly depolyed as a part of your project development workflow.

### Makefile

There should be a `Makefile` located at the root of your project, exposing the following targets:

- Setup the development environment:
```bash
make env-script # This step does not change the environment, it generates a `setup.sh` script
source setup.sh
```

- Build all developed software components:
```bash
make build-all
```

- Test all developed software components:
```bash
make test-all
```

### Project Organization

- The agent rule will force that each source code unit, including but not limited to
  `.c`, `.cpp`, `.py`, `.js`, `.java` files, always has a corresponding `.md` file with
  the same prefix located in the same folder.
- `docs/`: Documenting high-level knowledge about the project, including architectures,
   design decisions, and the general purpose of the project.
- `tests/`: Unit and integration tests for the project components.
- `agentize/`: This project will be a submodule located at the root of your project.


### Installation

Assuming you have already put this project as a submodule at the root of your project,
run the following commands in the root of **this project**:

```bash
make install
```

This will create `.claude` folder for you as well as installing all the agent rules for you.

## Agents

- `/feat2issue`: Descript the feature request, and discuss the implementation details with the
  agent, and then a Github issue will be created to summarize the discussion for future reference.

- `/issue2impl`: Giving a Github issue number, the agent will read the issue
  description and comments, and then fork a new branch for development.
  After the development, another subagent will be triggered to review the changes
  and merge the branch back upon approval.
