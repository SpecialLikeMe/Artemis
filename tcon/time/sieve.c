/* Sieve of Eratosthenes — array/memory bound. */
#include <stdio.h>
#define N 10000000
static unsigned char flags[N];

static int sieve(void) {
    for (int i = 0; i < N; i++) flags[i] = 1;
    int count = 0;
    for (int p = 2; p < N; p++) {
        if (flags[p]) {
            count++;
            for (int m = p + p; m < N; m += p) flags[m] = 0;
        }
    }
    return count;
}

int main(void) {
    int c = 0;
    for (int r = 0; r < 8; r++) c += sieve();
    printf("%d\n", c);
    return 0;
}
