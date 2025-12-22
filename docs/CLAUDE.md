# MyProject Documentation

TODO: Add project description

## Architecture

[TODO: Document your project architecture here]

### System Overview

```
[Add architecture diagram or description]
```

### Key Components

${COMPONENT_TAGS}

[TODO: Describe each component in detail]

#### [COMPONENT_A]
- **Purpose**: ...
- **Location**: ...
- **Dependencies**: ...

## Development Guide

### Prerequisites

- [TODO: List required dependencies, tools, versions]

### Environment Setup

```bash
source setup.sh
```

This will:
- Set up PATH and environment variables
- Load any required modules
- Verify tool availability

### Build

```bash
make build
```

[TODO: Describe what the build process does]

### Test

```bash
make test
```

The project uses a unified test infrastructure with project-local temporary directories (`.tmp/`) for better isolation and access control.

**Test Infrastructure:**
- Tests create isolated directories under `.tmp/` (not system `/tmp/`)
- Common test utilities in `tests/lib/` (test-utils.sh, assertions.sh)
- Unified `make test` target runs all SDK tests
- `make clean` removes `.tmp/` artifacts

**For detailed documentation:**
- See [tests/README.md](../tests/README.md) for test utilities reference
- See [Test Infrastructure Design](architecture/test-infrastructure.md) for architecture details

### Project Structure

```
project-root/
├── src/              # Source code
├── tests/            # Tests
├── docs/             # Documentation
├── .claude/          # AI workflow configuration
└── README.md         # Project overview
```

[TODO: Document your actual project structure]

## API Reference

[TODO: Document your public APIs, modules, or interfaces]

## Configuration

[TODO: Document configuration files and options]

## Troubleshooting

[TODO: Common issues and solutions]

## Contributing

[TODO: Add contribution guidelines]

### Code Style

[TODO: Document coding conventions]

### Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `make test`
5. Submit a pull request

## Resources

- Project Repository: [TODO: Add link]
- Issue Tracker: [TODO: Add link]
- Documentation: This file and `.claude/CLAUDE.md`

---

**Note**: This documentation is maintained alongside code. Update it when making architectural changes.
