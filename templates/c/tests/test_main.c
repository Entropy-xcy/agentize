#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include "hello.h"

int main(void) {
    /* Redirect stdout to capture output */
    FILE *output = tmpfile();
    if (!output) {
        fprintf(stderr, "Failed to create temporary file\n");
        return 1;
    }

    /* Save original stdout and redirect to temp file */
    int stdout_copy = dup(fileno(stdout));
    dup2(fileno(output), fileno(stdout));

    /* Call the hello function */
    hello();

    /* Restore stdout */
    fflush(stdout);
    dup2(stdout_copy, fileno(stdout));
    close(stdout_copy);

    /* Read the captured output */
    rewind(output);
    char buffer[256] = {0};
    fgets(buffer, sizeof(buffer), output);
    fclose(output);

    /* Check if output matches expected */
    if (strcmp(buffer, "Hello, World!\n") == 0) {
        printf("Test passed: hello() output is correct\n");
        return 0;
    } else {
        printf("Test failed: expected 'Hello, World!\\n', got '%s'\n", buffer);
        return 1;
    }
}
