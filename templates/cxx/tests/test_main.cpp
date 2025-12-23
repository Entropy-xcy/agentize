#include <iostream>
#include <sstream>
#include <string>
#include "hello.hpp"

int main() {
    // Redirect cout to capture output
    std::streambuf* original_cout = std::cout.rdbuf();
    std::ostringstream captured_output;
    std::cout.rdbuf(captured_output.rdbuf());

    // Call the hello function
    hello();

    // Restore cout
    std::cout.rdbuf(original_cout);

    // Check if output matches expected
    std::string output = captured_output.str();
    if (output == "Hello, World!\n") {
        std::cout << "Test passed: hello() output is correct" << std::endl;
        return 0;
    } else {
        std::cout << "Test failed: expected 'Hello, World!\\n', got '" << output << "'" << std::endl;
        return 1;
    }
}
