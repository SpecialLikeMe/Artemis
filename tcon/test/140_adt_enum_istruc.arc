// 140: ADT enum — istruc variant with methods
enum io_error {
    success,
    fatal .{
        const i8* msg;
        i32 code;
        i32 get_code(const fatal* self) { return self.code; }
    },
}

i32 main() {
    io_error e;
    e = io_error.success;

    e = io_error.fatal .{ .msg = "disk full", .code = 28 };
    i32 c = e.get_code();
    if (c != 28) { return 1; }
    return 0;
}
