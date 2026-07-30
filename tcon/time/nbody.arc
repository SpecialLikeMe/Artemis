// N-body simulation — floating-point heavy, from the Computer Language Benchmarks Game.
extern std.fmt;
@unsafe extern fn sqrt(x: f64) f64;
fn arc_sqrt(x: f64) f64 { let mut r: f64; @unsafe { r = sqrt(x); } return r; }

comptime i32 NB = 5;

let mut px: [5]f64;  let mut py: [5]f64;  let mut pz: [5]f64;
let mut vx: [5]f64;  let mut vy: [5]f64;  let mut vz: [5]f64;
let mut mass: [5]f64;

fn setup() void {
    let mut pi: f64= 3.141592653589793;
    let mut solar: f64= 4.0 * pi * pi;
    let mut dpy: f64= 365.24;

    px[0]=0.0; py[0]=0.0; pz[0]=0.0; vx[0]=0.0; vy[0]=0.0; vz[0]=0.0; mass[0]=solar;

    px[1]=4.84143144246472090;   py[1]=-1.16032004402742839;  pz[1]=-0.103622044471123109;
    vx[1]=0.00166007664274403694*dpy; vy[1]=0.00769901118419740425*dpy; vz[1]=-0.0000690460016972063023*dpy;
    mass[1]=0.000954791938424326609*solar;

    px[2]=8.34336671824457987;   py[2]=4.12479856412430479;   pz[2]=-0.403523417114321381;
    vx[2]=-0.00276742510726862411*dpy; vy[2]=0.00499852801234917238*dpy; vz[2]=0.0000230417297573763929*dpy;
    mass[2]=0.000285885980666130812*solar;

    px[3]=12.8943695621391310;   py[3]=-15.1111514016986312;  pz[3]=-0.223307578892655734;
    vx[3]=0.00296460137564761618*dpy; vy[3]=0.00237847173959480950*dpy; vz[3]=-0.0000296589568540237556*dpy;
    mass[3]=0.0000436624404335156298*solar;

    px[4]=15.3796971148509165;   py[4]=-25.9193146099879641;  pz[4]=0.179258772950371181;
    vx[4]=0.00268067772490389322*dpy; vy[4]=0.00162824170038242295*dpy; vz[4]=-0.0000951592254519715870*dpy;
    mass[4]=0.0000515138902046611451*solar;

    // Offset momentum so the system's centre of mass stays put.
    let mut sx: f64= 0.0; let mut sy: f64= 0.0; let mut sz: f64= 0.0;
    let mut i: i32= 0;
    while (i < NB) {
        sx = sx + vx[i] * mass[i];
        sy = sy + vy[i] * mass[i];
        sz = sz + vz[i] * mass[i];
        i = i + 1;
    }
    vx[0] = -sx / solar; vy[0] = -sy / solar; vz[0] = -sz / solar;
}

fn advance(dt: f64) void {
    let mut i: i32= 0;
    while (i < NB) {
        let mut j: i32= i + 1;
        while (j < NB) {
            let mut dx: f64= px[i] - px[j];
            let mut dy: f64= py[i] - py[j];
            let mut dz: f64= pz[i] - pz[j];
            let mut d2: f64= dx*dx + dy*dy + dz*dz;
            let mut dist: f64= arc_sqrt(d2);
            let mut mag: f64= dt / (d2 * dist);
            vx[i] = vx[i] - dx * mass[j] * mag;
            vy[i] = vy[i] - dy * mass[j] * mag;
            vz[i] = vz[i] - dz * mass[j] * mag;
            vx[j] = vx[j] + dx * mass[i] * mag;
            vy[j] = vy[j] + dy * mass[i] * mag;
            vz[j] = vz[j] + dz * mass[i] * mag;
            j = j + 1;
        }
        i = i + 1;
    }
    i = 0;
    while (i < NB) {
        px[i] = px[i] + dt * vx[i];
        py[i] = py[i] + dt * vy[i];
        pz[i] = pz[i] + dt * vz[i];
        i = i + 1;
    }
}

fn energy() f64 {
    let mut e: f64= 0.0;
    let mut i: i32= 0;
    while (i < NB) {
        e = e + 0.5 * mass[i] * (vx[i]*vx[i] + vy[i]*vy[i] + vz[i]*vz[i]);
        let mut j: i32= i + 1;
        while (j < NB) {
            let mut dx: f64= px[i] - px[j];
            let mut dy: f64= py[i] - py[j];
            let mut dz: f64= pz[i] - pz[j];
            e = e - (mass[i] * mass[j]) / arc_sqrt(dx*dx + dy*dy + dz*dz);
            j = j + 1;
        }
        i = i + 1;
    }
    return e;
}

pub fn main() i32 {
    setup();
    let mut n: i32= 20000000;
    let mut i: i32= 0;
    while (i < n) { advance(0.01); i = i + 1; }
    std.fmt.out_print_f64(energy());
    std.fmt.out_println("");
    return 0;
}
