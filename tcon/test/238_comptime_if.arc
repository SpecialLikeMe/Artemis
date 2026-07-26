// Test comptime if: compile-time branch selection with dead code elimination
// PASS PASS PASS PASS
@unsafe extern fn puts(s: *i8) int;

const DEBUG: int= 0;
const VERSION: int= 3;

pub @unsafe fn main() int {
    comptime if (DEBUG) {
        puts("FAIL debug should be off");
    } else {
        puts("PASS debug off");
    }

    comptime if (VERSION == 3) {
        puts("PASS version 3");
    } else {
        puts("FAIL wrong version");
    }

    comptime if (0) {
        puts("FAIL literal false");
    } else {
        puts("PASS literal false branch");
    }

    comptime if (1) {
        puts("PASS literal true");
    }

    return 0;
}
