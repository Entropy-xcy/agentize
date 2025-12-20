#include "__NAME__/hello.hpp"
#include <iostream>

namespace __NAME__ {

std::string get_greeting() {
    return "Hello from ${PROJECT_NAME}!\nThis is a C++ project template.";
}

void print_greeting() {
    std::cout << get_greeting() << std::endl;
}

} // namespace __NAME__
