// Sieve of Eratosthenes — array/memory bound.
package main

import "fmt"

const N = 10000000

var flags [N]uint8

func sieve() int {
	for i := 0; i < N; i++ {
		flags[i] = 1
	}
	count := 0
	for p := 2; p < N; p++ {
		if flags[p] != 0 {
			count++
			for m := p + p; m < N; m += p {
				flags[m] = 0
			}
		}
	}
	return count
}

func main() {
	c := 0
	for r := 0; r < 8; r++ {
		c += sieve()
	}
	fmt.Println(c)
}
