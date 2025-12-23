cmake_minimum_required(VERSION 3.10)
project(SDK CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Include directories
include_directories(include)

# Create a library from the SDK sources
add_library(sdk STATIC src/hello.cpp)

# Enable testing
enable_testing()

# Add test executable
add_executable(test_main tests/test_main.cpp)
target_link_libraries(test_main sdk)

# Add test to CTest
add_test(NAME HelloTest COMMAND test_main)
