// Test: std.toml — basic TOML parsing
extern std.toml;
@unsafe extern fn malloc(n: u64) *void;
@unsafe extern fn free(p: *void) void;
@unsafe extern fn strlen(s: *const char) u64;

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

    let mut src: *i8= "version = 3\nname = \"artemis\"\nenabled = true\n";
    let mut root: *std.toml.val= std.toml.parse(src, (i32)strlen(src), a);
    if (root == (std.toml.val*)0) { return 1; }
    if (root.kind != 6) { return 2; }  // TOML_TABLE

    let mut ver: *std.toml.val= std.toml.table_get(root, "version");
    if (ver == (std.toml.val*)0 || ver.kind != 2) { return 3; }  // TOML_INT
    if (ver.i_val != 3) { return 4; }

    let mut name: *std.toml.val= std.toml.table_get(root, "name");
    if (name == (std.toml.val*)0 || name.kind != 4) { return 5; } // TOML_STRING

    let mut enabled: *std.toml.val= std.toml.table_get(root, "enabled");
    if (enabled == (std.toml.val*)0 || enabled.kind != 1) { return 6; } // TOML_BOOL
    if (!enabled.b_val) { return 7; }

    a.deinit();
    return 0;
}
