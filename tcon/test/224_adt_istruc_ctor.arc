// 224: ADT enum istruc variant with user-defined __construct__ via x.variant() call
@unsafe extern fn strcmp(a: *const i8, b: *const i8) i32;

enum msg {
    empty,
    text .{
        let mut rc: *char;
        fn __construct__(self: *msg.text, a: *char) void {
            self.rc = a;
        }
    },
}

pub fn main() i32 {
    let mut bar: msg= msg.text("Hello world");
    let mut s: *char= (*bar).rc;
    if (strcmp(s, "Hello world") != 0) { return 1; }
    return 0;
}
