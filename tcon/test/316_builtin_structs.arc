// Verify that type_info (ADT enum) and memstr are compiler builtins — no @include needed.

pub fn main() i32 {
    // type_info accessible without @include std.typeinfo
    // New ADT format: { __tag: i32, __payload: [72]i8 }
    let mut ip: *type_info = @typeinfo(i32);
    if (ip == (type_info*)0) { return 1; }
    // i32 is the Int variant (tag 2)
    if (ip.__tag != 2) { return 4; }

    // @typeinfo on a pointer type returns Pointer variant (tag 9)
    let mut pp: *type_info = @typeinfo(*i32);
    if (pp == (type_info*)0) { return 2; }
    if (pp.__tag != 9) { return 3; }

    // memstr is a named istruc type without @include; field renamed 'data' -> 'ptr'
    let mut ms: memstr;
    ms.ptr    = (i8*)0;
    ms.vtable = (__vtable__*)0;
    if (ms.ptr != (i8*)0) { return 5; }

    return 0;
}
