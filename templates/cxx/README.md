# ${PROJECT_NAME}

${PROJ_DESC}

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
│       └── hello.hpp      # Public headers
├── src/
│   ├── hello.cpp          # Implementation
│   └── main.cpp           # Entry point
├── tests/
│   └── test_hello.cpp     # Tests
├── CMakeLists.txt         # Build configuration
└── README.md
```

## Requirements

- CMake >= 3.15
- C++17 compatible compiler (GCC 7+, Clang 5+, MSVC 2017+)

## License

MIT
