# Available Options of "Agentize"

This document describes the options available for the `make agentize` command used to create an AI-powered SDK for your software development project.
All the options are `make` variables with prefix `AGENTIZE_`.

## AGENTIZE_PROJECT_NAME (required)

Specifies the name of your project. This name will be used in various parts of the generated SDK.

## AGENTIZE_PROJECT_PATH (required)

Specifies the file system path where the SDK will be created. Ensure that you have write permissions to this path.

## AGENTIZE_PROJECT_LANG (required)

Specifies the programming language of your project. Supported values include:
- `c` for C language
- `cxx` for C++ language
- `python` for Python language

TODO: Add more supported languages, including Java, Rust, Go, JavaScript, etc.

## AGENTIZE_SOURCE_PATH (optional)

This is an optional variable that specifies the path to the source code of your project.
If not provided, for C/C++ projects, it will provide both `src/` and `include/` directories under the specified `AGENTIZE_PROJECT_PATH` by default.
If specified, for example, LLVM standard uses `lib/` directory for source code, you can set this variable as follows:

```bash
make agentize \
   AGENTIZE_PROJECT_NAME="/path/to/your/project" \
   AGENTIZE_PROJECT_PATH="your_project_name" \
   AGENTIZE_PROJECT_LANG="cxx" \
   AGENTIZE_SOURCE_PATH="lib"
```

## AGENTIZE_MODE (optional)

Supported modes are:
- `init`: Initializes an SDK structure in the specified project path, and copy necessary template files.
- `update`: Only copies or updates the AI-related rules and files in the existing SDK structure.

## AGENTIZE_CLI (TODO)

Currently we only support `claude` code, later let's add `codex` and `cursor` as well.