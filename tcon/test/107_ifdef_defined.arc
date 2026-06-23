@define <HAS_FEATURE> <>

@ifdef HAS_FEATURE
i32 value() { return 7; }
@endif

i32 main() {
    if (value() != 7) { return 1; }
    return 0;
}
