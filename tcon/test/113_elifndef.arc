@define <A> <>

@ifdef A
i32 which() { return 1; }
@elifndef B
i32 which() { return 2; }
@else
i32 which() { return 3; }
@endif

i32 main() {
    if (which() != 1) { return 1; }
    return 0;
}
