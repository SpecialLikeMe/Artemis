@define <LEVEL> <>

@ifdef LEVEL_1
i32 which() { return 1; }
@elifdef LEVEL
i32 which() { return 2; }
@elifdef LEVEL_3
i32 which() { return 3; }
@else
i32 which() { return 4; }
@endif

i32 main() {
    if (which() != 2) { return 1; }
    return 0;
}
