// Test: std.unordered_set — hash set with i32 keys
extern std.unordered_set;
@unsafe extern fn malloc(n: u64) *void;
@unsafe extern fn free(p: *void) void;

memstr Bump {
    let mut base: *void; let mut used: u64; let mut cap: u64;
    fn __construct__(self: *Bump, n: u64) void { self.base=malloc(n); self.used=0; self.cap=n; }
    fn mmap(self: *Bump, align: usize, n: usize) !*void {
        let mut al: u64=(n+7)&~(u64)7;
        if (self.used+al>self.cap) { return (void*)0; }
        let mut p: *void=(void*)((u8*)self.base+self.used); self.used=self.used+al; return p;
    }
    fn rmap(self: *Bump, align: usize, p: *void, n: iofs) !*void { return error.Unsupported; }
    fn deinit(self: *Bump) !void { free(self.base); }
}

pub fn main() i32 {
    let mut a: Bump(32768);
    let mut s: std.unordered_set<i32>(16, a);

    s.insert(5,  a);
    s.insert(3,  a);
    s.insert(8,  a);
    s.insert(1,  a);
    s.insert(3,  a);  // duplicate — should not increase size

    if (s.size() != 4)    { return 1; }
    if (!s.contains(5))   { return 2; }
    if (!s.contains(1))   { return 3; }
    if (s.contains(99))   { return 4; }
    if (s.is_empty())     { return 5; }

    s.remove(3);
    if (s.contains(3))    { return 6; }
    if (s.size() != 3)    { return 7; }

    s.deinit(a);
    a.deinit();
    return 0;
}
