// N-body simulation — floating-point heavy, from the Computer Language Benchmarks Game.
package main

import (
	"fmt"
	"math"
)

const NB = 5

var px, py, pz, vx, vy, vz, mass [NB]float64

func setup() {
	pi := 3.141592653589793
	solar := 4.0 * pi * pi
	dpy := 365.24
	mass[0] = solar
	px[1], py[1], pz[1] = 4.84143144246472090, -1.16032004402742839, -0.103622044471123109
	vx[1], vy[1], vz[1] = 0.00166007664274403694*dpy, 0.00769901118419740425*dpy, -0.0000690460016972063023*dpy
	mass[1] = 0.000954791938424326609 * solar
	px[2], py[2], pz[2] = 8.34336671824457987, 4.12479856412430479, -0.403523417114321381
	vx[2], vy[2], vz[2] = -0.00276742510726862411*dpy, 0.00499852801234917238*dpy, 0.0000230417297573763929*dpy
	mass[2] = 0.000285885980666130812 * solar
	px[3], py[3], pz[3] = 12.8943695621391310, -15.1111514016986312, -0.223307578892655734
	vx[3], vy[3], vz[3] = 0.00296460137564761618*dpy, 0.00237847173959480950*dpy, -0.0000296589568540237556*dpy
	mass[3] = 0.0000436624404335156298 * solar
	px[4], py[4], pz[4] = 15.3796971148509165, -25.9193146099879641, 0.179258772950371181
	vx[4], vy[4], vz[4] = 0.00268067772490389322*dpy, 0.00162824170038242295*dpy, -0.0000951592254519715870*dpy
	mass[4] = 0.0000515138902046611451 * solar
	var sx, sy, sz float64
	for i := 0; i < NB; i++ {
		sx += vx[i] * mass[i]
		sy += vy[i] * mass[i]
		sz += vz[i] * mass[i]
	}
	vx[0], vy[0], vz[0] = -sx/solar, -sy/solar, -sz/solar
}

func advance(dt float64) {
	for i := 0; i < NB; i++ {
		for j := i + 1; j < NB; j++ {
			dx, dy, dz := px[i]-px[j], py[i]-py[j], pz[i]-pz[j]
			d2 := dx*dx + dy*dy + dz*dz
			dist := math.Sqrt(d2)
			mag := dt / (d2 * dist)
			vx[i] -= dx * mass[j] * mag
			vy[i] -= dy * mass[j] * mag
			vz[i] -= dz * mass[j] * mag
			vx[j] += dx * mass[i] * mag
			vy[j] += dy * mass[i] * mag
			vz[j] += dz * mass[i] * mag
		}
	}
	for i := 0; i < NB; i++ {
		px[i] += dt * vx[i]
		py[i] += dt * vy[i]
		pz[i] += dt * vz[i]
	}
}

func energy() float64 {
	var e float64
	for i := 0; i < NB; i++ {
		e += 0.5 * mass[i] * (vx[i]*vx[i] + vy[i]*vy[i] + vz[i]*vz[i])
		for j := i + 1; j < NB; j++ {
			dx, dy, dz := px[i]-px[j], py[i]-py[j], pz[i]-pz[j]
			e -= (mass[i] * mass[j]) / math.Sqrt(dx*dx+dy*dy+dz*dz)
		}
	}
	return e
}

func main() {
	setup()
	for i := 0; i < 20000000; i++ {
		advance(0.01)
	}
	fmt.Printf("%f\n", energy())
}
