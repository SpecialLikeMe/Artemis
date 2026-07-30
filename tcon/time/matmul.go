// Dense 320x320 matrix multiply — nested loops and array indexing.
package main

import "fmt"

const SZ = 600

var a, b, c [SZ * SZ]float64

func main() {
	for i := 0; i < SZ; i++ {
		for j := 0; j < SZ; j++ {
			a[i*SZ+j] = float64(i + j)
			b[i*SZ+j] = float64(i - j)
			c[i*SZ+j] = 0.0
		}
	}
	for i := 0; i < SZ; i++ {
		for k := 0; k < SZ; k++ {
			aik := a[i*SZ+k]
			for j := 0; j < SZ; j++ {
				c[i*SZ+j] += aik * b[k*SZ+j]
			}
		}
	}
	// Sum every element: observing one cell would let the optimiser skip the rest.
	sum := 0.0
	for q := 0; q < SZ*SZ; q++ {
		sum += c[q]
	}
	fmt.Printf("%f\n", sum)
}
