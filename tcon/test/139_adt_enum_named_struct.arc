// 139: ADT enum — named struct variant
enum event {
    none,
    key_press { i32 key; i32 modifiers; },
    mouse_move { f32 x; f32 y; },
}

i32 main() {
    event e;
    e = event::key_press { .key = 65, .modifiers = 0 };
    i32 k = (*e).key;
    if (k != 65) { return 1; }

    e = event::mouse_move { .x = 1.5, .y = 2.5 };
    f32 xv = (*e).x;
    if (xv < 1.4 || xv > 1.6) { return 2; }
    return 0;
}
