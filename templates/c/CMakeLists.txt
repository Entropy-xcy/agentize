cmake_minimum_required(VERSION 3.10)
project(SDK C)

# Set C standard
set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Include directories
include_directories(include)

# Create a library from the SDK sources
add_library(sdk STATIC hello.c)

# Enable testing
enable_testing()

# Add test executable
add_executable(test_main tests/test_main.c)
target_link_libraries(test_main sdk)

# Add test to CTest
add_test(NAME HelloTest COMMAND test_main)
