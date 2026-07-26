// PASS: istruc field default values are applied before __construct__ runs
@unsafe extern fn strcmp(a: *i8, b: *i8) i32;
istruc Config {
    let mut width: i32 = 640;
    let mut height: i32 = 480;
    let mut enabled: bool = true;
    fn __construct__(self: *Config) void { }
}
istruc Named {
    let mut value: i32 = 99;
    fn __construct__(self: *Named, v: i32) void {
        self.value = v;
    }
}
pub fn main() i32 {
    let mut c: Config();
    if (c.width != 640)   { return 1; }
    if (c.height != 480)  { return 2; }
    if (!c.enabled)       { return 3; }
    // Constructor args override defaults
    let mut n: Named(42);
    if (n.value != 42) { return 4; }
    return 0;
}
