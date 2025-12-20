cmake_minimum_required(VERSION 3.15)

project(__PROJECT_NAME__
    VERSION 0.1.0
    DESCRIPTION "TODO: Add project description"
    LANGUAGES CXX
)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Build type
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# Compiler flags
if(MSVC)
    add_compile_options(/W4)
else()
    add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# Include directories
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/src
)

# Source files
set(SOURCES
    src/hello.cpp
    src/main.cpp
)

# Executable
add_executable(main ${SOURCES})

# Installation rules
install(TARGETS main
    RUNTIME DESTINATION bin
)

install(DIRECTORY include/
    DESTINATION include
    FILES_MATCHING PATTERN "*.hpp" PATTERN "*.h"
)

# Enable testing
enable_testing()

# Add test executable
add_executable(test_hello tests/test_hello.cpp src/hello.cpp)
add_test(NAME HelloTest COMMAND test_hello)
