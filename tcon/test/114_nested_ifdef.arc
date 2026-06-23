@define <OUTER> <>
@define <INNER> <>

@ifdef OUTER
@ifdef INNER
i32 val() { return 3; }
@endif
@endif

i32 main() {
    if (val() != 3) { return 1; }
    return 0;
}
