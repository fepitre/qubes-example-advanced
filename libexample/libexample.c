/*
 * Qubes Example Advanced - dummy shared library
 *
 * This is a minimal C library used as a placeholder to test
 * arch-specific (x86_64) RPM builds with debuginfo generation
 * and devel subpackages in qubes-builderv2 CI.
 */

#include "example.h"
#include <stdio.h>

int example_init(void)
{
    return 0;
}

const char *example_version(void)
{
    return EXAMPLE_VERSION;
}

void example_hello(void)
{
    printf("Hello from libexample!\n");
}
