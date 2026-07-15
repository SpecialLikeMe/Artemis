// Test @typeinfo builtin for primitive types
// PASS PASS PASS PASS PASS
int puts(i8* s);

int main() {
    type_info* ti = @typeinfo(i32);
    if (ti != (type_info*)0) { puts("PASS"); } else { puts("FAIL null"); return 1; }
    if (ti.kind == 0)   { puts("PASS"); } else { puts("FAIL kind"); return 2; }
    if (ti.bits == 32)  { puts("PASS"); } else { puts("FAIL bits"); return 3; }
    if (ti.size == 4)   { puts("PASS"); } else { puts("FAIL size"); return 4; }

    type_info* tu = @typeinfo(u8);
    if (tu.bits == 8)   { puts("PASS"); } else { puts("FAIL u8 bits"); return 5; }

    return 0;
}
