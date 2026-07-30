@unsafe extern fn malloc(n: u64) *void;
@unsafe extern fn free(p: *void) void;
@unsafe extern fn printf(f: *const i8, ...) i32;
memstr S {
    fn mmap(self: *S, align: usize, n: usize) !*void { return malloc(n); }
    fn free(self: *S, p: *void) !void { free(p); }
    fn destroy(self: *S) !void { }
}
pub @unsafe fn main() i32 {
    let mut a: S;
    // initializer position
    let mut p: *i32= (i32*)(a.mmap(16u) catch |e| { return 1; });
    p[0] = 42;
    printf("p0=%d\n", p[0]);
    // statement position
    a.free((void*)p) catch |e| { };
    a.destroy() catch |e| { };
    return 0;
}
