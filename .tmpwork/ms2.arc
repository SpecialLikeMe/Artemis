@unsafe @link_name("free") extern fn raw_free(p: *void) void;
@link_name("arc_free") fn free(p: *void) void { @unsafe { raw_free(p); } }
istruc thing {
    let x: i32;
    fn free(self: *thing, p: *void) void { free(p); }
}
pub fn main() i32 { return 0; }
