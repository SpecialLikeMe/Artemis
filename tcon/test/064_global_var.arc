let mut counter: i32= 0;

fn inc() void { counter = counter + 1; }
fn reset() void { counter = 0; }

pub fn main() i32 {
    if (counter != 0) { return 1; }
    inc(); inc(); inc();
    if (counter != 3) { return 2; }
    reset();
    if (counter != 0) { return 3; }
    return 0;
}
