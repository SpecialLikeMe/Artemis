@ifndef RELEASE

i32 mode() { return 1; }

@else

i32 mode() { return 0; }

@endif

i32 main() {
    if (mode() != 1) { return 1; }
    return 0;
}
