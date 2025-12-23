# C++ SDK

- `CMakeLists.txt`: This CMake configuration file is used to build the C++ SDK.
- `src/`: A folder containing source files for the C++ SDK (can be changed via `AGENTIZE_SOURCE_PATH`).
  - `hello.cpp`: A sample C++ source code for a function `hello` which prints "Hello, World!" to the screen.
- `include/`: A folder containing header files for the C++ SDK.
  - `hello.hpp`: The header file for the `hello` function.
- `tests/`: A folder containing test cases for the C++ SDK.
  - `test_main.cpp`: A simple case added to `ctest` which calls the `hello` function and checks the output to stdout is "Hello, World!".
- `Makefile`: The Makefile defines the build commands for the C++ SDK.
  - `make build`: `cmake -S . -B build && cmake --build build` to build the SDK.
  - `make clean`: `make -C build clean` to clean the build files.
  - `make test`: Runs the test cases for the C++ SDK.
