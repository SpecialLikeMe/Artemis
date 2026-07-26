// PASS: @drsizeof follows pointer types at compile time.
// For *T, it returns sizeof(ptr) + sizeof(T).
pub fn main() i32 {
    let mut foo: i32 = 12;
    let mut bar: *i32 = &foo;

    let shallow: usize = @srsizeof(bar);  // sizeof(ptr) = 8
    let deep: usize = @drsizeof(bar);     // sizeof(ptr) + sizeof(i32) = 12

    if (shallow != (usize)8) { return 1; }
    if (deep != (usize)12) { return 2; }
    // deep must be larger than shallow
    if (deep <= shallow) { return 3; }
    return 0;
}
