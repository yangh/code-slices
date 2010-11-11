/*
 * int-bit-counter.c - Count how many bit in a integer
 *
 * Author: pen9u1n
 *
 * History:
 *   2011-11-11 Initial version.
 */

#include <stdio.h>
#include <stdlib.h>

int
int_bit_counter (int n)
{
    int len = sizeof(int) * 8;
    int count = 0;
    int i;

    while (len--) {
        count += ((n >> len) & 0x1);
    }

    return count;
}

int main(int argc, char *argv[])
{
    int n = 0xF00D;

    if (argc > 1) {
        n = atoi (argv[1]);
    }

    printf("There are %d '1's in integer %d\n", int_bit_counter(n), n);

    return 0;
}

