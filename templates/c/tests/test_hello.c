#include "__NAME__/hello.h"
#include <assert.h>
#include <string.h>
#include <stdio.h>

int main(void) {
    const char* greeting = get_greeting();

    // Basic test: check that greeting is not NULL
    assert(greeting != NULL && "Greeting should not be NULL");

    // Check that greeting contains expected text
    assert(strstr(greeting, "Hello from") != NULL &&
           "Greeting should contain 'Hello from'");

    assert(strstr(greeting, "C project") != NULL &&
           "Greeting should contain 'C project'");

    printf("All tests passed!\n");

    return 0;
}
