@unsafe @link_name("free") extern fn raw_free(p: *void) void;
@link_name("arc_free") fn free(p: *void) void { @unsafe { raw_free(p); } }
struct __vt2 { let free: [](*void, *void)void; }
istruc memstr {
    let ptr: *void;
    let vtable: *__vt2;
    fn free(self: *memstr, data: *void) void { self.vtable.free(self.ptr, data); }
}
pub fn main() i32 { return 0; }
