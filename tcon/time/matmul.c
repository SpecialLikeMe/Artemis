/* Dense 320x320 matrix multiply — nested loops and array indexing. */
#include <stdio.h>
#define SZ 600
static double a[SZ*SZ], b[SZ*SZ], c[SZ*SZ];

int main(void) {
    for (int i = 0; i < SZ; i++)
        for (int j = 0; j < SZ; j++) {
            a[i*SZ+j] = (double)(i + j);
            b[i*SZ+j] = (double)(i - j);
            c[i*SZ+j] = 0.0;
        }
    for (int i = 0; i < SZ; i++)
        for (int k = 0; k < SZ; k++) {
            double aik = a[i*SZ+k];
            for (int j = 0; j < SZ; j++)
                c[i*SZ+j] += aik * b[k*SZ+j];
        }
    /* Sum every element: observing one cell would let the optimiser skip the rest. */
    double sum = 0.0;
    for (int q = 0; q < SZ*SZ; q++) sum += c[q];
    printf("%f\n", sum);
    return 0;
}
