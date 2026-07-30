@include <afmt_inc.arc>
namespace demo {
fn emit(name: *i8, line: i32) void {
    let mut b: [512]i8;
    afmt(b, (u64)512, "%s at %d", .{ name, line });
    aprint("msg: %s\n", .{ b });
    afprint(stdout_file(), "err: %s at %d\n", .{ name, line });
}
}
pub fn main() i32 { demo.emit("thing", 42); return 0; }
