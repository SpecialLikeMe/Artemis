@define <FLAG> <>
@undef FLAG

@ifndef FLAG
i32 val() { return 5; }
@else
i32 val() { return 0; }
@endif

i32 main() {
    if (val() != 5) { return 1; }
    return 0;
}
