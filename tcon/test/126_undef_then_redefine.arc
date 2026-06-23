@define <X> <1>
@undef X
@define <X> <99>

i32 main() {
    i32 v = X;
    if (v != 99) { return 1; }
    return 0;
}
