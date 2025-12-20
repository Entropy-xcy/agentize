# ${PROJECT_NAME}

TODO: Add project description

## Installation

```bash
# Install in development mode
pip install -e .

# Install with development dependencies
pip install -e .[dev]
```

## Usage

```bash
# Run the main program
python -m src.__NAME__.main

# Or after installation
python -c "from __NAME__.main import main; main()"
```

## Development

### Running Tests

```bash
# Run all tests
pytest tests/

# Run with coverage
pytest tests/ --cov=__NAME__ --cov-report=term-missing
```

### Code Quality

```bash
# Format code
black src/ tests/

# Lint code
ruff check src/ tests/

# Type checking
mypy src/
```

## Project Structure

```
.
├── src/
│   └── __NAME__/
│       ├── __init__.py
│       └── main.py
├── tests/
│   └── test_main.py
├── pyproject.toml
└── README.md
```

## License

MIT
