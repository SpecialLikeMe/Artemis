// ?T nullable: null is assignable to ?T and to pointer types
@unsafe extern fn malloc(n: u64) *void;
@unsafe extern fn free(p: *void) void;

pub fn main() i32 {
    let mut a: ?i32= null;
    if (a != null) { return 1; }

    let mut p: *i32= null;
    if (p != null) { return 2; }

    return 0;
}
