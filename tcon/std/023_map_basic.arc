// Test: std.map — ordered red-black tree map with i32 keys/values
extern std.map;
@unsafe extern fn malloc(n: u64) *void;
@unsafe extern fn free(p: *void) void;

memstr Bump {
    let mut base: *void; let mut used: u64; let mut cap: u64;
    fn __construct__(self: *Bump, n: u64) void { self.base=malloc(n); self.used=0; self.cap=n; }
    fn mmap(self: *Bump, n: u64) *void {
        let mut al: u64=(n+7)&~(u64)7;
        if (self.used+al>self.cap) { return (void*)0; }
        let mut p: *void=(void*)((u8*)self.base+self.used); self.used=self.used+al; return p;
    }
    fn rmap(self: *Bump, p: *void, n: u64) void {}
    fn deinit(self: *Bump) void { free(self.base); }
}

pub fn main() i32 {
    let mut a: Bump(65536);
    let mut m: std.map<i32,i32>(a);

    m.insert(10, 100, a);
    m.insert(5,  50,  a);
    m.insert(20, 200, a);
    m.insert(1,  10,  a);

    if (m.size() != 4) { return 1; }
    if (!m.contains(10)) { return 2; }
    if (!m.contains(5))  { return 3; }
    if (m.contains(99))  { return 4; }

    let mut v10: *i32= m.get(10);
    if (v10 == (i32*)0 || *v10 != 100) { return 5; }

    let mut v5: *i32= m.get(5);
    if (v5 == (i32*)0 || *v5 != 50) { return 6; }

    // Update existing key
    m.insert(10, 999, a);
    let mut v10b: *i32= m.get(10);
    if (v10b == (i32*)0 || *v10b != 999) { return 7; }

    if (m.is_empty()) { return 8; }

    a.deinit();
    return 0;
}
