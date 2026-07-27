@unsafe extern fn free(p: *void) void;
istruc thing {
    let x: i32;
    fn free(self: *thing, p: *void) void { free(p); }
}
pub fn main() i32 { return 0; }
