// Test @shcopy, @decopy, @move operators
// PASS PASS PASS PASS PASS PASS
int puts(i8* s);

istruc Vec2 {
    int x;
    int y;
}

int main() {
    Vec2 a;
    a.x = 3; a.y = 4;

    // @shcopy — explicit shallow copy (same as plain assignment)
    Vec2 b = @shcopy(a);
    if (b.x == 3 && b.y == 4) { puts("PASS"); } else { puts("FAIL shcopy values"); }
    b.x = 99;
    if (a.x == 3) { puts("PASS"); } else { puts("FAIL shcopy independence"); }

    // @decopy — deep copy (falls back to shallow for structs without __deep_copy__)
    Vec2 c = @decopy(a);
    if (c.x == 3 && c.y == 4) { puts("PASS"); } else { puts("FAIL decopy values"); }
    c.x = 55;
    if (a.x == 3) { puts("PASS"); } else { puts("FAIL decopy independence"); }

    // @move — copy value then zero source
    Vec2 d;
    d.x = 10; d.y = 20;
    Vec2 e = @move(d);
    if (e.x == 10 && e.y == 20) { puts("PASS"); } else { puts("FAIL move values"); }
    if (d.x == 0 && d.y == 0)   { puts("PASS"); } else { puts("FAIL move zeroed"); }

    return 0;
}
