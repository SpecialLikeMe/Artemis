@unsafe extern fn fopen(path: *i8, mode: *i8) *void;
namespace std {
namespace fs {
comptime i32 F_OK = 0;
istruc file {
    let mut fp: *void;
    fn is_open(self: *file) bool { return self.fp != (void*)0; }
}
}
}
pub fn main() i32 { return 0; }
