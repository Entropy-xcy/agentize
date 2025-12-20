# ${PROJECT_NAME}

TODO: Add project description

## Build

```bash
# Configure
cmake -B build -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build build

# Install (optional)
cmake --install build --prefix /usr/local
```

## Usage

```bash
# Run the program
./build/main
```

## Development

### Running Tests

```bash
# Build and run tests
cmake --build build
cd build && ctest --output-on-failure
```

### Build Types

```bash
# Debug build (with debugging symbols)
cmake -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build

# Release build (optimized)
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
```

## Project Structure

```
.
├── include/
│   └── __NAME__/
│       └── hello.h        # Public headers
├── src/
│   ├── hello.c            # Implementation
│   └── main.c             # Entry point
├── tests/
│   └── test_hello.c       # Tests
├── CMakeLists.txt         # Build configuration
└── README.md
```

## Requirements

- CMake >= 3.15
- C11 compatible compiler (GCC 4.7+, Clang 3.1+, MSVC 2015+)

## License

MIT
