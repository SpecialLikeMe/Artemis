namespace std {
namespace fs {
istruc file {
    let mut fp: *void;
    fn is_open(self: *file) bool { return self.fp != (void*)0; }
}
}
}
pub fn main() i32 { return 0; }
