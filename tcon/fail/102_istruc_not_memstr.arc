// Passing an istruc as &memstr must be rejected by the compiler.
extern fn malloc(n: u64) *void;
extern fn free(p: *void) void;

istruc BadAlloc {
    let mut ptr: *void;
    fn __construct__(self: *BadAlloc) void { self.ptr = (void*)0; }
}

// This function requires a memstr allocator
fn needs_memstr(&memstr a) void {
    // body intentionally empty (just testing type checking)
}

fn main() i32 {
    let mut b: BadAlloc;
    needs_memstr(b);  // ERROR: istruc is not a valid &memstr
    return 0;
}
