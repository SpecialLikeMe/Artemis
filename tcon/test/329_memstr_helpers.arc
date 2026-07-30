// Test: memstr's builtin helper layer — typed create, zeroed, and the five vtable ops.
// Regression: create returned null because comptime type parameters were only
// recognised for free functions with primitive type arguments. A user-defined type
// arrived as a plain identifier, and generic *methods* were never monomorphized.
@unsafe extern fn malloc(n: u64) *void;
@unsafe extern fn free(p: *void) void;

struct Pt { let x: i32; let y: i32; }

memstr Sys {
    fn mmap(self: *Sys, align: usize, n: usize) !*void                  { return malloc(n); }
    fn rsmap(self: *Sys, p: *void, n: iofs) bool       { return false; }
    fn rmap(self: *Sys, align: usize, p: *void, n: iofs) !*void       { return malloc((u64)n); }
    fn free(self: *Sys, p: *void) !void                 { free(p); }
    fn destroy(self: *Sys) !void                        { }
}

// A partial allocator: no free/rsmap/destroy slots. Calling them must be a no-op,
// not a crash.
memstr Partial {
    fn mmap(self: *Partial, align: usize, n: usize) !*void { return malloc(n); }
}

fn use_full(a: &memstr) i32 {
    // Every fallible op returns an error union, so each call site handles failure.
    let mut p: *Pt= a.create(Pt) catch |e| { return -1; };  // typed allocation via comptime T
    if (p == (Pt*)0) { return -1; }
    p.x = 3; p.y = 4;
    let mut sum: i32= p.x + p.y;

    let mut zraw: *void= a.zeroed((usize)8) catch |e| { return -2; };  // zeroed bytes
    let mut z: *u8= (u8*)zraw;
    if (z == (u8*)0) { return -2; }
    sum = sum + (i32)z[0];                 // must be 0

    let mut rraw: *void= a.mmap((usize)8) catch |e| { return -3; };    // raw vtable op
    let mut r: *i32= (i32*)rraw;
    if (r == (i32*)0) { return -3; }
    r[0] = 5;
    sum = sum + r[0];

    a.free((void*)p) catch |e| { return -4; };
    a.free((void*)z) catch |e| { return -4; };
    a.free((void*)r) catch |e| { return -4; };
    a.destroy() catch |e| { return -5; };
    return sum;                            // 3 + 4 + 0 + 5 = 12
}

fn use_partial(a: &memstr) i32 {
    let mut praw: *void= a.mmap((usize)8) catch |e| { return -1; };
    let mut p: *i32= (i32*)praw;
    if (p == (i32*)0) { return -1; }
    p[0] = 9;
    let mut v: i32= p[0];
    a.free((void*)p) catch |e| { return -2; };   // no free slot — no-op, must not crash
    a.destroy() catch |e| { return -3; };        // no destroy slot — no-op
    if (!a.rsmap((void*)p, (iofs)16)) { v = v + 1; }  // no rsmap slot — false
    return v;            // 10
}

pub fn main() i32 {
    let mut s: Sys;
    if (use_full(s) != 12) { return 1; }
    let mut q: Partial;
    if (use_partial(q) != 10) { return 2; }
    return 0;
}
