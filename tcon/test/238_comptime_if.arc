// Test comptime if: compile-time branch selection with dead code elimination
// PASS PASS PASS PASS
int puts(i8* s);

comptime int DEBUG = 0;
comptime int VERSION = 3;

int main() {
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
