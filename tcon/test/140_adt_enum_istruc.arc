// 140: ADT enum — istruc variant with methods
enum io_error {
    success,
    fatal .{
        const msg: *i8;
        let mut code: i32;
        fn get_code(self: *const fatal) i32 { return self.code; }
    },
}

pub fn main() i32 {
    let mut e: io_error;
    e = io_error.success;

    e = io_error.fatal .{ .msg = "disk full", .code = 28 };
    let mut c: i32= e.get_code();
    if (c != 28) { return 1; }
    return 0;
}
