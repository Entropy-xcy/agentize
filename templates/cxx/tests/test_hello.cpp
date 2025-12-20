#include "__NAME__/hello.hpp"
#include <cassert>
#include <string>
#include <iostream>

int main() {
    std::string greeting = __NAME__::get_greeting();

    // Basic test: check that greeting is not empty
    assert(!greeting.empty() && "Greeting should not be empty");

    // Check that greeting contains expected text
    assert(greeting.find("Hello from") != std::string::npos &&
           "Greeting should contain 'Hello from'");

    assert(greeting.find("C++ project") != std::string::npos &&
           "Greeting should contain 'C++ project'");

    std::cout << "All tests passed!" << std::endl;

    return 0;
}
