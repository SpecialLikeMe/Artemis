// Test: JSON arrays and objects grow beyond the old fixed 256-entry limit.
// Regression: parse_array/parse_object collected into a [256] stack buffer, so a
// larger document either overflowed the stack or was rejected outright.
extern std.json;
@unsafe extern fn malloc(n: u64) *void;
@unsafe extern fn free(p: *void) void;

memstr Bump {
    let mut base: *void; let mut used: u64; let mut cap: u64;
    fn __construct__(self: *Bump, n: u64) void { self.base=malloc(n); self.used=0; self.cap=n; }
    fn mmap(self: *Bump, n: u64) *void {
        let mut al: u64= (n+7)&~(u64)7;
        if (self.used+al>self.cap) { return (void*)0; }
        let mut p: *void= (void*)((u8*)self.base+self.used);
        self.used=self.used+al; return p;
    }
    fn rmap(self: *Bump, p: *void, n: u64) void {}
    fn deinit(self: *Bump) void { free(self.base); }
}

pub fn main() i32 {
    let mut a: Bump(1048576);

    // Build "[7,7,...,7]" with 1000 elements — well past the old 256 cap.
    let mut buf: [8192]i8;
    let mut pos: i32= 0;
    buf[pos] = '['; pos = pos + 1;
    for (let mut i: i32 = 0; i < 1000; i = i + 1) {
        if (i > 0) { buf[pos] = ','; pos = pos + 1; }
        buf[pos] = '7'; pos = pos + 1;
    }
    buf[pos] = ']'; pos = pos + 1;
    buf[pos] = 0;

    let mut v: *std.json.json_val= std.json.parse(buf, pos - 1, a);
    if (v == (std.json.json_val*)0) { a.deinit(); return 1; }
    if (v.arr_len != 1000)          { a.deinit(); return 2; }
    // Elements past the old cap must be real, not truncated or garbage.
    if (v.arr_items[999].i_val != 7) { a.deinit(); return 3; }
    if (v.arr_items[256].i_val != 7) { a.deinit(); return 4; }

    a.deinit();
    return 0;
}
