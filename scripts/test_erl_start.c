#include <stdio.h>

// Declare the function signature (if not already in a header file)
extern void erl_start(int argc, char **argv);

int main() {
    printf("Testing erl_start...\n");

    // Create test arguments
    int argc = 1;
    char *argv[] = {"test_program", NULL};

    // Call erl_start
    erl_start(argc, argv);

    printf("erl_start executed successfully!\n");
    return 0;
}