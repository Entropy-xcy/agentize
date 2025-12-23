# AI-powered SDK for Software Development

## Quick Start

1. Clone this repository:
```bash
git clone https://github.com/SyntheSys-Lab/agentize.git
```
2. Use this repository to create an SDK for your project.
```
make agentize \
   AGENTIZE_PROJECT_NAME="your_project_name" \
   AGENTIZE_PROJECT_PATH="/path/to/your/project" \
   AGENTIZE_PROJECT_LANG="c" \
   AGENTIZE_MODE="init"
```

This will create an initial SDK structure in the specified project path.
For more details of the variables and options available, refer to our
[usage document](./docs/OPTIONS.md).