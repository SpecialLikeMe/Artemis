@define <OUTER> <>

@ifdef OUTER
@ifdef INNER_MISSING
i32 val() { return 1; }
@else
i32 val() { return 2; }
@endif
@endif

i32 main() {
    if (val() != 2) { return 1; }
    return 0;
}
