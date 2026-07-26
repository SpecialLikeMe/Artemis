// std.debug — Panic handler, assertions, memory poison helpers.
// Access as: std.debug.panic(...), std.debug.assert(...), etc.

@unsafe extern fn printf(fmt: *i8, ...) i32;
@unsafe extern fn abort() void;
@unsafe extern fn malloc(n: u64) *void;

namespace std {
namespace debug {
fn panic(msg: *i8) void {
    printf("\nPANIC: %s\n", msg);
    abort();
}

fn panic_fmt(fmt_str: *i8, val: i32) void {
    printf("\nPANIC: ");
    printf(fmt_str, val);
    printf("\n");
    abort();
}

fn bounds_check(idx: i32, len: i32, context: *i8) void {
    if (idx < 0 || idx >= len) {
        printf("\nPANIC: bounds check failed in %s: index %d out of bounds [0,%d)\n",
               context, idx, len);
        abort();
    }
}

fn null_check(p: *void, context: *i8) void {
    if (p == (void*)0) {
        printf("\nPANIC: null pointer dereference in %s\n", context);
        abort();
    }
}

fn assert(cond: bool, msg: *i8) void {
@ifdef DEBUG
    if (!cond) { panic(msg); }
@endif
}

fn poison(p: *void, n: u64) void {
    let mut b: *u8= (u8*)p;
    for (let mut i: u64 = 0; i < n; i = i + 1) b[i] = (u8)(0xDEu ^ (u8)(i & 0xFFu));
}

fn is_poisoned(p: *void, n: u64) bool {
    let mut b: *u8= (u8*)p;
    let mut hits: i32= 0;
    for (let mut i: u64 = 0; i < n; i = i + 1) {
        if (b[i] == (u8)(0xDEu ^ (u8)(i & 0xFFu))) { hits = hits + 1; }
    }
    return hits > (i32)(n / 2);
}

fn breakpoint() void { }

} // namespace debug
} // namespace std