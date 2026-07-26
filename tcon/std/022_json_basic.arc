// Test: std.json — basic JSON parsing and value access
extern std.json;
@unsafe extern fn malloc(n: u64) *void;
@unsafe extern fn free(p: *void) void;
@unsafe extern fn strlen(s: *const char) u64;

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

pub @unsafe fn main() i32 {
    let mut a: Bump(65536);

    // Parse integer
    let mut s1: *i8= "42";
    let mut v1: *std.json.json_val= std.json.parse(s1, (i32)strlen(s1), a);
    if (v1 == (std.json.json_val*)0) { return 1; }
    if (v1.kind != 2) { return 2; }  // JSON_INT
    if (v1.i_val != 42) { return 3; }

    // Parse boolean
    let mut s2: *i8= "true";
    let mut v2: *std.json.json_val= std.json.parse(s2, (i32)strlen(s2), a);
    if (v2 == (std.json.json_val*)0 || v2.kind != 1) { return 4; } // JSON_BOOL
    if (!v2.b_val) { return 5; }

    // Parse array
    let mut s3: *i8= "[1,2,3]";
    let mut v3: *std.json.json_val= std.json.parse(s3, (i32)strlen(s3), a);
    if (v3 == (std.json.json_val*)0 || v3.kind != 5) { return 6; } // JSON_ARRAY
    if (v3.arr_len != 3) { return 7; }
    if (v3.arr_items[0].i_val != 1) { return 8; }
    if (v3.arr_items[2].i_val != 3) { return 9; }

    // Parse object
    let mut s4: *i8= "{\"n\":7}";
    let mut v4: *std.json.json_val= std.json.parse(s4, (i32)strlen(s4), a);
    if (v4 == (std.json.json_val*)0 || v4.kind != 6) { return 10; } // JSON_OBJECT
    let mut gv: *std.json.json_val= std.json.object_get(v4, "n");
    if (gv == (std.json.json_val*)0 || gv.i_val != 7) { return 11; }

    a.deinit();
    return 0;
}
