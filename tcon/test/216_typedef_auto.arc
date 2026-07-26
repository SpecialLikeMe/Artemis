// PASS: using auto creates a type alias that works like the underlying type.

using Meter = i32;
using Speed = i32;

fn velocity(dist: Meter, time: i32) Speed {
    return dist / time;
}

pub fn main() i32 {
    let mut d: Meter= 100;
    let mut v: Speed= velocity(d, 10);
    return v - 10;  // expect 0
}
