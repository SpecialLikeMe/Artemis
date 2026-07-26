// PASS: comptime if emits only the taken branch.
const VERSION: i32= 2;
pub fn main() i32 {
    comptime if (VERSION == 1) {
        return 1;  // should not be emitted
    } else {
        // Only this branch should be in the IR
    }

    comptime if (1 + 1 == 2) {
        // fine
    } else {
        return 2;
    }

    return 0;
}
