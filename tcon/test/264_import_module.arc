// Test @import as a proper parser-level module system.
// const NAME = @import("path") wraps the file in a namespace named NAME.
const math = @import("inc/math_helpers.arc");

pub fn main() i32 {
    if (math.add(3, 4) != 7)   { return 1; }
    if (math.mul(3, 4) != 12)  { return 2; }
    if (math.square(5) != 25)  { return 3; }
    return 0;
}
