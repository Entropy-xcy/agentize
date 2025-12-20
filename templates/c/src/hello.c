#include "__NAME__/hello.h"
#include <stdio.h>

const char* get_greeting(void) {
    return "Hello from ${PROJECT_NAME}!\nThis is a C project template.";
}

void print_greeting(void) {
    printf("%s\n", get_greeting());
}
